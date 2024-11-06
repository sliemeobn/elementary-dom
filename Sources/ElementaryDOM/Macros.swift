@attached(extension, conformances: View, _StatefulView, names: named(_initializeState), named(_restoreState), named(hasState))
@attached(memberAttribute)
public macro View() = #externalMacro(module: "ElementaryDOMMacros", type: "ViewMacro")
