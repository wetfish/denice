#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include "error.h"

// Print formatted error and if error is fatal, terminate
void error(int fatal, char* format, ...){
	va_list args;
	va_start(args, format);
	vfprintf(stderr, format, args);
	va_end(args);
	if(fatal)
		exit(1);
}
