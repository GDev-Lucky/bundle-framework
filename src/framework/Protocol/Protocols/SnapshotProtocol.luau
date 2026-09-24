--!strict

local Protocol = require("..")

type Protocol = Protocol.Protocol
type HostItem = Protocol.HostItem
type ItemId = Protocol.ItemId
type ProtocolBase = Protocol.ProtocolBase

export type SnapshotItem = HostItem & {
	source: string?,
}

export type Snapshot = {
	roots: { ItemId },
	items: { SnapshotItem },
}

type SnapshotProtocolBase = ProtocolBase & {
	_rootIds: { ItemId },
	_itemsById: { [ItemId]: SnapshotItem },
	_childrenByParentId: { [ItemId]: { HostItem } },
}

local SnapshotProtocol = setmetatable({}, Protocol)
SnapshotProtocol.__index = SnapshotProtocol

export type SnapshotProtocol = setmetatable<SnapshotProtocolBase, typeof(SnapshotProtocol)>

local function loadSnapshot(protocol: SnapshotProtocol, snapshot: Snapshot)
	local childrenByParentId = protocol._childrenByParentId
	local itemsById = protocol._itemsById

	for _, item in snapshot.items do
		local itemId = item.id
		if itemsById[itemId] then
			error("Duplicate snapshot, ItemId: " .. itemId)
		end
		itemsById[itemId] = item

		local parentId = item.parentId
		if not parentId then
			continue
		end

		local children = childrenByParentId[parentId]
		if not children then
			children = {}
			childrenByParentId[parentId] = children
		end

		table.insert(children, item)
	end
end

function SnapshotProtocol.new(snapshot: Snapshot): SnapshotProtocol
	local protocol = Protocol.new()

	local snapshotProtocol = protocol :: SnapshotProtocolBase

	snapshotProtocol._rootIds = snapshot.roots
	snapshotProtocol._itemsById = {}
	snapshotProtocol._childrenByParentId = {}

	local self = setmetatable(snapshotProtocol, SnapshotProtocol)

	loadSnapshot(self, snapshot)

	return self
end

function SnapshotProtocol.getRootItems(self: SnapshotProtocol): { HostItem }
	local roots = {}

	for _, id in self._rootIds do
		local item = self._itemsById[id]
		if item == nil then
			error("Unknown root item, ItemId:" .. id)
		end
		table.insert(roots, item)
	end

	return roots
end

function SnapshotProtocol.getChildren(self: SnapshotProtocol, id: ItemId): { HostItem }
	if not self._itemsById[id] then
		error("Unknown parent item, ItemId:" .. id)
	end
	return self._childrenByParentId[id] or {}
end

function SnapshotProtocol.readSource(self: SnapshotProtocol, id: ItemId): string
	local item = self._itemsById[id]
	if not item then
		error("Unknown parent item, ItemId:" .. id)
	end
	local source = item.source
	if not source then
		error("Item doesn't have source, ItemId:" .. id)
	end
	return source
end

return SnapshotProtocol
