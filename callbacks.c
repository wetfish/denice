#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>

#include "globals.h"
#include "error.h"
#include "callbacks.h"
#include "lua_callback_table.h"

// Generic libircclient callback function, passes events to registered Lua callbacks
void event_generic(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count){
	CBENTRY* func;
	printf("Received '%s' event.\n", event);
	for(func = cbtable_next(event, 0); func; func = cbtable_next(event, func)){
		int j;
		printf(" -> Sending to callback '%s'...\n", func->func);
		lua_getglobal(L, func->func);
		lua_pushstring(L, event);
		lua_pushstring(L, origin);
		lua_newtable(L);
		for(j = 0; j < count; j++){
			lua_pushnumber(L, j+1);
			lua_pushstring(L, params[j]);
			lua_settable(L, -3);
		}
		if(lua_pcall(L, 3, 0, 0) != 0){
			if(strcmp(event, "ERROR")){
				error(0, "Attempt to invoke Lua callback failed:\n%s\n", lua_tostring(L, -1));
			}
			else{
				fprintf(stderr, "Error calling error callback!\n%s\n", lua_tostring(L,-1));
			}
		}
	}
}

// Callback for numeric events, just translates the numeric event code to a string and gives it to event_generic
void event_numeric(irc_session_t *session, unsigned int event, const char *origin, const char **params, unsigned int count){
	char str[16];
	sprintf(str, "%d", event);
	event_generic(session, str, origin, params, count);
}
