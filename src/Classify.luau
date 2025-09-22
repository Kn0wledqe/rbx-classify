--[[
	File: Init.lua
	Author(s): Eric Karolchyk(Original Creator), Kn0wledqe
	Created: 09/22/2025 @ 16:00:00
	Version: 1

	Description:
		Provides a simple-to-use OOP class wrapper to easily create
		custom classes with built-in maid support, custom properties,
		and more!

	Documentation:
		Documentation can be found in the official doctr-oof/rbx-classify
		repository.
--]]

--[ Root Table ]--
local Classify = { meta = {}, prototype = {} }

--[ Internal Functions ]--
local function deepCopy(source: any, target: any): any
	local result = {}

	if type(source) == "table" then
		for index, value in next, source, nil do
			rawset(result, deepCopy(index), deepCopy(value))
		end

		setmetatable(result, deepCopy(getmetatable(source)))
	else
		result = source
	end

	if target then
		for index, value in next, source, nil do
			rawset(target, index, value)
		end
	else
		return result
	end
end

--[ Classify Metamethods ]--
function Classify.meta.__index(self: {}, key: string): any
	if key == "Destroyed" then
		return table.isfrozen(self)
	end

	if table.isfrozen(self) then
		error(("attempt to index nil with '%s'"):format(key), 2)
		return nil
	end

	if key == "SelfCleaningEnabled" then
		return rawget(self, "__classify").SelfCleaningEnabled
	end

	-- __classname is no longer required! but we'll still support it just in case...
	if key == "ClassName" then
		return rawget(self, "ClassName")
	end

	-- check if a private key exists in the class table before continuing
	local selfData = rawget(self, key)

	if selfData then
		return selfData
	end

	-- fetch properties table and null redirect target (if assigned)
	local properties = rawget(self, "__properties")

	if properties then
		local handler = properties[key]

		if handler then
			if type(handler) == "string" then
				return rawget(self, handler)
			else
				-- i don't feel like re-typing these...
				local read = handler.onRead
				local get = handler.get
				local bind = handler.bind
				local target = handler.target
				local internal = handler.internal
				local bindTarget = handler.bindTarget

				-- the read get handler is the only one that can be combined
				-- with the others
				if read then
					read(self)
				end

				-- the rest of the get handlers must be mutually exclusive
				if get then
					return get(self)
				elseif bindTarget then
					if type(bindTarget) == "string" then
						local targetKey = rawget(self, bindTarget)

						if targetKey then
							return targetKey[key]
						end
					elseif type(bindTarget) == "function" then
						return bindTarget(self)[key]
					end
				elseif bind and target then
					return target(self)[bind]
				elseif internal then
					local nodes = {}

					for node in internal:gmatch("([^.]+)") do
						table.insert(nodes, node)
					end

					if nodes and #nodes > 0 then
						local result = self

						for _, node in ipairs(nodes) do
							local step = rawget(result, node)

							if step then
								result = step
							else
								return nil
							end
						end

						return result
					else
						return rawget(self, internal)
					end
				end
			end
		end
	end

	-- null key redirection is the final check, as if this fails it will likely
	-- error. especially if the redirect target is a userdata
	local nullTarget = rawget(self, "__classify").NullTarget

	if nullTarget then
		local success, result = pcall(function()
			return nullTarget[key]
		end)

		if success then
			return result
		end
	end

	-- no key found anywhere else, return nil
	return nil
end

function Classify.meta.__newindex(self: {}, key: string, value: any)
	if table.isfrozen(self) then
		error(("attempt to index nil with '%s'"):format(key), 2)
		return
	end

	if key == "SelfCleaningEnabled" then
		rawget(self, "__classify").SelfCleaningEnabled = value or false
	end

	local properties = rawget(self, "__properties")
	local success = false

	if properties then
		local handler = properties[key]

		if handler then
			if type(handler) == "string" then
				rawset(self, handler, value)
				success = true
			else
				local write = handler.onWrite
				local internal = handler.internal
				local set = handler.set
				local bind = handler.bind
				local target = handler.target
				local bindTarget = handler.bindTarget

				if write then
					write(self)
				end

				if internal then
					rawset(self, internal, value)
					success = true
				end

				if set then
					set(self, value)
					success = true
				end

				if bind and target then
					target(self)[bind] = value
					success = true
				end

				if bindTarget then
					if type(bindTarget) == "string" then
						local targetKey = rawget(self, bindTarget)

						if targetKey then
							targetKey[key] = value
							success = true
						end
					elseif type(bindTarget) == "function" then
						bindTarget(self)[key] = value
						success = true
					end
				end
			end
		end
	end

	-- if no custom property was found, resort to nullTarget or direct
	-- key write
	if not success then
		local nullTarget = rawget(self, "__classify").NullTarget

		if nullTarget then
			local writeSuccess = pcall(function()
				nullTarget[key] = value
			end)

			if not writeSuccess then
				rawset(self, key, value)
			end
		else
			rawset(self, key, value)
		end
	end

	for _, signal in rawget(self, "__classify").PropertySignals do
		if signal[1] == key then
			signal[2]:Fire(value)
		end
	end
end

function Classify.meta.__tostring(self: {}): string
	if not self or table.isfrozen(self) then
		return "nil"
	end

	return self.ClassName or "nil"
end

--[ Classify-injected Private Functions ]--
function Classify.prototype:_markTrash(trash: TrashType): nil
	if trash == nil then
		error("Cannot ::_markTrash() that is nil.")
	end

	if type(trash) == "table" then
		for _, value in trash do
			table.insert(rawget(self, "__classify").Trash, value)
		end
	else
		table.insert(rawget(self, "__classify").Trash, trash)
	end
