
#ifndef _HAVOCVM_H
#define _HAVOCVM_H

#include <stdlib.h>
#include <malloc.h>

#include "instructions.h"

typedef enum {
   IP,
   CP,
   DP,
   FL,

   R0,
   R1,
   R2,
   R3,
   R4,
   R5,
   R6,
   R7,
   NUMREG
} hvreg;

typedef struct { 
      int reg[NUMREG];

      int memorylen;
      int* memory;
} hv_vm;


#define FLAG_EQ   0x01
#define FLAG_GT   0x02
#define FLAG_LT   0x04
#define FLAG_ZERO 0x08

hv_vm* makeVM( int );

void freeVM( hv_vm* );


int getReg( hv_vm*, hvreg );
void setReg( hv_vm*, hvreg, int );
int derefReg( hv_vm*, hvreg );

void printRegs( hv_vm* );

int makeInstruction( hvopcode, int, int, int, int );

#endif
