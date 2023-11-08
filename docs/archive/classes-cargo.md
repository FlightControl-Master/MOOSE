---
parent: Mission Designers Guide
grand_parent: Archive
nav_order: 3
---

# Cargo classes guide

![MOOSE CARGO](../images/classes/category-cargo.jpg)

MOOSE implements a whole enhanced mechanism to **create virtual cargo** within your missions.
Within this system, virtual cargo can be represented by:

   * Moveable cargo, represented by **groups of units**. It can be **boarded** into **carriers**, which can be
     **APCs or vehicles**, **helicopters**, **planes** or **ships**.
   * Stationary cargo, reprented by **static objects** or **static cargo objects**. It can be loaded into **carriers**,
     which can also be **APCs** or **vehicles**, **helicopters**, **planes** or **ships**.
   * Sling loadable cargo, reprented by **static cargo objects**. It can be sling loaded by **helicopter carriers**.

In order to use the MOOSE cargo management system, you'll need to declare cargo objects as part of your mission
script and setup either an **AI or a human cargo (task) dispatcher** to transport this virtual cargo around the
battlefield. For this, several MOOSE classes have been created for cargo dispatchment, which are listed below.

Click on each individual MOOSE class for detailed features and usage explanations, which are part of the detailed MOOSE
class documentation.

## 1. [WAREHOUSE]

![WAREHOUSE](../images/classes/functional/warehouse.jpg)

The MOOSE warehouse concept simulates the organization and implementation of complex operations regarding the flow of
assets between the point of origin and the point of consumption in order to meet requirements of a potential conflict.
In particular, this class is concerned with maintaining army supply lines while disrupting those of the enemy, since an
armed force without resources and transportation is defenseless.

**Features:**

  * Holds (virtual) assests in stock and spawns them upon request.
  * Manages requests of assets from other warehouses.
  * Queueing system with optional priorization of requests.
  * Realistic transportation of assets between warehouses.
  * Different means of automatic transportation (planes, helicopters, APCs, self propelled).
  * Strategic components such as capturing, defending and destroying warehouses and their associated infrastructure.
  * Intelligent spawning of aircraft on airports (only if enough parking spots are available).
  * Possibility to hook into events and customize actions.
  * Can be easily interfaced to other MOOSE classes.

Please note that his class is work in progress and in an **alpha** stage.

**Video:**

