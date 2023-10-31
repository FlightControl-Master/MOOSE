---
parent: Build system
nav_order: 2
---

# Build class documentation

The documentation of all classes are included in the code as comments.
This kind of documentation process is called [LuaDoc]. But we build the
html files for the documentation with [LuaDocumentor]. It is a tool
similar to [LuaDoc], but with some additional features the Moose team
decided to use.

{: .important }
> The team created also some modifications, which are not part of the
> official [LuaDocumentor] tool. So we use the code in the git repository
> [Applevangelist/luadocumentor] in the branch `patch-1`.

There are two git repositories which are used to save the generated
documentation:

- [MOOSE_DOCS] is the repository for the `master` branch of [MOOSE]
  - A configured GitHub Pages job will deploy the result to:<br/>
    <https://flightcontrol-master.github.io/MOOSE_DOCS/>
- [MOOSE_DOCS_DEVELOP] is the repository for the `develop` branch of [MOOSE]
  - A configured GitHub Pages job will deploy the result to:<br/>
    <https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/>

Main build steps to create the class documentation are defined in [.github/workflows/build-docs.yml]:

- Checkout of the git repository [MOOSE].
- Create output folders.
- Checkout of the git repository [Applevangelist/luadocumentor] with
  branch `patch-1` into a subdirectory.
- Update the Linux system software.
- Install needed tools:
    - [tree] - A tool to output a tree view of a folder structure.
    - [lua] - Package to run [Lua] scripts. This time [Lua] 5.1,
      because it matches the DCS environment.
    - [LuaRocks] - This is the package manager for Lua modules.
    - [markdown] - Dependency for [LuaDocumentor]
    - [penlight] - Dependency for [LuaDocumentor]
    - [metalua-compiler] - Dependency for [LuaDocumentor]
    - [metalua-parser] - Dependency for [metalua-compiler]
    - [checks] - Dependency for [metalua-parser]

- Run the build steps:
    - Run `luadocumentor.lua` to create the html files.

- Deploy build results:
    - Checkout [MOOSE_DOCS] or [MOOSE_DOCS_DEVELOP] git repository in a subdirectory.
        - Use the matching git repository for the branch of [MOOSE].
            - `master` -> [MOOSE_DOCS].
            - `develop` -> [MOOSE_DOCS_DEVELOP].
        - Use a `TOKEN` for checkout, so a `push` is possible later on.
    - Copy build result to `MOOSE_DOCS` folder.
    - Push results to the target repository.

[tree]: https://wiki.ubuntuusers.de/tree/
[LuaDoc]: https://keplerproject.github.io/luadoc/
[LuaDocumentor]: https://luarocks.org/modules/luarocks/luadocumentor
[Applevangelist/luadocumentor]: https://github.com/Applevangelist/luadocumentor/tree/patch-1
[markdown]: https://luarocks.org/modules/mpeterv/markdown
[penlight]: https://luarocks.org/modules/tieske/penlight
[metalua-compiler]: https://luarocks.org/modules/luarocks/metalua-compiler
[metalua-parser]: https://luarocks.org/modules/luarocks/metalua-parser
[checks]: https://luarocks.org/modules/fab13n/checks
[MOOSE]: https://github.com/FlightControl-Master/MOOSE
[MOOSE_DOCS]: https://github.com/FlightControl-Master/MOOSE_DOCS
[MOOSE_DOCS_DEVELOP]: https://github.com/FlightControl-Master/MOOSE_DOCS_DEVELOP
[Lua]: https://www.lua.org/
[LuaRocks]: https://luarocks.org/
[.github/workflows/build-docs.yml]: https://github.com/FlightControl-Master/MOOSE/blob/master/.github/workflows/build-docs.yml
