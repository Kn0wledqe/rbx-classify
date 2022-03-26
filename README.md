


**rbx-classify** (or simply **Classify**) is a simple-to-use super constructor that simplifies the OOP class-creation and clean-up coding process in Roblox Lua.

Its main goal is to simplify the custom-property creation process for classes that don't use or wrap Roblox instances (and therefore cannot make use of Attributes). It also completely removes the need for the programmer (you!) to have to handle metatables, cleanup, and table proxying.

**Before you continue:** it is STRONGLY recommended that you have a basic understanding of object-oriented programming practices and understand the purpose of an OOP workflow in the first place!

# Getting Started
Simply follow the steps below to get Classify installed and ready to use!

## Installing Classify
**Method 1: Rojo**

The Classify repository is fully rojo-compatible and can be inserted by simply cloning the repo and running `rojo serve` in your terminal.

**Method 2: Copy and Paste**

The easier way of using Classify in your project is to simply copy and paste the source code from `src/Classify/init.lua` into a ModuleScript. It's that easy!

## Loading the Module
Once you have the source code where you want it, you'll simply require it like you would any other ModuleScript:

```lua
local classify = require(path.to.Classify)
```

# Using Classify - Quick Start Guide
If you just want to quickly create a custom class without worrying about all the extra functionality that Classify provides you, this short quick start guide will show you how to do just that.

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

If you see "Hello, world!" in the output: congratulations! You've successfully set up and tested a basic class module.

# Using Classify - Advanced
For more advanced users who want to fully take advantage of Classify's unique features and built-in aids.

## Reserved Members & Functions
Classify will always reserve some members and functions in your main class table. These are extensions that the module adds for both your and Classify's internal use. Attempting to modify or overwrite these members will cause unpredictable (likely erroneous) behavior. They are as follows:

### Members
| Member | Description |
|--|--|
| `__classname` | Read-only. Mandatory class name identifier that must be specified for Classify to work. |
| `ClassName`  | Read-only. Built-in property that returns the `__classname` data you specified. |
| `__properties` | Internal table of properties that Classify reads to bind your custom properties. |

