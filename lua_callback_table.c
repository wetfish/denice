#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "lua_callback_table.h"
#include "mem.h"

MEM_POOL callback_table_pool, callback_string_pool;
CBENTRY** callback_table;

// Hash function for our hash table
int cbtable_hash(const char* type){
	int acc = 0;
	const char* p;
	for(p = type; *p; p++)
		acc += *p;
	return acc % LUA_CALLBACK_TABLE_SIZE;
}

// Alloc memory and initialize hash table
void cbtable_init(){
	callback_table_pool = mem_alloc_pool(LUA_CALLBACK_ENTRY_POOL_SIZE * sizeof(CBENTRY));
	callback_string_pool = mem_alloc_pool(LUA_CALLBACK_STRING_POOL_SIZE);
	callback_table = (CBENTRY**) malloc(LUA_CALLBACK_TABLE_SIZE * sizeof(CBENTRY*));
	int i;
	for(i = 0; i < LUA_CALLBACK_TABLE_SIZE; i++)
		callback_table[i] = 0;
}

// Free hash table
void cbtable_destroy(){
	free(callback_table);
	callback_table = 0;
	mem_free_pool(callback_table_pool);
	mem_free_pool(callback_string_pool);
	callback_table_pool = 0;
}

// Finds the string in the string_pool, or inserts it if it doesn't exist
char* cbtable_alloc_type_string(const char* type){
	CBENTRY* t;
	if((t = cbtable_next(type, 0)) != 0){
		return t->type;
	}
	else{
		return strcpy(mem_get_free(callback_string_pool, strlen(type)+1), type);
	}
}

// Adds a callback to the table
void cbtable_add(const char* type, const char* func){
	int hash = cbtable_hash(type);
	char* type_b = cbtable_alloc_type_string(type);
	CBENTRY* next = callback_table[hash];
	
	callback_table[hash] = (CBENTRY*) mem_get_free(callback_table_pool, sizeof(CBENTRY));
	callback_table[hash]->type = type_b;
	callback_table[hash]->func = strcpy(mem_get_free(callback_string_pool, strlen(func)+1), func);
	callback_table[hash]->next = next;
}

// Finds the next matching callback in the table
CBENTRY* cbtable_next(const char* type, CBENTRY* prev){
	CBENTRY* p = 0;
	if(prev == 0){
		int h = cbtable_hash(type);
		p = callback_table[h];
	}
	else{
		p = prev->next;
	}
		
	while(p && strcmp(p->type, type)){
		p = p->next;
	}
	
	return p;
}

