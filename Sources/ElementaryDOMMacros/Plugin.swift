import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ViewMacro.self,
        EntryMacro.self,
        EnvironmentKeyMacro.self,
        BindingMacro.self,
    ]
}
