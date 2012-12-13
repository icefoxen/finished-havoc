/* havocvm.c
 * Defines the data structure for the VM, and operations to manipulate it.
 * 
 * Simon Heath
 * 3/26/2007
 */

#include "havocvm.h"
#include "havocerr.h"

// Instructions are 32-bit values.
// We have many different types of instructions:
// Arithmatic and logic (integer and floating point)
// Jump, conditional jump
// Call, return.
// Loading, storing, and dereferencing of data
// Comparison
// Allocation.
//
// There may be instructions that can be followed by a data chunk
// of variable size, for say, long addresses.

// We have 4 special registers: the instruction pointer,
// stack pointer, data pointer, and a flag register
// We have two stacks, one for function calls, one for data.
// Kinda like Forth, yaknow, though this isn't stack-based.

// Um.  To do: Make this endian-independant.  Hm.
// Is it worth it?  Probably.  Is there a simple way to do it?
// Maybe.  Do I know it?  No.



// This is what you should actually use to make a new VM.
hv_vm* makeVM( int memorysize ) {
   int i = 0;
   hv_vm* vm = (hv_vm*) malloc( sizeof( hv_vm ) );
   if( vm == NULL ) {
      generalError( "makeVM: malloc() failed for interpreter!" );
   } 

   for( i = 0; i < NUMREG; i++ ) {
      vm->reg[i] = 0;
   }
   
   vm->memory = (int*) calloc( memorysize, sizeof( int ) );
   vm->memorylen = memorysize;

   if( vm->memory == NULL ) {
      generalError( "makeVM: malloc() failed for memory space!" );
   }
   
   return vm;
}

void freeVM( hv_vm* vm ) {
   free( vm->memory );
   free( vm );
}


int getReg( hv_vm* vm, hvreg reg ) {
#if DEBUG
   if( reg >= NUMREG ) {
      generalError( "getReg: Invalid register!" );
   }
#endif
   return vm->reg[reg];
}


void setReg( hv_vm* vm, hvreg reg, int val ) {
   if( reg >= NUMREG ) {
      generalError( "getReg: Invalid register!" );
   }
   vm->reg[reg] = val;
}

// Dereference a register, ie return the value of the memory location
// it's pointing at.
int derefReg( hv_vm* vm, hvreg reg ) {
   int regcontents = getReg( vm, reg );
   return *(vm->memory + regcontents);
}

void setFlag( hv_vm* vm, int flag ) {
   vm->reg[FL] |= flag;
}

void clearFlag( hv_vm* vm, int flag ) {
   vm->reg[FL] &= (~flag);
}

void clearFlags( hv_vm* vm ) {
   vm->reg[FL] = 0;
}

int getFlag( hv_vm* vm, int flag ) {
   return vm->reg[FL] & flag;
}

void printRegs( hv_vm* vm ) {
   printf( "r0: 0x%08X r1: 0x%08X r2: 0x%08X r3: 0x%08X\n", 
            vm->reg[R0], vm->reg[R1], vm->reg[R2], vm->reg[R3] );
   printf( "r4: 0x%08X r5: 0x%08X r6: 0x%08X r7: 0x%08X\n", 
            vm->reg[R4], vm->reg[R5], vm->reg[R6], vm->reg[R7] );
   printf( "ip: 0x%08X cp: 0x%08X dp: 0x%08X fl: 0x%08X\n", 
            vm->reg[IP], vm->reg[CP], vm->reg[DP], vm->reg[FL] );
}

