@echo on
"%~dp0luarocks/lua5.1.exe" -e "package.path=\"%~dp0luarocks/share/lua/5.1/?.lua;%~dp0luarocks/share/lua/5.1/?/init.lua;\"..package.path; package.cpath=\"%~dp0luarocks/lib/lua/5.1/?.dll;%~dp0luarocks/systree/lib/lua/5.1/?.dll;\"..package.cpath" -e "local k,l,_=pcall(require,\"luarocks.loader\") _=k and l.add_context(\"luasrcdiet\",\"0.3.0-2\")" "%~dp0luarocks/luasrcdiet/0.3.0-2/bin/luasrcdiet" %*

