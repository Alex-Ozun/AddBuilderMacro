import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct AddBuilderMacro: MemberMacro {
    public static func expansion<Declaration: DeclGroupSyntax, Context: MacroExpansionContext>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax] {
      guard let memberName = declaration.asProtocol(IdentifiedDeclSyntax.self)?.identifier.text else {
          fatalError()
      }
      guard declaration.is(StructDeclSyntax.self) else {
          context.diagnose(
            AddBuilderMacroDiagnostic.requiresStruct.diagnose(at: node)
          )
          return []
      }
      let variables = declaration.memberBlock.members
        .compactMap { $0.decl.as(VariableDeclSyntax.self) }
        .compactMap(Variable.init)
      
      let variablesBlock: [String] = try variables.map { variable in
        let defaultValue = try variable.getDefaultValue()
        return "var \(variable.name): \(variable.type) = \(defaultValue)"
      }
      let variablesBlockString = variablesBlock.joined(separator: "\n")
      
      let methodsBlock: [String] = variables.map { variable in
        return """
        func \(variable.name)(_ \(variable.name): \(variable.type)) -> Self {
          var copy = self
          copy.\(variable.name) = \(variable.name)
          return copy
        }
        """
      }
      let methodsBlockString = methodsBlock.joined(separator: "\n\n")
      
      let argumentsBlockString = variables.map { variable in
        return "\(variable.name): \(variable.name)"
      }.joined(separator: ",\n")
      return ["""
      struct Builder {
      \(raw: variablesBlockString)
      
      \(raw: methodsBlockString)
      
      init() {}
      
      func build() -> \(raw: memberName) {
        \(raw: memberName) (
          \(raw: argumentsBlockString)
        )
      }
      }
      """
      ]
    }
}

struct Variable {
  let name: String
  let type: TypeSyntax
  let defaultValue: String?
  
  func getDefaultValue() throws -> String {
    try defaultValue ?? type.getDefaultValue()
  }
  
  init?(_ variableSyntax: VariableDeclSyntax) {
    guard let binding = variableSyntax.bindings.first,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type else {
      return nil
    }
    self.name = name
    self.type = type
    self.defaultValue = variableSyntax.attributes?.first?.as(AttributeSyntax.self)?.argument?.as(TupleExprElementListSyntax.self)?.first?.expression.description
  }
}

@main
struct AddBuilderMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AddBuilderMacro.self,
    ]
}

enum TypeError: Error {
  case unsupportedType
}

extension TypeSyntax {
  func getDefaultValue() throws -> String {
    if let type = self.as(SimpleTypeIdentifierSyntax.self) {
      return try type.getDefaultValue()
    } else if self.is(ArrayTypeSyntax.self) || self.is(DictionaryTypeSyntax.self){
      return self.description + "()"
    } else if let type = self.as(OptionalTypeSyntax.self) {
      do {
        return try type.wrappedType.getDefaultValue()
      } catch {
        return "nil"
      }
    } else if let type = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return try type.wrappedType.getDefaultValue()
    } else if let type = self.as(FunctionTypeSyntax.self) {
      let argumentList = type.arguments.isEmpty
      ? ""
      : Array(repeating: "_", count: type.arguments.count).joined(separator: ",") + " in"
      let returnValue = try type.output.returnType.getDefaultValue()
      return "{ \(argumentList) \(returnValue) }"
    } else if let type = self.as(TupleTypeSyntax.self) {
      let values = try type.elements.map { try $0.type.getDefaultValue() }
      return "(\(values.joined(separator: ",")))"
    } else {
      throw TypeError.unsupportedType
    }
  }
}

extension SimpleTypeIdentifierSyntax {
  func getDefaultValue() throws -> String {
    switch name.text {
    case "Duration":
      return ".zero"
      
    case "Range":
      guard let boundType = genericArgumentClause?.arguments.first?.argumentType.description else {
        throw TypeError.unsupportedType
      }
      return "(\(boundType)()..<\(boundType)())"
      
    case "ClosedRange":
      guard let boundType = genericArgumentClause?.arguments.first?.argumentType.description else {
        throw TypeError.unsupportedType
      }
      return "(\(boundType)()...\(boundType)())"
      
    case "Character":
      return "\"/\""
      
    case "Date":
      return "Date(timeIntervalSince1970: 0)"
      
    case "UUID":
      return "UUID(uuidString: \"00000000-0000-0000-0000-000000000000\")!"

    case "URL":
      return "URL(string: \"/\")!"
      
    case "Bool",
      "Int", "Int8", "Int16", "Int32", "Int64",
      "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
      "Float","Float16", "Float80", "Float32", "Float64",
      "Double", "Decimal", "NSNumber",
      "CGFloat", "CGSize", "CGPoint", "CGRect",
      "String", "NSString",
      "TimeInterval",
      "Set", "NSSet",
      "Array", "NSArray",
      "Dictionary", "NSDictionary":
      return self.description + "()"
      
    case "Result":
      guard let succesType = genericArgumentClause?.arguments.first?.argumentType else {
        throw TypeError.unsupportedType
      }
      return try succesType.getDefaultValue()

    case "Optional":
      guard let wrappedType = genericArgumentClause?.arguments.first?.argumentType else {
        throw TypeError.unsupportedType
      }
      do {
        return try wrappedType.getDefaultValue()
      } catch {
        return "nil"
      }
      
    default:
      return self.description + ".Builder().build()"
    }
  }
}

struct BuilderDefault: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
      // Does nothing, used only to decorate members with data
      return []
  }
}

public enum AddBuilderMacroDiagnostic {
    case requiresStruct
}

extension AddBuilderMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requiresStruct:
            return "'AddBuilder' macro can only be applied to struct."
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "CodingKeysMacro.\(self)")
    }
}
