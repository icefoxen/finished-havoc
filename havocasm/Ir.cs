/* Intermediate representation and such for HavocAsm.
   Necessary, since ideally we want to actually do labels and such.
   So we go from text -> IR+symbol table -> instructions.
*/

using System;

namespace Havoc {
   public enum IR {
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
      NOP,

      /* IR directives */
      Label,
      Alloc,
      AllocFill,
      Const
   }

   public class Location {
      public override string ToString() {
         return "***LOCATION BASE CLASS, SHOULD NEVER HAPPEN***";
      } 
   }


   public class LocReg : Location {
      public REGISTERS loc;
      public LocReg( REGISTERS r ) {
         loc = r;
      }

      public override string ToString() {
         return loc.ToString();
      }
   }

   public class LocMemr : Location { 
      public REGISTERS loc;
      public LocMemr( REGISTERS r ) {
         loc = r;
      }

      public override string ToString() {
         return "^" + loc.ToString();
      }
   }
   
   public class LocMemc : Location {
      public int loc;
      public LocMemc( int r ) {
         loc = r;
      }

      public override string ToString() {
         return "^" + loc.ToString();
      }
   }

   public class LocMeml : Location {
      public string loc;
      public LocMeml( string r ) {
         loc = r;
      }

      public override string ToString() {
         return "^@" + loc.ToString();
      }
   }

   public class LocConst : Location {
      public int loc;
      public LocConst( int r ) {
         loc = r;
      }

      public override string ToString() {
         return loc.ToString();
      }
   }

   public class LocLabel : Location {
      public string loc;
      public LocLabel( string r ) {
         loc = r;
      }

      public override string ToString() {
         return "@" + loc;
      }
   }

   public class IrLoad : IrSym {
      public IrLoad( int l, LocReg to, Location from ) {
         dir = IR.LOAD;
         arg1 = to;
         arg2 = from;
         linenum = l;
      }

      public int InstructionSize() {
         return 0;
      }

      public Instruction Assemble() {
         Instruction i = new Instruction( OP.LOAD );
      }
   }

   // XXX: This'd be a decent place to put in checking.
   // Or, split this into a hojillion classes, one for each
   // IR symbol.
   public class IrSym {
      public IR dir;
      public Location arg1;
      public Location arg2;

      public int linenum;

      public IrSym( IR d, int l ) {
	 dir = d;
	 arg1 = null;
	 arg2 = null;
         linenum = l;
         checkInstr( d, 0 );
      }

      public IrSym( IR d, Location arg, int l ) {
	 dir = d;
	 arg1 = arg;
	 arg2 = null;
         linenum = l;
         checkInstr( d, 1 );
      }

      public IrSym( IR d, Location arga, Location argb, int l ) {
	 dir = d;
	 arg1 = arga;
	 arg2 = argb;
         linenum = l;
         checkInstr( d, 2 );
      }

      public override string ToString() {
         return dir + " " + arg1 + " " + arg2;

      }

      private void error( string text ) {
         Console.WriteLine( "Error on line {0}:", linenum );
         Console.WriteLine( text );
         throw new Exception( text );
      }

      // XXX: Todo: Check argument types!
      private void checkInstr( IR d, int numargs ) {
         if( numargs == 0 ) {
            switch( d ) {
               case IR.CLEARF: return;
               case IR.HALT: return;
               case IR.NOP: return;
               case IR.RET: return;
               default:
                  error( String.Format( 
                           "{0}: Wrong number of args: {1}", d, numargs ) ); 
                  return;
            }
         } else if( numargs == 1 ) {
            switch( d ) {
               case IR.PUSH: return;
               case IR.POP: return;
               case IR.NOT: return;
               case IR.CMPZ: return;
               case IR.JP: return;
               case IR.JZ: return;
               case IR.JNZ: return;
               case IR.JE: return;
               case IR.JNE: return;
               case IR.JL: return;
               case IR.JLE: return;
               case IR.JG: return;
               case IR.JGE: return;
               case IR.CALL: return; 
               case IR.READCHAR: return;
               case IR.WRITECHAR: return; 
               case IR.SETF: return; 
               case IR.Label: return;
               case IR.Alloc: return;
               default:
                  error( String.Format( 
                           "{0}: Wrong number of args: {1}", d, numargs ) ); 
                  return;
            }
         } else if( numargs == 2 ) {
            switch( d ) {
               case IR.LOAD: return;
               case IR.STORE: return;
               case IR.XCHG: return; 
               case IR.ADD: return;
               case IR.SUB: return;
               case IR.MUL: return;
               case IR.DIV: return;
               case IR.MOD: return; 
               case IR.SHL: return;
               case IR.SHR: return;
               case IR.AND: return;
               case IR.OR: return;
               case IR.XOR: return;
               case IR.ROTL: return;
               case IR.ROTR: return; 
               case IR.CMP: return; 
               case IR.AllocFill: return;
               case IR.Const: return;
               default:
                  error( String.Format( 
                           "{0}: Wrong number of args: {1}", d, numargs ) ); 
                  return;
            }
         } else {
                  error( String.Format( 
                           "{0}: Invalid number of args: {1} (This is impossible, btw)", d, numargs ) );
         } 
      } 
   }
}
