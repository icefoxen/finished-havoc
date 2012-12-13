using System;
using System.IO;
using System.Collections.Generic;

namespace Havoc {
   public class HavocAsm {
      public static void Main() {
         Parser p = new Parser( "test.hasm" );
         List<IrSym> l = p.Parse();
         foreach( IrSym s in l ) {
            Console.WriteLine( s );
         }
      }
   }
}
