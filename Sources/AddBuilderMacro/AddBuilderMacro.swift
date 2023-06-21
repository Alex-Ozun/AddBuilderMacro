// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(Builder))
public macro AddBuilder() = #externalMacro(module: "AddBuilderMacroMacros", type: "AddBuilderMacro")

@attached(member, names: arbitrary)
public macro AddBuilder<T>(default: T) = #externalMacro(module: "AddBuilderMacroMacros", type: "BuilderDefault")
