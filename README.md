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
* json4lua

The you can probably find the MySQL and Lua stuff in your package manager, but for the other crap
just drop them in ./libs and make them in there, and our makefile should find them

If you don't know how to google:
*  iniparser: http://ndevilla.free.fr/iniparser/
*  ircclient: http://sourceforge.net/projects/libircclient/
