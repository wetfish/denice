#include <stdio.h>
#include <ctype.h>
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
		    // catch ERROR events so we don't make an infinite loop
			if(strcmp(event, "ERROR")){
				error(0, "Attempt to invoke Lua '%s' callback failed:\n%s\n", func->func ,lua_tostring(L, -1));
			}
			else{
				fprintf(stderr, "Error calling error callback!\n%s\n", lua_tostring(L,-1));
			}
		}
	}
}

// Callback for !commands
void event_command(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count){
	CBENTRY* func;
	int i, called = 0;
	char *tmp, *end, *cmd, *parms;

	tmp = malloc(strlen(params[1]) + 1);
	strcpy(tmp, params[1]);

	end = tmp + strlen(tmp);

	// use generic callback if first char isn't !
	if(*tmp != '!'){
		event_generic(session, event, origin, params, count);
		return;
	}

	// split into 'command' and 'params' parts
	for(parms = tmp; parms < end && *parms!=' '; parms++);
	*(parms++) = '\0';

	cmd = malloc(strlen(tmp) + 1);
	for(i = 0; i < strlen(tmp); i++)
		cmd[i] = tolower(tmp[i]);
	cmd[i] = '\0';

	free(tmp);

        printf("Received '%s' command, params '%s'.\n", cmd, parms);

        for(func = cbtable_next(cmd, 0); func; func = cbtable_next(cmd, func)){
                int j;
                printf(" -> Sending to callback '%s'...\n", func->func);
                lua_getglobal(L, func->func);
                lua_pushstring(L, cmd);
                lua_pushstring(L, origin);
                lua_newtable(L);
                for(j = 0; j < count; j++){
                        lua_pushnumber(L, j+1);
			if(j == 1)
				lua_pushstring(L, parms);
			else
	                        lua_pushstring(L, params[j]);
                        lua_settable(L, -3);
                }
                if(lua_pcall(L, 3, 0, 0) != 0){
                    // catch ERROR events so we don't make an infinite loop
                        if(strcmp(event, "ERROR")){
                                error(0, "Attempt to invoke Lua '%s' callback failed:\n%s\n", func->func ,lua_tostring(L, -1));
                        }
                        else{
                                fprintf(stderr, "Error calling error callback!\n%s\n", lua_tostring(L,-1));
                        }
                }
		called++;
        }
	
	// legacy support
	if(called < 1)
		event_generic(session, event, origin, params, count);

}

// Callback for numeric events, just translates the numeric event code to a string and gives it to event_generic
void event_numeric(irc_session_t *session, unsigned int event, const char *origin, const char **params, unsigned int count){
	char str[16];
	sprintf(str, "%d", event);
	event_generic(session, str, origin, params, count);
}
