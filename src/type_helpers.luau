--!strict

export type function is_empty(value: type): boolean
	if not value:is("table") then
		return false
	end

	if value:indexer() ~= nil then
		return false
	end

	return next(value:properties()) == nil
end

export type function extends(value: type, constraint: type): type
	if not value:issubtypeof(constraint) then
		error(`{value} does not extend {constraint}`)
	end

	return value
end

export type function satisfies(value: type, constraint: type): type
	local visiting = {}

	local function property_name(key: type): string
		if key:is("singleton") then
			return tostring(key:value())
		end

		return tostring(key)
	end

	local function check(actual: type, expected: type, path: string)
		-- Don't ask Luau's subtype solver to recursively compare whole
		-- tables. Traverse them here so recursive pairs can be tracked.
		if not actual:is("table") or not expected:is("table") then
			if not actual:issubtypeof(expected) then
				error(`{path}: {actual} does not satisfy {expected}`)
			end

			return
		end

		local expected_types: { [type]: unknown } = visiting[actual]

		if expected_types == nil then
			expected_types = {}
			visiting[actual] = expected_types
		elseif expected_types[expected] then
			-- This actual/expected pair is already being checked.
			return
		end

		expected_types[expected] = true

		for key, expected_property in expected:properties() do
			local expected_read = expected_property.read

			if expected_read ~= nil then
				local actual_read = actual:readproperty(key)

				if actual_read == nil then
					local actual_indexer = actual:readindexer()

					if actual_indexer ~= nil and key:issubtypeof(actual_indexer.index) then
						actual_read = actual_indexer.result
					end
				end

				if actual_read == nil then
					error(`{path}: missing property "{property_name(key)}"`)
				end

				check(actual_read, expected_read, `{path}.{property_name(key)}`)
			end
		end

		local expected_indexer = expected:readindexer()

		if expected_indexer ~= nil then
			for key, actual_property in actual:properties() do
				local actual_read = actual_property.read

				if actual_read ~= nil and key:issubtypeof(expected_indexer.index) then
					check(actual_read, expected_indexer.result, `{path}.{property_name(key)}`)
				end
			end

			local actual_indexer = actual:readindexer()

			if actual_indexer ~= nil and actual_indexer.index:issubtypeof(expected_indexer.index) then
				check(actual_indexer.result, expected_indexer.result, `{path}[{actual_indexer.index}]`)
			end
		end

		expected_types[expected] = nil
	end

	check(value, constraint, "value")

	return value
end

