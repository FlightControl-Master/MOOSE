---
parent: Archive
nav_order: 1
---

# Starters Guide

## 1. MOOSE is an Object Oriented system.

MOOSE is an Object Oriented framework which provides different **classes** that take control of your simulation scenario.

### 1.1. Classes ...

  * **AI** - Take control of the AI controlled groups and units to execute specific tasks and processes.
  * **Tasking** - Assign tasks to human players, and let them achieve goals for logical missions setup in your simulation scenario.
  * **Functional** - Apply additional functionalities on top of the standard DCS simulation capabilities.
  * **Cargo** - Declare cargo objects, which are handled by moose in various ways.
  * **Wrapper** - The default dcs classes are wrapped by moose wrapper classes, and provide additional funtionality and easier access.
  * **Core** - The default dcs simulation capabilities are enhanced by moose, and provide additional functionality and easier access.

You as a mission designer are required to study each class features, and evaluate whether you want to apply
those features as part of your mission scenario.

### 1.2. Objects ...

If you want to apply a class, you need to **instantiate** the class by creating an **object** of that class.
Look at a **class** like the **definition of a process**, and the **object** **applies the process**.
Multiple objects can be created of the same class, and this is the power of an Object Oriented system.
These objects combine the combine **Methods** and **Variables**/**Properties** of the class as one encapsulated structure, that
hold state and work independently from each other!

Look at the following example:

Here we use the SPAWN class, which you can use to spawn new groups into your running simulation scenario.
The SPAWN class simplifies the process of spawning, and it has many methods to spawn new groups.

```lua
-- This creates a new SpawnObject from the SPAWN class, 
-- using the constructor :New() to instantiate a new SPAWN object.
-- It will search for the GroupName as the late activated group defined within your Mission Editor.
-- If found, the object "SpawnObject" will now contain a "copy" of the SPAWN class to apply the spawning process.  
local SpawnObject = SPAWN:New( "GroupName" ) 

-- Nothing is spawned yet..., so let's use now the SpawnObject to spawn a new GROUP.
-- We use the method :Spawn() to do that.
--  This method creates a new group from the GroupName template as defined within the Mission Editor.
local SpawnGroup = SpawnObject:Spawn() 
```

### 1.3. Inheritance ...

MOOSE classes **derive or inherit** from each other, that means, 
within MOOSE there is an **inheritance** structure.
The different moose classes are re-using properties and methods from its **parent classes**.

This powerful concept is used everywhere within the MOOSE framework. 
The main (Parent) Class in the MOOSE framework is the BASE class. 
Every MOOSE Class is derived from this top BASE Class.
So is also the SPAWN class derived from the BASE class. 
The BASE class provides powerful methods for debugging, 
event handling and implements the class handling logic.
As a normal MOOSE user, you won't implement any code using inheritance,
but just know that the inheritance structure is omni present in the intellisense and documentation.
You'll need to browse to the right MOOSE Class within the inheritance tree structure,
to identify which methods are properties are defined for which class.


## 2. MOOSE Demonstration Missions

The framework comes with demonstration missions which can be downloaded [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/), that you can try out and helps you to code.  
These missions provide examples of defined use cases how the MOOSE framework can be utilized. Each test mission is located in a separate directory, which contains at least one .lua file and .miz file.
The .lua file contains the mission script file that shows how the use case was implemented.
You can copy/paste code the code snippets from this .lua file into your missions, as it will accellerate your mission developments.
You will learn, see, and understand how the different MOOSE classes need to be applied, and how you can create
more complex mission scenarios by combining these MOOSE classes into a complex but powerful mission engine.

Some of these exact test missions are also demonstrated in a video format on the [YouTube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg).

