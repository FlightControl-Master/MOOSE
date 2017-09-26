package = 'LuaDocumentor'
version = '0.1.5-1'
description = {
  summary = 'LuaDocumentor allow users to generate HTML and API files from code documented using Lua documentation language.',
  detailed = [[
    This is an example for the LuaRocks tutorial.
    Here we would put a detailed, typically
    paragraph-long description.
  ]],
  homepage = 'http://wiki.eclipse.org/Koneki/LDT/User_Area/LuaDocumentor',
  license = 'EPL'
}
source = {
  url = 'git://github.com/LuaDevelopmentTools/luadocumentor.git',
  tag = 'v0.1.5-1'
}
dependencies = {
  'lua ~> 5.1',
  'luafilesystem ~> 1.6',
  'markdown ~> 0.32',
  'metalua-compiler ~> 0.7',
  'penlight ~> 0.9'
}
build = {
  type = 'builtin',
  install = {
    bin = {
      luadocumentor = 'luadocumentor.lua'
    },
    lua = {
      ['models.internalmodelbuilder'] = 'models/internalmodelbuilder.mlua'
    }
  },
  modules = {
    defaultcss = 'defaultcss.lua',
    docgenerator = 'docgenerator.lua',
    extractors = 'extractors.lua',
    lddextractor = 'lddextractor.lua',
    templateengine = 'templateengine.lua',

    ['fs.lfs'] = 'fs/lfs.lua',

    ['models.apimodel'] = 'models/apimodel.lua',
    ['models.apimodelbuilder'] = 'models/apimodelbuilder.lua',
    ['models.internalmodel'] = 'models/internalmodel.lua',
    ['models.ldparser'] = 'models/ldparser.lua',

    ['template.file'] = 'template/file.lua',
    ['template.index'] = 'template/index.lua',
    ['template.index.recordtypedef'] = 'template/index/recordtypedef.lua',
    ['template.item'] = 'template/item.lua',
    ['template.page'] = 'template/page.lua',
    ['template.recordtypedef'] = 'template/recordtypedef.lua',
    ['template.usage'] = 'template/usage.lua',
    ['template.utils'] = 'template/utils.lua',
  }
}
