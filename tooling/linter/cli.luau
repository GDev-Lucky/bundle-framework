--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local Analyzer = require("./Analyzer")

type DocumentRequest = {
	path: string,
	source: string,
}

local function normalize(path: string): string
	return string.gsub(path, "\\", "/") :: string
end

local function collectLuauFiles(path: string, files: { string })
	if fs.isFile(path) then
		if string.match(path, "%.lua[u]?$") then
			table.insert(files, path)
		end
		return
	end

	if not fs.isDir(path) then
		return
	end

	for _, entry in fs.readDir(path) do
		if entry ~= ".git" and entry ~= "node_modules" and entry ~= "dist" then
			collectLuauFiles(path .. "/" .. entry, files)
		end
	end
end

local command = process.args[1]
if command == "document" then
	local request = serde.decode("json", stdio.readToEnd()) :: DocumentRequest
	local diagnostics = Analyzer.analyze(request.source, request.path)
	-- Lune serializes an empty Luau table as a JSON object (`{}`). The document
	-- protocol always returns a diagnostics array, including when it is empty.
	if #diagnostics == 0 then
		stdio.write("[]")
	else
		stdio.write(serde.encode("json", diagnostics))
	end
elseif command == "check" then
	local paths = table.move(process.args, 2, #process.args, 1, {})
	if #paths == 0 then
		paths = { "src", "examples", "tooling" }
	end

	local files: { string } = {}
	for _, path in paths do
		collectLuauFiles(normalize(path), files)
	end
	table.sort(files)

	local count = 0
	for _, path in files do
		for _, item in Analyzer.analyze(fs.readFile(path), path) do
			count += 1
			stdio.ewrite(
				string.format(
					"%s:%d:%d: %s [%s]\n",
					path,
					item.startLine + 1,
					item.startCharacter + 1,
					item.message,
					item.code
				)
			)
		end
	end

	if count > 0 then
		stdio.ewrite(string.format("Lint check failed with %d diagnostic(s).\n", count))
		process.exit(1)
	end
	stdio.write(string.format("Lint check passed for %d Luau file(s).\n", #files))
else
	stdio.ewrite("Usage: lune run tooling/linter/cli.luau <document|check> [paths...]\n")
	process.exit(2)
end
