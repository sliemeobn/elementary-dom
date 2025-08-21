import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ViewMacro {}

extension ViewMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !protocols.isEmpty else { return [] }

        var result: [ExtensionDeclSyntax] = []

        let needsView = protocols.contains { $0.trimmed.description == "View" }
        let needsStatefulView = protocols.contains { $0.trimmed.description == "_StatefulView" }
        let needsFunctionView = protocols.contains { $0.trimmed.description == "_FunctionView" }
        let members = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }

        // add View conformance if not already present
        if needsView {
            // add loading environment properties
            let environmentLoads =
                members
                .filter { $0.isEnvironmentProperty }
                .map { variable -> DeclSyntax in
                    let name = variable.trimmedIdentifier!.text
                    return "view._\(raw: name).__load(from: context)"
                }

            let decl: DeclSyntax = """
                extension \(raw: type.trimmedDescription): View {
                    typealias _MountedNode = _FunctionNode<Content._MountedNode>
                    static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self) {
                        \(raw: environmentLoads.map { $0.description }.joined(separator: "\n"))
                    }
                }
                """
            result.append(decl.cast(ExtensionDeclSyntax.self))
        } else {
            // TODO: diagnostic "remove View conformance"
        }

        let stateMembers = members.filter { $0.isStateProperty }

        // add _StatefulView conformance if any @State member is declared
        if needsStatefulView, !stateMembers.isEmpty {
            var initCalls: [DeclSyntax] = []
            var restoreCalls: [DeclSyntax] = []

            for (index, member) in stateMembers.enumerated() {
                let name = member.trimmedIdentifier!.text

                initCalls.append("view._\(raw: name).__initializeState(storage: storage, index: \(raw: index))")
                restoreCalls.append("view._\(raw: name).__restoreState(storage: storage, index: \(raw: index))")
            }

            let decl: DeclSyntax = """
                extension \(raw: type.trimmedDescription): _StatefulView {
                    static func __initializeState(from view: borrowing Self) -> _ViewStateStorage {
                        let storage = _ViewStateStorage()
                        storage.reserveCapacity(\(raw: stateMembers.count))
                        \(raw: initCalls.map { $0.description }.joined(separator: "\n"))
                        return storage
                    }

                    static func __restoreState(_ storage: _ViewStateStorage, in view: inout Self) {
                        \(raw: restoreCalls.map { $0.description }.joined(separator: "\n"))
                    }
                }
                """

            result.append(decl.cast(ExtensionDeclSyntax.self))
        } else if needsFunctionView {
            let decl: DeclSyntax = """
                extension \(raw: type.trimmedDescription): _FunctionView {
                }
                """

            result.append(decl.cast(ExtensionDeclSyntax.self))
        }

        return result
    }
}

extension ViewMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let variable = member.as(VariableDeclSyntax.self), variable.isContentProperty else {
            return []
        }

        return [AttributeSyntax("@HTMLBuilder")]
    }
}

extension VariableDeclSyntax {
    var isVar: Bool {
        bindingSpecifier.trimmed.text == "var"
    }

    var isContentProperty: Bool {
        guard isVar, let trimmedIdentifier else { return false }

        return trimmedIdentifier.text == "content"
    }

    var trimmedIdentifier: TokenSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
    }

    var isStateProperty: Bool {
        isVar && hasAttribute(named: "State")
    }

    var isEnvironmentProperty: Bool {
        isVar && hasAttribute(named: "Environment")
    }

    func hasAttribute(named name: String) -> Bool {
        attributes.contains { a in a.as(AttributeSyntax.self)?.trimmedName == name }
    }
}

extension AttributeSyntax {
    var trimmedName: String? {
        attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text
    }
}
