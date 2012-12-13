


let _ =
   let i = Lex.lex "test.hasm" in
   Printf.printf "%d\n" (List.length i);
   List.iter (fun x -> Printf.printf "%s\n" (Lex.string_of_lexeme x)) i;
   let j = Parse.parse i in
   List.iter (fun x -> print_endline (Ir.string_of_opr x)) j;
;;
