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

void irc_error(irc_session_t* irc_session){
	int err = irc_errno(irc_session);
	const char* errstr = irc_strerror(err);
	error(1, "irc error: %s (%d)\n", errstr, err);
}

int main(int argc, char** argv){
	irc_session_t* irc_session;
	irc_callbacks_t irc_callbacks;
	dictionary *config;
	char* host_str;
	int host_len, ssl;
	
	if(argc != 2)
		error(1, "Error: config file must be specified on comand line\n");
	
	config = iniparser_load(argv[1]);
	//iniparser_dump(config, stdout);
	ssl = iniparser_getboolean(config, "server:ssl", 0);
	host_len = strlen(iniparser_getstring(config, "server:host", "")) + (ssl ? 1 : 0);
	host_str = malloc(host_len + 1);
	host_str[0] = '#';
	host_str[host_len] = '\0';
	strcpy(&host_str[ssl ? 1 : 0], iniparser_getstring(config, "server:host", ""));
	
	
	// init local data structures
	mem_init();
	cbtable_init();
		
	// init mysql
	S = mysql_init(NULL);
	if(mysql_real_connect(S,
	      iniparser_getstring(config, "mysql:host", "localhost"),
	      iniparser_getstring(config, "mysql:user", "root"),
	      iniparser_getstring(config, "mysql:pass", ""),
	      iniparser_getstring(config, "mysql:database", ""),
	      iniparser_getint(config, "mysql:port", 0), 0, 0) == NULL) 
	    error(1, "Unable to connect to mysql: %s\n", mysql_error(S));
	
	// init lua
	L = lua_open();
	luaopen_base(L);
	luaopen_table(L);
	luaopen_io(L);
	luaopen_string(L);
	luaopen_math(L);
	register_lua_functions();
	lua_dofile(L, iniparser_getstring(config,"bot:file","/dev/null"));

	// init libircclient
	memset(&irc_callbacks, 0, sizeof(irc_callbacks));
	irc_callbacks.event_connect = event_generic;
	irc_callbacks.event_nick    = event_generic;
	irc_callbacks.event_quit    = event_generic;
	irc_callbacks.event_join    = event_generic;
	irc_callbacks.event_part    = event_generic;
	irc_callbacks.event_part    = event_generic;
	irc_callbacks.event_mode    = event_generic;
	irc_callbacks.event_umode   = event_generic;
	irc_callbacks.event_topic   = event_generic;
	irc_callbacks.event_kick    = event_generic;
	irc_callbacks.event_channel = event_generic;
	irc_callbacks.event_privmsg = event_generic;
	irc_callbacks.event_notice  = event_generic;
	irc_callbacks.event_unknown = event_generic;
	irc_callbacks.event_invite  = event_generic;
	irc_callbacks.event_ctcp_req = event_generic;
	irc_callbacks.event_ctcp_rep = event_generic;
	irc_callbacks.event_ctcp_action = event_generic;
	irc_callbacks.event_channel_notice = event_generic;
	irc_callbacks.event_numeric = event_numeric;
	irc_session = irc_create_session(&irc_callbacks);
	irc_option_set(irc_session, LIBIRC_OPTION_STRIPNICKS);
	irc_option_set(irc_session, LIBIRC_OPTION_SSL_NO_VERIFY);
	irc_option_set(irc_session, LIBIRC_OPTION_DEBUG);
	
	if(!irc_session)
		error(1, "Unable to create IRC session... probably out of memory\n");
	
	// set up irc server connection
	if(irc_connect(irc_session,
				   host_str,
				   iniparser_getint(config,"server:port",6667), 0,
				   iniparser_getstring(config,"bot:nick","bot"),
				   iniparser_getstring(config,"bot:user","bot"),
				   "libircclient"
				  ))
		irc_error(irc_session);
	
	// not sure why we need to sleep here, but if we don't, we can't connect
	sleep(1);
	
	// run the irc client loop
	if(irc_run(irc_session))
		irc_error(irc_session);
	
	// clean up
	irc_destroy_session(irc_session);
	lua_close(L);
	cbtable_destroy();
	iniparser_freedict(config);
	free(host_str);
	return EXIT_SUCCESS;
}
