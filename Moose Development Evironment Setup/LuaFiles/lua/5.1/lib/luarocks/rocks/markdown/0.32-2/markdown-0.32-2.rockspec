package = "Markdown"
version = "0.32-2"
source = {
   url = "http://www.frykholm.se/files/markdown-0.32.tar.gz",
   dir = "."
}
description = {
   summary = "Markdown text-to-html markup system.",
   detailed = [[
      A pure-lua implementation of the Markdown text-to-html markup system.
   ]],
   license = "MIT",
   homepage = "http://www.frykholm.se/files/markdown.lua"
}
dependencies = {
   "lua >= 5.1",
}
build = {
   type = "none",
   install = {
      lua = { "markdown.lua" },
   }
}
