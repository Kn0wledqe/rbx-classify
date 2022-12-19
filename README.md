# Table of Contents
**Click on any of the links below to quick jump to a section:**
1. [What is Classify](#what-is-classify)
2. [Getting Started](#getting-started)
    1. [Geting the Source Code](#geting-the-source-code)
    2. [Installing Into Your Project](#installing-into-your-project)
    3. [Loading the Module](#loading-the-module)
3. [Introductory Guide](#introductory-guide)
    1. [Creating a Class](#creating-a-class)
    2. [Using the Class](#using-the-class)
    3. [Creating a Basic Custom Property](#creating-a-basic-custom-property)
4. [Advanced Guide & Documentation](#advanced-guide--documentation)
    1. [Destroying & Class Cleanup](#destroying--class-cleanup)
        1. [Destroy Function](#destroy-function)
        2. [Handling Trash](#handling-trash)
        3. [Detecting Destruction](#detecting-destruction)
        4. [Cleanup Example(s)](#cleanup-examples)

<br><br>

# What is Classify?
**Classify** is a single-function OOP wrapper that facilitates and streamlines the creation of classes in Roblox's Luau langauge. Classify aims to reduce the required code lift from the developer by implementing custom property handlers, inheritance, and memory cleanup - all without adding excess overhead into your code.

It is highly recommended that you have a moderate-level understanding of the following before bringing Classify into your project:
- What Lua metatables are and how they work. Specifically, the `__index` and `__newindex` metamethods.
- What Object-Oriented Programming actually means and when to use it.
- How to write performant, memory-respecting code.

<br><br><br>

# Getting Started
## Getting the Source Code
You can fetch the latest release of Classify from the following sources:
- The [releases page](https://github.com/doctr-oof/rbx-classify/releases) of the repository.
- By directly copying the [latest source code file] from the main branch.
<br><br>

## Installing Into Your Project
The Classify module is a single source file that is placed into a `ModuleScript` anywhere in your project hierarchy.

**NOTE:** I recommend keeping it somewhere in `ReplicatedStorage` so both the server and the client have access to the module.
<br><br>

## Loading the Module
Once you've installed classify into your project, all you'll need to do is require it like any other ModuleScript.

```lua
local Classify = require(path.to.Classify)
```
<br><br><br>

# Introductory Guide
## Creating a Class
Creating a class with Classify requires one simple function call:

```lua
-- MyClass.lua
local MyClass = {}
local Classify = require(path.to.Classify)

function MyClass.new()
    local self = Classify(MyClass)
    return self
end

function MyClass:SayHello()
    print("Hello, world!")
end

return MyClass
```
<br>

## Using the Class
Now you can require your class and create it with the `.new()` constructor:

```lua
-- Example.lua
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test:SayHello() --> "Hello, world!"
```
<br>

## Creating a Basic Custom Property
Classify implements a custom property manager that directs reads and writes (gets and sets) to your class through property-specific functions called **handlers**.

In order to create a custom property, your main class table must have a `__properties` table. This table holds all property keys and their respective get/set handlers:
```lua
MyClass.__properties = {
    -- the key of table is the name of the property
    CustomPropertyName = {
        -- all get/set handlers go in here
        get = function(self)
            return self._foo
        end,
        set = function(self, bar: any)
            self._foo = bar
        end
    }
}
```
Now we can create and use a custom `Name` property for our `MyClass` class:

```lua
-- MyClass.lua
local MyClass = {}
local Classify = require(path.to.Classify)

function MyClass.new()
    local self = Classify(MyClass)

    self._name = "MyClass"

    return self
end

function MyClass:SayHello()
    print("Hello, world!")
end

MyClass.__properties ={
    Name = {
        get = function(self)
            return self._name
        end,
        set = function(self, value: string)
            self._name = value
        end
    }
}

return MyClass
```
```lua
-- Example.lua
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test:SayHello() --> "Hello, world!"

print(Test.Name) --> "MyClass"

Test.Name = "Foo"

print(Test.Name) --> "Foo"
```
<br><br><br>

# Advanced Guide & Documentation
Everything below will cover all advanced features and nuances of Classify. It is strongly recommend that you have a higher level understanding of OOP in Luau before diving in to this documentation.
<br><br>

## Destroying & Class Cleanup
### Destroy Function
Any wrapped class will automatically have a `::Destroy(...)` function injected into its class table. This function acts similar to `Instance:Destroy()` in that all class data is cleared from memory, and any read or write operations that occur afterwards will cause an error.

**NOTE 1:** It is important to remember that `::Destroy(...)` will also call `::Destroy()` on any instances that are referenced in the class table, as well as any instances that are [marked as trash](#handling-trash). It will also disconnect any `RBXScriptSignals` that are referenced (it's basically a Maid that iterates over `self`).

**NOTE 2:** Any arguments passed through `::Destroy(...)` will be sent to the [`::_onDestroy(...)`](#detecting-destruction) callback.
<br><br>

### Handling Trash
In some cases, you may want to mark an instance for destruction that isn't already referenced in your class table. To do so, make use of the injected `::_markTrash(any|{any})` function. Any instance, RBXScriptSignal, or table (with a function called "Destroy") will be cleaned up when `::Destroy(...)` is called.

**NOTE 1:** `::_markTrash(any|{any})` will accept a single item *or* a table of items. It is NOT a variadic.

**NOTE 2:** You cannot remove an item from the trash list after it has been added.
<br><br>

### Detecting Destruction
You can optionally detect the destruction of your class by adding a function to your class table called `::_onDestroy(...)`.

**NOTE 1:** This function is blocking and will be called before Classify clears and locks class data.

**NOTE 2:** Any arguments passed to `::Destroy(...)` will be forwarded to this callback.
<br><br>

### Cleanup Example(s)
```lua
-- MyClass.lua
function MyClass.new()
    local self = Classify(MyClass)

    self._button = Instance.new("TextButton")

    return self
end

function MyClass:_onDestroy(...)
    -- this will print out any arguments passed
    -- then wait 3 seconds before actually destroying
    print("Destroy arguments:", ...)
    task.wait(3)
end
```
```lua
-- Example.lua
local Test = MyClass.new()
Test:Destroy("foo") --> Destroy arguments: foo
print("All gone!") --> All gone! (after 3 seconds have passed)
```

<br><br><br>
=
<br><br><br>
## **THE BELOW DOCUMENTATION IS OUTDATED AND DOES NOT WORK. IT IS CURRENTLY BEING REWRITTEN. DO NOT USE!!!!**
<br><br><br>
=

# Using Classify - Advanced
### Functions
| Function & Aliases  | Description |
|--|--|
| `::_inherit(class)` | Copies inheritable data from another class onto the current one. |
| `::_redirectNullProperties(Instance)` | Redirects null custom properties to the target instance. Essentially like importing an object's properties into your class. |
| `::__inherited(childClass)` | An optional yielding callback that is ran by Classify when the class is inherited. It passes the child class data in case you need to do any mandatory processing for the inheritance to work correctly. |
| `::GetPropertyChangedSignal(property)` | Creates and returns an RBXScriptSignal that fires (with the target value) when the specified property changes. |

## Inheritance
Classify has a very simple and high-level inheritance system that allows you quickly import functions and properties from other Classify-processed classes.

#### Current Limitations and Important Notes:
- To increase stability and reduce processing times for `::inherit(class)` calls, Classify will only allow the inheritance of other Classify-wrapped classes.
- Classify currently overwrites inherited metatable data with the inheritor's metatable. This is a Luau limitation and cannot be overcome in the current version.
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
    self:_inherit(SuperClass)
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
Classify offers functionality to implement custom properties into your classes with four key property handlers: **getters**, **setters**, **targeted binds**, and **internal binds**.

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

That's all, folks. Hit me up on Discord (**FriendlyBiscuit#0445**) if you have any issues, questions, or suggestions.
