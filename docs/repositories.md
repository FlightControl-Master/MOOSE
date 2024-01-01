---
title: Repositories
nav_order: 5
---

# MOOSE Repositories

The underlying picture documents the different repositories in the MOOSE framework.
The white ones are edited and are the source of the framework.
The red ones contain generated artefacts. See further the explanation for each repository.

![Graphic](/images/deployment-flow.png)

## [MOOSE](https://github.com/FlightControl-Master/MOOSE) - For development and static documentation

This repository contains the source lua code of the MOOSE framework.
Also the source files for this documentation are included in this repository.

## [MOOSE_INCLUDE](https://github.com/FlightControl-Master/MOOSE_INCLUDE) - For users (provides generated files)

This repository contains the `Moose.lua` and `Moose\_.lua` file to be included within your missions.
Note that the `Moose\_.lua` is technically the same as `Moose.lua`, but without any commentary or unnecessary whitespace in it.
You only need to load **one** of those files at the beginning of your mission.

## [MOOSE_DOCS](https://github.com/FlightControl-Master/MOOSE_DOCS) - Only to generate documentation website

This repository contains the generated documentation and pictures and other references.
The generated documentation is reflected in html and is published at: 
- `master`  branch: <https://flightcontrol-master.github.io/MOOSE_DOCS/>
- `develop` branch: <https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/>

## [MOOSE_GUIDES](https://github.com/FlightControl-Master/MOOSE_GUIDES) - For external documentation and help

This repository will be removed in future.

## [MOOSE_PRESENTATIONS](https://github.com/FlightControl-Master/MOOSE_PRESENTATIONS)

A collection of presentations used in the videos on the youtube channel of FlightControl.

## [MOOSE_MISSIONS](https://github.com/FlightControl-Master/MOOSE_MISSIONS) - For users (provides demo missions)

This repository contains all the demonstration missions in packed format (*.miz),
and can be used without any further setup in DCS WORLD.

## [Moose_Community_Scripts](https://github.com/FlightControl-Master/Moose_Community_Scripts)

This repository is for Moose based helper scripts, snippets, functional demos.

## [MOOSE_SOUND](https://github.com/FlightControl-Master/MOOSE_SOUND)

Sound packs for different MOOSE framework classes.

## [MOOSE_MISSIONS_DYNAMIC](https://github.com/FlightControl-Master/MOOSE_MISSIONS_DYNAMIC) - Outdated

This repository will be removed in future.

## [MOOSE_MISSIONS_UNPACKED](https://github.com/FlightControl-Master/MOOSE_MISSIONS_UNPACKED) - Outdated

This repository will be removed in future.

## [MOOSE_COMMUNITY_MISSIONS](https://github.com/FlightControl-Master/MOOSE_COMMUNITY_MISSIONS) - Outdated

A database of missions created by the community, using MOOSE.

## [MOOSE_TOOLS](https://github.com/FlightControl-Master/MOOSE_TOOLS) - Outdated

A collection of the required tools to develop and contribute in the MOOSE framework for DCS World.
