#include <lua.h>
#include <lauxlib.h>
#include <my_global.h>
#include <mysql.h>
#include <libircclient.h>
#include <iniparser.h>
#include <stdint.h>

#include "globals.h"
#include "interface.h"
#include "lua_callback_table.h"

/* BOT ADMIN SECTION */

// Lua function: rehash()
static int l_rehash(lua_State *L){
	// clear hash table and reload main script
	printf("Clearing callback table and reloading scripts...\n");
	cbtable_clear();
	lua_dofile(L, iniparser_getstring(C,"bot:file","/dev/null"));
	return 0;
}

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


/* IRC COMMAND SECTION */

// Lua function: irc_join(channel, key) or irc_join(channel)
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

// Lua function: irc_action(target, message)
static int l_irc_action(lua_State *L){
	size_t target_len = 0, message_len = 0;
	const char* target_str  = luaL_checklstring(L, 1, &target_len);
	const char* message_str = luaL_checklstring(L, 2, &message_len);
	printf("Sending CTCP ACTION to %s: '%s'.\n", target_str, message_str);
	irc_cmd_me(I, target_str, message_str);
	return 0;
}

// Lua function: irc_invite(nick, channel)
static int l_irc_invite(lua_State *L){
	size_t nick_len = 0, chan_len = 0;
	const char* nick_str = luaL_checklstring(L, 1, &nick_len);
	const char* chan_str = luaL_checklstring(L, 2, &chan_len);
	printf("Inviting %s to %s.\n", nick_str, chan_str);
	irc_cmd_invite(I, nick_str, chan_str);
	return 0;
}

// Lua function: irc_names(channel)
static int l_irc_names(lua_State *L){
	size_t chan_len = 0;
	const char* chan_str = luaL_checklstring(L, 1, &chan_len);
	printf("Querying for users on %s.\n", chan_str);
	irc_cmd_names(I, chan_str);
	return 0;
}

// Lua function: irc_list(channel) or irc_list()
static int l_irc_list(lua_State *L){
	size_t chan_len = 0;
	const char* chan_str = "";
	if(lua_gettop(L) == 1 && !lua_isnil(L, 1))
		chan_str = luaL_checklstring(L, 1, &chan_len);
	printf("Listing channels%s%s%s.\n", chan_len?" matching pattern '":"", chan_str, chan_len?"'":"");
	irc_cmd_list(I, chan_len?chan_str:0);
	return 0;
}

// Lua function: irc_topic(channel, topic) or irc_topic(channel)
static int l_irc_topic(lua_State *L){
	size_t chan_len = 0, topic_len = 0;
	const char* topic_str = 0;
	const char* chan_str = luaL_checklstring(L, 1, &chan_len);
	if(lua_gettop(L) == 2 && !lua_isnil(L, 2))
		topic_str = luaL_checklstring(L, 2, &topic_len);
	printf("%s topic on channel %s%s%s%s.\n",
			topic_str?"Setting":"Querying",
			chan_str, 
			topic_str?" to '":"",
			topic_str?topic_str:"",
		 	topic_str?"'":""
		 );
	irc_cmd_topic(I, chan_str, topic_str?topic_str:0);
	return 0;
}

// Lua function: irc_cmode(channel, mode) or irc_cmode(channel)
static int l_irc_cmode(lua_State *L){
	size_t chan_len = 0, mode_len = 0;
	const char* mode_str = 0;
	const char* chan_str = luaL_checklstring(L, 1, &chan_len);
	if(lua_gettop(L) == 2 && !lua_isnil(L, 2))
		mode_str = luaL_checklstring(L, 2, &mode_len);
	printf("%s mode on channel %s%s%s%s.\n",
			mode_str?"Setting":"Querying",
			chan_str, 
			mode_str?" to '":"",
			mode_str?mode_str:"",
		 	mode_str?"'":""
		 );
	irc_cmd_channel_mode(I, chan_str, mode_str?mode_str:0);
	return 0;
}

// Lua function: irc_umode(mode) or irc_umode()
static int l_irc_umode(lua_State *L){
	size_t mode_len = 0;
	const char* mode_str = 0;
	if(lua_gettop(L) == 1 && !lua_isnil(L, 1))
		mode_str = luaL_checklstring(L, 1, &mode_len);
	printf("%s mode on self%s%s%s.\n",
			mode_str?"Setting":"Querying",
			mode_str?" to '":"",
			mode_str?mode_str:"",
		 	mode_str?"'":""
		 );
	irc_cmd_user_mode(I, mode_str?mode_str:0);
	return 0;
}

