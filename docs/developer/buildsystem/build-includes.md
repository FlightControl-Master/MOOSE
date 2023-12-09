---
parent: Build system
grand_parent: Developer
nav_order: 1
---

# Build include files

Main build steps to create the include files are defined in [.github/workflows/build-includes.yml]:

- Checkout of the git repository [MOOSE].
- Create output folders.
- Update the Linux system software.
- Install needed tools:
    - [tree] - A tool to output a tree view of a folder structure.
    - [lua5.3] - Package to run [Lua] scripts. Version 5.3 is needed, because we
      need liblua5.3-dev for [LuaSrcDiet].
    - [LuaRocks] - LuaRocks is the package manager for Lua modules.
    - liblua5.3-dev - Header file of [Lua] needed for [LuaSrcDiet] to work.
    - [LuaSrcDiet] - To compress the [Lua] code and create `Moose_.lua`.
    - [LuaCheck] - This is a static code analyzer and a linter for [Lua].

- Run the build steps:
    - Run `./Moose Setup/Moose_Create.lua` to create `Moose.lua`.
    - Run `./Moose Setup/Moose_Create.lua` to create dynamic `Moose.lua` which
      loads individual Lua class files used by Moose developers.
    - Run [LuaSrcDiet] to compress the [Lua] code and create `Moose_.lua`
    - Run [LuaCheck] to find errors in the code. Warnings are ignored, because
      there are a lot of warnings, which cannot be resolved by the Moose team.

- Deploy build results:
    - Checkout [MOOSE_INCLUDE] git repository in a subdirectory.
        - Use the same branch used to checkout [MOOSE] git repository.
        - Use a `TOKEN` for checkout, so a `push` is possible later on.
    - Copy build result to `MOOSE_INCLUDE` folder
    - Push results to [MOOSE_INCLUDE] repository

# Build a preview locally

To generate a preview of the include files go into the folder
`docker/build-includes` and run `docker compose up`. It will create a Docker
image and start a Docker container.
Within this container all needed software packages are included to build the
include files.

- You need a working installation of [Docker].
- In the main repository folder a new folder `build` will be created.
- The following subfolders will be generated:
    - `build/result/Moose_Include_Dynamic` and
    - `build/result/Moose_Include_Static`
- `./Moose Setup/Moose_Create.lua` will be executed to generate the target files
- [LuaSrcDiet] will be executed to generate the target file `Moose_.lua`
- [LuaCheck] runs to find errors

[.github/workflows/build-includes.yml]: https://github.com/FlightControl-Master/MOOSE/blob/master/.github/workflows/build-includes.yml
[tree]: https://wiki.ubuntuusers.de/tree/
[lua5.3]: https://www.lua.org/manual/5.3/
[LuaRocks]: https://luarocks.org/
[LuaCheck]: https://github.com/mpeterv/luacheck
[MOOSE]: https://github.com/FlightControl-Master/MOOSE
[MOOSE_INCLUDE]: https://github.com/FlightControl-Master/MOOSE_INCLUDE
[LuaSrcDiet]: https://github.com/jirutka/luasrcdiet
[Lua]: https://www.lua.org/
[Docker]: https://www.docker.com/
