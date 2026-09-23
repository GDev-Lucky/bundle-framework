--!strict

local Lexer = {}

export type Token = {
	kind: "identifier" | "keyword" | "symbol" | "string" | "number",
	value: string,
	startLine: number,
	startCharacter: number,
	endLine: number,
	endCharacter: number,
}

local KEYWORDS = {
	["and"] = true,
	["break"] = true,
	["const"] = true,
	["continue"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["export"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["type"] = true,
	["typeof"] = true,
	["until"] = true,
	["while"] = true,
}

local function isIdentifierStart(character: string): boolean
	return string.match(character, "[A-Za-z_]") ~= nil
end

local function isIdentifierPart(character: string): boolean
	return string.match(character, "[A-Za-z0-9_]") ~= nil
end

local function longBracketLevel(source: string, index: number): (number?, number)
	if string.sub(source, index, index) ~= "[" then
		return nil, index
	end

	local cursor = index + 1
	while string.sub(source, cursor, cursor) == "=" do
		cursor += 1
	end

	if string.sub(source, cursor, cursor) == "[" then
		return cursor - index - 1, cursor + 1
	end

	return nil, index
end

function Lexer.scan(source: string): { Token }
	local tokens: { Token } = {}
	local index = 1
	local line = 0
	local character = 0
	local length = #source

	local function advance(): string
		local current = string.sub(source, index, index)
		index += 1
		if current == "\n" then
			line += 1
			character = 0
		else
			character += 1
		end
		return current
	end

	local function addToken(
		kind: "identifier" | "keyword" | "symbol" | "string" | "number",
		value: string,
		startLine: number,
		startCharacter: number
	)
		table.insert(tokens, {
			kind = kind,
			value = value,
			startLine = startLine,
			startCharacter = startCharacter,
			endLine = line,
			endCharacter = character,
		})
	end

	while index <= length do
		local current = string.sub(source, index, index)

		if string.match(current, "%s") then
			advance()
		elseif current == "-" and string.sub(source, index, index + 1) == "--" then
			advance()
			advance()
			local level, contentStart = longBracketLevel(source, index)
			if level ~= nil then
				while index < contentStart do
					advance()
				end
				local close = "]" .. string.rep("=", level) .. "]"
				while index <= length and string.sub(source, index, index + #close - 1) ~= close do
					advance()
				end
				for _ = 1, #close do
					if index <= length then
						advance()
					end
				end
			else
				while index <= length and string.sub(source, index, index) ~= "\n" do
					advance()
				end
			end
		elseif current == '"' or current == "'" or current == "`" then
			local quote = current
			local startLine = line
			local startCharacter = character
			local startIndex = index
			advance()
			while index <= length do
				local value = advance()
				if value == "\\" and index <= length then
					advance()
				elseif value == quote then
					break
				end
			end
			addToken("string", string.sub(source, startIndex, index - 1), startLine, startCharacter)
		else
			local level, contentStart = longBracketLevel(source, index)
			if level ~= nil then
				local startLine = line
				local startCharacter = character
				local startIndex = index
				while index < contentStart do
					advance()
				end
				local close = "]" .. string.rep("=", level) .. "]"
				while index <= length and string.sub(source, index, index + #close - 1) ~= close do
					advance()
				end
				for _ = 1, #close do
					if index <= length then
						advance()
					end
				end
				addToken("string", string.sub(source, startIndex, index - 1), startLine, startCharacter)
			elseif isIdentifierStart(current) then
				local startLine = line
				local startCharacter = character
				local startIndex = index
				repeat
					advance()
				until index > length or not isIdentifierPart(string.sub(source, index, index))
				local value = string.sub(source, startIndex, index - 1)
				addToken(if KEYWORDS[value] then "keyword" else "identifier", value, startLine, startCharacter)
			elseif string.match(current, "%d") then
				local startLine = line
				local startCharacter = character
				local startIndex = index
				repeat
					advance()
				until index > length or string.match(string.sub(source, index, index), "[%w_%.]") == nil
				addToken("number", string.sub(source, startIndex, index - 1), startLine, startCharacter)
			else
				local startLine = line
				local startCharacter = character
				local three = string.sub(source, index, index + 2)
				local two = string.sub(source, index, index + 1)
				local symbol = if three == "..."
					then three
					elseif table.find(
						{ "->", "::", "..", "==", "~=", "<=", ">=", "+=", "-=", "*=", "/=", "//=", "%=" },
						two
					) then two
					else current
				for _ = 1, #symbol do
					advance()
				end
				addToken("symbol", symbol, startLine, startCharacter)
			end
		end
	end

	return tokens
end

return Lexer