// Lua function: irc_kick(nick, channel, reason) or irc_kick(nick, channel)
static int l_irc_kick(lua_State *L){
	size_t nick_len = 0, chan_len = 0, msg_len = 0;
	const char *nick_str = 0, *chan_str = 0, *msg_str = 0;
	nick_str = luaL_checklstring(L, 1, &nick_len);
	chan_str = luaL_checklstring(L, 2, &chan_len);
	if(lua_gettop(L) == 3 && !lua_isnil(L, 3))
		msg_str = luaL_checklstring(L, 3, &msg_len);
	printf("Kicking %s from %s%s%s%s.\n", nick_str, chan_str, msg_str?" with reason '":"", msg_str?msg_str:"", msg_str?"'":"");
	irc_cmd_kick(I, nick_str, chan_str, msg_str);
	return 0;
}

// Lua function: irc_notice(target, message)
static int l_irc_notice(lua_State *L){
	size_t target_len = 0, message_len = 0;
	const char* target_str  = luaL_checklstring(L, 1, &target_len);
	const char* message_str = luaL_checklstring(L, 2, &message_len);
	printf("Sending notice to %s: '%s'.\n", target_str, message_str);
	irc_cmd_notice(I, target_str, message_str);
	return 0;
}

// Lua function: irc_ctcp_req(target, message)
static int l_irc_ctcp_req(lua_State *L){
	size_t target_len = 0, message_len = 0;
	const char* target_str  = luaL_checklstring(L, 1, &target_len);
	const char* message_str = luaL_checklstring(L, 2, &message_len);
	printf("Sending CTCP request to %s: '%s'.\n", target_str, message_str);
	irc_cmd_ctcp_request(I, target_str, message_str);
	return 0;
}

// Lua function: irc_ctcp_rep(target, message)
static int l_irc_ctcp_rep(lua_State *L){
	size_t target_len = 0, message_len = 0;
	const char* target_str  = luaL_checklstring(L, 1, &target_len);
	const char* message_str = luaL_checklstring(L, 2, &message_len);
	printf("Sending CTCP reply to %s: '%s'.\n", target_str, message_str);
	irc_cmd_ctcp_reply(I, target_str, message_str);
	return 0;
}

// Lua function: irc_nick(newnick)
static int l_irc_nick(lua_State *L){
	size_t nick_len = 0;
	const char* nick_str = luaL_checklstring(L, 1, &nick_len);
	printf("Changing nick to %s.\n", nick_str);
	irc_cmd_nick(I, nick_str);
	return 0;
}

// Lua function: irc_whois(nick)
static int l_irc_whois(lua_State *L){
	size_t nick_len = 0;
	const char* nick_str = luaL_checklstring(L, 1, &nick_len);
	printf("Querying whois on %s.\n", nick_str);
	irc_cmd_whois(I, nick_str);
	return 0;
}

// Lua function: irc_quit(reason) or irc_quit()
static int l_irc_quit(lua_State *L){
	size_t msg_len = 0;
	const char* msg_str = 0;
	if(lua_gettop(L) == 1 && !lua_isnil(L, 1))
		msg_str = luaL_checklstring(L, 1, &msg_len);
	printf("Quitting %s%s%s.\n",
			msg_str?" with message '":"",
			msg_str?msg_str:"",
		 	msg_str?"'":""
		 );
	irc_cmd_quit(I, msg_str?msg_str:0);
	return 0;
}

// Lua function: irc_raw(string)
static int l_irc_raw(lua_State *L){
	size_t cmd_len = 0;
	const char* cmd_str = luaL_checklstring(L, 1, &cmd_len);
	printf("Sending raw command: %s\n", cmd_str);
	irc_send_raw(I, cmd_str);
	return 0;
}


/* MYSQL SECTION */

// Lua function: sql_query(query)
static int l_sql_query(lua_State *L){
	size_t query_len = 0;
	MYSQL_RES *result;
	const char* query_str = luaL_checklstring(L, 1, &query_len);
	printf("Executing SQL query: %s\n", query_str);
	mysql_query(S, query_str);
	result = mysql_store_result(S);
	lua_pushnumber(L, (uintptr_t)result);
	return 1;
}