end

function Classify.prototype:_redirectNullKeys(target: table): nil
	if not self then
		return
	end
	rawget(self, "__classify").NullTarget = target
end

-- the price to pay for kinda-clean output is apparently ugly code (i'm sorry)
function Classify.prototype:_printClassData(): nil
	local resultStr = `{self.ClassName or "Class Data"}:\n  Keys:\n`

	for key, value in self do
		local prefix = ""
		local typeStr = typeof(value)
		local valueStr = type(value) ~= "function" and tostring(value) or ""
		local typeLenDiff = 20 - #typeStr
		local valueLenDiff = 30 - #key

		if typeLenDiff <= 0 then
			typeLenDiff = 4
		end
		if valueLenDiff <= 0 then
			valueLenDiff = 4
		end

		if key:find("_") == 1 then
			prefix ..= "private    " .. typeStr
		else
			prefix ..= "public     " .. typeStr
		end

		resultStr ..= `    {prefix .. string.rep(" ", typeLenDiff)}{key .. string.rep(" ", valueLenDiff)}{valueStr}\n`
	end

	print(resultStr)
end

function Classify.prototype:_protect(key: string): nil
	table.insert(rawget(self, "__classify").ProtectedKeys, key)
end

--[ Classify-injected Public Functions ]--
function Classify.prototype:GetPropertyChangedSignal(key: string): RBXScriptConnection | nil
	local object = Instance.new("BindableEvent")

	table.insert(rawget(self, "__classify").PropertySignals, { key, object })

	self:_markTrash(object)
	return object.Event
end

function Classify.prototype:Destroy(...: any)
	-- all _onDestroy() callbacks should run first
	local cleaningCallbacks = rawget(self, "__classify").CleaningCallbacks

	for _, callback in cleaningCallbacks do
		callback(self, ...)
	end

	-- collect all marked and keyed trash
	local meta = rawget(self, "__classify")
	local trash = meta.Trash

	if meta.SelfCleaningEnabled then
		for key, value in self do
			-- prevent strong references remaining on protected keys
			if table.find(meta.ProtectedKeys, key) then
				rawset(self, key, nil)
				continue
			end

			local canClean = false

			if typeof(value) == "RBXScriptConnection" or typeof(value) == "Instance" then
				canClean = true
			elseif type(value) == "table" and value.Destroy then
				canClean = true
			end

			if canClean then
				table.insert(trash, value)
			end
		end
	end

	-- clean it all up
	local index, item = next(trash)

	while item ~= nil do
		trash[index] = nil

		pcall(function()
			if typeof(item) == "RBXScriptConnection" then
				item:Disconnect()
			elseif type(item) == "function" then
				item()
			elseif item.Destroy then
				return item:Destroy()
			end
		end)

		index, item = next(trash)
	end

	-- wipe the class table
	for key, _ in self do
		rawset(self, key, nil)
	end

	rawset(self, "Destroy", function() end)
	table.freeze(self)
	self = nil
end

--[ Type ]--
export type TrashType = RBXScriptConnection | Instance | (() -> nil)
export type TrashParameter = TrashType | { TrashType }

export type Classify = {
	-- public properties
	Destroyed: boolean,
	SelfCleaningEnabled: boolean,
	ClassName: string,
	Name: string,

	-- public functions
	GetPropertyChangedSignal: (string) -> RBXScriptConnection | nil,
	Destroy: (...any) -> nil,

	-- internal functions
	_markTrash: (...TrashParameter) -> nil,
	_redirectNullKeys: (table) -> nil,
	_protect: (string) -> nil,
	_printClassData: () -> nil,

	-- internal variables
	__classify: {
		CleaningCallbacks: { (table, ...any) -> nil },
		PropertySignals: { string | RBXScriptConnection },
		ProtectedKeys: { string },
		SelfCleaningEnabled: boolean,
		NullTarget: table,
		Trash: { any },
	},

	__properties: {
		[string]: {
			get: (table) -> any,
			set: (table, any) -> nil,
			internal: string,
			bind: string,
			target: (table) -> Instance,
			bindTarget: string | (table) -> table,
		},
	},
}

--[ Main Classify Function ]--

--[[
---Base Classify constructor wrap function.
---@param class table The class table to wrap with Classify.
---@param lite boolean? Optional flag to disable injecting Classify internal functions. Custom properties will still work.
---@return table
return function(class: {}, lite: boolean?): table
	local proxy, result = deepCopy(class), nil

	deepCopy(Classify.meta, proxy)

	if not lite then
		deepCopy(Classify.prototype, proxy)
	end

	rawset(proxy, "__classify", {
		CleaningCallbacks = { rawget(proxy, "_onDestroy") },
		PropertySignals = {},
		ProtectedKeys = {},
		SelfCleaningEnabled = true,
		Trash = {},
	})

	result = deepCopy(proxy)
	return setmetatable(result, proxy)
end
]]

local initializedClasses = {}
return function(_class: {}, lite: boolean?): Classify
	-- Reuse cached class wrapper if available
	local class = initializedClasses[_class]
	if not class then
		class = deepCopy(_class)
		deepCopy(Classify.meta, class)
		table.freeze(class)
		initializedClasses[_class] = class
	end

	local object = {}
	rawset(object, "__classify", {
		CleaningCallbacks = { rawget(class, "_onDestroy") },
		PropertySignals = {},
		ProtectedKeys = {},
		SelfCleaningEnabled = true,
		Trash = {},
	})

	if not lite then
		deepCopy(Classify.prototype, object)
	end

	return setmetatable(object, class)
end