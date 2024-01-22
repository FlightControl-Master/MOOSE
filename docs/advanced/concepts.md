---
title: Concepts
parent: Advanced
nav_order: 01
---

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
For non developers the page can be confusing. Take your time and read this
documentation. We are not able to explain every single detail on using [GitHub]
and [Git]. Especially because it is changing really quick and this documentaion
will not. So try to use the help system of [GitHub] or find some videos on
[YouTube]. If you get stuck ask for help in the [Moose Discord].

Moose uses more then one repository on [GitHub] which doesn't exactly make it
any clearer. A list can be found on the [reposities] page.

# Branches: master & develop

As already explained in the [overview] two branches are used:

- [master]: Stable release branch.
- [develop]: Newest development with more OPS classes.

As a starter it is okay to begin your journey with the `master` branch.
If you are interested in some newer classes you need to use the `develop`
branch. The later one is also very stable, but it's missing more detailed
documentation and example missions for some of the new OPS classes.

You can switch between these branches with a drop down in the upper left corner
of th [GitHub] repository page. The list of branches is long. So it is a best
practise to save a bookmark in your browser with the links above.
Both branches are available on most of the different repositories. But because
of a limitation of [GitHub pages], we had to split the documentation in two
different repositories:

- Documentation of `master` branch: [MOOSE_DOCS]
- Documentation of `develop` branch: [MOOSE_DOCS_DEVELOP]

# Build result vs. source files

Moose consists of more than 140 individual files with the file extension `.lua`.
They are places in a [directory tree], which makes it more organized and its
semantic is pre-defined for IntelliSense to work.

On every change which is pushed to [GitHub] a build job will combine all of
these files to a single file called `Moose.lua`. In a second step all
comments will be removed to decrease the file size and the result will be saved
as `Moose_.lua`. These both files are created for users of Moose to include in
your missions.

The individual `.lua` files are used by the Mosse developers and power users.
It is complicated to use them, but in combination with an IDE and a debugger it
is very usefull to analyse even complex problems or write new additions to the
Moose framework.

# Static loading vs. dynamic loading

If you add a script file with a `DO SCRIPT FILE` trigger, like we described in
[Create your own Hello world], the script file will be copied into the mission
file. This mission file (file extension .MIZ) is only a compressed ZIP archive
with another file ending.

If you change the script file after adding it to the mission, the changes are
not available on mission start. You have to re-add the script after each change.
This can be very annoying and often leads to forgetting to add the change again.
Then you wonder why the script does not deliver the desired result.

But when the mission is finished you can upload it to your dedicated DCS server
or give it to a friend and it should run without problems. This way of embedding
the scripts do we call `static loading` and the resulting mission is very
portable.

The other way on loading scripts is by using `DO SCRIPT`. This time the mission
editor don't show a file browse button. Instead you see a (very small) text
field to enter the code directly into it. It is only usefull for very small
script snippets. But we can use it to load a file from our hard drive like this:

```lua
aaa
```

# IDE vs. Notepad++

# What is a debugger (good for)

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
