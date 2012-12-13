// instructions.h
// This is the definition and listing of all CPU instructions.
// For details, see havocspec.txt


#ifndef _INSTRUCTIONS_H
#define _INSTRUCTIONS_H



// These are so we can OR them all together to form instructions.

#define ARG_MEMC  0x00000000
#define ARG_REG   0x00000100
#define ARG_CONST 0x00000200
#define ARG_MEMR  0x00000300

#define FOLLOW_FLAG 0x00000400

#define MAKEDATAWORD( dest, src ) (((dest) << 8) | (src))

#define GETDESTBYTE( instr )   (((instr)->dataWord & 0x0000FF00) >> 8)
#define GETSOURCEBYTE( instr ) ((instr)->dataWord & 0x000000FF)

typedef enum {
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
} hvopcode;


typedef struct {
      hvopcode opcode;
      int locFlags;
      int followFlag;
      int followWord;
      int dataWord;
} instruction;

int instruction2opcode( instruction* );
void opcode2instruction( instruction*, int );
int hasFollowWord( int );

#endif
