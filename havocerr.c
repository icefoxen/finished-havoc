// Just general error functions.

#include "havocerr.h"
#include "havocvm.h"

void generalError( char* wossname ) {
   printf( "Error: %s\n", wossname );
   exit( 1 );
}

void processorException( hverror err, char* wossname ) {
   printf( "Processor exception %d: %s\n", (int) err, wossname );
   exit( 1 );
}
