--!strict
--!native
--!optimize 2

export type Callback<A...> = (A...) -> ()
export type ConnectionSet<A...> = { [Connection<A...>]: true }

export type Node = {
	_next: Node,
	_prev: Node,
	_isConnection: boolean?,
}

export type ConnectionBase<A...> = Node & {
	_callback: Callback<A...>?,
	_thread: thread?,
	_once: boolean?,
	_disconnectedSet: ConnectionSet<A...>,
}

local Connection = {}
Connection.__index = Connection

export type Connection<A...> = setmetatable<ConnectionBase<A...>, typeof(Connection)>

function Connection.new<A...>(item: Callback<A...> | thread, disconnectedSet: ConnectionSet<A...>): Connection<A...>
	local connection = {} :: ConnectionBase<A...>
	connection._next = connection
	connection._prev = connection
	connection._isConnection = true
	connection._disconnectedSet = disconnectedSet

	if typeof(item) == "thread" then
		connection._thread = item
	elseif typeof(item) == "function" then
		connection._callback = item
	else
		error("Unknow item to add to connection, item must be function | thread")
	end

	return setmetatable(connection, Connection)
end

function Connection.disconnect<A...>(self: Connection<A...>)
	-- // Mark for lazy removal
	self._disconnectedSet[self] = true
end

return table.freeze(Connection)
