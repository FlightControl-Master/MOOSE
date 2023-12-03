---
parent: Beginner
nav_order: 01
---
# Introduction
{: .no_toc }

1. Table of contents
{:toc}

This very short chapter is for people identifying as a consumer of MOOSE and not
wishing to learn to script. This is a condensed FAQ and set of links to get you
up and running. It specifically avoids any complexity.

## What is MOOSE?

[DCS] has included a [Simulator Scripting Engine] (short SSE). This SSE gives
mission designers access to objects in the game using [Lua] scripts.

**M**ission **O**bject **O**riented **S**cripting **E**nvironment, is a
scripting framework written in [Lua] that attempts to make the scripting of
missions within DCS easier, simpler and shorter than with the standard methods.

MOOSE is over 5 MB of code, with as many words as the Bible and the core of it
was written over several years by one person.

MOOSE is the brain-child of an talented programmer with the alias FlightControl.
If you want to know more about this topic, check out FC’s [MOOSE for Dummies]
videos on YouTube.

{: .note }
> We recommend video playback at 1.5x speed, as FC speaks slowly and distinctly.

## What is Lua?

[Lua] is a lightweight, programming language designed primarily to be embedded
in applications. It's main advantages are:

- It is fast,
- it is portable (Windows, Linux, MacOS),
- it is easy to use.

[Lua] is embedded in DCS, so we can use it without any modification to the game.

## What are scripts, frameworks and classes?

A script is a set of instructions in plain text read by a computer and processed
on the fly. Scripts do not need to be compiled before execution, unlike exe
files.

A framework is a structure that you can build software (or in this case missions)
on. It serves as a foundation, so you're not starting entirely from scratch.
It takes a lot of work off your hands because someone else has thought about it
and provides ready-made building blocks for many situations.

These building blocks are called classes in object oriented programming.

## What can MOOSE do for me?

Whilst MOOSE can be used to write customised [Lua] scripts, you are probably not
caring for learning [Lua] right now. Instead you can use a MOOSE script written
by someone else by just copy and paste it. You can configure the basic settings
of the classes to fit your needs in your mission.

Here are a few suggestions for well-known and popular classes:

- [Ops.Airboss] manages recoveries of human pilots and AI aircraft on aircraft
  carriers.
- [Functional.RAT] creates random airtraffic in your missions.
- [Functional.Range] (which counts hits on targets so you can practice),
- [Functional.Fox] to practice to evade missiles without being destroyed.
- and many more!

You will need to look through examples to know what functionallity you want to
add to your missions.

## What if I don’t want to learn scripting?

The good news for you: You don't need to become a professional [Lua] programmer
to use MOOSE. As explained already, you can copy and paste the code from example
missions. You need some basics how to add triggers in the mission editor. But we
will cover this later.

If you want to modify the behaviour of the classes slightly, some basics about
the [Lua] synthax (the rules how to write the code) will help you to avoid
errors.

The more customizations you want to make, the more knowledge about [Lua] you
will need. But you can learn this step by step.

## Next step

We will start with a very simple demonstartion of MOOSE in the next section
[Hello world mission].

[DCS]: https://www.digitalcombatsimulator.com/en/
[Simulator Scripting Engine]: https://wiki.hoggitworld.com/view/Simulator_Scripting_Engine_Documentation
[Lua]: https://www.lua.org/
[MOOSE for Dummies]: https://www.youtube.com/watch?v=ZqvdUFhKX4o&list=PL7ZUrU4zZUl04jBoOSX_rmqE6cArquhM4&index=2&t=618s

[Ops.Airboss]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.Airboss.html
[Functional.RAT]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.RAT.html
[Functional.Range]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Range.html
[Functional.Fox]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Functional.Fox.html

[Hello world mission]: hello-world.md
