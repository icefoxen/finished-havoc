

type op = 
   LOAD
 | STORE
 | XCHG
 | PUSH
 | POP

 | ADD
 | SUB
 | MUL
 | DIV
 | MOD

 | SHL
 | SHR
 | AND
 | OR
 | NOT
 | XOR
 | ROTL
 | ROTR

 | CMP
 | CMPZ
 | JP
 | JZ
 | JNZ
 | JE
 | JNE
 | JL
 | JLE
 | JG
 | JGE
 | CALL
 | RET

 | READCHAR
 | WRITECHAR

 | CLEARF
 | SETF
 | HALT
 | NOP
;;

type reg = 
   IP
 | CP (* Call ptr *)
 | DP (* Data ptr *)
 | FL

 | R0
 | R1
 | R2
 | R3
 | R4
 | R5
 | R6
 | R7
;;

let string_of_reg = function
   IP -> "ip"
 | CP -> "cp"
 | DP -> "dp"
 | FL -> "fl"

 | R0 -> "r0"
 | R1 -> "r1"
 | R2 -> "r2"
 | R3 -> "r3"
 | R4 -> "r4"
 | R5 -> "r5"
 | R6 -> "r6"
 | R7 -> "r7"
;;
