--!strict
local Protocol = require("../Protocol")

type Protocol = Protocol.Protocol

export type WorkspaceBase = {
	_protocol: Protocol,
}

local Workspace = {}
Workspace.__index = Workspace

export type Workspace = setmetatable<WorkspaceBase, typeof(Workspace)>

function Workspace.new(protocol: Protocol): Workspace
	local workspace = {} :: WorkspaceBase
	workspace._protocol = protocol

	return setmetatable(workspace, Workspace)
end

return Workspace
