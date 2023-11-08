---
parent: Mission Designers Guide
grand_parent: Archive
nav_order: 2
---

# Tasking classes guide

![MOOSE TASKING](../images/classes/category-tasking.jpg)

This chapter explains the major principles behind the tasking concepts in MOOSE.
Tasking is achieved through the utilization of various classes that fall in the category Tasking.

MOOSE allows humans to achieve mission goals, through the execution of tasks.

In order to setup the Tasking, you'll have to define:

  - At least one command center object for each coalition.
  - A mission or multiple missions for each command center.
  - A task dispatcher per mission.

**Features:**

  * Each coalition must have a command center.
  * Each command center can govern multiple missions.
  * Each command center owns a player menu.
  * Each mission can contain multiple tasks of different categories.
  * Each mission has a goal to be achieved.
  * Each mission has a state, that indicates the fase of the mission.
  * Each task can be joined by multiple human players, thus, a task is done in co-op mode.
  * Each task has a state, that indicates the fase of the task.
  * Players have their own menu. When a player joins a task, only that player will have the menu of the task.

## 1. [Command Center]

![Tasking Command Center](../images/classes/tasking/commandcenter.jpg)

A command center governs multiple missions, and takes care of the reporting and communications.

**Features:**

  * Govern multiple missions.
  * Communicate to coalitions, groups.
  * Assign tasks.
  * Manage the menus.
  * Manage reference zones.

## 2. [Mission]

![Tasking Command Center](../images/classes/tasking/mission.jpg)

A mission models a goal to be achieved through the execution and completion of tasks by human players.

**Features:**

  * A mission has a goal to be achieved, through the execution and completion of tasks of different categories by human players.
  * A mission manages these tasks.
  * A mission has a state, that indicates the fase of the mission.
  * A mission has a menu structure, that facilitates mission reports and tasking menus.
  * A mission can assign a task to a player.


## 3. [A2A Task Dispatcher]

![Tasking A2A Dispatching](../images/classes/tasking/task-a2a-dispatcher.jpg)

Dynamically allocates A2A tasks to human players, based on detected airborne targets through an EWR network.

**Features:**
 
  * Dynamically assign tasks to human players based on detected targets.
  * Dynamically change the tasks as the tactical situation evolves during the mission.
  * Dynamically assign (CAP) Control Air Patrols tasks for human players to perform CAP.
  * Dynamically assign (GCI) Ground Control Intercept tasks for human players to perform GCI.
  * Dynamically assign Engage tasks for human players to engage on close-by airborne bogeys.
  * Define and use an EWR (Early Warning Radar) network.
  * Define different ranges to engage upon intruders.
  * Keep task achievements.
  * Score task achievements.


## 3. [A2G Task Dispatcher]

![Tasking A2G Dispatching](../images/classes/tasking/task-a2g-dispatcher.jpg)

Dynamically allocates A2G tasks to human players, based on detected ground targets through reconnaissance.

**Features:**
 
  * Dynamically assign tasks to human players based on detected targets.
  * Dynamically change the tasks as the tactical situation evolves during the mission.
  * Dynamically assign (CAS) Close Air Support tasks for human players.
  * Dynamically assign (BAI) Battlefield Air Interdiction tasks for human players.
  * Dynamically assign (SEAD) Supression of Enemy Air Defense tasks for human players to eliminate G2A missile threats.
  * Define and use an EWR (Early Warning Radar) network.
  * Define different ranges to engage upon intruders.
  * Keep task achievements.
  * Score task achievements.

[Command Center]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Tasking.CommandCenter.html
[Mission]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Tasking.Mission.html
[A2A Task Dispatcher]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Tasking.Task_A2A_Dispatcher.html
[A2G Task Dispatcher]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Tasking.Task_A2G_Dispatcher.html
