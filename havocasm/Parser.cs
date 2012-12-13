using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Havoc {
   public class Parser {
      private string filename;

      private string[] opstrs;
      private string[] regstrs;



      private void buildOpstrs() {
	 int numOps = (int) IR.Const + 1;
	 opstrs = new string[numOps];

	 Array ops = Enum.GetValues( typeof( IR ) );
	 int i = 0;
	 foreach( IR o in ops ) {
	    opstrs[i] = o.ToString().ToLower();
   	    //Console.WriteLine( opstrs[i] );
	    i++;
	    
	 }
      }

      private void buildRegstrs() {
	 int numRegs = (int) REGISTERS.R7 + 1;
	 regstrs = new string[numRegs];

	 Array regs = Enum.GetValues( typeof( REGISTERS ) );
	 int i = 0;
	 foreach( REGISTERS r in regs ) {
	    regstrs[i] = r.ToString().ToLower();
	    i++;
	    
	 }
      }

      public Parser( string s ) {
	 filename = s;
	 buildOpstrs();
	 buildRegstrs();
      }

      public List<IrSym> Parse() {
	 List<IrSym> instrs = new List<IrSym>();

	 // The using statement makes sure the streamreader closes.
	 // With MAGIC!  Apparently.  Or IDisposable, at least.
         using( StreamReader sr = new StreamReader( filename ) ) {
            string line;
            int lineno = 1;
            while( (line = sr.ReadLine()) != null) {
               line = Decommentify( line );
               line = line.Trim( " \n\t\r".ToCharArray() );
               if( line != String.Empty ) {
                  instrs.Add( ParseLine( Decommentify( line ), lineno ) );
               }
               lineno += 1;
            }
         }
	 return instrs;
      }

      private string Decommentify( String s ) {
	 int i = s.IndexOf( ';' );
	 if( i < 0 ) {
	    return s;
	 } else if( i == 0 ) {
	    return "";
	 } else {
	    return s.Substring( 0, i );
	 }
      }


      private IR ParseOp( string s ) {
	 if( s == "alloc" ) return IR.Alloc;
	 if( s == "allocfill" ) return IR.AllocFill;
	 if( s == "const" ) return IR.Const;
	 if( s == "label" ) return IR.Label;

	 int o = Array.IndexOf( opstrs, s );
	 if( o < 0 ) {
	    Console.WriteLine( "Invalid op!  Hup-blah!  {0}", s );
	    throw (new Exception());
	 } else {
	    return (IR) o;
	 }  
      }

      private REGISTERS ParseReg( string s ) {
	 int r = Array.IndexOf( regstrs, s );
	 if( r < 0 ) {
	    Console.WriteLine( "Invalid register!  Hup-blah!  {0}", s );
	    throw (new Exception());
	 } else {
	    return (REGISTERS) r;
	 }
      }

      private bool IsReg( string s ) {
	 int r = Array.IndexOf( regstrs, s );
         return r > 0;
      }

      private bool IsNum( string s ) {
	 Regex dec = new Regex( @"^-?[0-9]+$" );
	 Regex hex = new Regex( @"^-?0x[0-9a-fA-F]+$" );
	 Regex oct = new Regex( @"^-?0o[0-7]+$" );
	 return (dec.IsMatch( s ) || hex.IsMatch( s ) || oct.IsMatch( s ));
      }

      private int ParseNum( string s ) {
	 Regex dec = new Regex( @"^-?[0-9]+$" );
	 Regex hex = new Regex( @"^0x[0-9a-fA-F]+$" );
	 Regex oct = new Regex( @"^0o[0-7]+$" );
	 if( dec.IsMatch( s ) ) {
	    return Convert.ToInt32( s, 10 );
	 } else if( hex.IsMatch( s ) ) {
	    s = s.Substring( 2 );
	    return Convert.ToInt32( s, 16 );
	 } else if( oct.IsMatch( s ) ) {
	    s = s.Substring( 2 );
	    return Convert.ToInt32( s, 8 );
	 } else {
	    Console.WriteLine( "Invalid number!  Hup-blah!  {0}", s );
	    throw (new Exception());
	 }
      }

      private Location ParseLocation( string s ) {
	 // Register
	 if( IsReg( s ) ) {
	    return new LocReg( ParseReg( s ) );
	 }
	 // Const
	 else if( IsNum( s ) ) {
	    return new LocConst( ParseNum( s ) );
	 }
	 // Mem const
	 else if( s[0] == '^' && IsNum( s.Trim( "^".ToCharArray() ) ) ) {
            return new LocMemc( ParseNum( s.Trim( "^".ToCharArray() ) ) );
	 }
	 // Mem reg
	 else if( s[0] == '^' && IsReg( s.Trim( "^".ToCharArray() ) ) ) {
            return new LocMemr( ParseReg( s.Trim( "^".ToCharArray() ) ) );
	 }
         // Labelled mem const
         else if( s.StartsWith( "^@" ) ) {
            return new LocMeml( s.Trim( "^@".ToCharArray() ) );
         }
	 // Label
         else { //if( s[0] == '@' ) {
	    return new LocLabel( s.Trim( "@".ToCharArray() ) );;
	 }
         /*
	 else {
	    Console.WriteLine( "Invalid location!  Hup-blah!  {0}", s );
	    throw (new Exception());
	 }
         */
	    
      }

      private IrSym ParseLine( String line, int lineno ) {
	 line = line.ToLower();
         string[] items = line.Split( " ".ToCharArray() );
	 string op = "";
	 string arg1 = "";
	 string arg2 = "";

	 switch( items.Length ) {
	    case 3:
	       arg2 = items[2];
	       arg1 = items[1];
	       op = items[0];
	       return 
		  new IrSym( ParseOp( op ), ParseLocation( arg1 ), 
			     ParseLocation( arg2 ), lineno );
	    case 2:
	       arg1 = items[1];
	       op = items[0];
	       return new IrSym( ParseOp( op ), ParseLocation( arg1 ), lineno );
	    case 1:
	       op = items[0];
	       return new IrSym( ParseOp( op ), lineno );
	    default:
	       Console.WriteLine( 
		  "Wrong number of args on line {0}: {1}", lineno, items.Length - 1 );
	       throw (new Exception());
	 }
      }
   }
}
