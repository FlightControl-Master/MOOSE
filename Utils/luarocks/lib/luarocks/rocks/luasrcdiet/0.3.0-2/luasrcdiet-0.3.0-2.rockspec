-- vim: set ft=lua:

package = 'LuaSrcDiet'
version = '0.3.0-2'

			source = { url = 'https://github.com/jirutka/luasrcdiet/archive/v0.3.0/luasrcdiet-0.3.0.tar.gz', md5 = 'c0ff36ef66cd0568c96bc54e9253a8fa' }

description = {
  summary = 'Compresses Lua source code by removing unnecessary characters',
  detailed = [[
This is revival of LuaSrcDiet originally written by Kein-Hong Man.]],
  homepage = 'https://github.com/jirutka/luasrcdiet',
  maintainer = 'Jakub Jirutka <jakub@jirutka.cz>',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
}

build = {
  type = 'builtin',
  modules = {
    ['luasrcdiet'] = 'luasrcdiet/init.lua',
    ['luasrcdiet.equiv'] = 'luasrcdiet/equiv.lua',
    ['luasrcdiet.fs'] = 'luasrcdiet/fs.lua',
    ['luasrcdiet.llex'] = 'luasrcdiet/llex.lua',
    ['luasrcdiet.lparser'] = 'luasrcdiet/lparser.lua',
    ['luasrcdiet.optlex'] = 'luasrcdiet/optlex.lua',
    ['luasrcdiet.optparser'] = 'luasrcdiet/optparser.lua',
    ['luasrcdiet.plugin.example'] = 'luasrcdiet/plugin/example.lua',
    ['luasrcdiet.plugin.html'] = 'luasrcdiet/plugin/html.lua',
    ['luasrcdiet.plugin.sloc'] = 'luasrcdiet/plugin/sloc.lua',
    ['luasrcdiet.utils'] = 'luasrcdiet/utils.lua',
  },
  install = {
    bin = {
      luasrcdiet = 'bin/luasrcdiet',
    }
  }
}
