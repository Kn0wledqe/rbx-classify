# **Table of Contents**
**Click on any of the links below to quickly jump to a section:**
1. [What is Classify](#1---what-is-classify)
2. [Getting Started](#2---getting-started)
    1. [Geting the Source Code](#21---getting-the-source-code)
    2. [Installing Into Your Project](#22---installing-into-your-project)
    3. [Loading the Module](#23---loading-the-module)
3. [Introductory Guide](#3---introductory-guide)
    1. [Creating a Class](#31---creating-a-class)
    2. [Using the Class](#32---using-the-class)
    3. [Creating a Basic Custom Property](#33---creating-a-basic-custom-property)
4. [Advanced Guide & Documentation](#4---advanced-guide--documentation)
    1. [Destroying & Class Cleanup](#41---destroying--class-cleanup)
        1. [Destroy Function](#411---destroy-function)
        2. [Handling Trash](#412---handling-trash)
        3. [Intercepting Destruction](#413---intercepting-destruction)
        4. [Handling Destroyed Classes](#414---handling-destroyed-classes)
        5. [Protecting Keys](#415---protecting-keys)
    2. [Inheritance](#42---inheritance)
        1. [Important Notes Before Continuing](#421---important-notes-before-continuing)
        2. [Creating Child & Super Classes](#422---creating-child--super-classes)
        3. [Inheriting a Class](#423---inheriting-a-class)


<br><br>

# **1 - What is Classify?**
**Classify** is an opinionated OOP wrapper that facilitates and streamlines the creation of classes in Roblox's Luau language. It aims to reduce the required code lift from the developer by implementing custom property handlers, inheritance, and memory cleanup - all without adding excess overhead into your code.

It is **highly recommended** that you have a high-level understanding of the following before using Classify in your project:
- What Lua metatables are and how they work. If you're not familiar with them, you're going to have a bad time.
- What Object-Oriented Programming actually means and when to use it (as well as when *not* to use it).
- How to write performant and memory-safe code; as well as have a basic understanding of Luau's garbage collection (e.g. knowing what a "hard reference" is).

<br>

### **!! READ:** Please understand that Classify is designed to *fully replace* your project's existing OOP paradigm, rather than simply compliment it. If you use Classify for some components while not using it for others - and decide to mix them together - you essentially risk signing yourself up for one gnarly headache. You've been warned!

<br><br>

# **2 - Getting Started**
## 2.1 - Getting the Source Code
You can fetch the latest release of Classify from the following sources:
- ~~The [releases page](https://github.com/doctr-oof/rbx-classify/releases) of this repository.~~ (not done)
- Directly copying the [latest source code file](https://github.com/doctr-oof/rbx-classify/blob/main/src/Classify3.lua) from the main branch.
<br><br>

## 2.2 - Installing Into Your Project
The Classify module is a single source file that is placed into a `ModuleScript` anywhere in your project hierarchy.

**NOTE:** It's recommended that you place it somewhere in `ReplicatedStorage` so both the server and the client have access to the module.
<br><br>

## 2.3 - Loading the Module
Once you've installed classify into your project, all you'll need to do is require it like any other ModuleScript.

```lua
local Classify = require(path.to.Classify)
```
<br><br>

# **3 - Introductory Guide**
## 3.1 - Creating a Class
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

## 3.2 - Using the Class
Now you can require your class and create it with the `.new()` constructor:

```lua
-- Example.lua
local MyClass = require(path.to.MyClass)

local Test = MyClass.new()
Test:SayHello() --> "Hello, world!"
```
<br>

## 3.3 - Creating a Basic Custom Property
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
        set = function(self, bar)
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
        set = function(self, value)
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
<br><br>

# 4 - **Advanced Guide & Documentation**
## 4.1 - Destroying & Class Cleanup
### 4.1.1 - Destroy Function
Any wrapped class will automatically have a `::Destroy(...)` function injected into its class table. This function acts similar to `Instance:Destroy()` in that all class data is cleared from memory, and any read or write operations that occur afterwards will cause an error.

**NOTE 1:** It is important to remember that `::Destroy(...)` will also call `::Destroy()` on any instances that are referenced in the class table, as well as any instances that are [marked as trash](#412---handling-trash). It will also disconnect any `RBXScriptSignal` that is referenced (it's basically a Maid that iterates over `self`). If there are keys that you don't want destroyed, you can utilize [key protection](#415---protecting-keys).

**NOTE 2:** Any arguments passed through `::Destroy(...)` will be sent to the [`::_onDestroy(...)`](#413---intercepting-destruction) callback.
<br><br>

### 4.1.2 - Handling Trash
In some cases, you may want to mark an instance or signal for destruction that isn't already referenced in your class table. To do so, make use of the injected `::_markTrash(any|{any})` method. Any instance, `RBXScriptSignal`, or table (with a function called "Destroy") will be cleaned up when `::Destroy(...)` is called.

**NOTE 1:** `::_markTrash(any|{any})` will accept a single item *or* a table of items. It is NOT a variadic.

**NOTE 2:** You cannot remove an item from the trash list after it has been added.
<br><br>

### 4.1.3 - Intercepting Destruction
You can optionally detect the destruction of your class by adding a function to your class table called `::_onDestroy(...)`.

**NOTE 1:** This function is blocking and will be called *before* Classify clears and locks class data.

**NOTE 2:** Any arguments passed to `::Destroy(...)` will be forwarded to this callback.
<br><br>

Here is an example of the `::_onDestroy(...)` callback:
```lua
-- MyClass.lua
function MyClass.new()
    local self = Classify(MyClass)

    self._button = Instance.new("TextButton")

    return self
end

function MyClass:_onDestroy(...)
    -- This will print out any arguments passed then
    -- wait 3 seconds before actually destroying.
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
<br>

### 4.1.4 - Handling Destroyed Classes
Since Classify classes are basically fancy tables and not actual userdatas, destroying one does not release/nullify hard references to it. This phenomenon can lead to unexpected behavior when using truthy/falsey/nil logic checks. For example, notice how the destroyed class below passes the conditional check and creates an erroneous condition:
```lua
local Test = MyClass.new()
Test:Destroy()

if Test then
    -- This will error because ::SayHello() was removed and
    -- the class table was frozen.
    Test:SayHello()
end
```

Thankfully, both Luau and Classify offer a workaround: `table.isfrozen(t)` and/or the `Destroyed` key, which always returns `true` if the class table was cleared and frozen:
```lua
local Test = MyClass.new()
Test:Destroy()

-- Alternatively you can use table.isfrozen(Test)
if not Test.Destroyed then
    Test:SayHello()
end
```
<br>

### 4.1.5 - Protecting Keys
For backwards compatibility, Classify 3.0 and later has a newly-injected `::_protect(key)` method. This function - when called with the name of the key to protect - will ensure the Classify does not automatically destroy/disconnect any instance/`RBXScriptSignals` associated with that key.

**NOTE 1:** This method should only be used for upgrading classes that use versions of Classify older than 3.0 in cases where restructuring isn't an option.

**NOTE 2:** Continuous use of this method can promote memory leaks due to unreleased hard references. It is strongly recommended to structure your class code in an alternate manner if you find yourself relying on this method often.

```lua
-- Memory-unsafe, but valid use:
function MyClass.new()
    local self = Classify(MyClass)

    self.partToKeep = Instance.new("Part")
    self:_protect("partToKeep")

    return self
end
```
```lua
-- Not as pretty, but much more memory-safe alternative:
function MyClass.new()
    local self = Classify(MyClass)

    -- Since class keys are simply nullified on destroy, object references
    -- within a table will not be targeted for destruction.
    self._objects = {}
    self._objects.partToKeep = Instance.new("Part")

    return self
end
```
<br>

## 4.2 - Inheritance
Classify provides a high-level inheritance system that aims to streamline development in projects by reducing the need to rewrite duplicate code to accomplish the same result across multiple similar components.

### 4.2.1 - Important Notes Before Continuing
- While Classify 3.0 and later supports the ability to inherit non-Classify-wrapped classes, you should note that the child class's (the inheriting module) metatable will always take precedent over the super class's (the inherited module) data. This means that custom implementations of `__newindex`, `__index`, etc. will not carry over to the child class.
- In fact, it is strongly recommended that you convert any third-party class modules to use Classify if able. Doing so will always guarantee a successful and predictable inheritance result.
- If both the child and super class have an `::_onDestroy(...)` callback, the child's callback will always run before the super's.
- Any class module (Classify-wrapped or otherwise) must have a `.new()` constructor to be inherited. The absence of a constructor will throw an error.
<br><br>

### 4.2.2 - Creating Child & Super Classes
There is no internal distinction between a "child" class and a "super" class with Classify. The only real distinction is in which module inherits the other one (e.g. **ModuleA** inherits **ModuleB**, which makes **ModuleB** the "super" class).

With that in mind, we'll differentiate all below examples by referring to one module as "SuperClass", and the other as "ChildClass" for ease of understanding.

```lua
-- SuperClass.lua
local SuperClass = {}

function SuperClass.new()
    return Classify(SuperClass)
end

function SuperClass:SayHello()
    print("Hello, world!")
end

SuperClass.__properties = {
    SuperProperty = {
        get = function()
            return "SuperClass Property!"
        end,
    },
}

return SuperClass
```
```lua
-- ChildClass.lua
local ChildClass = {}

function ChildClass.new()
    local self = Classify(ChildClass)
    return self
end

ChildClass.__properties = {
    ChildProperty = {
        get = function()
            return "ChildClass Property!"
        end,
    },
}

return ChildClass
```
<br>

### 4.2.3 - Inheriting a Class
The `::_inherit(superClass, overwriteChild?, ...?)` function can be called anywhere in your child class. This function will cause all methods, private and public members, and custom properties of the super class to be copied over to yours. The optional `::_onInherit(childClass, ...?)` callback also allows the super class to intercept and perform additional processing on the inheriting child class.

**NOTE 1:** Duplicate keys (e.g. methods or properties with the same name) cannot be inherited and will be discarded from the super class unless `overwriteChild` is `true`; in which case, the reverse will happen and the super class data will take precedent.

**NOTE 2:** All data passed through `::_inherit()` after `overwriteChild` will be passed to `::_onInherit()` if it exists.

```lua
-- SuperClass.lua
local SuperClass = {}

function SuperClass.new()
    return Classify(SuperClass)
end

function SuperClass:SayHello()
    print("Hello, world!")
end

function SuperClass:_onInherit(child)
    -- This will insert a new key into the child class table
    -- that can be accessed later.
    child._foo = "bar"
end

SuperClass.__properties = {
    SuperProperty = {
        get = function()
            return "SuperClass Property!"
        end,
    },
}

return SuperClass
```
```lua
-- ChildClass.lua
local ChildClass = {}

function ChildClass.new()
    local self = Classify(ChildClass)
    self:_inherit(SuperClass)
    return self
end

ChildClass.__properties = {
    ChildProperty = {
        get = function()
            return "ChildClass Property!"
        end,
    },
}

return ChildClass
```
```lua
-- Example.lua
local ChildTest = ChildClass.new()

-- Since ChildClass inherits SuperClass, we not have access
-- to SuperClass's methods and properties as if they were
-- a part of ChildClass!
ChildTest:SayHello() --> Hello, world!
print(ChildTest.SuperProperty) --> SuperClass Property!

-- Members of ChildClass remain untouched and still usable.
print(ChildTest.ChildProperty) --> ChildClass Property!
```


<br><br><br>
=
<br><br><br>
## **THE BELOW DOCUMENTATION IS OUTDATED AND IS CURRENTLY BEING REWRITTEN. *USE IS STRONGLY ILL-ADVISED!***
<br><br><br>
=










<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
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
