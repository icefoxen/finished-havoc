#include <stdio.h>
#include "instructions.h"

int instruction2opcode( instruction* instr ) {
   int opcode = 0;
   opcode |= instr->opcode;
   opcode |= instr->locFlags;
   opcode |= instr->followFlag;
   opcode |= (instr->dataWord & 0x0000FFFF) << 16;

   return opcode;
}


void opcode2instruction( instruction* instr, int opcode ) {
   int op = opcode & 0x000000FF;
   int locFlags = opcode & ARG_MEMR;
   int followFlag = opcode & FOLLOW_FLAG;
   int dataWord = (opcode & 0xFFFF0000) >> 16;

   instr->opcode = (hvopcode) op;
   instr->locFlags = locFlags;
   instr->followFlag = followFlag;
   instr->dataWord = dataWord;
}

int hasFollowWord( int opcode ) {
   return opcode & FOLLOW_FLAG;
}
