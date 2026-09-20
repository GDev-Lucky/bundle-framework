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

	local function copy_arguments(arguments: { type }): { type }
		local result: { type } = {}

		for index, argument in ipairs(arguments) do
			result[index] = argument
		end

		return result
	end

	local walk: (
		current_value: type,
		current_schema: type,
		arguments: { type },
		value_path: string,
		schema_path: string
	) -> ()

	walk = function(
		current_value: type,
		current_schema: type,
		arguments: { type },
		value_path: string,
		schema_path: string
	)
		local kind = read_schema_string(current_schema, kind_key, schema_path)

		if kind == "each" then
			if not current_value:is("table") then
				error(`{value_path} must be a table for an "each" schema, got {current_value}`)
			end

			local argument = read_schema_string(current_schema, argument_key, schema_path)

			if argument ~= "key" then
				error(`{schema_path}.argument must be "key", got "{argument}"`)
			end

			local next_schema = read_schema_property(current_schema, next_key, schema_path)

			for key, property in current_value:properties() do
				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{property_name(key)} is not readable`)
				end

				local next_arguments = copy_arguments(arguments)
				table.insert(next_arguments, key)

				walk(
					property_value,
					next_schema,
					next_arguments,
					`{value_path}.{property_name(key)}`,
					`{schema_path}.next`
				)
			end

			return
		end

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

			walk(property_value, next_schema, arguments, `{value_path}.{name}`, `{schema_path}.next`)

			return
		end

		if kind == "return" then
			table.insert(
				overloads,
				types.newfunction({
					head = arguments,
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

	walk(values, schema, {}, "values", "schema")

	if #overloads == 0 then
		return types.never
	elseif #overloads == 1 then
		return overloads[1]
	end

	return types.intersectionof(unpack(overloads))
end

local lib = {}

return lib
