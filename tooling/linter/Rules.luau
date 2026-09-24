--!strict

local Rules = {}

export type NameKind = "variable" | "function" | "parameter" | "constant" | "type" | "member" | "file"

local function isCamelCase(name: string): boolean
	if name == "_" or name == "self" then
		return true
	end

	local candidate = if string.sub(name, 1, 1) == "_" then string.sub(name, 2) else name
	return string.match(candidate, "^[a-z][A-Za-z0-9]*$") ~= nil
end

local function isPascalCase(name: string): boolean
	return string.match(name, "^[A-Z][A-Za-z0-9]*$") ~= nil
end

local function isLoudSnakeCase(name: string): boolean
	return string.match(name, "^[A-Z][A-Z0-9_]*$") ~= nil
		and string.match(name, "__") == nil
		and string.sub(name, -1) ~= "_"
end

function Rules.isValid(kind: NameKind, name: string, allowPascalCase: boolean?): boolean
	if kind == "constant" then
		return isLoudSnakeCase(name)
	elseif kind == "type" then
		return isPascalCase(name)
	elseif kind == "file" then
		return name == "init" or isCamelCase(name) or isPascalCase(name)
	elseif allowPascalCase then
		return isCamelCase(name) or isPascalCase(name)
	else
		return isCamelCase(name)
	end
end

function Rules.expected(kind: NameKind, allowPascalCase: boolean?): string
	if kind == "constant" then
		return "LOUD_SNAKE_CASE"
	elseif kind == "type" then
		return "PascalCase"
	elseif kind == "file" then
		return "camelCase or PascalCase"
	elseif allowPascalCase then
		return "camelCase or PascalCase for a module/class binding"
	else
		return "camelCase"
	end
end

return Rules
