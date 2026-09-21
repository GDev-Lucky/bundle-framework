--!strict
local type_helpers = require(script.Parent.type_helpers)

type require_overload_schema = {
	kind: "compact",
	argument: "key",

	next: {
		kind: "property",
		name: "api",

		next: {
			kind: "compact",
			argument: "key",

			next: {
				kind: "return",
			},
		},
	},
}

type dependency_require<D> = type_helpers.overload<D, require_overload_schema>

export type lease_handle = {}
export type manifest_entry = {
	bundle: ModuleScript,
	api: {
		[string]: {
			[string]: unknown,
		},
	},
}

export type manifest = {
	[string]: manifest_entry,
}

export type bundle_description<D, A> = {
	dependencies: D,
	entries: {
		[string]: ModuleScript,
	},
	assets: A,
}
export type bundle_object<D, A> = {
	require: dependency_require<D>,
	lease: (name: keyof<A>) -> lease_handle,
	dependencies: D,
}

return nil
