(* Intermediate representation.
 * Operations, plus directives.
 * We have four directives:
    * Label
    * Alloc
    * AllocFill
    * Const
 * Const defines a constant value.  AllocFill allocates and initializes an area
 * of memory.  Alloc allocates and zeros it.
 *)

open Instruction

type value = 
   Reg of reg
 | Int of int32
 | Lbl of string
 | Constant of string
;;

type location = 
   Location of value
 | Dereference of value
;;

type opr = 
   Load of reg * location
 | Store of location * reg
 | Xchg of reg * reg
 | Push of reg
 | Pop of reg

 | Add of reg * location
 | Sub of reg * location 
 | Mul of reg * location 
 | Div of reg * location 
 | Mod of reg * location 

 | Shl of reg * location 
 | Shr of reg * location 
 | And of reg * location 
 | Or of reg * location 
 | Not of reg
 | Xor of reg * location 
 | Rotl of reg * location 
 | Rotr of reg * location 

 | Cmp of reg * location 
 | Cmpz of location
 | Jp of location
 | Jz of location
 | Jnz of location
 | Je of location
 | Jne of location
 | Jl of location
 | Jle of location
 | Jg of location
 | Jge of location
 | Call of location
 | Ret

 | Readchar of reg
 | Writechar of location

 | Clearf
 | Setf of reg
 | Halt
 | Nop

 | Label of string
 | Const of string * int32
 | Alloc of int32
 | AllocFill of int32 * int32
;;


let string_of_value = function
   Reg( reg ) -> string_of_reg reg
 | Int( i ) -> Int32.to_string i
 | Lbl( str ) -> "@" ^ str
 | Constant( str ) -> str
;;

let string_of_location = function
   Location( vl ) -> string_of_value vl
 | Dereference( vl ) -> "^" ^ (string_of_value vl)
;;

let p = Printf.sprintf;;

let string_of_opr = function
   Load( reg, loc ) -> p "load %s %s" (string_of_reg reg) (string_of_location loc)
 | Store( loc, reg ) -> p "store %s %s" (string_of_location loc) (string_of_reg reg)
 | Xchg( reg1, reg2 ) -> p "xchg %s %s" (string_of_reg reg1) (string_of_reg
 reg2) 
 | Push( reg ) -> p "push %s" (string_of_reg reg) 
 | Pop( reg ) ->  p "pop %s" (string_of_reg reg) 
 
 | Add( reg, loc ) -> p "add %s %s" (string_of_reg reg) (string_of_location loc)
 | Sub( reg, loc ) -> p "sub %s %s" (string_of_reg reg) (string_of_location loc)
 | Mul( reg, loc ) -> p "mul %s %s" (string_of_reg reg) (string_of_location loc)
 | Div( reg, loc ) -> p "div %s %s" (string_of_reg reg) (string_of_location loc)
 | Mod( reg, loc ) -> p "mod %s %s" (string_of_reg reg) (string_of_location loc)

 | Shl( reg, loc ) -> p "shl %s %s" (string_of_reg reg) (string_of_location loc)
 | Shr( reg, loc ) -> p "shr %s %s" (string_of_reg reg) (string_of_location loc)
 | And( reg, loc ) -> p "add %s %s" (string_of_reg reg) (string_of_location loc)
 | Or( reg, loc ) -> p "or %s %s" (string_of_reg reg) (string_of_location loc)
 | Not( reg ) -> p "not %s" (string_of_reg reg)
 | Xor( reg, loc ) -> p "xor %s %s" (string_of_reg reg) (string_of_location loc)
 | Rotl( reg, loc ) -> p "rotl %s %s" (string_of_reg reg) (string_of_location loc)
 | Rotr( reg, loc ) -> p "rotr %s %s" (string_of_reg reg) (string_of_location loc)

 | Cmp( reg, loc ) -> p "cmp %s %s" (string_of_reg reg) (string_of_location loc)
 | Cmpz( loc ) -> p "cmpz %s" (string_of_location loc)
 | Jp( loc ) -> p "jp %s" (string_of_location loc)
 | Jz( loc ) -> p "jz %s" (string_of_location loc)
 | Jnz( loc ) -> p "jnz %s" (string_of_location loc)
 | Je( loc ) -> p "je %s" (string_of_location loc)
 | Jne( loc ) -> p "jne %s" (string_of_location loc)
 | Jl( loc ) -> p "jl %s" (string_of_location loc)
 | Jle( loc ) -> p "jle %s" (string_of_location loc)
 | Jg( loc ) -> p "jg %s" (string_of_location loc)
 | Jge( loc ) -> p "jge %s" (string_of_location loc)
 | Call( loc ) -> p "call %s" (string_of_location loc)
 | Ret -> "ret"

 | Readchar( reg ) -> p "readchar %s" (string_of_reg reg)
 | Writechar( loc ) -> p "writechar %s" (string_of_location loc)

 | Clearf -> "clearf"
 | Setf( reg ) -> p "setf %s" (string_of_reg reg)
 | Halt -> "halt"
 | Nop -> "nop"
 
 | Label( str ) -> p "label %s" str
 | Const( str, i ) -> p "const %s %ld" str i
 | Alloc( i ) -> p "alloc %ld" i
 | AllocFill( i, j ) -> p "allocfill %ld %ld" i j
