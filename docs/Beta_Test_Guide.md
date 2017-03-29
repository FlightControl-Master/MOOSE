
*** UNDER CONSTRUCTION ***

## 2.2) Get your MOOSE repository installed on your PC and linked with GITHUB

### 2.2.1) Install GITHUB desktop

Install [GITHUB](https://desktop.github.com) desktop. 
We use GITHUB desktop to sync the moose repository to your system.


### 2.1.1) Link the MOOSE repository

Link the MOOSE repository on GITHUB to your freshly installed GITHUB desktop. 
Do this by browing to the MOOSE repository at GITHUB, and select the green button **Clone or Download** -> **Open in Desktop**.
Specify a local directory on your PC where you want to store the MOOSE repository contents.
Sync the MOOSE repository to a defined local MOOSE directory on your PC using GITHUB desktop (press the sync button).

### 2.1.1) Sync the Dcs folder in the MOOSE repository

On your local MOOSE directory, execute the batch file [DCS_Folder_Sync.bat](https://github.com/FlightControl-Master/MOOSE/blob/master/DCS_Folder_Sync.bat). 
This will sync the dcs folder in the MOOSE repository from the submodule DCS API.
The Dcs folder is what we call a GITHUB submodule, which needs to be synced separately.
You will be notified when you need to re-sync the Dcs folder through GITHUB channels.

# 5) MOOSE Directory Structure

The MOOSE framework is devided into a couple of directories:

* Moose Development: Contains the collection of lua files that define the MOOSE classes. You can use this directory to build the dynamic luadoc documentation intellisense in your eclipse development environment.
* Moose Mission Setup: Contains the Moose.lua file to be included in your scripts when using MOOSE classes (see below the point Mission Design with Moose).
* Moose Test Missions: Contains a directory structure with Moose Test Missions and examples. In each directory, you will find a miz file and a lua file containing the main mission script.
* Moose Training: Contains the documentation of Moose generated with luadoc from the Moose source code. The presentations used during the videos in my [youtube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg), are also to be found here.
