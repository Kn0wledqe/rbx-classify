
**rbx-classify** (or simply **Classify**) is a simple-to-use super constructor that simplifies the OOP class-creation and clean-up coding process in Roblox Lua.

Its main goal is to simplify the custom-property creation process for classes that don't use or wrap Roblox instances (and therefore cannot make use of Attributes). It also completely removes the need for the programmer (you!) to have to handle metatables, cleanup, and table proxying.

**Before you continue:** it is STRONGLY recommended that you have a basic understanding of object-oriented programming practices and understand the purpose of an OOP workflow in the first place!

# Getting Started
Simply follow the steps below to get Classify installed and ready to use!

## Installing Classify
**Method 1: Rojo**

The Classify repository is fully rojo-compatible and can be inserted by simply cloning the repo and running `rojo serve` in your terminal.

**Method 2: Copy and Paste**

The easier way of using Classify in your project is to simply copy and paste the source code from ___src/Classify/init.lua___ into a ModuleScript. It's that easy!

## Loading the Module
Once you have the source code where you want it, you'll simply require it like you would any other ModuleScript:
```lua
local classify = require(path.to.Classify)
```

# Using Classify
The following documentation should get you started with using Classify!

## Creating a Simple Class
Once you've required Classify, you'll need to get your class code laid out:
```lua
-- Your Class Script
local MyClass = { }
MyClass.__classname = "MyNewClass" -- this is REQUIRED for Classify to accept your code

function MyClass.new()
	local self = classify(MyClass)
	return self
end

function MyClass:SayHello()
	print("Hello, world!")
end

return MyClass
```
Sweet! You now have the bare-minimum required to start programming your brand new class!

## Using Your Class
Now let's test it out our new class with another simple script:
```lua
-- Testing Script
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test:SayHello() -- should output "Hello, world!"
```
If you see "Hello, world!" in the output: congratulations! You've successfully set up your basic class module.

## Reserved Members
Classify will always reserve some members of your class table. These members are extensions that the module adds for your use. Attempting to modify or overwrite these members will cause unpredictable (likely erroneous) behavior. They are as follows:

**\<function\> ::Destroy(...: any)**

This is the Destroy() function that is exposed to all code that uses your class. This function will automatically clean up all data associated with your class when called - including **disposables** (more on those below). It can be passed any number of arguments that will be forwarded to the `::__cleaning()` callback (more on that below too).

**\<function\> ::_clean()**

This is an internal function called by the Destroy() method above *after* the `::__cleaning()` callback completes (if assigned). This function alone only cleans up class data - it does NOT clean up disposables nor does it fire the `::__cleaning()` callback.

**\<function\> ::_dispose()**

This is an internal function called by the Destroy() method above *after* the `:__cleaning()` callback completes (if assigned), and *after* `::_clean()` completes as well. This function alone *only* cleans up disposables - it does NOT clean up class data nor does it fire the `::__cleaning()` callback.

**\<function\> ::_mark_disposable(data: variant\<table, Instance, RBXScriptSignal, function>\)**

This is an internal function that you can call from within your class code to mark any kind of disposable data as... well... disposable! Any table or Instance with a Destroy() function will be destroyed, any RBXScriptSignal will be disconnected, and any function will be ran. (It works just like the Maid library!)

Example:
```lua
-- Your Class Script
function MyClass.new()
	local self = classify(MyClass)
	local button = Instance.new("TextButton")
	
	self:_mark_disposable(button)
	-- The TextButton will now be destroyed when ::Destroy() is called on this class
	
	return self
end
```

**\<function\> ::_mark_disposables(table{data: variant\<table, Instance, RBXScriptSignal, function>}\)**

Same as above, but takes a table of disposables instead. Good for bulk-adding data.

**\<table\> __properties**
Custom properties! More on that below.

## Cleaning Up
If you need to execute a specific routine before the class and disposables are destroyed, you can assign a callback to `__cleaning`. Any arguments passed to Destroy() will also be forward to the callback. Example:
```lua
-- Your Class Script
function MyClass.new()
	local self = classify(MyClass)
	local button = Instance.new("TextButton")
	
	self:_mark_disposable(button)
	
	return self
end

function MyClass:__cleaning(...)
	print("We're cleaning up! Arguments:", ...)
	-- Your code goes here.
	-- This will be invoked and will yield the cleaning process until it's complete.
end
```
```lua
-- Testing Script
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test:SayHello()
wait(1)
Test:Destroy("Goodbye!") -- You should see "We're cleaning up! Arguments: Goodbye!" in the output.
```

## Custom Properties
Last (but definitely not least), Classify exposes the ability to quickly create getters, setters, and targeted binds for custom properties for your classes.

In order to create a custom property, you will need to create a table called `__properties` in your class module and populate it.

**Creating a Getter**
Getters are functions that fetch and return data on a property is referenced. Example:
```lua
-- Your Class Script
MyClass.__properties = {
	Name = {
		get = function(self)
			return self._name
		end
	}
}
```

**Creating a Setter**
Setters are functions that do the opposite. The take data provided to the property and do stuff with it. Example:
```lua
-- Your Class Script
MyClass.__properties = {
	Name = {
		get = function(self) -- You can do both at the same time!
			return self._name
		end,
		set = function(self, value: string)
			self._name = value
		end
	}
}
```

**Creating a Targeted Bind**
A targeted bind is a simple way of binding a custom property to a real one (say the Text property of a TextButton). These **cannot** be combined with getters and setters!

To create a bind, you'll need to provide a `target` function that returns the userdata you're binding to, and a `bind` string that tells Classify the name of what to get/set for you. Example:
```lua
-- Your Class Script
MyClass.__properties = {
	Text = {
		bind = "Text",
		target = function(self) return self._button end
	}
}
```
```lua
-- Testing Script
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test.Text = "Hello, world!"
print(Test.Text) --> Should output "Hello, world!"
```

That's pretty much all there is to it. You can get pretty creative with Classify. You can also keep it as simple or make it as complicated as you want.

That's all, folks.