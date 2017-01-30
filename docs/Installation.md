# 2) Installation of the MOOSE Environment.

This document describes how to install your MOOSE development environment, enhancing the mission design experience for your missions in DCS World.

## 2.1) Install Eclipse LDT, a lua advanced editor

Install [Eclipse LDT](https://eclipse.org/ldt) on your Windows 64 bit system. 
This is a free lua editor based on the Eclipse ecosystem. 
The advantage of LDT is that it greatly enhances your lua development environment with intellisense, better search capabilities etc. 
You may have to install [java](https://www.java.com/en/download) first. 
Ensure you install the **64-bit versions** of both Eclipse LDT and java!

## 2.2) Get your MOOSE repository installed on your PC and linked with GITHUB

### 2.2.1) Install GITHUB desktop

Install [GITHUB](https://desktop.github.com) desktop. 
We use GITHUB desktop to sync the moose repository to your system.

### 2.2.2) Link the MOOSE repository

Link the MOOSE repository on GITHUB to your freshly installed GITHUB desktop. 
Do this by browing to the MOOSE repository at GITHUB, and select the green button **Clone or Download** -> **Open in Desktop**.
Specify a local directory on your PC where you want to store the MOOSE repository contents.
Sync the MOOSE repository to a defined local MOOSE directory on your PC using GITHUB desktop (press the sync button).

### 2.2.3) Sync the Dcs folder in the MOOSE repository

On your local MOOSE directory, execute the batch file [DCS_Folder_Sync.bat](https://github.com/FlightControl-Master/MOOSE/blob/master/DCS_Folder_Sync.bat). 
This will sync the dcs folder in the MOOSE repository from the submodule DCS API.
The Dcs folder is what we call a GITHUB submodule, which needs to be synced separately.
You will be notified when you need to re-sync the Dcs folder through GITHUB channels.

** As a result, you have installed the MOOSE repository on your PC, and it is fully synced. **

## 2.3) Configuration of the Eclipse LDT to work with MOOSE and activate your intellisense etc.

The section explains how to setup your Eclipse LDT environment, link it with the MOOSE respository.
This will enable you to start developing mission scripts in lua, which will be fully intellisense enabled!!!

### 2.3.1) Create a new **Workspace** in LDT.

The LDT editor has a concept of "workspaces", this contains all your settings of your editing environment, like views, menu options etc.
I suggest you create a workspace at your user id, the default location when you first start LDT.

1. Open Eclipse LDT.
2. Select the workspace to be stored at your user id.

### 2.3.2) Create a new **Project** in LDT.

Here we will create a new project called "Moose_Framework" in your LDT environment.
The project details are already defined within the MOOSE framework repository, which is installed on your local MOOSE directory on your PC.
We will link into that directory and load the Project properties.

1. Select from the Menu: File -> New -> Lua Project.

![LDT_New_Project](Installation/LDT_New_Project.JPG)

2. A "New Project" dialog box is shown.

![LDT_Project](Installation/LDT_Project.JPG)

3. Type the Project Name: **Moose_Framework**.
4. In the sub-box "Project Contents", select the option Create Project at existing location (from existing source). 
5. Browse to the local MOOSE directory (press on the Browse button) and select the root directory of your local MO.OSE directory on your PC. Press OK.
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
