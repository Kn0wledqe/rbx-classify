# **Table of Contents**
**Click on any of the links below to quickly jump to a section:**
1. [What is Classify](#1---what-is-classify)
2. [Getting Started](#2---getting-started)
    1. [Getting the Source Code](#21---getting-the-source-code)
    2. [Installing Into Your Project](#22---installing-into-your-project)
    3. [Loading the Module](#23---loading-the-module)
3. [Introductory Guide](#3---introductory-guide)
    1. [Creating a Class](#31---creating-a-class)
    2. [Using the Class](#32---using-the-class)
4. [Advanced Features Guide](#4---advanced-features-guide)
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
        4. [Post-Inheritance Processing](#424---post-inheritance-processing)
    3. [Custom Properties](#43---custom-properties)
        1. [Get Handlers Explained](#431---get-handlers-explained)
        2. [Set Handlers Explained](#432---set-handlers-explained)
        3. [Using Handlers](#433---using-handlers)
            1. [get](#4331---get)
            2. [set](#4332---set)
            3. [internal](#4333---internal)
            4. [bind and target](#4334---bind-and-target)
            5. [bindTarget](#4335---bindtarget)
        4. [Advanced Property Example](#434---advanced-property-example)
5. [Pending Documentation](#5---pending-documentation)


<br><br>

# **1 - What is Classify?**
**Classify** is an opinionated OOP wrapper that facilitates and streamlines the creation of classes in Roblox's Luau language. It aims to reduce the required code lift from the developer by implementing custom property handlers, inheritance, and memory cleanup - all without adding excess overhead into your code.

It is **highly recommended** that you have a high-level understanding of the following before using Classify in your project:
- What Lua metatables are and how they work. If you're not familiar with them, you're going to have a bad time.
- What Object-Oriented Programming actually means and when to use it (as well as when *not* to use it).
- How to write performant and memory-safe code; as well as have a basic understanding of Luau's garbage collection (e.g. knowing what a "strong reference" is).

<br>

**!! READ:** Please understand that Classify is designed to *fully replace* your project's existing OOP paradigm, rather than simply compliment it. If you use Classify for some components while not using it for others - and decide to mix them together - you essentially risk signing yourself up for one gnarly headache. You've been warned!

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
Once you've installed Classify into your project, all you'll need to do is require it like any other ModuleScript.

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
Test:Destroy()
```
<br>

**Congratulations! You now have the absolute minimum required code to create and use your new custom class!**

Don't stop here though! Classify has a plethora of features that provide you the tools necessary to reshape how you write OOP code.

<br><br>

# 4 - **Advanced Features Guide**
## 4.1 - Destroying & Class Cleanup
### 4.1.1 - Destroy Function
Any wrapped class will automatically have a `::Destroy(...?)` function injected into its class table. This function acts similar to `Instance:Destroy()` in that all class data is cleared from memory, and any read or write operations that occur afterwards will cause an error.

**NOTE 1:** It is important to remember that `::Destroy(...?)` will also call `::Destroy()` on any instances that are referenced in the class table, as well as any instances that are [marked as trash](#412---handling-trash). It will also disconnect any `RBXScriptSignal` that is referenced (it's basically a Maid that iterates over `self`). If there are keys that you don't want destroyed, you can utilize [key protection](#415---protecting-keys).

**NOTE 2:** Any arguments passed through `::Destroy(...?)` will be sent to the [`::_onDestroy(...?)`](#413---intercepting-destruction) callback.
<br><br>

### 4.1.2 - Handling Trash
In some cases, you may want to mark an instance or signal for destruction that isn't already referenced in your class table. To do so, make use of the injected `::_markTrash(any|{any})` method. Any instance, `RBXScriptSignal`, or table (with a function called "Destroy") will be cleaned up when `::Destroy(...?)` is called.

**NOTE 1:** `::_markTrash(any|{any})` will accept a single item *or* a table of items. It is NOT a variadic.

**NOTE 2:** You cannot remove an item from the trash list after it has been added.
<br><br>

### 4.1.3 - Intercepting Destruction
You can optionally detect the destruction of your class by adding a function to your class table called `::_onDestroy(...?)`.

**NOTE 1:** This function is blocking and will be called *before* Classify clears and locks class data.

**NOTE 2:** Any arguments passed to `::Destroy(...?)` will be forwarded to this callback.
<br><br>

Here is an example of the `::_onDestroy(...?)` callback:
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
For backwards compatibility, Classify 3.0 and later has a newly-injected `::_protect(key)` method. This function - when called with the name of the key to protect - will ensure that Classify does not automatically destroy/disconnect any instance/`RBXScriptSignals` associated with that key.

**NOTE 1:** This method should only be used for upgrading classes that use versions of Classify older than 3.0 in cases where restructuring isn't an option.

**NOTE 2:** Continuous use of this method can promote memory leaks due to unreleased strong references. It is strongly recommended to structure your class code in an alternate manner if you find yourself relying on this method often.

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
Classify provides a high-level inheritance system that aims to streamline development in projects by reducing the need to rewrite duplicate code to accomplish the same result across similar components.

### 4.2.1 - Important Notes Before Continuing
- While Classify 3.0 and later supports the ability to inherit non-Classify-wrapped classes, you should note that the child class's (the inheriting module) metatable will always take precedent over the super class's (the inherited module) data. This means that custom implementations of `__newindex`, `__index`, etc. will not carry over to the child class.
- In fact, it is strongly recommended that you convert any third-party class modules to use Classify if able. Doing so will always guarantee a successful and predictable inheritance result.
- If both the child and super class have an `::_onDestroy(...?)` callback, the child's callback will always run before the super's.
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
        get = function(self)
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
        get = function(self)
            return "ChildClass Property!"
        end,
    },
}

return ChildClass
```
<br>

### 4.2.3 - Inheriting a Class
The `::_inherit(super, overwriteChild?, ...?)` function can be called anywhere in your child class. This function will cause all methods, private and public members, and custom properties of the super class to be copied over to yours. The optional `::_onInherit(child, ...?)` callback also allows the super class to intercept and perform additional processing on the inheriting child class.

**NOTE 1:** Duplicate keys (e.g. methods or properties with the same name) cannot be inherited and will be discarded from the super class unless `overwriteChild` is `true`; in which case, the reverse will happen and the super class data will take precedent.

**NOTE 2:** All data passed through `::_inherit(super, overwriteChild?, ...?)` after `overwriteChild` will be passed to `::_onInherit(child, ...?)` if it exists.

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
        get = function(self)
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
        get = function(self)
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
<br>

### 4.2.4 - Post-Inheritance Processing
You can optionally perform extra processing on a child class after the internal inherit operation completes with the `::_onInherit(child, ...?)` callback. This callback will only be called *after* Classify has finished copying over internal class data. Example:
```lua
-- SuperClass.lua
function SuperClass:_onInherit(childClass, ...)
    -- The "_foo" key will be added to the child class
    -- data and be accessible to both external and child
    -- class code.
    childClass._foo = "bar"
end
```
<br>

## 4.3 - Custom Properties
Classify provides a sandboxed custom property paradigm that allows you to assign **getters** and **setters** (referred to as **handlers** internally) to keys of your choice. This allows you to fully control what happens when a property is read from (get) or written to (set).

All custom properties are stored in the `__properties` table within your class:
```lua
-- Structure Definition:
-- MyClass.__properties = {
--     Property1Name = {
--         handler1 = ...,
--         handler2 = ...,
--     },
--     Property2Name = {
--         handler1 = ...,
--         handler2 = ...,
--     },
-- }

-- Real-world Example:
MyClass.__properties = {
    Active = {
        internal = "_active",
        set = function(self, value)
            self.someObject.Active = value
        end,
    },
    Text = {
        bindTarget = function(self)
            return self.someObject
        end,
    },
}
```

### 4.3.1 - Get Handlers Explained
**Get handlers** are used when the property is **read from** (e.g. getting the Text of a button). They are **mutually exclusive**, meaning that only one will return a value - even though you can technically have multiple handlers.

Because of their mutual exclusivity, Classify checks for get handlers in a certain order: `get`, `bindTarget`, `bind` and `target`, and lastly `internal`. Example:
```lua
-- The property will always return "MyProperty's Value" as
-- the get() handler will always take precedent over internal.
MyClass.__properties = {
    MyProperty = {
        internal = "_someKey",
        get = function(self)
            return "MyProperty's Value"
        end,
    },
}
```
**NOTE:** If the only handler your property uses is `get`, then your property will be treated as **read-only**. This means that any attempt to write to the property may cause errors!
<br><br>

### 4.3.2 - Set Handlers Explained
**Set handlers** are used when the property is **written to** (e.g. setting the Color of a Part). They are **not mutually exclusive**, meaning that any combination of set handlers will work during a write operation.

That said, set handlers are used in a certain order to prevent race conditions: `internal`, `set`, `bind` and `target`, and lastly `bindTarget`. Example:
```lua
-- The key "_someKey" will be set in the class table first
-- then the set() handler will be called.
MyClass.__properties = {
    MyProperty = {
        internal = "_someKey",
        set = function(self, value)
            print("Set MyProperty to:", value)
        end,
    },
}
```
**NOTE:** If the only handler your property uses is `set`, then your property will be treated as **write-only**. This means that any attempt to read from the property may cause errors!
<br><br>

### 4.3.3 - Using Handlers
#### 4.3.3.1 - get
The **get** handler is a function that must return at least one value. Only called when the property is read from. ***MUST NOT YIELD!***
```
<any> get(self: any)
  self: The owner class.
```
```lua
MyProperty = {
    get = function(self)
        return self._foo
    end,
}
```
<br>

#### 4.3.3.2 - set
The **set** handler is a function that is called when data is written to the property. Only called when the property is written to. ***MUST NOT YIELD!***
```
<void> set(self: any, value: any)
  self: The owner class.
  value: The value that is being written.
```
```lua
MyProperty = {
    set = function(self, value)
        if value == "bar" then
            self._foo = true
        else
            self._foo = false
        end
    end,
}
```
<br>

#### 4.3.3.3 - internal
The **internal** handler is a string that is the name of key in your class table. It exists solely to act
as "syntax sugar" and to eliminate the need to use both `get` and `set` handlers to expose a key. Used for both reads and writes.
```
internal = <string>
```
```lua
MyProperty = {
    internal = "_foo",
}
```
<br>

#### 4.3.3.4 - bind and target
The **bind and target** handler is a pair of keys that allows you to redirect a custom property to a real Roblox instance property. `bind` is a string that is the name of the target object's property. `target` is a function that must return the object you're binding to. Both `bind` and `target` are required to work. Used for both reads and writes.
```
bind = <string>

<Instance> target(self)
  self: The owner class.
```
```lua
MyProperty = {
    bind = "Text",
    target = function(self)
        return self.someTextLabel
    end,
}
```
<br>

#### 4.3.3.5 - bindTarget
The **bindTarget** handler is a shortcut version of **bind and target**. The key difference is that the name of the property itself is treated as `bind` in the **bind and target** handler. The value of `bindTarget` itself can either be a string (making it point to an internal class key) or a function that returns the target object. Used for both reads and writes.
```
bindTarget = <string>

OR

<Instance> bindTarget(self)
  self: The owner class.
```
```lua
Text = {
    bindTarget = "someTextLabel",
}

-- OR:

Text = {
    bindTarget = function(self)
        return self.someTextLabel
    end,
}
```
<br>

### 4.3.4 - Advanced Property Example
This example demonstrates how to combine multiple handlers to create a Text property that automatically resizes a button class:
```lua
local TextService = game:GetService("TextService")

MyButton.__properties = {
    Text = {
        -- Assign an internal key to the value of the Text.
        internal = "_rawText",

        -- Redirect the value to an object stored as "innerTextLabel"
        -- so the text is automatically updated for us.
        bindTarget = "innerTextLabel",

        -- Process the text value and update the size of the TextButton.
        set = function(self, value)
            local size = TextService:GetTextSize(value, 12, "Roboto", Vector2.new(500, 500))
            self.buttonFrame.Size = UDim2.fromOffset(sizeX + 20, 50)
        end,
    },
}
```
<br><br>

# 5 - Pending Documentation
Some niche features haven't been documented yet, but will be soon! For now I'll just list them out below for the sake of making them visible to those who may want to tinker:
- `::GetPropertyChangedSignal()` injected method
- `::_redirectNullKeys(target: any)` injected method
- `::_printClassData()` injected method