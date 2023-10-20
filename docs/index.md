---
title: Overview
nav_order: 1
layout: home
---

[![Moose-Includes](https://github.com/FlightControl-Master/MOOSE/actions/workflows/build-includes.yml/badge.svg?branch=master)](https://github.com/FlightControl-Master/MOOSE/actions/workflows/build-includes.yml) &nbsp;
[![Moose-Docs](https://github.com/FlightControl-Master/MOOSE/actions/workflows/build-docs.yml/badge.svg?branch=master)](https://github.com/FlightControl-Master/MOOSE/actions/workflows/build-docs.yml)

# MOOSE framework

MOOSE is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment for mission designers in [DCS World].
It allows to quickly setup complex missions using pre-scripted scenarios using the available classes within the MOOSE Framework.
MOOSE is written in [Lua] which is a small and fast programming language, which is embedded in [DCS World].

## Goal of MOOSE

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, 
which can be instantiated from defined classes within the framework. This will allow to write mission scripts with 
minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios.
The MOOSE is a service that is produced while being consumed. It will evolve further as more classes are developed
for the framework and as more users are using it.
MOOSE is not a one-man show, it is a collaborative effort and meant to evolve within a growing community around the framework.
Within the community, key users will start supporting, documenting, explaining and even creating new classes for the framework.
It is the ambition to grow this framework as a de-facto standard for mission designers to use.

## Two branches - Choose wisely

In [DCS World] there is a `Stable` version and an `OpenBeta`. New features are released to the `OpenBeta` first and applied to `Stable` later.
People who choose to use `OpenBeta` can use the newest featuest and module, but accept the risk of bugs and unstable updates.
In MOOSE there is a `master` branch, which is comparable to the `Stable` version.
And there is the `development` branch, which is more like the `OpenBeta`.
New modules (called classes in [Lua], like [OPS.Auftrag]) will only available in the `development` branch.

Releases are the most stable approach to use MOOSE.
From time to time the current state of the `master` branch is used to create release.
A release gets a spefific version number and will not be changed later on.

## Documentation

Documentation on the MOOSE class hierarchy will be automatically generated from [LuaDoc] comments inside of the source code of MOOOSE.
You can find the results on these websites:

- Stable `master` branch: <https://flightcontrol-master.github.io/MOOSE_DOCS/>
- `develop` branch: <https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/>

## YouTube Tutorials

There are different tutorial playlists available on YouTube:

- AnyTimeBaby (Pene) has kindly created a [tutorial series for MOOSE](https://youtube.com/playlist?list=PLLkY2GByvtC2ME0Q9wrKRDE6qnXJYV3iT)
 with various videos that you can watch.
- FlightControl (initiator of the project) has created a lot of [videos](https://www.youtube.com/@flightcontrol5350/featured) on how to use MOOSE.
 They are a little bit outdated, but they still contain a lot of valuable information.

## MOOSE on Discord

MOOSE has a living community of users, beta testers and contributors.
The gathering point is a service provided by [Discord].
If you want to join this community, just click the link below and you'll be on board in no time.

- [Moose for DCS Discord server](https://discord.gg/aQtjcR94Qf)

[DCS World]: https://www.digitalcombatsimulator.com/de/
[Lua]: https://www.lua.org/
[LuaDoc]: https://keplerproject.github.io/luadoc/
[Ops.Auftrag]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.Auftrag.html
[Discord]: https://discord.com/
