import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ReactiveMacro.self,
        ReactivePropertyMacro.self,
        ReactiveIgnoredMacro.self,
    ]
}
