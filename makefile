SOURCE_FILES = $(wildcard src/*.asm)
OBJECT_FILES = $(patsubst src/%.asm, bin/%.o, $(SOURCE_FILES))
DEBUG_FLAGS = -g -F dwarf
bin/main : $(OBJECT_FILES)
	gcc $(OBJECT_FILES) -o bin/main -no-pie 

bin/%.o : src/%.asm
	nasm $< -o $@ -f elf64 $(DEBUG_FLAGS)