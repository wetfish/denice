# Paths and flags for Lua
LUA_INCLUDE_DIR=/usr/include/lua5.2
LUA_LIBRARY_DIR=/usr/lib/i386-linux-gnu
LUA_FLAGS=-llua5.2

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
CCFLAGS=-Wall $(INCPATHS)
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
