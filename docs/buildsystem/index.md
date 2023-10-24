---
has_children: true
nav_order: 3
---

# Build system

{: .note }
> This documentation is not needed for end users. Only the people of the
> development team, who must maintain the build system need to read this.

In this document we want to describe our build system for MOOSE.
MOOSE consists of multiple [Lua] files. Each class is stored in its own file.
This is needed for MOOSE developers to maintain clarity.
For users this is not practical, because they want to include the whole framework
as a single file into their missions.

Because of this the build will collect all needed files and merge them together
in one file with the name `Moose.lua`. It includes also all comments and the
class documentation. Because of this its size is about 6-7 MB.

To reduce the size of the file and make mission files smaller, the Moose team
decided to create a version without all comments and documentation. This file
is named `Moose_.lua`. It is created by a tool with the name [LuaSrcDiet].

Both files will be called static includes. In other programming languages includes
are dependencies. For Moose it is easier to memorize, that these files must be
included in your mission to use Moose. It is an static approach because you need
to add it once and it is only read from inside of the mission file after that.
A dynamic approach is to load all the single class files on each mission start
from the hard disk. But this is more for advanced Moose users and Moose developers.

## Details

In the past [AppVeyor] was used to run the build on a Windows system.
We decided to migrate this build to [GitHub Actions]. Installation of
dependencies was not stable on Windows with [GitHub Actions]. So we switched
to Ubuntu Linux.

### GitHub Actions yml files

The build configuration is stored in the folder `.github/workflows`. You will find
multiple files in this directory:

- [build-docs.yml] - Job definition to generate the class documentation
- [build-includes.yml] - Job definition to build the static includes
- [gh-pages.yml] - Job to build this documentation page

We decided to use different files for each job for separation of duties and easier
maintenance.

[Lua]: https://www.lua.org/
[LuaSrcDiet]: https://github.com/jirutka/luasrcdiet
[AppVeyor]: https://www.appveyor.com/
[GitHub Actions]: https://docs.github.com/en/actions
[build-docs.yml]: build-docs.md
[build-includes.yml]: build-includes.md
[gh-pages.yml]: gh-pages.md
