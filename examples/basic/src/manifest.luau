--!strict
local framework = require(script.Parent.framework)

local bundles = script.Parent.bundles

local manifest, define = framework.manifest({
	catalog = {
		bundle = bundles.catalog,
		api = {
			server = require(bundles.catalog.public.server),
			faa = {
				hello = 1,
			},
		},
	},
	consumer = {
		bundle = bundles.consumer,
		api = {
			baa = {
				hello = 1,
			},
		},
	},
})

return function()
	return manifest, define
end
