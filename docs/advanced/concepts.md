---
title: Concepts
parent: Advanced
nav_order: 01
---

# Concepts
{: .no_toc }

1. Table of contents
{:toc}

If you want to get deeper into Moose, you will encounter a few terms and
concepts that we will explain here. You will need them for the later pages.

# Git and GitHub

Moose has about 260.000 lines of code and the amount is increasing each week.
To maintain such a big code base a vcs (version control system) is needed.
Moose uses [GitHub] as developer platform to create, store, and manage the code.
[GitHub] uses [Git] as version control system and provides additional
functionality like access control, bug tracking, feature requests and much more.

As a Moose user you don't need to learn how to use [Git]. You can download the
files on [GitHub] with a browser. But using [Git] will ease up the steps to keep
the Moose version on your hard disk up to date.

You will need to interact with [GitHub]. At least to download the Moose files.
For non-developers the page can be confusing. Take your time and read this
documentation. We are not able to explain every single detail on using [GitHub]
and [Git]. Especially because it is changing really quick and this documentation
will not. So try to use the help system of [GitHub] or find some videos on
[YouTube]. If you get stuck ask for help in the [Moose Discord].

Moose uses more than one repository on [GitHub] which doesn't exactly make it
any clearer. A list can be found on the [reposities] page.

# Branches: master & develop

As already explained in the [overview] two branches are used:

- Branch [master]: Stable release branch.
- Branch [develop]: Newest development with more OPS classes.

As a starter it is okay to begin your journey with the `master` branch.
If you are interested in some newer classes you need to use the `develop`
branch. The later one is also very stable, but it's missing more detailed
documentation and example missions for some of the new OPS classes.

You can switch between these branches with a drop down in the upper left corner
of the [GitHub] repository page. The list of branches is long. So it is a best
practice to save a bookmark in your browser with the links above.
Both branches are available on most of the different repositories. But because
of a limitation of [GitHub pages], we had to split the documentation in two
different repositories:

- Documentation of `master` branch: [MOOSE_DOCS]
- Documentation of `develop` branch: [MOOSE_DOCS_DEVELOP]

# Build result vs. source files

Moose consists of more than 140 individual files with the file extension `.lua`.
They are places in a [directory tree], which makes it more organized and its
semantic is pre-defined for [IntelliSense] to work.

On every change which is pushed to [GitHub] a build job will combine all of
these files to a single file called `Moose.lua`. In a second step all
comments will be removed to decrease the file size and the result will be saved
as `Moose_.lua`. These both files are created for users of Moose to include in
your missions.

The individual `.lua` files are used by the Moose developers and power users.
It is complicated to use them, but in combination with an IDE and a debugger it
is very useful to analyze even complex problems or write new additions to the
Moose framework.

# Static loading

If you add a script file with a `DO SCRIPT FILE` trigger, like we described in
[Create your own Hello world], the script file will be copied into the mission
file. This mission file (file extension .MIZ) is only a compressed ZIP archive
with another file ending.

If you change the script file after adding it to the mission, the changes are
not available on mission start. You have to re-add the script after each change.
This can be very annoying and often leads to forgetting to add the change again.
Then you wonder why the mission does not deliver the desired result.

But when the mission is finished you can upload it to your dedicated DCS server
or give it to a friend and it should run without problems. This way of embedding
the scripts do we call `static loading` and the resulting mission is very
portable.

#  Dynamic loading of mission scripts

The other way of loading scripts is by using `DO SCRIPT`. This time the mission
editor don't show a file browse button. Instead you see a (very small) text
field to enter the code directly into it. It is only useful for very small
script snippets. But we can use it to load a file from your hard drive like
this:

```lua
dofile('C:/MyScripts/hello-world.lua')
dofile('C:\\MyScripts\\hello-world.lua')
dofile([[C:\MyScripts\hello-world.lua]])
```

So all lines above do the same. In [Lua] you need to specify the path with
slashes, escape backslashes or use double square brackets around the string.
Double square brackets are usefull, because you can copy paste the path
without any modification.

