--!strict
local framework = require(script.Parent.framework)

local bundles = script.Parent.bundles

local manifest, define = framework.manifest({
	catalog = {
		bundle = bundles.catalog,
		api = {
			server = require(bundles.catalog.public.server),
		},
	},
	consumer = {
		bundle = bundles.consumer,
		api = {},
	},
})

return function()
	return manifest, define
end
