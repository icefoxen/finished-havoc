

open Ir
open Instruction
open Lex

exception ParseException of int * string

let parseError line msg =
   raise (ParseException( line, msg ) )
;;

let parseReg line stream =
   if Lex.isStreamEmpty stream then
      parseError line "Incomplete statement, expected reg"
   else
      let tok = Stream.next stream in
      match tok with 
         Register( l, r ) -> Printf.printf "Parsed register\n"; r
       | x -> parseError line (Printf.sprintf "Expected reg, got %s." 
                                              (Lex.string_of_lexeme x))
;;

let parseString line stream =
   if Lex.isStreamEmpty stream then
      parseError line "Incomplete statement, expected string"
   else
      let tok = Stream.next stream in
      match tok with 
         Symbol( l, x ) -> Printf.printf "Parsed string: %s\n" x; x
       | _ -> parseError line "Expected string, got something else."
;;

let parseNumber line stream =
   if Lex.isStreamEmpty stream then
      parseError line "Incomplete statement, expected number"
   else
      let tok = Stream.next stream in
      match tok with 
         Integer( l, x ) -> Printf.printf "Parsed number: %ld\n" x; x
       | _ -> parseError line "Expected number, got something else."
;;

(* Lookahead is a bitch... *)
let parseValue line stream =
   if Lex.isStreamEmpty stream then
      parseError line "Incomplete statement, expected value"
   else
      let tok = Stream.next stream in
      match tok with 
         Pointer( _ ) -> parseError line "Sorry, nesting pointers doesn't work" 
       | Symbol( l, s ) -> Ir.Constant( s )
       | Label( l ) -> Ir.Lbl( parseString line stream )
       | Register( l, r ) -> Ir.Reg( r )
       | Integer( l, x ) -> Ir.Int( x )
;;


let parseLocation line stream =
   if Lex.isStreamEmpty stream then
      parseError line "Incomplete statement, expected reg"
   else
      let tok = Stream.next stream in
      match tok with 
         Symbol( l, s ) -> Location( Ir.Constant( s ) )
       | Label( l ) -> Location( Ir.Lbl( parseString line stream ) )
       | Register( l, r ) -> Location( Ir.Reg( r ) )
       | Integer( l, x ) -> Location( Ir.Int( x ) )
       | Pointer( l ) -> Ir.Dereference( parseValue line stream )
;;


(* Remember kids, the order of evaluation of a function (or constructor!)'s
 * arguments is NOT DEFINED!
 * Wheeee!
 *)
let parseOp line sym stream =
   match sym with
   "load" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Load( reg, loc )
 | "store" -> 
      let loc = parseLocation line stream in
      let reg = parseReg line stream in
      Store( loc, reg )
 | "xchg" -> 
      let reg1 = parseReg line stream in
      let reg2 = parseReg line stream in
      Xchg( reg1, reg2 )
 | "push" -> 
      let reg = parseReg line stream in
      Push( reg )
 | "pop" -> 
      let reg = parseReg line stream in
      Pop( reg )

 | "add" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Add( reg, loc )
 | "sub" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Sub( reg, loc )
 | "mul" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Mul( reg, loc )
 | "div" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Div( reg, loc )
 | "mod" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Mod( reg, loc )

 | "shl" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Shl( reg, loc )
 | "shr" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Shr( reg, loc )
 | "and" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      And( reg, loc )
 | "or" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Or( reg, loc )
 | "not" -> 
      let reg = parseReg line stream in
      Not( reg )
 | "xor" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Xor( reg, loc )
 | "rotl" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Rotl( reg, loc )
 | "rotr" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Rotr( reg, loc )

 | "cmp" -> 
      let reg = parseReg line stream in
      let loc = parseLocation line stream in
      Cmp( reg, loc )
 | "cmpz" -> 
      let loc = parseLocation line stream in
      Cmpz( loc )
 | "jp" -> 
      let loc = parseLocation line stream in
      Jp( loc )
 | "jz" -> 
      let loc = parseLocation line stream in
      Jz( loc )
 | "jnz" -> 
      let loc = parseLocation line stream in
      Jnz( loc )
 | "je" -> 
      let loc = parseLocation line stream in
      Je( loc )
 | "jne" -> 
      let loc = parseLocation line stream in
      Jne( loc )
 | "jl" -> 
      let loc = parseLocation line stream in
      Jl( loc )
 | "jle" -> 
      let loc = parseLocation line stream in
      Jle( loc )
 | "jg" -> 
      let loc = parseLocation line stream in
      Jg( loc )
 | "jge" -> 
      let loc = parseLocation line stream in
      Jge( loc )
 | "call" -> 
      let loc = parseLocation line stream in
      Call( loc )
 | "ret" -> 
      Ret

 | "readchar" -> 
      let reg = parseReg line stream in
      Readchar( reg )
 | "writechar" -> 
      let loc = parseLocation line stream in
      Writechar( loc )

 | "clearf" -> 
      Clearf
 | "setf" -> 
      let reg = parseReg line stream in
      Setf( reg )
 | "halt" -> 
      Halt
 | "nop" -> 
      Nop

 | "label" -> 
      Ir.Label( parseString line stream )
 | "const" -> 
       let name = parseString line stream in
       let num = parseNumber line stream in
      Const( name, num )
 | "alloc" -> 
      Alloc( parseNumber line stream )
 | "allocfill" -> 
       let num1 = parseNumber line stream in
       let num2 = parseNumber line stream in
      AllocFill( num1, num2 ) 
 | x -> parseError line ("Op or directive expected, got " ^ x)
;;

(* Takes stream of lex tokens, spits out a stream of IR directives.
 * We might be able to bypass that step and output shit directly... but, no.  
 *)
let parse l =
   let stream = Stream.of_list l in

   let rec loop accm = 
      if Lex.isStreamEmpty stream then
         accm
      else
         let tok = Stream.next stream in
         match tok with
            Symbol( line, x ) ->
               Printf.printf "Parsed symbol: %s\n" x;
               let s = parseOp line x stream in
               loop (s :: accm)
          | Integer( l, i ) -> parseError l 
          (Printf.sprintf "Symbol expected, got int: %ld" i)
          | Register( l, _ ) -> parseError l "Symbol expected, got reg"
          | Pointer( l ) -> parseError l "Symbol expected, got pointer"
          | Label( l ) -> parseError l "Symbol expected, got label"
   in 
   List.rev (loop [])
;;
