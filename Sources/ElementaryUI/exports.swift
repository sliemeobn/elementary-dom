// NOTE: The intention is that ElementaryUI will be the top-level import that is controlled via SwiftPM traits.
// The ultimate goal is to have a CSR / SSR / SSG mode via traits so the same codebase can be used for all three somehow.
// However, this only really makes sense once we have a router implementation and hydration in place.
// We can refine the sub-module structure later and figure out how to evolve the OG elementary package into a "core" package - or just include it here eventually.
// CSR-only imports (JavaScriptKit) will eventually be conditionally included.

@_exported import ElementaryDOM
@_exported import Reactivity
