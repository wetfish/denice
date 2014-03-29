#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include "callbacks.h"
#include "globals.h"
#include "error.h"

// Print formatted error and if error is fatal, terminate
void error(int fatal, char* format, ...){
	va_list args;
	va_start(args, format);
	vfprintf(stderr, format, args);
	if(fatal){
		va_end(args);
		fprintf(stderr,"Fatal error... Exiting.\n");
		exit(1);
	}
	else if(I){
		char str[256];
		const char** strp = malloc(sizeof(char*));
		strp[0] = str;
		fprintf(stderr,"Generating ERROR event...\n");
		vsnprintf(str, 256, format, args);
		va_end(args);
		if(str[strlen(str)-1] == '\n')
			str[strlen(str)-1] = '\0';
		event_generic(I, "ERROR", "<ERROR>", strp, 1);
		free(strp);
	}
	
}
