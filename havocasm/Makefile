CSC=gmcs

SRC=HavocAsm.cs Instruction.cs Parser.cs Ir.cs Assembler.cs

OUTPUT=havocasm

all: $(OUTPUT) 


.PHONY: clean nuke

clean:
	rm -f *.o
	rm -f *~

nuke: clean
	rm -f HavocAsm.exe

$(OUTPUT): $(OBJ)
	$(CSC) $(SRC)