;;



(***************************************************************************)
(* Okay, now we do semantic analysis!  Yay! *)

exception SemantError of string

let semantError str =
   raise (SemantError( str ))
;;


type programContext = { 
   symtbl : (string * int32 option) list;
   (* XXX: I'm going to ASSUME that the current address will not exceed a 
    * billion or so...
    *)
   currentAddr : int;
};;

(* Woah.  A typo turned into something deeper:
 * This is not a function.  It does not need to be a function; we will never
 * need to CREATE a new programContext, because it is immutable, and so this
 * one will ALWAYS serve.
 * Wow.
 *)
let newProgramContext = {
   symtbl = [];
   currentAddr = 0;
};;

let symbolExists pc sym =
   List.mem_assoc sym pc.symtbl
;;

let addSymbol pc sym vl =
   if symbolExists pc sym then
       semantError ("Redefined symbol: " ^ sym)
   else
      { symtbl = (sym, vl) :: pc.symtbl;
        currentAddr = pc.currentAddr; }
;;

let redefineSymbol pc sym vl =
   let l = List.remove_assoc sym pc.symtbl in
   { symtbl = (sym, vl) :: l;
     currentAddr = pc.currentAddr; }

let incAddr pc = {
   symtbl = pc.symtbl;
   currentAddr = pc.currentAddr + 1;
};;

let addAddr pc a = {
   symtbl = pc.symtbl;
   currentAddr = pc.currentAddr + a;
};;

(* So we make several passes: first we get all the symbols defined, then we look
 * at all the symbols mentioned and make sure they all exist, then we go through
 * counting numbers and actually resolve all the addresses.
 *)

let populateSymtbl pc ir =
   let rec loop pc ir =
      match ir with
         [] -> pc
       | Label( name ) :: rst -> loop (addSymbol pc name None) rst
       | Const( name, vl ) :: rst -> loop (addSymbol pc name (Some( vl ))) rst
       | _ :: rst -> loop pc rst
   in
   loop pc ir
;;

let getLabelFromLocation = function
   Location( l ) 
 | Dereference( l ) ->
       match l with
          Lbl( lbl ) -> Some( lbl )
        | Constant( lbl ) -> Some( lbl )
        | _ -> None
;;

let verifyLabel pc loc =
   match getLabelFromLocation loc with
      Some( lbl ) ->
         if symbolExists pc lbl then
            ()
         else
            semantError ("Symbol " ^ lbl ^ " used but never declared!")
    | None -> ()
;;


let verifyLabels pc ir =
   let rec loop pc ir =
      match ir with
         Load( _, l ) :: rst 
       | Store( l, _ ) :: rst
       | Add( _, l ) :: rst
       | Sub( _, l ) :: rst
       | Mul( _, l ) :: rst
       | Div( _, l ) :: rst
       | Mod( _, l ) :: rst
       | Shl( _, l ) :: rst
       | Shr( _, l ) :: rst
       | And( _, l ) :: rst
       | Or( _, l ) :: rst
       | Xor( _, l ) :: rst
       | Rotl( _, l ) :: rst
       | Rotr( _, l ) :: rst
       | Cmp( _, l ) :: rst
       | Jp( l ) :: rst
       | Je( l ) :: rst
       | Jne( l ) :: rst
       | Jg( l ) :: rst
       | Jge( l ) :: rst
       | Jl( l ) :: rst
       | Jle( l ) :: rst
       | Call( l ) :: rst
       | Writechar( l ) :: rst -> verifyLabel pc l; loop pc rst
       | _ :: rst -> loop pc rst
       | [] -> ()
   in
   loop pc ir
;;

(* XXX: Make this work.  Has to figure out whether we need a follow flag word
 * and such.  Ugh. *)
let instructionSize ir =
   0
;;

(* This replaces every undefined symbol with a defined one *)
let resolveAddresses pc ir =
   ()
;;

(* This turns every Lbl or Constant value into an Int value *)
let substituteAddresses pc ir =
   ()
;;

let semanticCheck ir =
   let pc = newProgramContext in
   let pc = populateSymtbl pc ir in
   verifyLabels pc ir;
   let pc = resolveAddresses pc ir in
   pc
;;

(***************************************************************************)
(* Now I guess we might as well do the actual assembly. *)
let stripDirectives ir =
   ()
;;

let instruction_of_ir ir =
   ()
;;

(* Will actually return a list of one or two int32's *)
let opcode_of_instruction i =
   ()
;;
