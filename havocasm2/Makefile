# Dependancies: Lua, libredblack, pthreads...

SOURCES = instruction.ml lex.ml ir.ml parse.ml main.ml
OBJS = instruction.cmx lex.cmx ir.cmx parse.cmx main.cmx

OCAMLOPT = ocamlopt

FLAGS = 

#SSLPATH=`ocamlfind query ssl`

#LDFLAGS = -I $(SSLPATH) ssl.cmxa unix.cmxa

PROGRAM = havocasm

all: $(PROGRAM)

$(PROGRAM): $(OBJS)
	$(OCAMLOPT) $(LDFLAGS) $(OBJS) -o $(PROGRAM)

$(OBJS): $(SOURCES)
	$(OCAMLOPT) $(FLAGS) -c $(SOURCES)

clean:
	rm -rf *.cmx *.cmi *.o *~

