#ifndef _HAVOCERR_H
#define _HAVOCERR_H

#include <stdio.h>
#include <stdlib.h>

typedef enum {
   HVERR_USER,
   HVERR_INVALIDOP,
   HVERR_MEMERROR,
   HVERR_UNKNOWN
} hverror;

void generalError( char* );

void processorException( hverror, char* );

#endif
