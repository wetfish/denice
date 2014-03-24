#include <stdlib.h>
#include <stdio.h>
#include "mem.h"

#define ERROR_MSG(msg)  { fprintf(stderr, "%s\n", msg); exit(-1); }

#define MAX_POOL  10
MEM_POOL_NODE mem_pools[MAX_POOL];
MEM_POOL next_free_pool;

// initialize memory management structures
void mem_init()
{
    int i;
    
    for (i = 0; i < MAX_POOL-1; i++) {
      mem_pools[i].link = &mem_pools[i+1];
      mem_pools[i].pool = NULL;
    }
    mem_pools[i].link = NULL;
    mem_pools[i].pool = NULL;
    next_free_pool = mem_pools;
}

// allocate memory pool
MEM_POOL mem_alloc_pool(int size)
{
    MEM_POOL mpool = next_free_pool;

    if (mpool == NULL)
      ERROR_MSG("Running out of memory pools");

    if (size <= 0)
      ERROR_MSG("mem_alloc_pool: requested size <= 0");
    
    mpool->pool = malloc(size);
    mpool->size = size;
    mpool->next_free = mpool->pool;

    next_free_pool = mpool->link;
    mpool->link = NULL;
 
    return(mpool);
}

// reset memory pool
void mem_reset_pool(MEM_POOL mpool)
{
    if ((mpool == NULL) || (mpool->pool == NULL))
       ERROR_MSG("Invalid memory pool");

    mpool->next_free = mpool->pool;
}

// free memory pool
void mem_free_pool(MEM_POOL mpool)
{
    if ((mpool == NULL) || (mpool->pool == NULL))
       ERROR_MSG("Invalid memory pool");

    free(mpool->pool);
    mpool->pool = NULL;
    mpool->size = 0;
    mpool->next_free = NULL;
    mpool->link = next_free_pool;
    next_free_pool = mpool;
}

// get free space from pool
char *mem_get_free(MEM_POOL mpool, int size)
{
    char *ptr;
    
    if ((mpool == NULL) || (mpool->pool == NULL))
       ERROR_MSG("Invalid memory pool");

    ptr = mpool->next_free;

    if (ptr + size > mpool->pool + mpool->size)
      ERROR_MSG("Memory pool overflows");

    mpool->next_free = ptr + size;
    return(ptr);
}

