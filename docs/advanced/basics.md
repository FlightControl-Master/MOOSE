---
title: Basics
parent: Advanced
nav_order: 01
---

If you want to get deeper into Moose, you will encounter a few terms and
concepts that we will explain here. You will need them for the later pages.

# Git and GitHub

Moose has about 260.000 lines of code and the amount is increasing each week.
To maintain such a big code base a vcs (version control system) is needed.
Moose uses [Git], a distributed source code management created 2005 by Linus
Torvalds for the development of the Linux kernel.

As developer platform [GitHub] was choosen as a central place for Moose
to create, store, and manage the code. [GitHub] use [Git] for version control
and provides additional functionality like access control, bug tracking, feature
requests and much more.

As a Moose you don't need to learn to use [Git]. You can download the files on
[GitHub] with a browser. But using [Git] will ease up the steps to keep the
Moose version on your hard disk up to date.

You will need to interact with [GitHub]. At least to download the Moose files.
For non developers the page can be confusing. Take your time and read this
documentation. We are not able to explain every single detail on using [GitHub]
and [Git]. Especially because it is changing really quick and this documentaion
will not. So try to uns the help system of [GitHub] or find some videos on
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
documentation and example missions.

You can switch between these branches with a drop down in the upper left corner
of th GitHub repository page. The list of branches is long. So it is a best
practise to save a bookmark in your browser with the links above.

# Build result vs. source files

Moose consists of more than 140 individual files with the file extension `.lua`.
They are places in a directory tree, which makes it more organized and its
semantic is pre-defined for IntelliSense to work.

On every change which is pushed to [GitHub] a build job will combine all of
these files to a the single file called `Moose.lua`. In a seconds step all
comments will be removed to decrease the file size and the result will be saved
as `Moose_.lua`. These both files are created for users of Moose to include in
your missions.

The individual `.lua` files are used by the Mosse developers and power users.
It is complicated to use them, but in combination with an IDE and a debugger it
is very usefull to analyse even complex problems or write new additions to the
Moose framework.

# Static loading vs. dynamic loading

# IDE vs. Notepad++

# What is a debugger (good for)

[Git]: https://en.wikipedia.org/wiki/Git
[Moose Discord]: https://discord.gg/gj68fm969S
[overview]: ../index.md
[reposities]: ../repositories.md
[master]: https://github.com/FlightControl-Master/MOOSE/tree/master
[develop]: https://github.com/FlightControl-Master/MOOSE/tree/develop
