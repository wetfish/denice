#ifndef mem_h
#define mem_h

typedef struct MEM_POOL_NODE_STRUCT
{
    struct MEM_POOL_NODE_STRUCT  *link;
    char      *next_free;
    int        size;
    char      *pool;
} MEM_POOL_NODE;

typedef MEM_POOL_NODE *MEM_POOL;

void mem_init();
MEM_POOL mem_alloc_pool(int size);
void mem_reset_pool(MEM_POOL mpool);
void mem_free_pool(MEM_POOL mpool);
char *mem_get_free(MEM_POOL mpool, int size);

#endif
