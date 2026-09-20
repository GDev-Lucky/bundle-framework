--!strict
local type_helpers = require(script.type_helpers)
local types = require(script.types)

type description<dependencies> = types.bundle_description<dependencies>
type object<dependencies> = types.bundle_object<dependencies>
type satisfies<v, c> = type_helpers.satisfies<v, c>
type valid_object<dependencies> = object<satisfies<dependencies, { [string]: types.manifest_entry }>>

local function define_temp<dependencies>(description: description<dependencies>): valid_object<dependencies>
	return {} :: types.bundle_object<dependencies>
end

local framework = {}

function framework.manifest<T>(value: T): (type_helpers.satisfies<T, types.manifest>, typeof(define_temp))
	return value, define_temp
end

return framework
