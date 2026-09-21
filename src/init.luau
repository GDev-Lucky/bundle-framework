--!strict
local type_helpers = require(script.type_helpers)
local types = require(script.types)

type description<D, A> = types.bundle_description<D, A>
type object<D, A> = types.bundle_object<D, A>
type satisfies<V, C> = type_helpers.satisfies<V, C>
type valid_object<D, A> = object<satisfies<D, { [string]: types.manifest_entry }>, A>

local function define_temp<D, A>(description: description<D, A>): valid_object<D, A>
	return {} :: types.bundle_object<D, A>
end

local framework = {}

function framework.manifest<T>(value: T): (type_helpers.satisfies<T, types.manifest>, typeof(define_temp))
	return value, define_temp
end

function framework.start() end

return framework
