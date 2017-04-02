# 1) MOOSE Usage Guide

Using the MOOSE framework is very easy, and this document provides you with a detailed explanation how to install
and use MOOSE within your missions.

## 1.1) MOOSE framework at GitHub

You can find the source of [MOOSE framework on GITHUB](https://github.com/FlightControl-Master/MOOSE/). 
It is free for download and usage, since it is released under the GNU 3.0 open source license policy.
Although the MOOSE contributors and tester are using the GitHub service to enforces a structured approval process, release and change management, and a communicative distribution and deployment, you, as a mission designer, don't need to mess with it. Still, if you are interrested intesting the latest features of MOOSE of in adding your own, you can read the [relevant](http://flightcontrol-master.github.io/MOOSE/Beta_Test_Guide.html) [guides](http://flightcontrol-master.github.io/MOOSE/Contribution_Guide.html) and/or contact FlightControl 
The MOOSE framework development is an open source project, and as such, contributors are welcome and encouraged to contribute on the development.Some key users have already started with this process.

## 1.2) Eclipse LDT

MOOSE utilizes the Eclipse Lua Development Tools. As a result, the MOOSE framework is documented using the luadocumentor standard.
Every class, method and variable is documented within the source, and mission designers can write mission script lua code that is **intellisense**(-ed) ...
What that means is that while you are coding your mission, your object and variables (derived from MOOSE classes) will list the methods and properties of that class interactively while coding ...

![Intellisense](Usage/Intellisense.JPG)

## 1.3) LUA training

In order to efficiently use the MOOSE framework, it is highly recommended that you learn a couple of basic principles of lua.
I recommend you learn the basic lua principles following this [lua tutorial](https://www.tutorialspoint.com/lua).
We're not asking you to become an expert in lua, leave that to the experts, but, you'll need to have some basic lua coding 
knowledge to "understand" the code, and also, to understand the syntax.  

**Therefore, I suggest you walk through this [lua quick guide](https://www.tutorialspoint.com/lua/lua_quick_guide.htm)**.  
Ignore the lua environment setup. DCS comes with a pre-defined lua environment.

# 2) MOOSE Installation Guide

## 2.1) Download the latest release of MOOSE

The delivery of MOOSE follows a structured release process. Over time, new features are added that can be used in your mission.

## The latest release of MOOSE can be downloaded **[here](https://github.com/FlightControl-Master/MOOSE/releases)**.  

**Unzip the files into a directory of your choice, but keep the folder structure intact**.  


## 2.2) Download and install the Eclipse Lua Development Tools (LDT), which is an advanced lua editor.

1. If you don't have JAVA yet, you may have to install [java](https://www.java.com/en/download) first. 
2. Download and Install [Eclipse LDT](https://eclipse.org/ldt) on your Windows 64 bit system.

TNow you should have a working LDT on your system.
Don't skip this step, LDT is a game-changer. Don't believe us ? Well we challenge you to test and tell us what you think ! Once you tried coding with intellisense, you won't go back !

## 2.3) Configure your LDT for the usage of MOOSE.

You need to configure your Eclipse LDT environment and link it with the MOOSE respository.
This will enable you to **start developing mission scripts** in lua, which will be **fully intellisense enabled**!!!  

Please follow the steps outlined!

### 2.3.1) Create a new **Workspace** in LDT.

The LDT editor has a concept of **Workspaces**, which contains all your settings of your editing environment, 
like views, menu options etc, and your code... Nothing to pay attention to really, but you need to set it up!
When you open EclipseLDT for the first time, it will ask you where to put your *workspace area*...

1. Open Eclipse LDT.
2. Select the default workspace that LDT suggests.

### 2.3.2) Create a new **Project** in LDT.

Here, we will create a **New Project** called **Moose_Framework** in your LDT environment.
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

# 2.4) Your first mission

## 2.4.1) Setup your **Mission Project** in LDT

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

### 2.4.1.1. Select from the Menu: **File** -> **New** -> **Lua Project**.

![LDT_New_Project](Installation/LDT_New_Project.JPG)

### 2.4.1.2. A **New Project** dialog box is shown.

![LDT_Project](Installation/LDT_Project.JPG)

### 2.4.1.3. Type your Project Name: (In my example it is **DCS_Caucasus_Missions**.


Note the indicated options in yellow:

  * Note that you can select the option **No execution environment**.
  * Deselect the option **Create default project template ready to run**.

![LDT_Project](Installation/LDT_Project_My_Missions.JPG)

### 2.4.1.4. Press **Next >**

### 2.4.1.5. Click the **Projects** tab at the top of the window.

![LDT_Project](Installation/LDT_New_Project_Projects.JPG)

### 2.4.1.6. Press the **Add...** button.

### 2.4.1.7. A new windows will be displayed: **Required Project Selection**.

This is an important step. This will _link_ your project to the Moose_Framework project and will activate **intellisense**.

![LDT_Project](Installation/LDT_Select_Moose_Framework.JPG)

### 2.4.1.8. After the selection, press the **OK** button.

### 2.4.1.9. Watch your newly created project in the Script Explorer of LDT.

You can delete the possibly created SRC directory. You won't need it at all.

![LDT_Project](Installation/LDT_Delete_Src.JPG)

### 2.4.1.10. Within your newly created Missions Project, right click and select **New -> Folder**.

As explained above, each of your missions will be stored in a separate folder. Please follow the explanation how to do that.

![LDT_Project](Installation/LDT_Add_Folder.JPG)

### 2.4.1.11. Type the **Folder Name**.

This can be any descriptive text explaining the title of your mission.

![LDT_Project](Installation/LDT_Mission_Folder_Name.JPG)

### 2.4.1.12. In your newly created **Mission Folder**, right click and select **New -> Lua File**.

This will create your **mission script file**, 
the file that contains all the lua code using the Moose framework using your mission.

### 2.4.1.13. Type the **Lua Mission Script Name**.

![LDT_Project](Installation/LDT_Mission_Lua_File_Name.JPG)


## 2.4.2) Create your first Mission file

In the root of the MOOSE package, a file named **Moose.lua** can be found. 
In order to create or design a mission using the MOOSE framework, 
you'll have to include this **Moose.lua** file into your missions:

  1. Create a new mission in the DCS World Mission Editor.
  2. In the mission editor, create a new trigger.
  3. Name the trigger Moose Load and let it execute only at MISSION START.
  4. Add an action DO SCRIPT FILE (without a condition, so the middle column must be empty).
  5. In the action, browse to the **[Moose.lua](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Mission%20Setup)** file in the **Moose Mission Setup** directory, and include this file within your mission.
  6. Make sure that the "Moose Load" trigger is completely at the top of your mission.

Voila, MOOSE is now included in your mission. During the execution of this mission, all MOOSE classes will be loaded, and all MOOSE initializations will be exectuted before any other mission action is executed.

Find below a detailed explanation of the actions to follow:

### 2.4.2.1. Open the Mission Editor in DCS, select an empty mission, and click the triggers button.

![LDT_Project](Installation/DCS_Triggers_Empty.JPG)

### 2.4.2.2. Add a new trigger, that will load the Moose.lua file.

Check the cyan colored circles:

  * This trigger is loaded at MISSION START.
  * It is the first trigger in your mission.
  * It contains a DO SCRIPT FILE action.
  * No additional conditions!

![LDT_Project](Installation/DCS_Triggers_Load_Moose_Add.JPG)

### 2.4.2.3. Select the Moose.lua loader from the **Moose Mission Setup** folder in the Moose_Framework pack.

Additional notes:

  * If you've setup a folder link into Saved Games/DCS/Missions/Moose Mission Setup, then you can directly select this folder from **My Missions**.
  * See point ...

Press the **OK** button.

![LDT_Project](Installation/DCS_Triggers_Load_Moose_Select_File.JPG)

### 2.4.2.4. Check that the Moose.lua file has been correctly added to your Mission.

![LDT_Project](Installation/DCS_Triggers_Load_Moose_File_Added.JPG)

### 2.4.2.5. Add a new trigger, that will load your mission .lua file.

Check the cyan colored circles:

  * This trigger is loaded at MISSION START.
  * It is the second trigger in your mission.
  * It contains a DO SCRIPT FILE action.
  * No additional conditions!

![LDT_Project](Installation/DCS_Triggers_Load_Mission_Add.JPG)

### 2.4.2.6. Select the mission .lua file from your **missions** folder you just created or already have.

Additional notes:

  * If you've setup a folder link into Saved Games/DCS/Missions/Moose Mission Setup, then you can directly select this folder from **My Missions**.
  * See point ...

Press the **OK** button.

![LDT_Project](Installation/DCS_Triggers_Load_Mission_File_Select.JPG)

### 2.4.2.7. Check that your mission .lua script file has been correctly added to your mission.

![LDT_Project](Installation/DCS_Triggers_Load_Mission_File_Added.JPG)


## 2.4.3) Maintain your .miz files

IMPORTANT NOTE: When a new version of MOOSE is released, you'll have to UPDATE the Moose.lua file in EACH OF YOUR MISSION.
This can be a tedious task, and for this purpose, a tool has been developed that will update the Moose.lua files automatically within your missions.

### 2.4.3.1. Select the **Update SELECTED Mission** from the External Tools in LDT.

This will activate a script that will automatically re-insert your mission .lua file into your mission.

![LDT_Project](Installation/DCS_Triggers_Load_Mission_File_Added.JPG)

## 2.4.4) Create folder links into your "My Missions" folder in Saved Games/DCS/Missions. 

***TODO : Detail how hard links work, explain how they help the wworkflow***

This trick will save you a lot of time. You need to install the tool ... to create easily new links.

Select from the following possible links that can be created to save you time while browing through the different folders to include script files:

### 2.4.4.1. Create a link to your **Moose Mission Setup** folder ...

### 2.4.4.2. Create a link to your **missions** folder ...

# 4) Demonstration Missions

The framework comes with demonstration missions which can be downloaded [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases), that you can try out and helps you to code.   
These missions provide examples of defined use cases how the MOOSE framework can be utilized. Each test mission is located in a separate directory, which contains at least one .lua file and .miz file. The .lua file contains the mission script file that shows how the use case was implemented. You can copy/paste code the code snippets from this .lua file into your missions, as it will accellerate your mission developments. You will learn, see, and understand how the different MOOSE classes need to be applied, and how you can create more complex mission scenarios by combining these MOOSE classes into a complex but powerful mission engine.
Some of these exact test missions are also demonstrated in a video format on the [YouTube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg).

