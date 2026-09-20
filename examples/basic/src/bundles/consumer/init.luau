--!strict
local manifest, define = require(script.Parent.Parent.manifest)()

return define({
	entries = {
		server = script.server,
	},
	dependencies = {
		catalog = manifest.catalog,
	},
	assets = {},
})
