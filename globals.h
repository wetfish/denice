#ifndef globals_h
#define globals_h

#include <lua.h>
#include <mysql.h>
#include <libircclient.h>
#include <iniparser.h>

// global state pointers for irc, lua, sql, config
irc_session_t* I;
lua_State* L;
MYSQL *S;
dictionary *C;

// remember our config file
char* conf_file;

#endif
