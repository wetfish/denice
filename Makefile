# Paths and flags for Lua
LUA_INCLUDE_DIR=libs/lua-5.2.3/src
LUA_LIBRARY_DIR=libs/lua-5.2.3/src
LUA_FLAGS=-llua

# Paths for Libircclient
IRC_INCLUDE_DIR=libs/libircclient-1.7/include
IRC_LIBRARY_DIR=libs/libircclient-1.7/src
IRC_FLAGS=-lircclient -lssl -lcrypto -lnsl

# Paths for Iniparser
INI_INCLUDE_DIR=libs/iniparser/src
INI_LIBRARY_DIR=libs/iniparser
INI_FLAGS=-liniparser

# Paths for MySQL
SQL_CFLAGS=`mysql_config --cflags`
SQL_LIBS=`mysql_config --libs`

INCPATHS=-I$(LUA_INCLUDE_DIR) -I$(IRC_INCLUDE_DIR) -I$(INI_INCLUDE_DIR) $(SQL_CFLAGS)
LIBPATHS=-L$(IRC_LIBRARY_DIR) -L$(LUA_LIBRARY_DIR) -L$(INI_LIBRARY_DIR)
LIBFLAGS=$(SQL_LIBS) $(LUA_FLAGS) $(IRC_FLAGS) $(INI_FLAGS)
CC=gcc
CCFLAGS=-g -Wall $(INCPATHS)
LDFLAGS=$(LIBPATHS) $(LIBFLAGS)
SOURCES=$(wildcard *.c)
OBJECTS=$(SOURCES:.c=.o)
TARGET=denice

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c %.h
	$(CC) $(CCFLAGS) -c $<

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

clean:
	rm -f *.o $(TARGET)
