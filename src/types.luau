--!strict
local type_helpers = require(script.Parent.type_helpers)

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

export type bundle_description<dependencies> = {
	dependencies: dependencies,
	entries: {
		[string]: ModuleScript,
	},
	assets: {},
}

type require_overload_schema = {
	kind: "each",
	argument: "key",

	next: {
		kind: "property",
		name: "api",

		next: {
			kind: "each",
			argument: "key",

			next: {
				kind: "return",
			},
		},
	},
}

type dependency_require<dependencies> = type_helpers.overload<dependencies, require_overload_schema>

export type bundle_object<dependencies> = {
	require: dependency_require<dependencies>,
}

return nil
