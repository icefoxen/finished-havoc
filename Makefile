CC=gcc
CFLAGS=-O3 -Wall

OBJ=instructions.o havocerr.o havocvm.o havocinterp.o havocmain.o
OUTPUT=havoc

all: $(OUTPUT) 


.PHONY: clean nuke

clean:
	rm -f *.o
	rm -f *~

nuke: clean
	rm -f havoc

$(OUTPUT): $(OBJ)
	$(CC) $(CFLAGS) -o $(OUTPUT) $(OBJ)
