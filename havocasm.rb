#!/usr/bin/env ruby


### Below is pretty much a copy of half of instructions.h and havocvm.h.
#   It should be kept in sync, if those files change.
OPCODES = [
   "load",
   "store",
   "xchg",
   "push",
   "pop",

   "add",
   "sub",
   "mul",
   "div",
   "mod",

   "shl",
   "shr",
   "and",
   "or",
   "not",
   "xor",
   "rotl",
   "rotr",

   "cmp",
   "cmpz",
   "jmp",
   "jz",
   "jnz",
   "je",
   "jne",
   "jl",
   "jle",
   "jg",
   "jge",
   "call",
   "ret",

   "readchar",
   "writechar",

   "clearf",
   "setf",
   "halt",
   "nop"
]


MEMCFLAG   = 0x00000000
REGFLAG    = 0x00000100
CONSTFLAG  = 0x00000200
MEMRFLAG   = 0x00000300

FOLLOWFLAG = 0x00000400


REGISTERS = [
   "ip",
   "cp",
   "dp",
   "fl",

   "r0",
   "r1",
   "r2",
   "r3",
   "r4",
   "r5",
   "r6",
   "r7"
]


###  Below is the actual assembler.


def asmError( line, message )
   print "Error on line ", line, ":\n"
   print message
   exit 1
end

def slurpLines file
   lines = IO.readlines file
   lines = lines.map {|line| line.strip}              # Cut whitespace
   lines = lines.find_all {|line| line[0] != ";"[0]}  # Cut comments
   lines = lines.find_all {|line| line != ""}         # Cut empty lines
   return lines
end

# This takes a line and parses it.
class LineParser
   attr :opcode
   attr :source
   attr :dest
   attr :sourcetype
   attr :desttype
   attr :numargs
   attr :linenum

   def initialize( string, linenum )
      @linenum = linenum
      parseLine( string )
   end

   def parseLine( str )
      parts = str.split
      @numargs = 0
      # If items [1] and [2] don't exist, they just get passed as nil.
      # If parts[0] doesn't exist, you have a problem.
      parseOp( parts[0] )
      parseDest( parts[1] )
      parseSource( parts[2] )
      verify
   end

   def parseOp( str )
      if not str then
         asmError( @linenum, "This is a bug" )
      end
      
      # Is it a label?
      #if str[0] == '@' then

      
      # Is it a data decleration?
      

      # Then it's an opcode!  
      str.downcase!
      code = OPCODES.index( str )
      if not code then
         asmError( @linenum, "Nonexistant opcode " + str )
      end

      @opcode = code
   end

   def getType( str )
      s = str.downcase
      i = REGISTERS.index( s )
      #print "PARSING STRING: ", s, "\n"
      if i then
         return [REGFLAG, i]
      # Character constants!
      elsif s =~ /^\d+$/ then
         return [CONSTFLAG, s.to_i]
      elsif s =~ /^\[\d+\]$/ then
         return [MEMCFLAG, s[1..-2].to_i]
      elsif s =~ /^\[..\]$/ then
         str = s[1..-2]
         #print str, "\n"
         i = REGISTERS.index( str )
         return [MEMRFLAG, i]

      elsif s =~ /^'.\'$/ then
         return [CONSTFLAG, s[1]]
      else
         # XXX: Labels not yet implemented
         asmError( @linenum, "Invalid arg: " + str )
      end
   end

   def parseDest( str )
      if not str then return end
      @numargs += 1
      a = getType( str )
      @desttype = a[0]
      @dest = a[1]
   end

   def parseSource( str )
      if not str then return end
      @numargs += 1
      a = getType( str )
      @sourcetype = a[0]
      @source = a[1]
   end

   def val2asm( val, type )
      if type == MEMCFLAG then
         return "[#{val.to_s}]"
      elsif type == REGFLAG then
         return REGISTERS[val]
      elsif type == MEMRFLAG then
         return "[#{REGISTERS[val]}]"
      else # type == CONSTFLAG
         return val.to_s
      end
   end

   def to_s
      #print @opcode, " ", @dest, " ", @source, "\n"
      opcode = OPCODES[@opcode]
      dest = val2asm( @dest, @desttype )
      src = val2asm( @source, @sourcetype )
      return "#{opcode} #{dest} #{src}"
   end

   # This does all the squidgy error-checking.
   def verify
      # This hacks up a special case.
      # The way the flags work out is this.
      # If there's only one arg, @desttype is used as the
      # flagged location.  If there are two, then @sourcetype
      # is the thing represented in the flag, because the
      # dest is always a register.  Except, if it's a
      # store instruction, then the dest isn't a register,
      # but some sort of memory location, and we need to know
      # what kind.
      # This is all much simpler for the VM than the assembler, honest.
      # Though it's still a special case there...
      if opcode == OPCODES.index( "store" ) then
         @sourcetype = @desttype
         #@desttype = MEMFLAG
         #@sourcetype = MEMFLAG
      end
   end

