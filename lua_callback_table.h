#ifndef lua_callback_table_h
#define lua_callback_table_h

#define LUA_CALLBACK_TABLE_SIZE 8
#define LUA_CALLBACK_ENTRY_POOL_SIZE 256
#define LUA_CALLBACK_STRING_POOL_SIZE 1024


typedef struct LUA_CALLBACK_TABLE_ENTRY {
	char* type;
	char* func;
	struct LUA_CALLBACK_TABLE_ENTRY* next;
} CBENTRY;

int cbtable_hash(const char* type);
void cbtable_init();
void cbtable_clear();
void cbtable_destroy();
void cbtable_add(const char* type, const char* func);
CBENTRY* cbtable_next(const char* type, CBENTRY* prev);


#endif
