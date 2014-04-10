denice
======

Jakncoke has defeated me in my ass with a carton of milk for 2.30. Fucking ripoffs lol.


libraries
======

Denice (core) requires:
* libiniparser 3.1
* libircclient 1.7 **compiled with SSL support**
* libmysqlclient
* liblua **5.2**

Additionally, the scripts require some Lua modules:
* luasocket 3.0 rc1
* luaxml
* luajson (also depends on lpeg)

The you can probably find the MySQL and Lua stuff in your package manager, but for the other crap
just drop them in ./libs and make them in there, and our makefile should find them. You
must update the paths in the Makefile for the core dependencies, and add the install directories of the
module dependencies to the Lua path if they aren't in it already. Check the use of add_lib_dir in main.lua
for details.

Dependency links (if you don't know how to google):
* iniparser: http://ndevilla.free.fr/iniparser/
* ircclient: http://sourceforge.net/projects/libircclient/
* luasocket: https://github.com/diegonehab/luasocket
* luaxml: http://viremo.eludi.net/LuaXML/
* luajson: http://luaforge.net/projects/luajson/
* lpeg: http://www.inf.puc-rio.br/~roberto/lpeg/

Some things that are helpful and you might want to do:
* Patch libircclient to use a larger send buffer (recommend ~4KB, rather than the 1KB default)
* Patch libircclient to allow read operations to timeoout, so the bot can detect when it is disconnected

Running the bot:
* Import tables.sql into your database
* Edit conf.ini (or whatever you want to call it)
* ./denice conf.ini
