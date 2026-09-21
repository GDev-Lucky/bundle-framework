--!strict
local bundle = require(script.Parent)

local catalog = bundle.require("catalog.server")
local types = require(script.Parent.Parent.catalog.public.types)

local name = "foo"

local consumer = {}

function consumer.init()
	print(catalog.find(name))
	bundle.lease("hello")
end

function consumer.start() end

function consumer.cleanup() end

local function export<T>(val: T?): T
	return val :: T
end

local module = {}

module.type = export<<{ [string]: number }>>()

type x = typeof(module.type)

return consumer
