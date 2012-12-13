/* havocinterp.c
 * This is the heart of the thing, the actual interpreter that
 * decodes and executes instructions
 * Behold.
 *
 * Someday we need a debug version of this that does bounds-checking
 * and stuff, a dangerous version of it that doesn't check anything, and so
 * on.
 * Maybe.
 */


#include "havocerr.h"
#include "havocinterp.h"
#include "instructions.h"




int doLoad( hv_vm* vm, int dest, int src ) {
   return src;   
}

void doStoreC( hv_vm* vm, instruction* instr ) {
   //printf( "data1: %d, data2: %d\n", GETDESTBYTE( instr ), GETSOURCEBYTE( instr ) );
   int addrToStoreAt = GETDESTBYTE( instr );
   hvreg valToStore = getReg( vm, GETSOURCEBYTE( instr ) );
   //printf( "Storing %d into address %d\n", valToStore, addrToStoreAt );
   if( instr->followFlag ) {
      addrToStoreAt += instr->followWord;
   }
   vm->memory[addrToStoreAt] = valToStore;
}

void doStoreR( hv_vm* vm, instruction* instr ) {
   int addrToStoreAt = getReg( vm, GETDESTBYTE( instr ) );
   int valToStore = getReg( vm, GETSOURCEBYTE( instr ) );
   *(vm->memory + addrToStoreAt) = valToStore;
}

void doStore( hv_vm* vm, instruction* instr ) {
   if( instr->locFlags == ARG_MEMR ) {
      doStoreR( vm, instr );
   } else {
      doStoreC( vm, instr );
   }
}


void doXchg( hv_vm* vm, instruction* instr ) {
   int tmp = getReg( vm, GETSOURCEBYTE( instr ) );
   setReg( vm, GETSOURCEBYTE( instr ), getReg( vm, GETDESTBYTE( instr ) ) );
   setReg( vm, GETDESTBYTE( instr ), tmp );
}

void doPush( hv_vm* vm, instruction* instr ) {
   int valToStore = getReg( vm, GETDESTBYTE( instr ) );
   vm->reg[DP] -= 1;
   if( vm->reg[DP] < 0 ) {
      processorException( HVERR_MEMERROR, "Data stack overflow!" );
   }
   *(vm->memory + vm->reg[DP]) = valToStore;
}

int doPop( hv_vm* vm, int dest, int src ) {
   int res = *(vm->memory + vm->reg[DP]);
   vm->reg[DP] += 1;
   if( vm->reg[DP] >= vm->memorylen ) {
      processorException( HVERR_MEMERROR, "Data stack underflow!" );
   }
   return res;
}

int doAdd( hv_vm* vm, int dest, int src ) {
   return dest + src;
}

int doSub( hv_vm* vm, int dest, int src ) {
   return dest - src;
}

int doMul( hv_vm* vm, int dest, int src ) {
   return dest * src;
}

int doDiv( hv_vm* vm, int dest, int src ) {
   return dest / src;
}

int doMod( hv_vm* vm, int dest, int src ) {
   return dest % src;
}

int doAnd( hv_vm* vm, int dest, int src ) {
   return dest & src;
}

int doOr( hv_vm* vm, int dest, int src ) {
   return dest | src;
}

int doNot( hv_vm* vm, int dest, int src ) {
   return ~dest;
}

int doXor( hv_vm* vm, int dest, int src ) {
   return dest ^ src;
}

int doShl( hv_vm* vm, int dest, int src ) {
   return dest << src;
}

int doShr( hv_vm* vm, int dest, int src ) {
   return dest >> src;
}

int doRotr( hv_vm* vm, int dest, int src ) {
   processorException( HVERR_INVALIDOP, "XXX: Rotr/rotl are not implemented!" );
   return 0;
}

int doRotl( hv_vm* vm, int dest, int src ) {
   processorException( HVERR_INVALIDOP, "XXX: Rotr/rotl are not implemented!" );
   return 0;
}

int doCmp( hv_vm* vm, int dest, int src ) {
   vm->reg[FL] = 0;
   //printf( "Comparing %X to %X\n", dest, src );
   if( dest == src ) {
      vm->reg[FL] |= FLAG_EQ;
   } else if( dest > src ) {
      vm->reg[FL] |= FLAG_GT;
   } else if( dest < src ) {
      vm->reg[FL] |= FLAG_LT;
   }

   if( dest == 0 ) {
      vm->reg[FL] |= FLAG_ZERO;
   }
   return dest;
}

void doCmpz( hv_vm* vm, int value ) {
   if( value == 0 ) {
      vm->reg[FL] |= FLAG_ZERO;
   }
}

