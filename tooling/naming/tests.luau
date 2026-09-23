--!strict

local Analyzer = require("./Analyzer")

local function codes(source: string, path: string): { string }
	local result = {}
	for _, diagnostic in Analyzer.analyze(source, path) do
		table.insert(result, diagnostic.code)
	end
	return result
end

local valid = [[
const MAX_RETRIES = 3
local ModuleName = require("./ModuleName")
local Parser = {}
export type ParseResult = { value: string }
type function TransformValue(argument: number): number
end
local function parseValue(sourceText: string): ParseResult
	for itemIndex, itemValue in {} do
		print(itemIndex, itemValue)
	end
	return { value = sourceText }
end
function Parser.parse(sourceText: string)
	return parseValue(sourceText)
end
return Parser
]]

assert(#codes(valid, "Parser.luau") == 0, "valid source should not produce diagnostics")

local invalid = [[
local bad_name = 1
local function BadFunction(Bad_parameter: string)
	return Bad_parameter
end
export type parse_result = string
type function transform_value(argument: number): number
end
return BadFunction
]]

local invalidCodes = codes(invalid, "wrong-file.luau")
assert(table.find(invalidCodes, "naming/variable") ~= nil)
assert(table.find(invalidCodes, "naming/function") ~= nil)
assert(table.find(invalidCodes, "naming/parameter") ~= nil)
assert(table.find(invalidCodes, "naming/type") ~= nil)
assert(table.find(invalidCodes, "naming/file") ~= nil)

print("Naming analyzer tests passed")
