#ifndef globals_h
#define globals_h

#include <lua.h>
#include <mysql.h>
#include <libircclient.h>

// global state pointers for irc, lua, and sql
irc_session_t* I;
lua_State* L;
MYSQL *S;

#endif
