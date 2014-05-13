// Standard includes
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

// Lua includes
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// Libircclient includes
#include <libircclient.h>
#include <libirc_rfcnumeric.h>

// Iniparser includes
#include <iniparser.h>

// Mysql includes
#include <my_global.h>
#include <mysql.h>

// Project includes
#include "globals.h"
#include "error.h"
#include "mem.h"
#include "lua_callback_table.h"
#include "callbacks.h"
#include "interface.h"

// Main function
int main(int argc, char** argv){
	irc_callbacks_t irc_callbacks;
	char* host_str;
	int host_len, ssl;
	I = 0;
	
	if(argc != 2)
		error(1, "Error: config file must be specified on comand line\n");
	
	// load config from ini
	conf_file = argv[1];
	C = iniparser_load(conf_file);
	
	// parse server config and generate a string to give to libircclient
	ssl = iniparser_getboolean(C, "server:ssl", 0);
	host_len = strlen(iniparser_getstring(C, "server:host", "")) + (ssl ? 1 : 0);
	host_str = malloc(host_len + 1);
	host_str[0] = '#';
	host_str[host_len] = '\0';
	strcpy(&host_str[ssl ? 1 : 0], iniparser_getstring(C, "server:host", ""));
	
	// init local data structures
	mem_init();
	cbtable_init();
		
	// init mysql
	S = mysql_init(NULL);
	if(mysql_real_connect(S,
	      iniparser_getstring(C, "mysql:host", "localhost"),
	      iniparser_getstring(C, "mysql:user", "root"),
	      iniparser_getstring(C, "mysql:pass", ""),
	      iniparser_getstring(C, "mysql:database", ""),
	      iniparser_getint(C, "mysql:port", 0), 0, 0) == NULL) 
	    error(1, "Unable to connect to mysql: %s\n", mysql_error(S));
	
	// init lua
	L = luaL_newstate();
	luaL_openlibs(L);
	register_lua_functions();
	if(luaL_dofile(L, iniparser_getstring(C,"bot:file","/dev/null"))){
		size_t lua_errlen = 0;
		const char* lua_error = luaL_checklstring(L, -1, &lua_errlen);
		error(1, "Error processing Lua script:\n%s\n", lua_error);
	}

	// init libircclient
	memset(&irc_callbacks, 0, sizeof(irc_callbacks));
	irc_callbacks.event_connect = event_generic;
	irc_callbacks.event_nick    = event_generic;
	irc_callbacks.event_quit    = event_generic;
	irc_callbacks.event_join    = event_generic;
	irc_callbacks.event_part    = event_generic;
	irc_callbacks.event_mode    = event_generic;
	irc_callbacks.event_umode   = event_generic;
	irc_callbacks.event_topic   = event_generic;
	irc_callbacks.event_kick    = event_generic;
	irc_callbacks.event_channel = event_command;
	irc_callbacks.event_privmsg = event_command;
	irc_callbacks.event_notice  = event_generic;
	irc_callbacks.event_unknown = event_generic;
	irc_callbacks.event_invite  = event_generic;
	irc_callbacks.event_ctcp_req = event_generic;
	irc_callbacks.event_ctcp_rep = event_generic;
	irc_callbacks.event_ctcp_action = event_generic;
	irc_callbacks.event_channel_notice = event_generic;
	irc_callbacks.event_numeric = event_numeric;
	do_quit = 0;

	while(!do_quit){
		if(I) irc_destroy_session(I);

		I = irc_create_session(&irc_callbacks);
		if(!I)
			error(1, "Unable to create IRC session... probably out of memory\n");
		irc_option_set(I, LIBIRC_OPTION_STRIPNICKS);
		irc_option_set(I, LIBIRC_OPTION_SSL_NO_VERIFY);
		irc_option_set(I, LIBIRC_OPTION_DEBUG);
		
		// initialize irc server connection
		if(irc_connect(I,
				   host_str,
				   iniparser_getint(C,"server:port",6667), 0,
				   iniparser_getstring(C,"bot:nick","bot"),
				   iniparser_getstring(C,"bot:user","bot"),
				   "libircclient"
				  ))
			irc_error(I,1);
	
		// not sure why we need to sleep here, but if we don't, we can't connect
		sleep(1);
	
		// run the irc client loop
		if(irc_run(I))
		irc_error(I,0);
	}
	
	// clean up
	mysql_close(S);
	irc_destroy_session(I);
	lua_close(L);
	cbtable_destroy();
	iniparser_freedict(C);
	free(host_str);
	return EXIT_SUCCESS;
}
