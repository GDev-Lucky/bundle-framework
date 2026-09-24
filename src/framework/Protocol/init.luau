--!strict
local Signal = require("../utils/Signal")

export type ItemId = string

export type HostItem = {
	id: ItemId,
	parentId: ItemId?,
	name: string,
	kind: string,
}

export type ProtocolBase = {
	onChanged: Signal.Signal<>,
}

local Protocol = {}
Protocol.__index = Protocol

export type Protocol = setmetatable<ProtocolBase, typeof(Protocol)>

function Protocol.new(): Protocol
	local protocol = {} :: ProtocolBase
	protocol.onChanged = Signal.new()

	return setmetatable(protocol, Protocol)
end

function Protocol.getRootItems(self: Protocol): { HostItem }
	error("Not implemented, abstract method")
end

function Protocol.getChildren(self: Protocol, id: ItemId): { HostItem }
	error("Not implemented, abstract method")
end

function Protocol.readSource(self: Protocol, id: ItemId): string
	error("Not implemented, abstract method")
end

return Protocol
