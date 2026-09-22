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

	local x = is_empty(value)

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
	-- schema

	local kind_key = types.singleton("kind")
	local select_key = types.singleton("select")
	local match_key = types.singleton("match")
	local next_key = types.singleton("next")
	local separator_key = types.singleton("separator")
	local call_key = types.singleton("call")
	local element_key = types.singleton("element")
	local unpack_key = types.singleton("unpack")

	local overloads: { type } = {}

	local function field_name(key: type): string
		if key:is("singleton") then
			return tostring(key:value())
		end

		return tostring(key)
	end

	local function when_order(name: string): number?
		if name == "when" then
			return -1
		end

		local prefix = "when_"

		if string.sub(name, 1, #prefix) ~= prefix then
			return nil
		end

		return tonumber(string.sub(name, #prefix + 1))
	end

	local function is_keyword(name: string): boolean
		return name == "kind"
			or name == "select"
			or name == "match"
			or name == "next"
			or name == "separator"
			or name == "call"
			or name == "element"
			or name == "unpack"
			or when_order(name) ~= nil
	end

	local function read_field(current_schema: type, key: type, path: string): type?
		if not current_schema:is("table") then
			error(`{path} must be a schema table, got {current_schema}`)
		end

		return current_schema:readproperty(key)
	end

	local function require_field(current_schema: type, key: type, path: string): type
		local value = read_field(current_schema, key, path)

		if value == nil then
			error(`{path} is missing "{field_name(key)}"`)
		end

		return value
	end

	local function string_value(value: type, key: type, path: string): string
		if not value:is("singleton") then
			error(`{path}.{field_name(key)} must be a string singleton, got {value}`)
		end

		local result = value:value()

		if type(result) ~= "string" then
			error(`{path}.{field_name(key)} must be a string singleton, got {value}`)
		end

		return result
	end

	local function boolean_value(value: type, key: type, path: string): boolean
		if not value:is("singleton") then
			error(`{path}.{field_name(key)} must be a boolean singleton, got {value}`)
		end

		local result = value:value()

		if type(result) ~= "boolean" then
			error(`{path}.{field_name(key)} must be a boolean singleton, got {value}`)
		end

		return result
	end

	local function require_string(current_schema: type, key: type, path: string): string
		return string_value(require_field(current_schema, key, path), key, path)
	end

	local function read_string(current_schema: type, key: type, path: string, default: string): string
		local value = read_field(current_schema, key, path)

		if value == nil then
			return default
		end

		return string_value(value, key, path)
	end

	local function read_boolean(current_schema: type, key: type, path: string, default: boolean): boolean
		local value = read_field(current_schema, key, path)

		if value == nil then
			return default
		end

		return boolean_value(value, key, path)
	end

	local function require_table(value: type, path: string, kind: string)
		if not value:is("table") then
			error(`{path} must be a table for "{kind}", got {value}`)
		end
	end

	-- scope

	local function make_scope(current_schema: type, parent: any, path: string): any
		local scope = {
			parent = parent,
			definitions = {},
		}

		for key, property in current_schema:properties() do
			if not key:is("singleton") then
				continue
			end

			local name = key:value()

			if type(name) ~= "string" or is_keyword(name) then
				continue
			end

			local value = property.read

			if value ~= nil then
				scope.definitions[name] = {
					value = value,
					path = `{path}.{name}`,
				}
			end
		end

		return scope
	end

	local function find_definition(scope: any, name: string): (type?, any?, string?)
		local current = scope

		while current ~= nil do
			local definition = current.definitions[name]

			if definition ~= nil then
				return definition.value, current, definition.path
			end

			current = current.parent
		end

		return nil, nil, nil
	end

	local function singleton_string(value: type): string?
		if not value:is("singleton") then
			return nil
		end

		local result = value:value()

		if type(result) ~= "string" then
			return nil
		end

		return result
	end

	local function resolve_match(value: type, scope: any): type
		local name = singleton_string(value)

		if name == nil then
			return value
		end

		local definition = find_definition(scope, name)

		return definition or value
	end

	local function resolve_schema(value: type, scope: any, path: string): (type, any, string)
		local name = singleton_string(value)

		if name == nil then
			return value, scope, path
		end

		local definition, definition_scope, definition_path = find_definition(scope, name)

		if definition == nil then
			error(`{path} references unknown definition "{name}"`)
		end

		return definition, definition_scope, definition_path or path
	end

	-- arguments

	local function read_selector(current_schema: type, path: string): string
		local selector = require_string(current_schema, select_key, path)

		if selector ~= "key" and selector ~= "value" then
			error(`{path}.select must be "key" or "value", got "{selector}"`)
		end

		return selector
	end

	local function select_value(selector: string, key: type, value: type): type
		if selector == "key" then
			return key
		end

		return value
	end

	local function append_argument(arguments: { type }, value: type): { type }
		local result: { type } = {}

		for index, argument in ipairs(arguments) do
			result[index] = argument
		end

		result[#result + 1] = value

		return result
	end

	local function union_values(values_u: { type }): type
		if #values_u == 0 then
			return types.never
		elseif #values_u == 1 then
			return values_u[1]
		end

		return types.unionof(unpack(values_u))
	end

	-- branches

	local function when_matches(condition: type, scope: any, key: type, value: type, path: string): boolean
		local selector = read_selector(condition, path)
		local expected = resolve_match(require_field(condition, match_key, path), scope)
		local selected = select_value(selector, key, value)

		return selected:issubtypeof(expected)
	end

	local function collect_conditions(
		current_schema: type,
		schema_path: string
	): {
		{
			order: number,
			condition: type,
			path: string,
		}
	}
		local result: {
			{
				order: number,
				condition: type,
				path: string,
			}
		} = {}

		for key, property in current_schema:properties() do
			if not key:is("singleton") then
				continue
			end

			local name = key:value()

			if type(name) ~= "string" then
				continue
			end

			local order = when_order(name)

			if order == nil then
				continue
			end

			local condition = property.read

			if condition == nil then
				error(`{schema_path}.{name} is not readable`)
			end

			if not condition:is("table") then
				error(`{schema_path}.{name} must be a table, got {condition}`)
			end

			result[#result + 1] = {
				order = order,
				condition = condition,
				path = `{schema_path}.{name}`,
			}
		end

		table.sort(result, function(a: { order: number }, b: { order: number })
			return a.order < b.order
		end)

		return result
	end

	local function resolve_branch(
		node: type?,
		parent_scope: any,
		path: string,
		id: string
	): (type?, any, string, boolean, string)
		local consume = true

		while node ~= nil do
			node, parent_scope, path = resolve_schema(node, parent_scope, path)

			if not node:is("table") then
				error(`{path} must resolve to a schema table, got {node}`)
			end

			local scope = make_scope(node, parent_scope, path)
			local kind = require_string(node, kind_key, path)

			if kind == "ignore" then
				return nil, parent_scope, path, false, id
			end

			if kind ~= "skip" then
				return node, parent_scope, path, consume, id
			end

			consume = false
			node = read_field(node, next_key, path)
			parent_scope = scope
			path = `{path}.next`
		end

		return nil, parent_scope, path, consume, id
	end

	local function choose_branch(
		current_schema: type,
		scope: any,
		key: type,
		value: type,
		schema_path: string
	): (type?, any, string, boolean, string)
		for _, branch in ipairs(collect_conditions(current_schema, schema_path)) do
			local condition_scope = make_scope(branch.condition, scope, branch.path)

			if when_matches(branch.condition, condition_scope, key, value, branch.path) then
				return resolve_branch(branch.condition, scope, branch.path, branch.path)
			end
		end

		return resolve_branch(
			read_field(current_schema, next_key, schema_path),
			scope,
			`{schema_path}.next`,
			`{schema_path}.next`
		)
	end

	-- join

	local function join_segment(selected: type, selector: string, path: string): string
		if not selected:is("singleton") then
			error(`{path} selected "{selector}" must be a string singleton, got {selected}`)
		end

		local value = selected:value()

		if type(value) ~= "string" then
			error(`{path} selected "{selector}" must be a string singleton, got {selected}`)
		end

		return value
	end

	-- returns

	local function array_element(value: type, path: string, flag: string): type
		if not value:is("table") then
			error(`{path}.{flag} requires an array-like table, got {value}`)
		end

		local indexer = value:readindexer()

		if indexer == nil then
			error(`{path}.{flag} requires an array-like table, got {value}`)
		end

		local index = indexer.index

		if not index:issubtypeof(types.number) or not types.number:issubtypeof(index) then
			error(`{path}.{flag} requires a number-indexed array, got {index}`)
		end

		return indexer.result
	end

	local function single_return(head: { type }?, tail: type?, path: string, flag: string): type
		local local_values = head or {}

		if tail ~= nil then
			error(`{path}.{flag} requires exactly one return value`)
		end

		if #local_values ~= 1 then
			error(`{path}.{flag} requires exactly one return value, got {#local_values}`)
		end

		return local_values[1]
	end

	local function build_return_pack(
		value: type,
		current_schema: type,
		path: string
	): {
		head: { type }?,
		tail: type?,
	}
		local call = read_boolean(current_schema, call_key, path, false)
		local element = read_boolean(current_schema, element_key, path, false)
		local unpack_array = read_boolean(current_schema, unpack_key, path, false)

		if element and unpack_array then
			error(`{path} cannot use both "element" and "unpack"`)
		end

		local head: { type }? = { value }
		local tail: type? = nil

		if call and value:is("function") then
			local returns = value:returns()

			head = returns.head
			tail = returns.tail
		end

		if element then
			head = {
				array_element(single_return(head, tail, path, "element"), path, "element"),
			}
			tail = nil
		end

		if unpack_array then
			tail = array_element(single_return(head, tail, path, "unpack"), path, "unpack")
			head = {}
		end

		return {
			head = head,
			tail = tail,
		}
	end

	local function merge_return_packs(
		packs: {
			{
				head: { type }?,
				tail: type?,
			}
		},
		path: string
	): {
		head: { type }?,
		tail: type?,
	}
		local first = packs[1]

		if first == nil then
			return {
				head = {},
				tail = nil,
			}
		end

		local first_head = first.head or {}
		local count = #first_head
		local variadic = first.tail ~= nil

		for _, pack in ipairs(packs) do
			local head = pack.head or {}

			if #head ~= count then
				error(`{path}: union branches have incompatible return counts`)
			end

			if (pack.tail ~= nil) ~= variadic then
				error(`{path}: union branches have incompatible return packs`)
			end
		end

		local head: { type } = {}

		for index = 1, count do
			local variants: { type } = {}

			for _, pack in ipairs(packs) do
				local pack_head = pack.head or {}

				variants[#variants + 1] = pack_head[index]
			end

			head[index] = union_values(variants)
		end

		local tail: type? = nil

		if variadic then
			local variants: { type } = {}

			for _, pack in ipairs(packs) do
				local pack_tail = pack.tail

				if pack_tail == nil then
					error(`{path}: missing variadic return`)
				end

				variants[#variants + 1] = pack_tail
			end

			tail = union_values(variants)
		end

		return {
			head = head,
			tail = tail,
		}
	end

	-- traversal

	local traverse: (
		value: type,
		current_schema: type,
		parent_scope: any,
		arguments: { type },
		joined: string?,
		join_separator: string?,
		value_path: string,
		schema_path: string
	) -> ()

	traverse = function(
		value: type,
		current_schema: type,
		parent_scope: any,
		arguments: { type },
		joined: string?,
		join_separator: string?,
		value_path: string,
		schema_path: string
	)
		if not current_schema:is("table") then
			error(`{schema_path} must be a schema table, got {current_schema}`)
		end

		local scope = make_scope(current_schema, parent_scope, schema_path)
		local kind = require_string(current_schema, kind_key, schema_path)

		if kind == "ignore" then
			return
		elseif kind == "skip" then
			local node = read_field(current_schema, next_key, schema_path)

			if node ~= nil then
				local node_scope

				node, node_scope, schema_path = resolve_schema(node, scope, `{schema_path}.next`)

				traverse(value, node, node_scope, arguments, joined, join_separator, value_path, schema_path)
			end
		elseif kind == "each" then
			require_table(value, value_path, kind)

			local selector = read_selector(current_schema, schema_path)

			for key, property in value:properties() do
				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{field_name(key)} is not readable`)
				end

				local node, node_scope, node_path, consume =
					choose_branch(current_schema, scope, key, property_value, schema_path)

				if node ~= nil then
					local next_arguments = arguments

					if consume then
						next_arguments = append_argument(arguments, select_value(selector, key, property_value))
					end

					traverse(
						property_value,
						node,
						node_scope,
						next_arguments,
						nil,
						nil,
						`{value_path}.{field_name(key)}`,
						node_path
					)
				end
			end
		elseif kind == "join" then
			require_table(value, value_path, kind)

			local selector = read_selector(current_schema, schema_path)
			local separator = read_string(current_schema, separator_key, schema_path, ".")

			for key, property in value:properties() do
				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{field_name(key)} is not readable`)
				end

				local node, node_scope, node_path, consume =
					choose_branch(current_schema, scope, key, property_value, schema_path)

				if node ~= nil then
					local next_kind = require_string(node, kind_key, node_path)

					if not consume then
						if next_kind == "join" then
							traverse(
								property_value,
								node,
								node_scope,
								arguments,
								joined,
								join_separator,
								`{value_path}.{field_name(key)}`,
								node_path
							)
						else
							local next_arguments = arguments

							if joined ~= nil then
								next_arguments = append_argument(arguments, types.singleton(joined))
							end

							traverse(
								property_value,
								node,
								node_scope,
								next_arguments,
								nil,
								nil,
								`{value_path}.{field_name(key)}`,
								node_path
							)
						end

						continue
					end

					local segment = join_segment(
						select_value(selector, key, property_value),
						selector,
						`{value_path}.{field_name(key)}`
					)

					local joined_value = segment

					if joined ~= nil then
						joined_value = joined .. (join_separator or ".") .. segment
					end

					if next_kind == "join" then
						traverse(
							property_value,
							node,
							node_scope,
							arguments,
							joined_value,
							separator,
							`{value_path}.{field_name(key)}`,
							node_path
						)
					else
						traverse(
							property_value,
							node,
							node_scope,
							append_argument(arguments, types.singleton(joined_value)),
							nil,
							nil,
							`{value_path}.{field_name(key)}`,
							node_path
						)
					end
				end
			end
		elseif kind == "union" then
			require_table(value, value_path, kind)

			local selector = read_selector(current_schema, schema_path)

			local groups: {
				[string]: {
					consume: boolean,
					selected: { type },

					packs: {
						{
							head: { type }?,
							tail: type?,
						}
					},

					path: string,
				},
			} =
				{}

			for key, property in value:properties() do
				local property_value = property.read

				if property_value == nil then
					error(`{value_path}.{field_name(key)} is not readable`)
				end

				local selected = select_value(selector, key, property_value)

				local node, node_scope, node_path, consume, branch_id =
					choose_branch(current_schema, scope, key, property_value, schema_path)

				if node ~= nil then
					local node_kind = require_string(node, kind_key, node_path)

					if node_kind == "return" then
						local group_id = branch_id

						if not consume then
							group_id = "__skip__"
						end

						local group = groups[group_id]

						if group == nil then
							group = {
								consume = consume,
								selected = {},
								packs = {},
								path = node_path,
							}

							groups[group_id] = group
						end

						if consume then
							group.selected[#group.selected + 1] = selected
						end

						group.packs[#group.packs + 1] = build_return_pack(property_value, node, node_path)
					else
						local next_arguments = arguments

						if consume then
							next_arguments = append_argument(arguments, selected)
						end

						traverse(
							property_value,
							node,
							node_scope,
							next_arguments,
							nil,
							nil,
							`{value_path}.{field_name(key)}`,
							node_path
						)
					end
				end
			end

			for _, group in pairs(groups) do
				local next_arguments = arguments

				if group.consume then
					next_arguments = append_argument(arguments, union_values(group.selected))
				end

				overloads[#overloads + 1] = types.newfunction({
					head = next_arguments,
				}, merge_return_packs(group.packs, group.path))
			end
		elseif kind == "return" then
			overloads[#overloads + 1] = types.newfunction({
				head = arguments,
			}, build_return_pack(value, current_schema, schema_path))
		else
			error(`unknown schema kind "{kind}" at {schema_path}`)
		end
	end

	-- entry

	if not values:is("table") then
		error(`expected values to be a table, got {values}`)
	end

	if not schema:is("table") then
		error(`expected schema to be a table, got {schema}`)
	end

	traverse(values, schema, nil, {}, nil, nil, "values", "schema")

	if #overloads == 0 then
		return types.never
	elseif #overloads == 1 then
		return overloads[1]
	end

	local result: type = types.newfunction()

	for i, overload in overloads do
		if i >= 14 then
			continue
		end
		result = types.intersectionof(result, overloads[i])
	end

	return result
end

type complex = {
	api: {
		auth: {
			login: (username: string, password: string) -> (boolean, string?),
			roles: () -> { [number]: "admin" | "member" | "guest" },
			tokens: () -> { [number]: string },
		},

		cache: {
			get: (key: string) -> string?,
			snapshot: () -> { [number]: number },
		},
	},

	paths: {
		v1: {
			users: {
				list: "GET",
				create: "POST",
			},

			posts: {
				list: "GET",
				create: "POST",
			},
		},

		v2: {
			users: {
				list: "GET",
				remove: "DELETE",
			},
		},
	},

	choices: {
		text: "ready",
		code: "200",
		enabled: true,
		callback: () -> boolean,
	},

	aliases: {
		primary: "main",
		fallback: "backup",
		hidden: "internal",
	},

	arrays: {
		element: {
			roles: { [number]: "admin" | "member" },
			ids: { [number]: number },
		},

		unpack: {
			words: { [number]: string },
			codes: { [number]: number },
		},
	},

	ignored: {
		this: "should never appear",
	},

	unknown: {
		this: "also gets ignored by the default branch",
	},
}

type complex_schema = {
	kind: "skip",

	-- root definitions

	result: {
		kind: "return",
	},

	discard: {
		kind: "ignore",
	},

	api_name: "api",
	paths_name: "paths",
	choices_name: "choices",
	aliases_name: "aliases",
	arrays_name: "arrays",

	-- api

	api_branch: {
		kind: "each",
		select: "key",

		-- shadows the root "result"
		result: {
			kind: "return",
			call: true,
		},

		next: {
			kind: "each",
			select: "key",

			roles_name: "roles",

			-- call function, then extract array element
			when: {
				kind: "return",
				select: "key",
				match: "roles_name",

				call: true,
				element: true,
			},

			-- call function, then turn returned array into varargs
			when_1: {
				kind: "return",
				select: "key",
				match: "tokens",

				call: true,
				unpack: true,
			},

			-- resolves to api_branch.result, not root.result
			next: "result",
		},
	},

	-- paths

	paths_branch: {
		kind: "join",
		select: "key",

		-- default separator is "."

		next: {
			kind: "join",
			select: "key",
			separator: "/",

			next: {
				kind: "join",
				select: "key",

				next: "result",
			},
		},
	},

	-- union

	choices_branch: {
		kind: "union",
		select: "key",

		callback_name: "callback",
		special_names: "callback" | "code",

		-- callback matches both conditions, but "when"
		-- has priority over "when_1"
		when: {
			kind: "return",
			select: "key",
			match: "callback_name",
			call: true,
		},

		when_1: {
			kind: "return",
			select: "key",
			match: "special_names",
		},

		next: "result",
	},

	-- value selection

	aliases_branch: {
		kind: "each",
		select: "value",

		hidden_value: "internal",

		-- condition itself also selects the VALUE
		when: {
			kind: "ignore",
			select: "value",
			match: "hidden_value",
		},

		next: "result",
	},

	-- arrays

	arrays_branch: {
		kind: "each",
		select: "key",

		when: {
			kind: "each",
			select: "key",
			match: "element",

			-- local "result" shadows root.result
			result: {
				kind: "return",
				element: true,
			},

			next: "result",
		},

		when_1: {
			kind: "each",
			select: "key",
			match: "unpack",

			-- another local shadow
			result: {
				kind: "return",
				unpack: true,
			},

			next: "result",
		},

		next: "discard",
	},

	-- actual root

	root: {
		kind: "each",
		select: "key",

		-- explicit ignore branch
		when: {
			kind: "ignore",
			select: "key",
			match: "ignored",
		},

		-- all of these use skip so the outer category
		-- doesn't become an overload argument

		when_1: {
			kind: "skip",
			select: "key",
			match: "api_name",
			next: "api_branch",
		},

		when_2: {
			kind: "skip",
			select: "key",
			match: "paths_name",
			next: "paths_branch",
		},

		when_3: {
			kind: "skip",
			select: "key",
			match: "choices_name",
			next: "choices_branch",
		},

		when_4: {
			kind: "skip",
			select: "key",
			match: "aliases_name",
			next: "aliases_branch",
		},

		when_5: {
			kind: "skip",
			select: "key",
			match: "arrays_name",
			next: "arrays_branch",
		},

		-- anything unknown disappears
		next: "discard",
	},

	next: "root",
}

local lib = {}

return lib
