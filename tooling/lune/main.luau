--!strict

local stdio = require("@lune/stdio")
local serde = require("@lune/serde")

local Framework = require("../../src/framework")
local SnapshotProtocol = require("../../src/framework/Protocol/Protocols/SnapshotProtocol")

type Snapshot = SnapshotProtocol.Snapshot

local encoded = stdio.readToEnd()

--// json formatted like snapshot
local snapshot = serde.decode("json", encoded) :: Snapshot
local protocol = SnapshotProtocol.new(snapshot)

local _framework = Framework.new(protocol)

return ""
