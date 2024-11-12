@attached(member, names: named(_$reactivity))
@attached(memberAttribute)
@attached(extension, conformances: ReactiveObject, names: named(_$typeID))
public macro Reactive() = #externalMacro(module: "ReactivityMacros", type: "ReactiveMacro")

@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_), prefixed($propertyID_))
public macro ReactiveProperty() = #externalMacro(module: "ReactivityMacros", type: "ReactivePropertyMacro")

@attached(accessor, names: named(willSet))
public macro ReactiveIgnored() = #externalMacro(module: "ReactivityMacros", type: "ReactiveIgnoredMacro")
