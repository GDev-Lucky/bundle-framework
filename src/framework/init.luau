--!strict

local Protocol = require("./Protocol")
local Workspace = require("./Workspace")

export type Protocol = Protocol.Protocol
export type Workspace = Workspace.Workspace

export type FrameworkBase = {
	workspace: Workspace,
}

local Framework = {}
Framework.__index = Framework

export type Framework = setmetatable<FrameworkBase, typeof(Framework)>

function Framework.new(protocol: Protocol): Framework
	local framework = {} :: FrameworkBase
	framework.workspace = Workspace.new(protocol)

	return setmetatable(framework, Framework)
end

return Framework
