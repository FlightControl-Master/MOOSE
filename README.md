[![Build status](https://ci.appveyor.com/api/projects/status/1y8nfmx7lwsn33tt?svg=true)](https://ci.appveyor.com/project/Applevangelist/MOOSE)

# MOOSE framework

MOOSE is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment, and is meant for mission designers in DCS World.
It allows to quickly setup complex missions using pre-scripted scenarios using the available classes within the MOOSE Framework.
  
  
##  MOOSE Framework Goal

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, which can be instantiated from defined classes within the framework. This will allow to write mission scripts with minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios. 
The MOOSE is a service that is produced while being consumed ... , it will evolve further as more classes are developed for the framework, and as more users are using it.
MOOSE is not a one-man show, it is a collaborative effort and meant to evolve within a growing community around the framework.
Within the community, key users will start supporting, documenting, explaining and even creating new classes for the framework.
It is the ambition to grow this framework as a de-facto standard for mission designers to use.
  
  
##  MOOSE Repositories

The underlying picture documents the different repositories in the MOOSE framework. The white ones are edited and are the source of the framework.
The red ones contain generated artefacts. See further the explanation for each repository.

![Graphic](https://raw.githubusercontent.com/FlightControl-Master/MOOSE_DOCS/master/Configuration/Master.png)
 
  
###   [MOOSE](https://github.com/FlightControl-Master/MOOSE) - For edit and development

This repository contains the source lua code of the MOOSE framework.
  
  
###   [MOOSE_INCLUDE](https://github.com/FlightControl-Master/MOOSE_INCLUDE) - For use and generated 

This repository contains the Moose.lua file to be included within your missions. Note that the Moose\_.lua is technically the same as Moose.lua, but without any commentary or unnecessary whitespace in it. You only need to load **one** of those at the beginning of your mission.
  
 
###   [MOOSE_DOCS](https://github.com/FlightControl-Master/MOOSE_DOCS) - Not for use

This repository contains the generated documentation and pictures and other references. The generated documentation is reflected in html and is published at: https://flightcontrol-master.github.io/MOOSE_DOCS/
  
  
###   [MOOSE_MISSIONS](https://github.com/FlightControl-Master/MOOSE_MISSIONS) - For use and generated

This repository contains all the demonstration missions in packed format (*.miz), and can be used without any further setup in DCS WORLD.
  
  
###   [MOOSE_MISSIONS_DYNAMIC](https://github.com/FlightControl-Master/MOOSE_MISSIONS_DYNAMIC) - For use and generated

This repository contains all the demonstration missions in packed format (*.miz), but MOOSE is dynamically loaded from your disk! These missions are to be used by beta testers of the MOOSE framework and are not for end uers!!!!
 
    
###   [MOOSE_MISSIONS_UNPACKED](https://github.com/FlightControl-Master/MOOSE_MISSIONS_UNPACKED) - For edit and development

This repository contains all the demonstration missions in unpacked format. That means that there is no .miz file included, but all the .miz contents are unpacked.


##  [MOOSE Web Site](https://flightcontrol-master.github.io/MOOSE_DOCS/)

Documentation on the MOOSE class hierarchy, usage guides and background information can be found here for normal users, beta testers and contributors.

![Click on this link to browse to the MOOSE main web page.](https://raw.githubusercontent.com/FlightControl-Master/MOOSE_DOCS/master/Configuration/Site.png)
  
  
  
##  [MOOSE Youtube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)

MOOSE has a [broadcast and training channel on YouTube](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg) with various channels that you can watch.
  
  
    
##  [MOOSE on Discord](https://discord.gg/yBPfxC6)

MOOSE has a living (chat and video) community of users, beta testers and contributors. The gathering point is a service provided by discord.com. If you want to join this community, just click Discord and you'll be on board in no time.
  
   

Kind regards,
The Moose Team
  
   
