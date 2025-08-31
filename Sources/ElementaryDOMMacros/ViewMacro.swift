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

        let needsFunctionView = protocols.contains { $0.trimmed.description == "__FunctionView" }
        let members = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }

        let stateMembers = members.filter { $0.isStateProperty }

        // add _StatefulView conformance if any @State member is declared
        if needsFunctionView {
            var decls: [DeclSyntax] = []

            // add loading environment properties
            let environmentLoads =
                members
                .filter { $0.isEnvironmentProperty }
                .map { variable -> DeclSyntax in
                    let name = variable.trimmedIdentifier!.text
                    return "view._\(raw: name).__load(from: context)"
                }

            decls.append(
                DeclSyntax(
                    """
                        static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self) {
                            \(raw: environmentLoads.map { $0.description }.joined(separator: "\n"))
                        }
                    """
                )
            )

            if !stateMembers.isEmpty {
                var initCalls: [DeclSyntax] = []
                var restoreCalls: [DeclSyntax] = []

                for (index, member) in stateMembers.enumerated() {
                    let name = member.trimmedIdentifier!.text

                    initCalls.append("view._\(raw: name).__initializeState(storage: storage, index: \(raw: index))")
                    restoreCalls.append("view._\(raw: name).__restoreState(storage: storage, index: \(raw: index))")
                }

                decls.append(
                    DeclSyntax(
                        """
                        static func __initializeState(from view: borrowing Self) -> _ViewStateStorage {
                            let storage = _ViewStateStorage()
                            storage.reserveCapacity(\(raw: stateMembers.count))
                            \(raw: initCalls.map { $0.description }.joined(separator: "\n"))
                            return storage
                        }
                        """
                    )
                )
                decls.append(
                    DeclSyntax(
                        """
                        static func __restoreState(_ storage: _ViewStateStorage, in view: inout Self) {
                            \(raw: restoreCalls.map { $0.description }.joined(separator: "\n"))
                        }
                        """
                    )
                )
            } else {
                decls.append(
                    DeclSyntax(
                        """
                        typealias __ViewState = Void
                        """
                    )
                )
            }

            let extensionDecl: DeclSyntax = """
                extension \(raw: type.trimmedDescription): __FunctionView {
                    typealias _MountedNode = _FunctionNode<Self, Self.Content._MountedNode>
                    
                    \(raw: decls.map { $0.description }.joined(separator: "\n"))
                }
                """

            result.append(extensionDecl.cast(ExtensionDeclSyntax.self))
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
