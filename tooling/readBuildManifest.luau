--!strict

local serde = require("@lune/serde")
local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local manifestPath = process.args[1]
if manifestPath == nil then
	stdio.ewrite("Usage: lune run tooling/readBuildManifest.luau <build.luau>\n")
	process.exit(2)
end

type BuildManifest = {
	entries: { string }?,
	extensions: { string }?,
	platforms: { string }?,
}

local chunk, loadError = loadstring(fs.readFile(manifestPath), manifestPath)
if chunk == nil then
	error(string.format("could not load build manifest '%s': %s", manifestPath, loadError))
end
local manifest = chunk() :: BuildManifest

local function validateList(name: string, value: { string }?): { string }
	if value == nil then
		return {}
	end
	if type(value) ~= "table" then
		error(string.format("build.luau field '%s' must be an array of strings", name))
	end

	local seen: { [string]: boolean } = {}
	local result: { string } = {}
	for index, item in value do
		if type(item) ~= "string" or item == "" then
			error(string.format("build.luau field '%s' item %d must be a non-empty string", name, index))
		end
		if seen[item] then
			error(string.format("build.luau field '%s' cannot contain duplicate item '%s'", name, item))
		end
		seen[item] = true
		table.insert(result, item)
	end
	return result
end

stdio.write(serde.encode("json", {
	entries = validateList("entries", manifest.entries),
	extensions = validateList("extensions", manifest.extensions),
	platforms = validateList("platforms", manifest.platforms),
}))