If you upload a mission with this code, you need to create the folder
`C:\MyScripts\` on the server file system and upload the newest version of
`hello-world.lua`, too. The same applies, if you give the mission to a friend.
This makes the mission less portable, but on the other hand the mission uses the
file on the hard disk, without the need to add it to the mission again.
All you need to do is save the file and restart the mission.

The following can be used to increase portability:

```lua
dofile(lfs.writedir() .. '/Missions/hello-world.lua')
```

The function `lfs.writedir()` will return your [Saved Games folder].
So you place the scripts in the subfolder Missions. This way the folder
structure is already available on all target systems. But you need to ensure
mission and script are both in sync to avoid problems. If you changed both and
upload only one of them to your server, you may get trouble.

There is another method you may find useful to dynamically load scripts:

```lua
assert(loadfile('C:/MyScripts/hello-world.lua'))()
assert(loadfile('C:\\MyScripts\\hello-world.lua'))()
assert(loadfile([[C:\MyScripts\hello-world.lua]]))()
```

It is a little bit harder to read and write because of all these different
brackets. Especially the one on line 3. But it is a little safer than `dofile`.
Because of readability I prefer to use `dofile`.

#  Dynamic loading of Moose

Of course you can use the same method to load Moose. This way you can place one
Moose file in your [Saved Games folder], which is used by multiple missions.
If you want to update Moose you just need to replace the file and all missions
will use the new version. But I prefer to add Moose by a `DO SCRIPT FILE`
trigger so I can add and test the new version for each mission step by step.

But we added two different ways to load the Moose source files automatically.
This is useful for Moose developers and it is a requirement to use a debugger.
This will be explained later in the [Debugger Guide].

# Automatic dynamic loading

With the code below you can have the advantages of both approaches.
- Copy the code into your mission script at the beginning.
- Save the mission script into the folder Missions in your [Saved Games folder].
- Change script filename in line 2 to match to your script.
- [De-Sanitize] your `MissionScripting.lua`.

Now the mission will use the script on your hard drive instead of the script
embedded in th MIZ file, as long as it is available. So you can chnge the
script, save it and restart the mission, without the need to readd it after each
change.

If you reach a stable state in your script development and want to upload the
mission to your server or give it to a friend, then just add the script again
like in the static method and save the mission.

{: .important }
> Do not forget to readd the script, prior uploading or sharing the mission,
> or it will run with an outdated version of your script and may fail if the
> objects in the mission don't match to this old version.

```lua
-- Use script file from hard disk instead of the one included in the .miz file
if lfs and io then
  MissionScript = lfs.writedir() .. '/Missions/hello-world-autodyn.lua'
  -- Check if the running skript is from temp directory to avoid an endless loop
  if string.find( debug.getinfo(1).source, lfs.tempdir() ) then
    local f=io.open(MissionScript,"r")
    if f~=nil then
      io.close(f)

      env.info( '*** LOAD MISSION SCRIPT FROM HARD DISK *** ' )
      dofile(MissionScript)
      do return end
    end
  end
else
  env.error( '*** LOAD MISSION SCRIPT FROM HARD DISK FAILED (Desanitize lfs and io)*** ' )
end

--
-- Simple example mission to show the very basics of MOOSE
--
MESSAGE:New( "Hello World! This messages is printed by MOOSE!", 35, "INFO" ):ToAll():ToLog()
```

# IDE vs. Notepad++

As a beginner you should start with a good text editor, which supports syntax
highlighting of [Lua] code. This must not be [Notepad++]. It can be any other
powerful editor of your choice. Do yourself a favor and don't use the Windows
editor.

If you are a developer of [Lua] or another programming language, then your are
most likely familiar with an IDE (Integrated Develop Environment).

Otherwise you should know, that an IDE may help you with code completion,
Refactoring, Autocorrection, Formatting Source Code, showing documentation
as popup on mouse hover over keywords and Debugging.

There are different IDEs available. And not all IDEs support all features.
The three most important for Moose are:

- [Eclipse LDT]
- [Visual Studio Code]
- [PyCharm] (or [IntelliJ IDEA])

Eclipse has the best support for hover documentation and [IntelliSense] with
Moose. The Inventor of Moose (FlightControl) did an amazing job by adding an
integration to Eclipse LDT (a special version for Lua).
Unfortunately Eclipse LDT is not maintained any longer (last release 2018).
And the debugger doesn't work anymore, since an update of DCS.

In Visual Studio Code the support of Lua can be added by an addon.
The debugger works with Moose and DCS, but showing the LuaDoc and [IntelliSense]
is very limited.

PyCharm supports Lua also with an addon. The debugger works with Moose and DCS,
but showing the LuaDoc and [IntelliSense] is very limited.

It is up to you to choose the IDE according to your taste. Guides on how to
setup Moose with different IDEs and Debuggers are provided later in this
documentation.

[Git]: https://en.wikipedia.org/wiki/Git
[GitHub]: https://github.com/
[YouTube]: https://www.youtube.com/
[Moose Discord]: https://discord.gg/gj68fm969S
[overview]: ../index.md
[reposities]: ../repositories.md
[master]: https://github.com/FlightControl-Master/MOOSE/tree/master
[develop]: https://github.com/FlightControl-Master/MOOSE/tree/develop
[GitHub pages]: https://pages.github.com/
[MOOSE_DOCS]: https://flightcontrol-master.github.io/MOOSE_DOCS/
[MOOSE_DOCS_DEVELOP]: https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/
[directory tree]: https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Development/Moose
[Saved Games folder]: ../beginner/tipps-and-tricks.md#find-the-saved-games-folder
[Lua]: https://www.lua.org/
[Create your own Hello world]: ../beginner/hello-world-build.md
[Debugger Guide]: debugger.md
[IntelliSense]: https://en.wikipedia.org/wiki/IntelliSense
[De-Sanitize]: desanitize-dcs.md
[Notepad++]: https://notepad-plus-plus.org/downloads/
[Eclipse LDT]: https://projects.eclipse.org/projects/tools.ldt
[Visual Studio Code]: https://code.visualstudio.com/
[PyCharm]: https://www.jetbrains.com/pycharm/
[IntelliJ IDEA]: https://www.jetbrains.com/idea/
