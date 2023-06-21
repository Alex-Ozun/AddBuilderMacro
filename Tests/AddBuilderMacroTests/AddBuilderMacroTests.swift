import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AddBuilderMacroMacros

let testMacros: [String: Macro.Type] = [
    "AddBuilder": AddBuilderMacro.self,
]

final class AddBuilderMacroTests: XCTestCase {
    func testMacro() {
        assertMacroExpansion(
            """
            @AddBuilder()
            struct Person {
              let name: String
              @AddBuilder(default: Cat(name: "Bob"))
              let cat: Cat
              var middleName: String?
              let age: Int
            }
            """,
            expandedSource: """
            
            struct Person {
              let name: String
              let cat: Cat
              var middleName: String?
              let age: Int
              struct Builder {
                  var name: String = .init()
                  var cat: Cat = Cat(name: "Bob")
                  var middleName: String? = .init()
                  var age: Int = .init()
            
                  func name(_ name: String) -> Self {
                    var copy = self
                    copy.name = name
                    return copy
                  }
            
                  func cat(_ cat: Cat) -> Self {
                    var copy = self
                    copy.cat = cat
                    return copy
                  }
            
                  func middleName(_ middleName: String?) -> Self {
                    var copy = self
                    copy.middleName = middleName
                    return copy
                  }
            
                  func age(_ age: Int) -> Self {
                    var copy = self
                    copy.age = age
                    return copy
                  }
            
                  init() {
                  }
            
                  func build() -> Person {
                    Person (
                      name: name,
                      cat: cat,
                      middleName: middleName,
                      age: age
                    )
                  }
              }
            }
            """,
            macros: testMacros
        )
    }
  
//  func testMacro2() {
//      assertMacroExpansion(
//          """
//          @AddBuilder
//          struct Person {
//            let name: String
//            var middleName: String?
//            let age: Int
//            let cats: Array<Cat>
//            let contacts: Dictionary<String, String>
//          }
//          """,
//          expandedSource: """
//          
//          struct Person {
//            let name: String
//            var middleName: String?
//            let age: Int
//            let cats: Array<Cat>
//            let contacts: Dictionary<String, String>
//            struct Builder {
//                var name: String = .init()
//                var middleName: String? = .init()
//                var age: Int = .init()
//                var cats: Array<Cat> = .init()
//                var contacts: Dictionary<String, String> = .init()
//            }
//          }
//          """,
//          macros: testMacros
//      )
//  }
}
