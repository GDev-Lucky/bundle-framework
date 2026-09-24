--!strict
--!native
--!optimize 2

local Connection = require("./Connection")

type Node = Connection.Node
type Connection<A...> = Connection.Connection<A...>
type Callback<A...> = Connection.Callback<A...>
type ConnectionSet<A...> = Connection.ConnectionSet<A...>

type SignalBase<A...> = Node & {
	_fireCount: number,
	_disconnectedSet: ConnectionSet<A...>,
	_destroyed: boolean?,
	_awaitingClear: boolean?,
}

local Signal = {}
Signal.__index = Signal

export type Signal<A...> = setmetatable<SignalBase<A...>, typeof(Signal)>

local function addToSignal<A...>(signal: Signal<A...>, connection: Connection<A...>)
	local last = signal._prev
	last._next = connection
	connection._prev = last
	connection._next = signal
	signal._prev = connection
end

local function clearSignal<A...>(signal: Signal<A...>)
	local head = signal._next
	while head and head._isConnection do
		local connection = head :: Connection<A...>
		local thread = connection._thread
		if thread and coroutine.status(thread) ~= "dead" then
			local success, err = pcall(coroutine.close, thread)
			if not success then
				print("Failed to close thread on signal clear: ", err)
			end
		end
		head = connection._next
		connection._next = connection
		connection._prev = connection
	end
	table.clear(signal._disconnectedSet)
	signal._next = signal
	signal._prev = signal
end

local workerThread: thread? = nil

local function runCallback<A...>(callback: Callback<A...>, ...: A...)
	workerThread = nil
	callback(...)
	workerThread = coroutine.running()
end

local function createWorkerThread(): thread
	local thread = coroutine.create(function()
		while true do
			runCallback(coroutine.yield())
		end
	end)

	-- Advance the worker to its initial yield.
	local success, err = coroutine.resume(thread)
	if not success then
		error(err)
	end

	workerThread = thread

	return thread
end

function Signal.new<A...>(): Signal<A...>
	local signal = {} :: SignalBase<A...>

	signal._prev = signal
	signal._next = signal
	signal._fireCount = 0
	signal._disconnectedSet = {}

	return setmetatable(signal, Signal)
end

function Signal.fire<A...>(self: Signal<A...>, ...: A...)
	if self._destroyed then
		error("Signal has been destroyed, cannot call fire after destruction")
	end

	local head = self._next

	local disconnectedSet = self._disconnectedSet

	if self._awaitingClear then
		return
	end

	-- // Block removal of connections while in fire
	self._fireCount += 1

	local tail = self._prev :: Connection<A...>

	while head and head._isConnection do
		local connection = head :: Connection<A...>
		local nextConnection = connection._next
		local reachedTail = connection == tail

		if disconnectedSet[connection] then
			head = connection._next
			continue
		end

		if connection._once then
			disconnectedSet[connection] = true
		end

		local thread = connection._thread
		if thread then
			coroutine.resume(thread, ...)
		end

		local callback = connection._callback

		if callback then
			local callbackThread: thread = workerThread or createWorkerThread()
			local success, err = coroutine.resume(callbackThread, callback, ...)
			if not success then
				print(debug.traceback(callbackThread, err))
			end
		end

		head = nextConnection

		--// Prevent any connections added during this fire to not run till next fire
		if reachedTail then
			break
		end

		if self._awaitingClear then
			break
		end
	end

	-- // ALlow removal of connections again
	self._fireCount -= 1

	-- // Remove disconnected connections
	if self._fireCount > 0 then
		return
	end

	for connection, _ in self._disconnectedSet do
		local next = connection._next
		local prev = connection._prev
		next._prev = prev
		prev._next = next
		connection._next = connection
		connection._prev = connection
		-- // No need to check for threads because wait() never exposes a connection
		-- // and internally threads are resumed after marking for removal
	end

	table.clear(self._disconnectedSet)

	if self._awaitingClear then
		self._awaitingClear = nil
		clearSignal(self)
	end
end

function Signal.wait<A...>(self: Signal<A...>): ...any
	if self._destroyed then
		error("Signal has been destroyed, cannot call wait after destruction")
	end

	local thread = coroutine.running()
	local connection = Connection.new(thread, self._disconnectedSet)
	connection._once = true
	addToSignal(self, connection)
	return coroutine.yield(thread)
end

function Signal.connect<A...>(self: Signal<A...>, callback: Callback<A...>): Connection<A...>
	if self._destroyed then
		error("Signal has been destroyed, cannot call connect after destruction")
	end
	local connection = Connection.new(callback, self._disconnectedSet)
	addToSignal(self, connection)
	return connection
end

function Signal.once<A...>(self: Signal<A...>, callback: Callback<A...>): Connection<A...>
	if self._destroyed then
		error("Signal has been destroyed, cannot call once after destruction")
	end

	local connection = Connection.new(callback, self._disconnectedSet)
	connection._once = true
	addToSignal(self, connection)
	return connection
end

function Signal.disconnectAll<A...>(self: Signal<A...>)
	if self._destroyed then
		error("Signal has been destroyed, cannot call disconnectAll after destruction")
	end

	if self._fireCount > 0 then
		self._awaitingClear = true
		return
	end

	clearSignal(self)
end

function Signal.destroy<A...>(self: Signal<A...>)
	local shouldClear = not self._destroyed
	self._destroyed = true

	if not shouldClear then
		return
	end

	if self._fireCount > 0 then
		self._awaitingClear = true
		return
	end
	clearSignal(self)
end

return table.freeze(Signal)