// Lua function: sql_num_rows(result)
static int l_sql_num_rows(lua_State *L){
	uintptr_t query = luaL_checknumber(L, 1);
	lua_pushnumber(L, mysql_num_rows((MYSQL_RES*) query));
	return 1;
}

// Lua function: sql_fetch_row(result)
static int l_sql_fetch_row(lua_State *L){
	MYSQL_RES* query;
	uintptr_t query_ptr;
	query_ptr = (uintptr_t) luaL_checknumber(L, 1);
	query = (MYSQL_RES*) query_ptr;
	int num_fields = mysql_num_fields(query), i;
	MYSQL_ROW row = mysql_fetch_row(query);
	lua_newtable(L);
	for(i = 0; i < num_fields; i++){
		MYSQL_FIELD* field = mysql_fetch_field(query);
		lua_pushstring(L, field->name);
		lua_pushstring(L, row[i]);
		lua_settable(L, -3);
	}
	return 1;
}

// Lua function: sql_num_fields(result)
static int l_sql_num_fields(lua_State *L){
	uintptr_t query = luaL_checknumber(L, 1);
	lua_pushnumber(L, mysql_num_fields((MYSQL_RES*) query));
	return 1;
}

// Lua function: sql_affected_rows()
static int l_sql_affected_rows(lua_State *L){
	lua_pushnumber(L, mysql_affected_rows(S));
	return 1;
}

// Lua function: sql_errno()
static int l_sql_errno(lua_State *L){
	lua_pushnumber(L, mysql_errno(S));
	return 1;
}

// Lua function: sql_error()
static int l_sql_error(lua_State *L){
	lua_pushstring(L, mysql_error(S));
	return 1;
}




/* INTERFACE REGISTRATION SECTION */

// Registers above Lua functions with the Lua state
void register_lua_functions(lua_State* L){

	lua_pushcfunction(L, l_rehash);
	lua_setglobal(L, "rehash");
	
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
	
	lua_pushcfunction(L, l_irc_action);
	lua_setglobal(L, "irc_action");
	
	lua_pushcfunction(L, l_irc_invite);
	lua_setglobal(L, "irc_invite");
	
	lua_pushcfunction(L, l_irc_names);
	lua_setglobal(L, "irc_names");
	
	lua_pushcfunction(L, l_irc_list);
	lua_setglobal(L, "irc_list");
	
	lua_pushcfunction(L, l_irc_topic);
	lua_setglobal(L, "irc_topic");
	
	lua_pushcfunction(L, l_irc_cmode);
	lua_setglobal(L, "irc_cmode");
	
	lua_pushcfunction(L, l_irc_umode);
	lua_setglobal(L, "irc_umode");
	
	lua_pushcfunction(L, l_irc_kick);
	lua_setglobal(L, "irc_kick");
	
	lua_pushcfunction(L, l_irc_notice);
	lua_setglobal(L, "irc_notice");
	
	lua_pushcfunction(L, l_irc_ctcp_req);
	lua_setglobal(L, "irc_ctcp_req");
	
	lua_pushcfunction(L, l_irc_ctcp_rep);
	lua_setglobal(L, "irc_ctcp_rep");
	
	lua_pushcfunction(L, l_irc_nick);
	lua_setglobal(L, "irc_nick");
	
	lua_pushcfunction(L, l_irc_whois);
	lua_setglobal(L, "irc_whois");
	
	lua_pushcfunction(L, l_irc_quit);
	lua_setglobal(L, "irc_quit");
	
	lua_pushcfunction(L, l_irc_raw);
	lua_setglobal(L, "irc_raw");
	
	lua_pushcfunction(L, l_sql_query);
	lua_setglobal(L, "sql_query");
	
	lua_pushcfunction(L, l_sql_num_rows);
	lua_setglobal(L, "sql_num_rows");
	
	lua_pushcfunction(L, l_sql_fetch_row);
	lua_setglobal(L, "sql_fetch_row");
	
	lua_pushcfunction(L, l_sql_num_fields);
	lua_setglobal(L, "sql_num_fields");
	
	lua_pushcfunction(L, l_sql_affected_rows);
	lua_setglobal(L, "sql_affected_rows");
	
	lua_pushcfunction(L, l_sql_errno);
	lua_setglobal(L, "sql_errno");
	
	lua_pushcfunction(L, l_sql_error);
	lua_setglobal(L, "sql_error");
	
}


