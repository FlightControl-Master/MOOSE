*** UNDER CONSTRUCTION ***

You are interrested in testing the bleeding edge functionnalities and features added by the developers every day, and you are not afraid of bug that will inevitably crop up from time to time ? Then this page is for you ! You are going to learn :
1. How to set up your development environment
2. How is the Moose repository organized
3. How Moose is loaded in the missions and how this can make your workflow more efficient
4. How to use tools to process your .miz files efficiently
5. How Moose's release cycle work
6. How to report a bug

This might be a bit daunting at first, but the rewards in term of simplified workflow and direct access to new features is well worth the effort! If you have any problem during the setup or at any other point, don't hesitate to ask the [community](Communities) for help!

This guide assumes that you already setup your development environment, lust like a "normal" mission designer. Which means Lua Development Tools (LDT) is installed on your computer, and you already know how to create a mission using MOOSE. If it is not the case, please follow the instructions [here](http://flightcontrol-master.github.io/MOOSE/Usage_Guide.html).

# 1) Installation

## 1.1) Get your MOOSE repository installed on your PC and linked with GITHUB

### 1.1.1) Install GITHUB desktop

Install [GITHUB](https://desktop.github.com) desktop. 
Since the MOOSE code is evolving very rapidely between Releases, we store the MOOSE code on GitHub, and we use the GitHUb to sync it between the remote repository (the "origin") and your local MOOSE repository. That way, only one click is needed to update to the latest version of GitHub


### 1.1.2) Link the MOOSE repository

Link the MOOSE repository on GITHUB to your freshly installed GITHUB desktop. 
Do this by browing to the MOOSE repository at GITHUB, and select the green button **Clone or Download** -> **Open in Desktop**.
![](Installation/GitHub_Clone.jpg)
Specify a local directory on your PC where you want to store the MOOSE repository contents.
Sync the MOOSE repository to a defined local MOOSE directory on your PC using GITHUB desktop (press the sync button).
You now have a copy of the code on computer, which you can update at any time by simply pressing the sync button.

### 1.2) Install 7-Zip

Install [7-Zip](http://www.7-zip.org/) if you don't already have it. It is a free and open source file archiver program. Since DCS' .miz files are simply renamed .zip files, 7-Zip is very usefull to manimulate them. We are providing the MOOSE testers and developpers tools to batch process their .miz files, and they rely on 7-Zip. Keep the path to your 7-Zip installation handy, it will be use in the next step !

### 1.3) Run the Install script

Because DCS is going to load Moose dynamically (more on that later), we need to do some (slightly) advanced stuff to finish the setup of your own development enviroment. Thankfully we wrote a program to do all of it automatically for you !
Browse to your local MOOSE repository and run `Moose Development Environment Setup\MooseDevelopmentEnvironmentSetup.exe` **as an administrator** (Select the file > Left Click > Run as administrator). 
* The Splash screen opens, click ok
* Enter (or browse for) the 3 paths asked and click ok. Don't worry about the trailing backslashs.
* Let the program do it's magic ! 
* When the program finishes, it will inform you that you need to restart your computer to use the tools related to .miz files.

If you encounter a problem during this installation, please contact the [community](Communities), with the mdes.log file which was generated next to the executable file. We'll try our best to help you!

**Wait, I'm not running a program randomly found on the internet like that. I don't even know what it does, and why does it have to be run as an administartor anyway?!**
And you are right. But the explanation is a bit technical, your are warned!
The software will do the following:
* Create a hard link between your local repository and `DCSWorld/Scripts/`
* Add 7-Zip to your PATH environment variable (this explains the restart requirement)
* Copy a precompiled version of Lua 5.1 to your `Program Files` (this explains the administrator priviledge requirement)

The script is made in AutoIt, it is available near the executable if you want to know what it does. If you are still reluctant, the whole process can be done manually by experienced users, get in touch with the [community](Communities)!

# 2) MOOSE Directory Structure

The MOOSE framework is devided into a couple of directories:

* Moose Development: Contains the collection of lua files that define the MOOSE classes. You can use this directory to build the dynamic luadoc documentation intellisense in your eclipse development environment.
* Moose Mission Setup: Contains the Moose.lua file to be included in your scripts when using MOOSE classes (see below the point Mission Design with Moose).
* Moose Test Missions: Contains a directory structure with Moose Test Missions and examples. In each directory, you will find a miz file and a lua file containing the main mission script.
* Moose Training: Contains the documentation of Moose generated with luadoc from the Moose source code. The presentations used during the videos in my [youtube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg), are also to be found here.

# 3) Static Loading vs Dynamic Loading

## 3.1) Static Loading

Moose static loading is what the "normal" mission designer uses. Simply put, there is a tool which concatenates every .lua file which constitutes Moose into just one: Moose.lua. This is the file which is loaded in Mission Editorr by the mission designer.
This process is very useful when you are using a stable Release of Moose which don't change often, because it is really easy to set up for the mission designer. It also allows him to release missions which are contained in their entirety in the .miz file.
But in a context in wich Moose changes sometimes multiple times a day, static loading would require the generation of a new Moose.lua each time, replace the old Moose.lua in the .miz file you are using to test your changes, and play the mission. Add to this process the fact that the Mission Editor doesn't like changes to the .miz file while the mission is open, so you would need to close and reopen the ME everytime, and this process becomes unworkable for both the tester and the developper.

## 3.2) Dynamic Loading

Enter Moose Dynamic loading. In this process, the Moose.lua you insert in your .miz file looks for every .lua which constitute Moose in `DCSWorld\Scripts`, and asks DCS to load them. This way, the latest changes to Moose's .lua files in `DCSWorld\Scripts` are automatically taken into account when you restart the mission, no need to fiddle around with the .miz file or to close the mission editor!
Now, there is still a problem left : you wouldn't want to have to copy the Moose's .lua files from your local repository to `DCSWorld\Scripts` everytime you retrieve a new version of Moose. The solution to this problem is a dynamic link! It is created by the Install Scipt (see above), and, simply put, makes sure that the folder `DCSWorld\Scripts\Moose` is always in sync with your local repository. That way, everytime you want to update to the next Moose, you simply sync your local repository with the remote with GitHub, and restart your mission !
Note that if you want to release your missions to end users, you will need to make it use the static loading process. There is a tool to automate this task, read below.

# 4) Tools to help you manage your .miz files

# 5) The release cycle

To ensure that the next Release of Moose is as bug-free and feature rich as possible, every developer respects a 

# 6) How to report a bug ?

