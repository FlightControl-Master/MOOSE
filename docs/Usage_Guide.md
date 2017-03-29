# 2.1) MOOSE Usage Guide

Using the MOOSE framework is very easy, and this document provides you with a detailed explanation how to install
and use MOOSE within your missions.

## 2.1.1) MOOSE framework at GitHub

You can find the source of [MOOSE framework on GITHUB](https://github.com/FlightControl-Master/MOOSE/). 
It is free for download and usage, but it is under license of the GNU 3.0 open source license policy.
The MOOSE development uses the GITHUB service to enforce and control a structured development within a growing community.
GITHUB enforces a structured approval process, release and change management, and a communicative distribution and deployment.
The MOOSE framework development is considered an open source project, where contributors are welcome to contribute on the development.
Some key users have already started with this process. Contact me if you're interested to contribute.

## 2.1.2) Eclipse LDT

MOOSE utilizes the Eclipse Lua Development Tools. As a result, the MOOSE framework is documented using the luadocumentor standard.
Every class, method and variable is documented within the source, and mission designers can write mission script lua code that is **intellisense**(-ed) ...
What that means is that while you are coding your mission, your object and variables (derived from MOOSE classes) will list the methods and properties of that class interactively while coding ...

![Intellisense](Usage/Intellisense.JPG)

## 2.1.3) LUA training

In order to efficiently use the MOOSE framework, it is highly recommended that you learn a couple of basic principles of lua.
I recommend you learn the basic lua principles following this [lua tutorial](https://www.tutorialspoint.com/lua).
We're not asking you to become an expert in lua, leave that to the experts, but, you'll need to have some basic lua coding 
knowledge to "understand" the code, and also, to understand the syntax.  

**Therefore, I suggest you walk through this [lua quick guide](https://www.tutorialspoint.com/lua/lua_quick_guide.htm)**.  
Ignore the lua environment setup. DCS comes with a pre-defined lua environment.

# 2.2) MOOSE Installation Guide

## 2.2.1) Download the latest release of MOOSE

The delivery of MOOSE follows a structured release process. Over time, new features are added that can be used in your mission.

## The latest release of MOOSE can be downloaded **[here](https://github.com/FlightControl-Master/MOOSE/releases)**.  

**Unzip the files into a directory of your choice, but keep the folder structure intact**.  


## 2.2.2) Download and install the Eclipse Lua Development Tools (LDT), which is an advanced lua editor.

1. If you don't have JAVA yet, you may have to install [java](https://www.java.com/en/download) first. 
2. Download and Install [Eclipse LDT](https://eclipse.org/ldt) on your Windows 64 bit system.

Now you should have a working LDT on your system.

## 2.2.3) Configure your LDT for the usage of MOOSE.

You need to configure your Eclipse LDT environment and link it with the MOOSE respository.
This will enable you to **start developing mission scripts** in lua, which will be **fully intellisense enabled**!!!  

Please follow the steps outlined!

### 2.2.3.1) Create a new **Workspace** in LDT.

The LDT editor has a concept of **Workspaces**, which contains all your settings of your editing environment, 
like views, menu options etc, and your code... Nothing to pay attention to really, but you need to set it up!
When you open EclipseLDT for the first time, it will ask you where to put your *workspace area*...

1. Open Eclipse LDT.
2. Select the default workspace that LDT suggests.

### 2.2.3.2) Create a new **Project** in LDT.

Here we will create a **New Project** called **Moose_Framework** in your LDT environment.
The project details are already defined within the MOOSE framework repository, 
which is unzipped on your local MOOSE directory on your PC.
We will link into that directory and automatically load the Project properties.

1. Select from the Menu: **File** -> **New** -> **Lua Project**.

![LDT_New_Project](Installation/LDT_New_Project.JPG)

2. A **New Project** dialog box is shown.

![LDT_Project](Installation/LDT_Project.JPG)

3. Type the Project Name: **Moose_Framework**.
4. In the sub-box "Project Contents", select the option **Create Project at existing location** (from existing source). 
5. **Browse** to the local MOOSE directory (press on the Browse button) and select the root directory of your local MO.OSE directory on your PC. Press OK.
6. You're back at the "New Project" dialog box. Press the **Next** button below the dialog box. 
__(All the other settings are by default ok)__.
7. You should see now a dialog box with the following properties. 
Note that the Moose Development/Moose directory is flagged as the **Source Directory*. (It is listed totally on top.) 
This is important because it will search in the files in this directory and sub directories for lua documentator enabled lua files. 
This will enable the intellisense of the MOOSE repository!

![LDT Finish](Installation/LDT_Moose_Framework_Finish.JPG)

8. Press the **Finish** button.

As a result, when you browse to the Script Explorer, you'll see the following:

![LDT_Script_Explorer](Installation/LDT_Script_Explorer.JPG)

**Congratulations! You have now setup your Moose_Framework project LDT environment!**

# 2.3) Your first mission

## 2.3.1) Setup your **Mission Project** in LDT

In order to design your own missions, it is recommended you create a separate directory on your PC 
which contains your mission files. Your mission will be designed consisting possibly 
out of a couple of components, which are:

  * (Mandatory) An include of the Moose.lua file (see 2.3.2).
  * (Mandatory) An include of your lua mission script file(s) (also with a .lua extension).
  * (Optionally) Sound files (.ogg) and pictures (.jpg) which are added into your mission.

Using the menu system of the DCS World Mission Editor, you need to include files in your mission (.miz) file.
However, once included, maintaining these files is a tedious task, 
having to replace each time manually these files when they change 
(due to a new release or a change in your mission script).

Therefore, **the recommendation is that your create for each mission a separate folder**.
The MOOSE test mission folder structure is a good example how this could be organized.
The LDT has been customized and provides a tool to **automatically** maintain your existing .miz files.

1. Select from the Menu: **File** -> **New** -> **Lua Project**.

![LDT_New_Project](Installation/LDT_New_Project.JPG)

2. A **New Project** dialog box is shown.

![LDT_Project](Installation/LDT_Project.JPG)

3. Type the Project Name: **My Missions**.


## 2.3.2) Create your first Mission file

In the MOOSE package, a file named **Moose.lua** can be found. 
In order to create or design a mission using the MOOSE framework, 
you'll have to include this **Moose.lua** file into your missions:

  1. Create a new mission in the DCS World Mission Editor.
  2. In the mission editor, create a new trigger.
  3. Name the trigger Moose Load and let it execute only at MISSION START.
  4. Add an action DO SCRIPT FILE (without a condition, so the middle column must be empty).
  5. In the action, browse to the **[Moose.lua](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Mission%20Setup)** file in the **Moose Mission Setup** directory, and include this file within your mission.
  6. Make sure that the "Moose Load" trigger is completely at the top of your mission.

Voila, MOOSE is now included in your mission. During the execution of this mission, all MOOSE classes will be loaded, and all MOOSE initializations will be exectuted before any other mission action is executed.

## 2.3.3) Maintain your .miz files

IMPORTANT NOTE: When a new version of MOOSE is released, you'll have to UPDATE the Moose.lua file in EACH OF YOUR MISSION.
This can be a tedious task, and for this purpose, a tool has been developed that will update the Moose.lua files automatically within your missions.

# 2.4) Support Channels

MOOSE is broadcasted, documented and supported through various social media channels.  

[Click here for the communities guide of the MOOSE framework](Communities.html).

# 2.5) Demonstration Missions

The framework comes with [Test Missions](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Test%20Missions), 
that you can try out and helps you to code. These test missions provide examples of defined use cases how the MOOSE
framework can be utilized. Each test mission is located in a separate directory, which contains at least one .lua file and .miz file.
The .lua file contains the mission script file that shows how the use case was implemented.
You can copy/paste code the code snippets from this .lua file into your missions, as it will accellerate your mission developments.
You will learn, see, and understand how the different MOOSE classes need to be applied, and how you can create
more complex mission scenarios by combining these MOOSE classes into a complex but powerful mission engine.

These exact test missions are also demonstrated at the demo videos in the YouTube channel.

