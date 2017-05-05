rocks_trees = {
    home..[[/luarocks]],
    { name = [[user]],
         root    = home..[[/luarocks]],
    },
    { name = [[system]],
         root    = [[C:/Users/Hugues/Documents/GitHub/MOOSE/Utils/luarocks\systree]],
    },
}
variables = {
    MSVCRT = 'MSVCR80',
    LUALIB = 'lua5.1.lib'
}
verbose = false   -- set to 'true' to enable verbose output
