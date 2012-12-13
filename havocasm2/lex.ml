open Instruction

(* Filename, line, message *)
exception LexException of string * int * string

type lex_context = {
   filename : string;
   line : int;
}

let newLexContext filename = {
   filename = filename;
   line = 0;
};;

let incLine lc = {
   filename = lc.filename;
   line = lc.line + 1;
};;

let lexError lc msg =
   raise (LexException( lc.filename, lc.line, msg ))
;;

type lexeme = 
   (* Line numbers! *)
   Symbol of int * string
 | Integer of int * int32
 | Register of int * reg
 | Label of int
 | Pointer of int
;;


let string_of_lexeme = function
   Symbol( l, name ) -> Printf.sprintf "Symbol( %d, %s )" l name
 | Integer( l, i ) -> Printf.sprintf "Integer( %d, %ld )" l i
 | Register( l, r ) -> Printf.sprintf "Register( %d, %s )" l (string_of_reg r)
 | Label( l ) -> Printf.sprintf "Label( %d )" l
 | Pointer( l ) -> Printf.sprintf "Pointer( %d )" l
;;

let reg_of_string = function
   "ip" -> IP
 | "cp" -> CP
 | "dp" -> DP
 | "fl" -> FL

 | "r0" -> R0
 | "r1" -> R1
 | "r2" -> R2
 | "r3" -> R3
 | "r4" -> R4
 | "r5" -> R5
 | "r6" -> R6
 | "r7" -> R7
 | x -> raise (Failure( "reg_of_string" ))
;;

let isReg = function
   "ip" 
 | "cp" 
 | "dp"
 | "fl" 
 | "r0" 
 | "r1" 
 | "r2" 
 | "r3" 
 | "r4" 
 | "r5" 
 | "r6" 
 | "r7"  -> true
 | _ -> false
;;


let string_of_list lst =
   let a = Array.of_list lst in
   let s = String.create (Array.length a) in
   Array.iteri (fun i c -> s.[i] <- c) a;
   s
;;

let isStreamEmpty s =
   match Stream.peek s with
      Some( n ) -> false
    | None -> true
;; 


(* XXX: Might explode on mac-format newlines *)
let eatComment stream =
   while (Stream.next stream) != '\n' do
      ()
   done
;;

let isDigit x =
   match x with 
      '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' |
      'a' | 'b' | 'c' | 'd' | 'e' | 'f' |
      'A' | 'B' | 'C' | 'D' | 'E' | 'F' |
      'o' | 'x' | '-' -> true
    | _ -> false
;;


let isNewline chr =
   chr = '\n'
;;

let isWhitespace chr =
   (chr = ' ') or (chr = '\n') or (chr = '\t') or (chr = '\r') 
;;


(* Huzzah for OCaml doing number parsing exactly the way I want to. *)
let getNumber lc initial stream =
   let rec loop accm =
      if isStreamEmpty stream then
         (lc, accm)
      else
         let n = Stream.next stream in
         (if isDigit n then
            loop (n :: accm)
         else if isNewline n then
            ((incLine lc), accm)
         else
            (lc, accm))
   in
   let lc, res = loop [initial] in
   let l = List.rev res in 
   (lc, Integer( lc.line,  Int32.of_string (string_of_list l) ))
;;

let getSymbol lc initial stream =
   let rec loop accm =
      if isStreamEmpty stream then
         (lc, accm)
      else 
         let c = Stream.next stream in
         if isNewline c then
            ((incLine lc), accm)
         else if isWhitespace c then
            (lc, accm)
         else
            loop (c :: accm)
   in
   let lc, l = loop [initial] in
   let s = string_of_list (List.rev l) in
   if isReg s then
      (lc, Register( lc.line, reg_of_string s ))
   else
      (lc, Symbol( lc.line, s ))
;;

let isStreamEmpty s =
   match Stream.peek s with
      Some( n ) -> false
    | None -> true
;;

let lex filename =
   let f = open_in filename in
   let stream = Stream.of_channel f in
   let rec loop lc accm =
      if isStreamEmpty stream then
         accm
      else
         let c = Stream.next stream in
         match c with
         (* Eat whitespace *)
         ' ' | '\t' | '\r' -> loop lc accm
       | '\n' -> loop (incLine lc) accm
         (* Special symbols *)
       | '^' -> loop lc ((Pointer( lc.line )) :: accm)
       | '@' -> loop lc ((Label( lc.line )) :: accm)
         (* comments *)
       | ';' -> eatComment stream; loop (incLine lc) accm
         (* numbers *)
       | '-' | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ->
             let lc, n = getNumber lc c stream in
             loop lc (n :: accm) 
         (* Registers/symbols *)
       | x -> let lc, n = getSymbol lc x stream in
              loop lc (n :: accm)
   in
   List.rev (loop (newLexContext filename) [])
;;