void doJp( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   vm->reg[IP] = value;
}

void doJz( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }

   if( vm->reg[FL] & FLAG_ZERO ) {
      vm->reg[IP] = value;
   }
}

void doJnz( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }

   if( !(vm->reg[FL] & FLAG_ZERO) ) {
      vm->reg[IP] = value;
   }
}

void doJe( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( (vm->reg[FL] & FLAG_EQ) ) {
      vm->reg[IP] = value;
   }
}

void doJne( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( !(vm->reg[FL] & FLAG_EQ) ) {
      vm->reg[IP] = value;
   }
}

void doJg( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( (vm->reg[FL] & FLAG_GT) ) {
      vm->reg[IP] = value;
   }
}

void doJge( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( (vm->reg[FL] & (FLAG_GT | FLAG_EQ)) ) {
      vm->reg[IP] = value;
   }
}

void doJl( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( (vm->reg[FL] & FLAG_LT) ) {
      vm->reg[IP] = value;
   }
}

void doJle( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to jump outside of memory!" );
   }
   if( (vm->reg[FL] & (FLAG_LT | FLAG_EQ)) ) {
      vm->reg[IP] = value;
   }
}

// Basically, this is:
// pushToCP ip
// jmp value
void doCall( hv_vm* vm, int value ) {
   if( value >= vm->memorylen || value < 0 ) {
      processorException( HVERR_MEMERROR, "Tried to call outside of memory!" );
   }

   vm->reg[CP] -= 1;
   if( vm->reg[CP] < 0 ) {
      processorException( HVERR_MEMERROR, "Call stack overflow!" );
   }
   *(vm->memory + vm->reg[CP]) = vm->reg[IP];

   vm->reg[IP] = value;
}

void doRet( hv_vm* vm, instruction* instr ) {
   if( vm->reg[CP] > vm->memorylen ) {
      processorException( HVERR_MEMERROR, "Call stack underflow!" );
   }

   int retAddr = *(vm->memory + vm->reg[CP]);
   vm->reg[CP] += 1;

   if( retAddr < 0 || retAddr > vm->memorylen ) {
      processorException( HVERR_MEMERROR, "Tried to return outside of memory!  How??" );
   }

   vm->reg[IP] = retAddr;
}

void doWritechar( hv_vm* vm, int value ) {
   putchar( value );
}

int doReadchar( hv_vm* vm, int dest, int src ) {
   return fgetc( stdin );

}


void doSetf( hv_vm* vm, int value ) {
   vm->reg[FL] = value;
}





// Handles operations of the format "op, reg, mem|reg|const"
// Passes the contents of the source and dest to the given function,
// and puts the result of it in the dest.
// Dest is specified by data1, src by data2.
//
// This covers most of the math and logic, and a couple other things.
void doToReg( hv_vm* vm, instruction* instr,
	      int(*func)( hv_vm*, int, int ) ) {
   int srcdata = 0;
   int destdata = getReg( vm, (hvreg) GETDESTBYTE( instr ) );
   
   switch( instr->locFlags ) {
      case ARG_MEMR:
         /* Right now, we don't support memory accesses of the form
          * [Rn+c]
	 if( instr->followFlag ) {
	    offset = instr->followWord;
	 } else {
	    offset = 0;
	 }
         */
	 srcdata = derefReg( vm, (hvreg) GETSOURCEBYTE( instr ) );
	 break;

      case ARG_MEMC:
	 if( instr->followFlag ) {
            srcdata = instr->followWord;
	 } else {
	    srcdata = GETSOURCEBYTE( instr );
	 }
         srcdata = vm->memory[srcdata];
	 break;

      case ARG_REG:
	 srcdata = getReg( vm, (hvreg) GETSOURCEBYTE( instr ) );
	 break;

      case ARG_CONST:
	 if( instr->followFlag ) {
	    srcdata = instr->followWord;
	 } else {
	    srcdata = GETSOURCEBYTE( instr );
	 }
	 break;
   }

   setReg( vm, (hvreg) GETDESTBYTE( instr ), func( vm, destdata, srcdata ) );
}


