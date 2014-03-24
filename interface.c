#include <lua.h>
#include <lauxlib.h>

#include "globals.h"
#include "interface.h"
#include "lua_callback_table.h"

// Lua function: register_callback(event, func)
static int l_register_callback(lua_State *L){
	size_t type_len, func_len;
	const char* type_str = luaL_checklstring(L, 1, &type_len);
	const char* func_str = luaL_checklstring(L, 2, &func_len);
	printf("registering callback '%s' for event '%s'\n", func_str, type_str);
	cbtable_add(type_str, func_str);
	return 0;
}

// Registers above Lua functions with the Lua state
void register_lua_functions(lua_State* L){
	lua_pushcfunction(L, l_register_callback);
	lua_setglobal(L, "register_callback");
}
