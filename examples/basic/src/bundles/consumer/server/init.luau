--!strict
local bundle = require(script.Parent)

local catalog = bundle.require("catalog", "server")

local name = "foo"

local consumer = {}

function consumer.init()
	print(catalog.find(name))
end

function consumer.start() end

function consumer.cleanup() end

return consumer
