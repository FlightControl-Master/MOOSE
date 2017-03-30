--*-lua-*-
package = "checks"
version = "1.0-1"
source = {
    url = "https://github.com/fab13n/checks/raw/master/checks-1.0-1.tar.gz",
    dir = "checks",
}

description = {
    summary = "Easy, terse, readable and fast function arguments type checking",
    detailed = [[
            This library declares a `checks()` function and a
            `checkers` table, which allow to check the parameters
            passed to a Lua function in a fast and unobtrusive way.

            Althought provided here as a standalone library, it is
            part of Sierra Wireless' Aleos Applicaion Framework,
            available under the Eclipse Public License, currently at:

                https://github.com/SierraWireless/luasched

   ]],
   homepage = "https://github.com/SierraWireless/luasched",
   license = "Eclipse public license"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = 'builtin',
    modules = {
        checks = 'checks.c'
    }
}
