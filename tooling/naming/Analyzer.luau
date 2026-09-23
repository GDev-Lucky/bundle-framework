--!strict

local Lexer = require("./Lexer")
local Rules = require("./Rules")

local Analyzer = {}

type Token = Lexer.Token

export type Diagnostic = {
	code: string,
	message: string,
	severity: string,
	startLine: number,
	startCharacter: number,
	endLine: number,
	endCharacter: number,
}

local function diagnostic(token: Token, code: string, message: string): Diagnostic
	return {
		code = code,
		message = message,
		severity = "warning",
		startLine = token.startLine,
		startCharacter = token.startCharacter,
		endLine = token.endLine,
		endCharacter = token.endCharacter,
	}
end

local function validateName(diagnostics: { Diagnostic }, token: Token, kind: Rules.NameKind, allowPascalCase: boolean?)
	if not Rules.isValid(kind, token.value, allowPascalCase) then
		table.insert(
			diagnostics,
			diagnostic(
				token,
				"naming/" .. kind,
				string.format(
					"%s '%s' must use %s",
					string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2),
					token.value,
					Rules.expected(kind, allowPascalCase)
				)
			)
		)
	end
end

local function skipType(tokens: { Token }, index: number): number
	local depth = 0
	while index <= #tokens do
		local value = tokens[index].value
		if value == "(" or value == "{" or value == "[" or value == "<" then
			depth += 1
		elseif value == ")" or value == "}" or value == "]" or value == ">" then
			if depth == 0 then
				return index
			end
			depth -= 1
		elseif depth == 0 and (value == "," or value == "=" or value == "in" or value == "do") then
			return index
		end
		index += 1
	end
	return index
end

local function parseParameters(tokens: { Token }, openIndex: number, diagnostics: { Diagnostic }): number
	local depth = 1
	local index = openIndex + 1
	local expectingParameter = true

	while index <= #tokens and depth > 0 do
		local token = tokens[index]
		if token.value == "(" then
			depth += 1
		elseif token.value == ")" then
			depth -= 1
			if depth == 0 then
				return index
			end
		elseif depth == 1 then
			if token.value == "," then
				expectingParameter = true
			elseif expectingParameter and token.kind == "identifier" then
				validateName(diagnostics, token, "parameter")
				expectingParameter = false
			elseif token.value == ":" then
				index = skipType(tokens, index + 1) - 1
			end
		end
		index += 1
	end

	return index
end

local function findInitializer(tokens: { Token }, index: number): Token?
	local depth = 0
	while index <= #tokens do
		local token = tokens[index]
		if token.value == "(" or token.value == "{" or token.value == "[" or token.value == "<" then
			depth += 1
		elseif token.value == ")" or token.value == "}" or token.value == "]" or token.value == ">" then
			depth = math.max(0, depth - 1)
		elseif depth == 0 and token.value == "=" then
			return tokens[index + 1]
		elseif depth == 0 and token.value == ";" then
			return nil
		end
		index += 1
	end
	return nil
end

local function parseBindings(
	tokens: { Token },
	startIndex: number,
	diagnostics: { Diagnostic },
	isConstant: boolean
): number
	local index = startIndex
	local names: { Token } = {}

	while index <= #tokens do
		local token = tokens[index]
		if token.kind ~= "identifier" then
			break
		end
		table.insert(names, token)
		index += 1
		if tokens[index] and tokens[index].value == ":" then
			index = skipType(tokens, index + 1)
		end
		if not tokens[index] or tokens[index].value ~= "," then
			break
		end
		index += 1
	end

	local initializer = if #names == 1 then findInitializer(tokens, index) else nil
	local allowPascalCase = initializer ~= nil and (initializer.value == "{" or initializer.value == "require")
	for _, name in names do
		validateName(diagnostics, name, if isConstant then "constant" else "variable", allowPascalCase)
	end

	return math.max(startIndex, index - 1)
end

local function baseName(path: string): string
	local normalized = string.gsub(path, "\\", "/")
	local name = string.match(normalized, "([^/]+)$") or normalized
	return string.gsub(name, "%.lua[u]?$", "") :: string
end

function Analyzer.analyze(source: string, path: string): { Diagnostic }
	local tokens = Lexer.scan(source)
	local diagnostics: { Diagnostic } = {}
	local index = 1

	while index <= #tokens do
		local token = tokens[index]
		local previous = tokens[index - 1]
		local nextToken = tokens[index + 1]

		if token.value == "type" and nextToken then
			if nextToken.kind == "identifier" then
				validateName(diagnostics, nextToken, "type")
				index += 1
			elseif nextToken.value == "function" and tokens[index + 2] and tokens[index + 2].kind == "identifier" then
				validateName(diagnostics, tokens[index + 2], "type")
				index += 2
			end
		elseif token.value == "function" then
			local nameIndex = index + 1
			local isLocal = previous ~= nil and (previous.value == "local" or previous.value == "const")
			local nameToken = tokens[nameIndex]
			if nameToken and nameToken.kind == "identifier" then
				local finalName = nameToken
				while
					tokens[nameIndex + 1]
					and (tokens[nameIndex + 1].value == "." or tokens[nameIndex + 1].value == ":")
					and tokens[nameIndex + 2]
					and tokens[nameIndex + 2].kind == "identifier"
				do
					nameIndex += 2
					finalName = tokens[nameIndex]
				end
				validateName(diagnostics, finalName, if isLocal then "function" else "member")
			end
			while nameIndex <= #tokens and tokens[nameIndex].value ~= "(" do
				nameIndex += 1
			end
			if tokens[nameIndex] then
				index = parseParameters(tokens, nameIndex, diagnostics)
			end
		elseif
			(token.value == "local" or token.value == "const")
			and nextToken
			and nextToken.value ~= "function"
			and nextToken.kind == "identifier"
		then
			index = parseBindings(tokens, index + 1, diagnostics, token.value == "const")
		elseif token.value == "for" then
			local cursor = index + 1
			while tokens[cursor] and tokens[cursor].kind == "identifier" do
				validateName(diagnostics, tokens[cursor], "variable")
				cursor += 1
				if not tokens[cursor] or tokens[cursor].value ~= "," then
					break
				end
				cursor += 1
			end
		end

		index += 1
	end

	local fileName = baseName(path)
	if not Rules.isValid("file", fileName) then
		table.insert(diagnostics, {
			code = "naming/file",
			message = string.format("File '%s' must use %s", fileName, Rules.expected("file")),
			severity = "warning",
			startLine = 0,
			startCharacter = 0,
			endLine = 0,
			endCharacter = 1,
		})
	end

	return diagnostics
end

return Analyzer