### Functions
| Function & Aliases  | Description |
|--|--|
| `::Destroy(...)` | A pre-built all-encompassing destroy method that tells Classify to call your optionally-assigned `::__cleaning()` callback (with any arguments supplied to `::Destroy()`, clean up all class memory, dispose of marked instances, and lock the metatable of your class. |
| `::__cleaning(...)`  | An optional yielding callback that is ran by Classify when `::Destroy()` is called on your class. Any arguments passed through `::Destroy()` are passed through. |
| `::_clean()` | Internal function called by the built-in `::Destroy()` method that cleans up all class memory. You shouldn't need this. |
| `::_dispose()`  | Internal function called by the built-in `::Destroy()` method that cleans up marked disposable instances. You shouldn't need this. |
| `::_mark_disposable(...)` `::markDisposable(...)` | Marks a table (with a `::Destroy()` method), Instance, RBXScriptSignal, or Function as a disposable set of data. |
| `::_mark_disposables({...})`  `::markDisposables({...})` | Same as `::_mark_disposable()`, but accepts a table of data instead. |
| `::Inherit(class)` `::inherit(class)` | Copies inheritable data from another class onto the current one. |
| `::__inherited(childClass)` | An optional yielding callback that is ran by Classify when the class is inherited. It passes the child class data in case you need to do any mandatory processing for the inheritance to work correctly. |
| `::GetPropertyChangedSignal(property)` | Creates and returns an RBXScriptSignal that fires (with the target value) when the specified property changes. |

## Handling Cleanup
Classify will automatically handle the cleanup of class memory when `::Destroy()` is called. However, Classify does *not* destroy Roblox instances that are created by your class or stored in its memory. To get around this, Classify exposes two functions that allow you to mark them as "disposable": `::_mark_disposable(...)` and `::_mark_disposables({...})` - both of which are documented under the **Reserved Members & Functions** section above.

It accepts the same argument types as a standard Maid: any table with a `::Destroy()` method, a Roblox Instance, RBXScriptSignal, or function. Example:

```lua
function MyClass.new()
    local self =  classify(MyClass)
    
    local button =  Instance.new("TextButton")
    
    self:markDisposable(button) -- this button will now be destroyed when the class is destroyed
    
    return  self
end
```

You can also bind a callback to intercept when your class is destroyed called `::__cleaning(...)`. This callback will yield the destruction and cleanup process until it finishes execution. It is also the first step in the cleanup chain, so you can still access class memory and marked disposables. Example:

```lua
function MyClass:__cleaning(...)
    print("::Destroy() was called on MyClass! The following arguments were passed:" ...)
end
```

## Inheritance
Classify has a very simple and high-level inheritance system that allows you quickly import functions and properties from other Classify-processed classes.

#### Current Limitations and Important Notes:
- To increase stability and reduce processing times for `::inherit(class)` calls, Classify will only allow the inheritance of other Classify-wrapped classes.
- Classify currently overwrites inherited metatable with the inheritor's metatable data. This is a Luau limitation and cannot be overcome in the current version.
- If a property is inherited that already exists in the inheritor, Classify will skip the importation of said property and output a warning.
- If the inherited class contains a `::__cleaning(...)` callback, it will be ran *before* the inheritor's callback (if assigned).
- Inheritance should be performed in the inheritor's `.new()` constructor function to ensure the inherited data is available to code that uses your class at run time.
- Any code that runs in the inherited class's `.new()` constructor ***will not run***, as `.new()` is overwritten by the inheritor.

Here is a very simple example of an example class ("ChildClass") inheriting another example class ("SuperClass")

```lua
-- SuperClass.lua
local SuperClass = { }
SuperClass.__classname = "SuperClass"

function SuperClass.new()
    local self = classify(SuperClass)
    return self
end

SuperClass.__properties = {
    CustomSuperProperty = {
        get = function() return "SuperClass Custom Property!" end
    }
}

return SuperClass
```

```lua
-- ChildClass.lua
local SuperClass = require(path.to.SuperClass)

local ChildClass= { }
ChildClass.__classname = "ChildClass"

function ChildClass.new()
    local self = classify(ChildClass)
    self:inherit(SuperClass)
    return self
end

ChildClass.__properties = {
    CustomChildProperty = {
        get = function() return "ChildClass Custom Property!" end
    }
}

return ChildClass
```

```lua
local ChildClass = require(path.to.ChildClass)

local Test = ChildClass.new()
print(Test.CustomChildProperty) --> "ChildClass Custom Property!"
print(Test.CustomSuperProperty) --> "SuperClass Custom Property!"
```

## Custom Properties
Classify exposes a high level way to implement custom properties into your classes with four key property handlers: **getters**, **setters**, **targeted binds**, and **internal binds**.

### Creating Your First Property
Classify looks for an internal table called `__properties` in your class data to process custom properties. All custom property code handlers go in this table. Example:

```lua
MyClass.__properties = {
    MyProperty = { } -- handlers will go in each property's table
}
```

### Reading From Your Property
To return data when a property is indexed, you must add a handler to it. **Getters**, **targeted binds**, and **internal binds** are the three handler types that can return data, but *only one* can actually return data at a time. If all three handlers are attached to a property, Classify will prioritize them in this order based on which ones are present: **getters** -> **targeted binds** -> **internal binds**.

#### Adding a Getter
A getter is a function called `get` that is passed `self` (the class) as its sole argument, and can return any data to the code that indexed the property. Example:

```lua
-- In your class script
MyClass.__properties = {
    MyProperty = {
        get = function(self)
            return 1234
        end
    }
}

-- In another script
local Test = MyClass.new()
print(MyClass.MyProperty) --> 1234
```

#### Adding a Targeted Bind
A targeted bind is both a function called `target` that is passed `self` (the class) as its sole argument, *and* a string called `bind` that points to a data key (or instance property) that you want Classify to redirect to. Targeted binds are technically both *readable* and *writeable* depending on whether or not the property is indexed, or written to. This can be used to quickly redirect custom properties to in-engine instances. Example:

```lua
-- In your class script
MyClass.__properties = {
    MyProperty = {
        bind = 'Text',
        target = function(self)
		    return path.to.a.Textbutton
        end
    }
}

-- In another script
local Test = MyClass.new()
print(MyClass.MyProperty) --> "whatever the button text is"
Test.MyProperty = "Hello, world!'
print(MyClass.MyProperty) --> "Hello, world!"
```

#### Adding an Internal Bind
An internal bind is simply a quick and easy way to reference internal class data. I pretty much added it because I was lazy, and using targeted binds just to write to an internal variable looked ugly. Internal binds are technically both *readable* and *writeable* depending on whether or not the property is indexed, or written to. Example:

```lua
-- In your class script
function MyClass.new()
    local self = classify(MyClass)
    
    self._test = "Hello, world!"
    
    return self
end

MyClass.__properties = {
    MyProperty = { internal = "_test" }
}

-- In another script
local Test = MyClass.new()
print(Test.MyProperty) --> "Hello, world!"
Test.MyProperty = "Goodbye!"
print(Test.MyProperty) --> "Goodbye!"
```

### Writing To Your Property
In order to process data that is given to your property, you'll need to use one (or a combination) of the three write handlers: **setters**, **targeted binds**, and **internal binds**. All three handlers can be used at the same time, however it should be noted that Classify will process them in a specific order of priority based on which ones are present: **internal binds** -> **setters** -> **targeted binds**.

#### Adding a Setter
A setter is a function called `set` that is passed `self` (the class) and `value` (the value that the property is trying to be set to). It should not return any data. Example:

```lua
-- In your class script
MyClass.__properties = {
    MyProperty = {
        set = function(self, value)
            print("MyProperty is being set to", value)
        end
    }
}

-- In another script
local Test = MyClass.new()
Test.MyProperty = "Hello, world!" --> "MyProperty is being set to Hello, world!"
```

#### Possible Use Case/Example for Combining Write Handlers
In this example, I combine all 3 property write handlers to update a TextLabel's `Text` property, update its size to fit the text, and assign the text to an internal variable:

```lua
local TextService = game:GetService("TextService")

function MyClass.new()
    local self = classify(MyClass)
    
    self._text = ""
    self._button = Instance.new("TextButton")
    
    return self
end

MyClass.__properties = {
    MyProperty = {
	    internal = "_text", -- update internal _text key
	    bind = "Text", -- update TextProperty of self._button (returned below)
	    target = function(self) return self._button end,
	    set = function(self, value) -- process text and update size
	        local size = TextService:GetTextSize(value, 12, "Gotham", Vector2.new(500, 500))
	        self._button.Size = UDim2.fromOffset(size.X + 30, 50)
	    end
    }
}
```

It's a little extra, but it just gives you a very light example of how you can combine these handlers to streamline property updates.

# The End
That's pretty much all there is to it. You can get pretty creative with Classify. How deep you want to take its functionality is completely up to you.

That's all, folks. Hit my up on Discord (**FriendlyBiscuit#0445**) if you have any issues, questions, or suggestions.
