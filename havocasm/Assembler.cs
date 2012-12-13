/* Okay, this is where we put the machinery to actually do stuff.
   Steps to complete:
   1) Read and parse directives and stick them into a list and symbol table.
   1.5) Detect unused, reused and nonexistant labels.
   2) Go through and count instructions, and find the locations of all labels,
   resolving memory-allocation directives as you go.
   3) Go through and put the locations of all labels into everything
   referencing them.


   Directives:
   Label decleration
   Constant decleration
   Allocate memory
   Allocate and fill memory
*/

using System.Collections.Generic;

namespace Havoc {
   class Assembler {
      private Dictionary<string,int> symtable;

      private const int invalidLoc = -1;
      private int programLength;

      private Assembler( List<IrSym> l ) {
         symtable = new Dictionary<string,int>();
         programLength = 0;
      }

      public int[] MakeItGo( List<IrSym> l ) {
         PopulateSymtable( l );
         VerifySymtable( l );
         FindAddresses( l );
         List<IrSym> newl = ResolveAddresses( l );
         return TurnIntoOpcodes( newl );
      }

      private void PopulateSymtable( List<IrSym> l ) {
      }

      // Check for re-declared, nonexistant and unused labels
      private void VerifySymtable( List<IrSym> l ) {
      }

      // Find and update them in the symbol table, that is.
      private void FindAddresses( List<IrSym> l ) {
      }

      // Go through and replace labels with constant numbers
      private List<IrSym> ResolveAddresses( List<IrSym> l ) {
         return new List<IrSym>();
      }

      private int[] TurnIntoOpcodes( List<IrSym> l ) {
         return new int[5];
      } 
   }
}
