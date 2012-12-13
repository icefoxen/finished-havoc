using System;

namespace Havoc {
   public enum OP {
      LOAD,
      STORE,
      XCHG,
      PUSH,
      POP,
      
      ADD,
      SUB,
      MUL,
      DIV,
      MOD,

      SHL,
      SHR,
      AND,
      OR,
      NOT,
      XOR,
      ROTL,
      ROTR,

      CMP,
      CMPZ,
      JP,
      JZ,
      JNZ,
      JE,
      JNE,
      JL,
      JLE,
      JG,
      JGE,
      CALL,
      RET,

      READCHAR,
      WRITECHAR,

      CLEARF,
      SETF,
      HALT,
      NOP   
   }


   public enum REGISTERS {
      IP,
      CP, // Call pointer
      DP, // Data pointer
      FL,

      R0,
      R1,
      R2,
      R3,
      R4,
      R5,
      R6,
      R7 
   }

   /* These are probably slightly less than convenient for the bitwise
    * operations we have to do with them.
    */
   /*
     public enum ARGTYPE {
     MEMC = 0x00000000,
     REG = 0x00000100,
     CONST = 0x00000200,
     MEMR  = 0x00000400
     }
   */
   public class Instruction {
      public OP opcode;
      public int locFlags;
      public int followFlag;
      public int followWord;
      public int dataWord;
      
      public const int ARG_MEMC    = 0x00000000;
      public const int ARG_REG     = 0x00000100;
      public const int ARG_CONST   = 0x00000200;
      public const int ARG_MEMR    = 0x00000300;
      public const int FOLLOW_FLAG = 0x00000400;

      public Instruction( OP o ) {
         opcode = o;
      }

      public Instruction( OP o, LocReg l ) {
      }

      public Instruction( OP o, LocMemr l ) {
      }

      public Instruction( OP o, LocMemc l  ) {
      }

      public Instruction( OP o, LocConst l ) {
      }

      
      public Instruction( int opc ) {
	 int op = opc & 0x000000FF;
	 locFlags = opc & ARG_MEMR;
	 followFlag = opc & FOLLOW_FLAG;
	 dataWord = (int) (opc & 0xFFFF0000) >> 16;

	 opcode = (OP) op;
      }

      public int ToOpcode() {
         int op = 0;
	 op |= (int) opcode;
	 op |= locFlags;
	 op |= followFlag;
	 op |= (dataWord & 0x0000FFFF) << 16;

	 return op;
	 
      }

      public override string ToString() {
         return String.Format( 
	    "OP: {0} LOC: {1} FFLAGS: {2} FWORD: {3} DATA: {4}", 
	    opcode, locFlags, followFlag, followWord, dataWord );
      }
   }
}
