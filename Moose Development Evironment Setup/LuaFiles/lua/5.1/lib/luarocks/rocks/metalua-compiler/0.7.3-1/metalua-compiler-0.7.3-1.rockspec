--*-lua-*--
package = "metalua-compiler"
version = "0.7.3-1"
source = {
  url = "http://git.eclipse.org/c/koneki/org.eclipse.koneki.metalua.git/snapshot/org.eclipse.koneki.metalua-v0.7.3.tar.gz"
}

description = {
  summary = "Metalua's compiler: converting (Meta)lua source strings and files into executable Lua 5.1 bytecode",
  detailed = [[
    This is the Metalua copmiler, packaged as a rock, depending
    on the spearate metalua-parser AST generating library. It
    compiles a superset of Lua 5.1 into bytecode, which can
    then be loaded and executed by a Lua 5.1 VM. It also allows
    to dump ASTs back into Lua source files.
  ]],
  homepage = "http://git.eclipse.org/c/koneki/org.eclipse.koneki.metalua.git",
  license = "EPL + MIT"
}
dependencies = {
  "lua ~> 5.1",              -- Lua 5.2 bytecode not supported
  "luafilesystem ~> 1.6",    -- Cached compilation based on file timestamps
  "metalua-parser >= 0.7.3", -- AST production
}

build = {
  type="builtin",
  modules={
    ["metalua.compiler.bytecode"] = "metalua/compiler/bytecode.lua",
    ["metalua.compiler.globals"] = "metalua/compiler/globals.lua",
    ["metalua.compiler.bytecode.compile"] = "metalua/compiler/bytecode/compile.lua",
    ["metalua.compiler.bytecode.lcode"] = "metalua/compiler/bytecode/lcode.lua",
    ["metalua.compiler.bytecode.lopcodes"] = "metalua/compiler/bytecode/lopcodes.lua",
    ["metalua.compiler.bytecode.ldump"] = "metalua/compiler/bytecode/ldump.lua",
    ["metalua.loader"] = "metalua/loader.lua",
  },
  install={
    lua={
      ["metalua.treequery"] = "metalua/treequery.mlua",
      ["metalua.compiler.ast_to_src"] = "metalua/compiler/ast_to_src.mlua",
      ["metalua.treequery.walk"] = "metalua/treequery/walk.mlua",
      ["metalua.extension.match"] = "metalua/extension/match.mlua",
      ["metalua.extension.comprehension"] = "metalua/extension/comprehension.mlua",
      ["metalua.repl"] = "metalua/repl.mlua",
    }
  }
}
