#include <lua.h>
#include <lauxlib.h>
#include <my_global.h>
#include <mysql.h>
#include <libircclient.h>
#include <iniparser.h>

#include "globals.h"
#include "interface.h"
#include "lua_callback_table.h"

// Lua function: get_config(key)
static int l_get_config(lua_State *L){
	size_t key_len;
	const char* key_str = luaL_checklstring(L, 1, &key_len);
	lua_pushstring(L, iniparser_getstring(C, key_str, ""));
	return 1;
}

// Lua function: register_callback(event, func)
static int l_register_callback(lua_State *L){
	size_t type_len, func_len;
	const char* type_str = luaL_checklstring(L, 1, &type_len);
	const char* func_str = luaL_checklstring(L, 2, &func_len);
	printf("Registering callback '%s' for event '%s'.\n", func_str, type_str);
	cbtable_add(type_str, func_str);
	return 0;
}

// Lua function: irc_join(channel, key)
static int l_irc_join(lua_State *L){
	size_t chan_len = 0, key_len = 0;
	const char* key_str = "";
	const char* chan_str = luaL_checklstring(L, 1, &chan_len);
	if(lua_gettop(L) == 2 && !lua_isnil(L, 2))
		key_str  = luaL_checklstring(L, 2, &key_len);
	printf("Joining channel %s%s%s%s.\n", chan_str, key_len?" with key '":"", key_str, key_len?"'":"");
	irc_cmd_join(I, chan_str, key_len?key_str:0);
	return 0;
}

// Lua function: irc_part(channel)
static int l_irc_part(lua_State *L){
	size_t chan_len = 0;
	const char* chan_str = luaL_checklstring(L, 1, &chan_len);
	printf("Parting channel %s.\n", chan_str);
	irc_cmd_part(I, chan_str);
	return 0;
}

// Lua function: irc_msg(target, message)
static int l_irc_msg(lua_State *L){
	size_t target_len = 0, message_len = 0;
	const char* target_str  = luaL_checklstring(L, 1, &target_len);
	const char* message_str = luaL_checklstring(L, 2, &message_len);
	printf("Sending message to %s: '%s'.\n", target_str, message_str);
	irc_cmd_msg(I, target_str, message_str);
	return 0;
}

// Registers above Lua functions with the Lua state
void register_lua_functions(lua_State* L){
	lua_pushcfunction(L, l_get_config);
	lua_setglobal(L, "get_config");

	lua_pushcfunction(L, l_register_callback);
	lua_setglobal(L, "register_callback");
	
	lua_pushcfunction(L, l_irc_join);
	lua_setglobal(L, "irc_join");
	
	lua_pushcfunction(L, l_irc_part);
	lua_setglobal(L, "irc_part");
	
	lua_pushcfunction(L, l_irc_msg);
	lua_setglobal(L, "irc_msg");
}