[![Warehouse](https://img.youtube.com/vi/e98jzLi5fGk/0.jpg)](https://youtu.be/e98jzLi5fGk "Warehouse")

## 2. [AI_CARGO_DISPATCHER]

![AI_CARGO_DISPATCHER](../images/classes/ai/cargo-dispatcher.jpg)

This section details the classes that you can use to setup an automatic cargo dispatching system that will make
AI carriers transport cargo (automatically) through the battlefield. Depending on the type of AI unit types, various
classes are implemented.

However, this class is the **BASE class** and contains the main functionality for the underlying more detailed
implementation classes. So, please read the documentation of the AI_CARGO_DISPATCHER class first (by clicking on it!)


### 2.1. [AI_CARGO_DISPATCHER_APC]

![AI_Cargo_Dispatcher_APC](../images/classes/ai/cargo-dispatcher-apc.jpg)

Models the intelligent transportation of **infantry** and other **small or lightweight cargo** using **APCs or trucks**.
This class models cargo to be transported between **zones**!

**Features:**

  * The vehicles follow the roads to ensure the fastest possible cargo transportation over the ground.
  * Multiple vehicles can transport multiple cargo as one vehicle group.
  * Infantry loaded as cargo, will unboard in case enemies are nearby and will help defending the vehicles.
  * Different ranges can be setup for enemy defenses.


### 2.2. [AI_CARGO_DISPATCHER_HELICOPTER]

![AI_Cargo_Dispatcher_Helicopter](../images/classes/ai/cargo-dispatcher-helicopters.jpg)

Models the intelligent transportation of **infantry** and other **small cargo** using **Helicopters**.
This class models cargo to be transported between **zones**!

**Features:**

  * The helicopters will fly towards the pickup locations to pickup the cargo.
  * The helicopters will fly towards the deploy zones to deploy the cargo.
  * Precision deployment as well as randomized deployment within the deploy zones are possible.
  * Helicopters will orbit the deploy zones when there is no space for landing until the deploy zone is free.


### 2.3. [AI_CARGO_DISPATCHER_AIRPLANE]

![AI_Cargo_Dispatcher_Airplane](../images/classes/ai/cargo-dispatcher-airplanes.jpg)

Models the intelligent transportation of **infantry, vehicles** and other **heavy cargo** using **Airplanes**.
This class models cargo to be transported between **airbases**!

**Features:**

  * The airplanes will fly towards the pickup airbases to pickup the cargo.
  * The airplanes will fly towards the deploy airbases to deploy the cargo.

---

## 3. Human cargo transportation dispatching.
 
Also **humans can achieve tasks** by to **transporting cargo** as part of a task or mission **goal**.

### 3.1. [TASK_CARGO_DISPATCHER]

![TASK_CARGO_DISPATCHER](../images/classes/tasking/cargo-dispatcher.jpg)

The [TASK_CARGO_DISPATCHER] allows you to setup various tasks for let human players transport cargo as part of a task.

The cargo dispatcher will implement for you mechanisms to create cargo transportation tasks:

  * As setup by the mission designer.
  * Dynamically create CSAR missions (when a pilot is downed as part of a downed plane).
  * Dynamically spawn new cargo and create cargo taskings!

**Features:**

  * Creates a task to transport @{Cargo.Cargo} to and between deployment zones.
  * Derived from the TASK_CARGO class, which is derived from the TASK class.
  * Orchestrate the task flow, so go from Planned to Assigned to Success, Failed or Cancelled.
  * Co-operation tasking, so a player joins a group of players executing the same task.

**A complete task menu system to allow players to:**

   * Join the task, abort the task.
   * Mark the task location on the map.
   * Provide details of the target.
   * Route to the cargo.
   * Route to the deploy zones.
   * Load/Unload cargo.
   * Board/Unboard cargo.
   * Slingload cargo.
   * Display the task briefing.

**A complete mission menu system to allow players to:**

   * Join a task, abort the task.
   * Display task reports.
   * Display mission statistics.
   * Mark the task locations on the map.
   * Provide details of the targets.
   * Display the mission briefing.
   * Provide status updates as retrieved from the command center.
   * Automatically assign a random task as part of a mission.
   * Manually assign a specific task as part of a mission.

**A settings system, using the settings menu:**

   * Tweak the duration of the display of messages.
   * Switch between metric and imperial measurement system.
   * Switch between coordinate formats used in messages: BR, BRA, LL DMS, LL DDM, MGRS.
   * Different settings modes for A2G and A2A operations.
   * Various other options.

---

## 4. The cargo system explained.

The following section provides a detailed explanation on the cargo system, how to use etc.

<https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.Cargo.html>

---

## 5. Cargo management classes.

MOOSE has implemented **a separate system for cargo handling**.
It combines the capabilities of DCS world to combine infantry groups, cargo static objects and static objects
as "cargo" objects. Cargo classes provides a new and enhanced way to handle cargo management and transportation.
In order to use these MOOSE cargo facilities, you'll have to declare those groups and static objects
in a special way within your scripts and/or within the mission editor.

The main [Cargo.Cargo] class is the base class for all the cargo management.
It contains the required functionality to load / board / unload / unboard cargo, and manage the state of each cargo
object. From this CARGO class are other CARGO_ classes derived, which inherit the properties and functions from CARGO,
but implement a specific process to handle specific cargo objects!
It is not the purpose to use directly the CARGO class within your missions.
However, consult the CARGO documention as it provides a comprehensive description on how to manage cargo within your
missions.

### 5.1. [CARGO_GROUP]

![CARGO_GROUP](../images/classes/cargo/cargogroup.jpg)

Management of **moveable** and **grouped** cargo logistics, which are based on a
[Wrapper.Group] object. Typical cargo of this type can be infantry or (small) vehicles.

**Features:**

  * Board cargo into a carrier.
  * Unboard cargo from a carrier.
  * Automatic detection of destroyed cargo.
  * Respawn cargo.
  * Maintain cargo status.
  * Communication of cargo through messages.
  * Automatic declaration of group objects to be treated as MOOSE cargo in the mission editor!


### 5.2. [CARGO_CRATE]

![CARGO_CRATE](../images/classes/cargo/cargocrate.jpg)

Management of single cargo crates, which are based on a [Wrapper.Static] object. Typical cargo of this type can be
crates, oil barrels, wooden crates etc. The cargo can be ANY static type! So potentially also other types of static
objects can be treated as cargo! Like flags, tires etc.

**Features:**

  * Loading / Unloading of cargo.
  * Automatic detection of destroyed cargo.
  * Respawn cargo.
  * Maintain cargo status.
  * Communication of cargo through messages.
  * Automatic declaration of group objects to be treated as MOOSE cargo in the mission editor!

### 5.3. [CARGO_SLINGLOAD]

![CARGO_SLINGLOAD](../images/classes/cargo/cargoslingload.jpg)

Management of **sling loadable** cargo crates, which are based on a [Wrapper.Static] object. This cargo can only be
slingloaded.

**Features:**

  * Slingload cargo.
  * Automatic detection of destroyed cargo.
  * Respawn cargo.
  * Maintain cargo status.
  * Communication of cargo through messages.
  * Automatic declaration of group objects to be treated as MOOSE cargo in the mission editor!


### 5.4. [CARGO_UNIT]

Management of **moveable** units, which are based on a [Wrapper.Unit] object.
Note that this is an **Internal** class and is only mentioned here for reference!

[WAREHOUSE]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Warehouse.html
[AI_CARGO_DISPATCHER]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/AI.AI_Cargo_Dispatcher.html
[AI_CARGO_DISPATCHER_APC]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/AI.AI_Cargo_Dispatcher_APC.html
[AI_CARGO_DISPATCHER_HELICOPTER]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/AI.AI_Cargo_Dispatcher_Helicopter.html
[AI_CARGO_DISPATCHER_HELICOPTER]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/AI.AI_Cargo_Dispatcher_Helicopter.html
[AI_CARGO_DISPATCHER_AIRPLANE]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/AI.AI_Cargo_Dispatcher_Airplane.html
[TASK_CARGO_DISPATCHER]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Tasking.Task_Cargo_Dispatcher.html
[CARGO_GROUP]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.CargoGroup.html
[CARGO_CRATE]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.CargoCrate.html
[CARGO_SLINGLOAD]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.CargoSlingload.html
[CARGO_UNIT]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.CargoUnit.html

[Cargo.Cargo]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Cargo.Cargo.html
[Wrapper.Group]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Wrapper.Group.html
[Wrapper.Static]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Wrapper.Static.html
[Wrapper.Unit]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Wrapper.Unit.html
