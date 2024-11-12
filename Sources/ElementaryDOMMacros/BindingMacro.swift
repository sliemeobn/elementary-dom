import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum BindingMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let expression = node.arguments.first else { return "" }
        // TODO: all sorts of validation and diagnostics
        return "Binding(get: { \(expression) }, set: { \(expression) = $0 })"
    }
}
