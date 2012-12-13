// havocmain.c
// Front-end code.
// Reads the files, initializes the VM, all that stuff.


#include "havocvm.h"
#include "havocerr.h"
#include "havocinterp.h"

#include "instructions.h"

#define K 1024
#define M (1024 * 1024)


// 0: load r1 0xCAFEBABE
// 2: sub r1 0xE
// 3: jp 100
// 4: halt
// 
// 100: mul r0 5
// 101: jp 4
void loadTestProg1( hv_vm* vm ) {
   instruction i;
   vm->reg[R0] = 16;
   vm->reg[R1] = 17;

   i.opcode = LOAD;
   i.locFlags = ARG_CONST;
   i.followFlag = FOLLOW_FLAG;
   i.dataWord = MAKEDATAWORD( R1, 0 );
   *(vm->memory+0) = instruction2opcode( &i );
   *(vm->memory+1) = 0xCAFEBABE;

   i.opcode = SUB;
   i.followFlag = 0;
   i.dataWord = MAKEDATAWORD( R1, 0xE );
   *(vm->memory+2) = instruction2opcode( &i );

   i.opcode = JP;
   i.dataWord = 100;
   *(vm->memory+3) = instruction2opcode( &i );

   i.opcode = HALT;
   *(vm->memory+4) = instruction2opcode( &i );

   i.opcode = MUL;
   i.dataWord = MAKEDATAWORD( R0, 5 );
   *(vm->memory+100) = instruction2opcode( &i );

   i.opcode = JP;
   i.dataWord = 4;
   *(vm->memory+101) = instruction2opcode( &i );
}


// This is a (very stupid) benchmark.
// A good one would have it run through every instruction there is.
// But I want an assembler, first.
// However, on my 2GHz AMD processor, it runs through 30 million 
// instructions in a bit less than 3 seconds.  With -O3, at least.
// That's, call it 10 MIPS, or a 200x slowdown.
//
// About what I expected, considering the actual interpreter is not 
// optimized at all.  It'd probably be quite a bit quicker if I didn't
// have all the function pointers and indirection and stuff in 
// doInstruction()
//
// Interestingly, taking the bounds checking out of the JNZ instruction
// doesn't seem to affect it at all.
// I'ma gonna do some profiling and see what I can tighten, just for fun.
// doInstruction takes like 40-50% of all the time, which is rather
// interesting, 'cause it's just a big switch statement.
// run() is the next biggest at 20%, and opcode2instruction next at 10%,
// then getReg() at 5%.  All the actual instructions are below that.
// Wild.  I wonder if I can replace doInstruction() with a jump table
// or something?
//
// However, after merely removing a couple fflush() calls that shouldn't be 
// there, it went through 300 million instructions in 11.5 seconds or so.
// That's 25 MIPS, an 80x slowdown.  Much much better.  And really,
// profiling reveals that if I optimized the fuck out of doInstruction()
// and run(), I'd get at best a 2-2.5x increase in speed.  I may do it
// someday, but not now.
//
// 25 MHz is as fast as the first computer I ever used.
//
// 0: load r0 100,000,000
// 2: sub r0 1
// 3: cmpz r0
// 4: jnz 2
// 5: halt
void loadTestProg2( hv_vm* vm ) {
   instruction i;

   i.opcode = LOAD;
   i.locFlags = ARG_CONST;
   i.followFlag = FOLLOW_FLAG;
   i.dataWord = MAKEDATAWORD( R0, 0 );
   *(vm->memory+0) = instruction2opcode( &i );
   printf( "0x%08X\n", *(vm->memory+0) );
   *(vm->memory+1) = 100000000;

      

   i.opcode = SUB;
   i.followFlag = 0;
   i.dataWord = MAKEDATAWORD( R0, 1 );
   *(vm->memory+2) = instruction2opcode( &i );
   printf( "0x%08X\n", *(vm->memory+2) );

   i.opcode = CMPZ;
   i.locFlags = ARG_REG;
   i.dataWord = MAKEDATAWORD( R0, 0 );
   *(vm->memory+3) = instruction2opcode( &i );
   printf( "0x%08X\n", *(vm->memory+3) );

   i.opcode = JNZ;
   i.locFlags = ARG_CONST;
   i.dataWord = 2;
   *(vm->memory+4) = instruction2opcode( &i );
   printf( "0x%08X\n", *(vm->memory+4) );

   i.opcode = HALT;
   i.locFlags = 0;
   i.dataWord = 0;
   *(vm->memory+5) = instruction2opcode( &i );
   printf( "0x%08X\n", *(vm->memory+5) );

}


// 0: load r0 128
// 1: load r1 101
// 2: store [100] r0
// 3: store [r1] r0
// 4: load r4 [100]
// 5: load r5 [r1]
// 6: halt
void loadTestProg3( hv_vm* vm ) {
   instruction i;

   i.opcode = LOAD;
   i.locFlags = ARG_CONST;
   i.followFlag = 0;
   i.dataWord = MAKEDATAWORD( R0, 128 );
   *(vm->memory+0) = instruction2opcode( &i );

   i.opcode = LOAD;
   i.locFlags = ARG_CONST;
   i.dataWord = MAKEDATAWORD( R1, 101 );
   *(vm->memory+1) = instruction2opcode( &i );

   i.opcode = STORE;
   i.locFlags = ARG_MEMC;
   i.dataWord = MAKEDATAWORD( 100, R0 );
   *(vm->memory+2) = instruction2opcode( &i );

   i.opcode = STORE;
   i.locFlags = ARG_MEMR;
   i.dataWord = MAKEDATAWORD( R1, R0 );
   *(vm->memory+3) = instruction2opcode( &i );

   i.opcode = LOAD;
   i.locFlags = ARG_MEMC;
   i.dataWord = MAKEDATAWORD( R4, 100 );
   *(vm->memory+4) = instruction2opcode( &i );

   i.opcode = LOAD;
   i.locFlags = ARG_MEMR;
   i.dataWord = MAKEDATAWORD( R5, R1 );
   *(vm->memory+5) = instruction2opcode( &i );

   i.opcode = HALT;
   *(vm->memory+6) = instruction2opcode( &i );
}

void loadFile( char* fname, hv_vm* vm ) {
   FILE* f = fopen( fname, "rb" );
   int count = 0;
   if( !f ) {
      printf( "File '%s' does not exist.\n", fname );
      exit( 1 );
   }
   printf( "Loading %s... ", fname );
   fflush( stdout );
   count = fread( vm->memory, sizeof( int ), vm->memorylen, f );
   printf( "done, %d words read\n", count );
   fflush( stdout );
   fclose( f );
}

void parseArgs( char** args, int argc ) {
}

int main( int argc, char** argv ) {
   hv_vm* vm = makeVM( 4*K ); 
/*   if( argc > 1 ) {
      loadFile( argv[1], vm );
   } else {
      printf( "Please specify a code file!\n" );
      return 1;
   }
   */
   loadTestProg2( vm );

   run( vm );

   printRegs( vm );

   freeVM( vm );

   return 0;
}