// This handles single-argument instructions of the form
// op mem|reg|const
// and uses the whole 16-bit data section of the instruction as
// that data.  These instructions return no value anywhere.
// Basically, jump and call instructions.
void doWithVal( hv_vm* vm, instruction* instr,
		void(*func)( hv_vm*, int ) ) {
   int offset = 0;
   int value  = 0;
   switch( instr->locFlags ) {
      case ARG_MEMC:
	 if( instr->followFlag ) {
	    offset = instr->followWord;
	 } else {
	    offset = GETSOURCEBYTE( instr );
	 }
	 value = vm->memory[offset];
	 break;

      case ARG_MEMR:
         value = derefReg( vm, (hvreg) GETSOURCEBYTE( instr ) );
         break;

      case ARG_REG:
	 value = getReg( vm, (hvreg) GETDESTBYTE( instr ) );
	 break;

      case ARG_CONST:
	 if( instr->followFlag ) {
	    value = instr->followWord;
	 } else {
	    value = instr->dataWord;
	 }
	 break;
   }
   func( vm, value );
}

void doInstruction( hv_vm* vm, instruction* instr ) {
   switch( instr->opcode ) {
      case LOAD:
	 doToReg( vm, instr, doLoad );
	 break;
      case STORE:
	 doStore( vm, instr );
	 break;
      case XCHG:
	 doXchg( vm, instr );
	 break;
      case PUSH:
	 doPush( vm, instr );
	 break;
      case POP:
	 doToReg( vm, instr, doPop );
	 break;

      case ADD:
	 doToReg( vm, instr, doAdd );
	 break;
      case SUB:
	 doToReg( vm, instr, doSub );
	 break;
      case MUL:
	 doToReg( vm, instr, doMul );
	 break;
      case DIV:
	 doToReg( vm, instr, doDiv );
	 break;
      case MOD:
	 doToReg( vm, instr, doMod );
	 break;
      
      case SHL:
	 doToReg( vm, instr, doShl );
	 break;
      case SHR:
	 doToReg( vm, instr, doShr );
	 break;
      case AND:
	 doToReg( vm, instr, doAnd );
	 break;
      case OR:
	 doToReg( vm, instr, doOr );
	 break;
      case NOT:
	 doToReg( vm, instr, doNot );
	 break;
      case XOR:
	 doToReg( vm, instr, doXor );
	 break;
      case ROTL:
	 doToReg( vm, instr, doRotl );
	 break;
      case ROTR:
	 doToReg( vm, instr, doRotr );
	 break;

      case CMP:
	 doToReg( vm, instr, doCmp );
	 break;
      case CMPZ:
	 doWithVal( vm, instr, doCmpz );
	 break;
      case JP:
	 doWithVal( vm, instr, doJp );
	 break;
      case JZ:
	 doWithVal( vm, instr, doJz );
	 break;
      case JNZ:
	 doWithVal( vm, instr, doJnz );
	 break;
      case JE:
	 doWithVal( vm, instr, doJe );
	 break;
      case JNE:
	 doWithVal( vm, instr, doJne );
	 break;
      case JL:
	 doWithVal( vm, instr, doJl );
	 break;
      case JLE:
	 doWithVal( vm, instr, doJle );
	 break;
      case JG:
	 doWithVal( vm, instr, doJg );
	 break;
      case JGE:
	 doWithVal( vm, instr, doJge );
	 break;
      case CALL:
	 doWithVal( vm, instr, doCall );
	 break;
      case RET:
	 doRet( vm, instr );
	 break;
	 
      case READCHAR:
         doToReg( vm, instr, doReadchar );
	 break;
      case WRITECHAR:
         doWithVal( vm, instr, doWritechar );
	 break;
	 
      case CLEARF:
	 vm->reg[FL] = 0;
	 break;
      case SETF:
	 doWithVal( vm, instr, doSetf );
	 break;
      case NOP:
	 break;

      // HALT is handled in run().

      default:
	 printf( "(ip points one past the instruction just executed.\n" );
	 printRegs( vm );
	 processorException( HVERR_INVALIDOP, "Invalid opcode!" );
   }
}

void readInstruction( hv_vm* vm, instruction* instr ) {
   int op = *(vm->memory + vm->reg[IP]);
   vm->reg[IP] += 1;
   opcode2instruction( instr, op );

   if( instr->followFlag ) {
      instr->followWord = *(vm->memory + vm->reg[IP]);
      vm->reg[IP] += 1;
   }
}



void run( hv_vm* vm ) {
   instruction i;

   while( 1 ) {
      if( (vm->reg[IP] >= vm->memorylen) || (vm->reg[IP] < 0) ) {
	 printf( "IP: %X not in [0,%X)\n", vm->reg[IP], vm->memorylen );
	 processorException( HVERR_MEMERROR, 
               "IP ran off end of code segment!" );
      }
      readInstruction( vm, &i );

      if( i.opcode == HALT ) {
	 printf( "Halt recieved at 0x%X!\n", vm->reg[IP] );
	 return;
      }
      doInstruction( vm, &i );
   }
}