end


# This represents an actual opcode.  It can take a parser and figure out the
# right values to use, and turn them into an integer.
# data1 is the dest, aka the first argument.  It occupies the leftmost 8 bits.
# data2 is the source/second argument.  It occupies the next 8 bits to the
# right.
class Opcode
   attr :opcode
   attr :locflag
   attr :followflag
   attr :dataseg
   attr :srcdata
   attr :destdata
   attr :followdata
   attr :numargs

   def initialize p
      @opcode = 0
      @locflag = 0
      @followflag = 0
      # Src is the lower byte of the data word,
      # dest is the upper byte.
      @srcdata = 0
      @destdata = 0
      @numargs = 0

      fromParser p
   end

   def fromParser p
      @opcode = p.opcode
      @numargs = p.numargs
      if p.dest then
         @locflag = p.desttype
         if p.dest > 0xFFFF then
            @followflag = FOLLOWFLAG
            @followdata = p.dest
            @destdata = nil
         else
            @destdata = p.dest
         end
      end
      if p.source then
         @locflag = p.sourcetype
         if p.source > 0xFF then
            @followflag = FOLLOWFLAG
            @followdata = p.source
         else
            @srcdata = p.source
         end
      end

   end

   def toNum
      num = 0
      num |= @opcode
      num |= @locflag
      num |= @followflag

      # In the ancient and exalted phrases of programmerdom...
      # HACK HACK HACK!
      dataseg = 0
      if numargs == 1 then
         dataseg = @destdata
         if @locflag == REGFLAG then
            dataseg <<= 8
         end
      elsif numargs == 2 then
         dataseg = (@destdata << 8) | @srcdata
      end 

      num |= (dataseg << 16)

      return num
   end

   def to_s
      return sprintf( "0x%08X", toNum )
   end

end



### This is all I/O stuff.


def writeFile( arr, filename )
   f = File.new( filename, 'w' )
   f.binmode
   arr = words2bytes( arr )
   arr.each { |byte|
      f.write( byte.chr )
   }
   f.close 
end


def words2bytes( arr )
   newarr = []
   arr.each { |word|
      #print word, " ", word.class, "\n"
      newarr << ((word & 0xFF))
      newarr << ((word >> 8) & 0xFF)
      newarr << ((word >> 16) & 0xFF)
      newarr << ((word >> 24) & 0xFF)
   }
   return newarr
end


def assembleLine( str, code, linenum, list=false )
   l = LineParser.new( str, linenum )
   o = Opcode.new( l )
   if list then
      printf( "%20s %12s\n", l, o )
# l, "\t\t", o, "\n"
   end
   code << o.toNum
   if o.followflag != 0 then
      code << o.followdata
   end 
end

# Command-line args


def printHelp
   print "Usage: havocasm.rb <options> FILE\n"
   print "   Options:\n"
   print "  -h or --help   This text\n"
   print "  -l             List opcodes as they are output."
   print "\n\n"
end

def handleCommandLine
   if ARGV.length == 0 or
      ARGV.index( "--help" ) or
      ARGV.index( "-h" ) then
      printHelp
      exit
   end
   infile = ARGV[-1]
   idx = infile.rindex( '.' )
   outfile = infile[0..(idx-1)] + '.hc'
   list = false
   if ARGV.index( "-l" ) then
      list = true
   end

   return [list, infile, outfile]
end
   

def main
   doList, infile, outfile = handleCommandLine
   code = []
   slurpLines( infile ).each_with_index { |x, linenum|
      if x then
         assembleLine( x, code, linenum, doList )
      end
   }
   writeFile( code, outfile )
end
main