export type function overload(values: type, schema: type): type
	local kind_key = types.singleton("kind")
	local argument_key = types.singleton("argument")
	local name_key = types.singleton("name")
	local next_key = types.singleton("next")
	local format_key = types.singleton("format")

	local overloads: { type } = {}

	local function property_name(key: type): string
		if key:is("singleton") then
			return tostring(key:value())
		end

		return tostring(key)
	end

	local function read_schema_property(current_schema: type, key: type, path: string): type
		if not current_schema:is("table") then
			error(`{path} must be a schema table, got {current_schema}`)
		end

		local value = current_schema:readproperty(key)

		if value == nil then
			error(`{path} is missing "{property_name(key)}"`)
		end

		return value
	end

	local function read_schema_string(current_schema: type, key: type, path: string): string
		local value = read_schema_property(current_schema, key, path)

		if not value:is("singleton") then
			error(`{path}.{property_name(key)} must be a string singleton, got {value}`)
		end

		local singleton_value = value:value()

		if type(singleton_value) ~= "string" then
			error(`{path}.{property_name(key)} must be a string singleton, got {value}`)
		end

		return singleton_value
	end

	local function read_optional_schema_string(current_schema: type, key: type, path: string, default: string): string
		if not current_schema:is("table") then
			error(`{path} must be a schema table, got {current_schema}`)
		end

		local value = current_schema:readproperty(key)

		if value == nil then
			return default
		end

		if not value:is("singleton") then
			error(`{path}.{property_name(key)} must be a string singleton, got {value}`)
		end

		local singleton_value = value:value()

		if type(singleton_value) ~= "string" then
			error(`{path}.{property_name(key)} must be a string singleton, got {value}`)
		end

		return singleton_value
	end

	local function copy_arguments(arguments: { type }): { type }
		local result: { type } = {}

		for index, argument in ipairs(arguments) do
			result[index] = argument
		end

		return result
	end

	local function copy_strings(values_s: { string }): { string }
		local result: { string } = {}

		for index, value in ipairs(values_s) do
			result[index] = value
		end

		return result
	end

	local function join_strings(values_s: { string }, separator: string): string
		local result = ""

		for index, value in ipairs(values_s) do
			if index > 1 then
				result ..= separator
			end

			result ..= value
		end

		return result
	end

	local function union_or_never(values_u: { type }): type
		if #values_u == 0 then
			return types.never
		elseif #values_u == 1 then
			return values_u[1]
		end

		return types.unionof(unpack(values_u))
	end

	-- Turns the currently accumulated compact path into one
	-- function argument.
	--
	-- Example:
	--     { "foo", "bar", "baz" }, "."
	-- becomes:
	--     "foo.bar.baz"
	local function flush_compact(arguments: { type }, compact_parts: { string }?, compact_format: string?): { type }
		if compact_parts == nil then
			return arguments
		end

		if #compact_parts == 0 then
			return arguments
		end

		local result = copy_arguments(arguments)

		table.insert(result, types.singleton(join_strings(compact_parts, compact_format or ".")))

		return result
	end

	local walk: (
		current_value: type,
		current_schema: type,
		arguments: { type },
		compact_parts: { string }?,
		compact_format: string?,
		value_path: string,
		schema_path: string
	) -> ()

	walk = function(
		current_value: type,
		current_schema: type,
		arguments: { type },
		compact_parts: { string }?,
		compact_format: string?,
		value_path: string,
		schema_path: string
	)
		local kind = read_schema_string(current_schema, kind_key, schema_path)

		--
		-- COMPACT
		--
		-- Unlike `each`, this does not immediately add an
		-- argument.
		--
		-- Instead it accumulates keys until the compact group
		-- reaches an argument-producing node or `return`.
		--
		if kind == "compact" then
			if not current_value:is("table") then
				error(`{value_path} must be a table for a "compact" schema, got {current_value}`)
			end

			local argument = read_schema_string(current_schema, argument_key, schema_path)

			if argument ~= "key" then
				error(`{schema_path}.argument must be "key", got "{argument}"`)
			end

			local next_schema = read_schema_property(current_schema, next_key, schema_path)

			-- If this starts a new compact group, use this node's
			-- format, defaulting to ".".
			--
			-- If we're already inside a compact group, inherit the
			-- existing format.
			local active_format = compact_format

			if compact_parts == nil then
				active_format = read_optional_schema_string(current_schema, format_key, schema_path, ".")
			else
				-- If a nested compact explicitly specifies a
				-- format, require it to match the active group.
				local format_value = current_schema:readproperty(format_key)

				if format_value ~= nil then
					local specified_format = read_schema_string(current_schema, format_key, schema_path)

					if specified_format ~= active_format then
						error(
							`{schema_path}.format cannot change inside the same compact group: expected "{active_format}", got "{specified_format}"`
						)
					end
				end
			end

			for key, property in current_value:properties() do
				if not key:is("singleton") then
					error(`{value_path}.{property_name(key)} must have a singleton key for a "compact" schema`)
				end

				local key_value = key:value()

				if type(key_value) ~= "string" then
					error(`{value_path}.{property_name(key)} must have a string singleton key for a "compact" schema`)
				end

				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{property_name(key)} is not readable`)
				end

				local next_parts: { string }

				if compact_parts == nil then
					next_parts = {}
				else
					next_parts = copy_strings(compact_parts)
				end

				table.insert(next_parts, key_value)

				-- Important:
				--
				-- We recurse normally while carrying the compact
				-- state with us.
				--
				-- Because `property` also carries the state through,
				-- this allows:
				--
				-- compact
				--   -> property
				--      -> compact
				--
				-- to remain one compact argument.
				walk(
					property_value,
					next_schema,
					arguments,
					next_parts,
					active_format,
					`{value_path}.{property_name(key)}`,
					`{schema_path}.next`
				)
			end

			return
		end

		--
		-- PROPERTY
		--
		-- Property is transparent to compact groups.
		--
		-- It navigates deeper into the value but neither adds
		-- an argument nor flushes the currently accumulated
		-- compact path.
		--
		if kind == "property" then
			if not current_value:is("table") then
				error(`{value_path} must be a table for a "property" schema, got {current_value}`)
			end

			local name = read_schema_string(current_schema, name_key, schema_path)

			local property_value = current_value:readproperty(types.singleton(name))

			if property_value == nil then
				error(`{value_path} is missing property "{name}"`)
			end

			local next_schema = read_schema_property(current_schema, next_key, schema_path)

			walk(
				property_value,
				next_schema,
				arguments,

				-- Preserve compact state.
				compact_parts,
				compact_format,

				`{value_path}.{name}`,
				`{schema_path}.next`
			)

			return
		end

		--
		-- EACH
		--
		-- `each` produces its own argument, so an active compact
		-- group must be completed before this argument.
		--
		if kind == "each" then
			if not current_value:is("table") then
				error(`{value_path} must be a table for an "each" schema, got {current_value}`)
			end

			local argument = read_schema_string(current_schema, argument_key, schema_path)

			if argument ~= "key" then
				error(`{schema_path}.argument must be "key", got "{argument}"`)
			end

			local next_schema = read_schema_property(current_schema, next_key, schema_path)

			-- Finish any active compact group before adding
			-- the `each` argument.
			local base_arguments = flush_compact(arguments, compact_parts, compact_format)

			for key, property in current_value:properties() do
				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{property_name(key)} is not readable`)
				end

				local next_arguments = copy_arguments(base_arguments)

				table.insert(next_arguments, key)

				walk(
					property_value,
					next_schema,
					next_arguments,

					-- Compact group ended.
					nil,
					nil,

					`{value_path}.{property_name(key)}`,
					`{schema_path}.next`
				)
			end

			return
		end

		--
		-- UNION
		--
		-- Like `each`, union creates an argument, so it also
		-- terminates an active compact group first.
		--
		if kind == "union" then
			if not current_value:is("table") then
				error(`{value_path} must be a table for a "union" schema, got {current_value}`)
			end

			local argument = read_schema_string(current_schema, argument_key, schema_path)

			if argument ~= "key" then
				error(`{schema_path}.argument must be "key", got "{argument}"`)
			end

			local next_schema = read_schema_property(current_schema, next_key, schema_path)

			local next_kind = read_schema_string(next_schema, kind_key, `{schema_path}.next`)

			if next_kind ~= "return" then
				error(`{schema_path}.next.kind must be "return" for a "union" schema, got "{next_kind}"`)
			end

			local keys: { type } = {}
			local property_values: { type } = {}

			for key, property in current_value:properties() do
				if not key:is("singleton") or type(key:value()) ~= "string" then
					error(`{value_path}.{property_name(key)} must have a string singleton key for a "union" schema`)
				end

				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{property_name(key)} is not readable`)
				end

				table.insert(keys, key)

				table.insert(property_values, property_value)
			end

			if #keys == 0 then
				return
			end

			-- Finish the compact argument first.
			local next_arguments = flush_compact(arguments, compact_parts, compact_format)

			-- Don't modify the flushed table in case it happens
			-- to be shared.
			next_arguments = copy_arguments(next_arguments)

			table.insert(next_arguments, union_or_never(keys))

			walk(
				union_or_never(property_values),
				next_schema,
				next_arguments,

				-- Compact group ended.
				nil,
				nil,

				value_path,
				`{schema_path}.next`
			)

			return
		end

		--
		-- RETURN
		--
		-- If the schema ends while a compact group is active,
		-- flush it as the final function argument.
		--
		if kind == "return" then
			local final_arguments = flush_compact(arguments, compact_parts, compact_format)

			table.insert(
				overloads,
				types.newfunction({
					head = final_arguments,
				}, {
					head = {
						current_value,
					},
				})
			)

			return
		end

		error(`unknown schema kind "{kind}" at {schema_path}`)
	end

	if not values:is("table") then
		error(`expected values to be a table, got {values}`)
	end

	if not schema:is("table") then
		error(`expected schema to be a table, got {schema}`)
	end

	local arguments: { type } = {}

	walk(values, schema, arguments, nil, nil, "values", "schema")

	if #overloads == 0 then
		return types.never
	elseif #overloads == 1 then
		return overloads[1]
	end

	return types.intersectionof(unpack(overloads))
end

local lib = {}

return lib
