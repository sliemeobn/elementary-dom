@attached(extension, conformances: View, _StatefulView, names: named(__initializeState), named(__restoreState), named(__applyContext))
@attached(memberAttribute)
public macro View() = #externalMacro(module: "ElementaryDOMMacros", type: "ViewMacro")

@freestanding(expression)
public macro Key<Value>(_: KeyPath<EnvironmentValues, Value>) -> EnvironmentValues._Key<Value> = #externalMacro(module: "ElementaryDOMMacros", type: "EnvironmentKeyMacro")

// @freestanding(expression)
// public macro Key<Store: _ValueStorage, Value>(_: KeyPath<Store, Value>) -> Store._Key<Value> = #externalMacro(module: "ElementaryDOMMacros", type: "KeyMacro2")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(_$key_))
public macro Entry() = #externalMacro(module: "ElementaryDOMMacros", type: "EntryMacro")
