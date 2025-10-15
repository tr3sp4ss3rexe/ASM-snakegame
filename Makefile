# Makefile for the Snake lab.
# This is a modified version of the nibbles 
# lab by Simon Kågström and Håkan Grahn
#
# Author: Christoffer Åleskog

all: snake_asm snake_asm_start

# Rule for compiling C source
.c.o:
	gcc -Os -Wall -g -c $<

# Rule for compiling assembly source
snake.o: snake.asm
	gcc -Os -Wall -g -x assembler -c $< -o $@
start.o: start.asm
	gcc -Os -Wall -g -x assembler -c $< -o $@

# ASM game
snake_asm: main.o snake.o helpers.o
	gcc $^ -o $@ -lncursesw -ltinfo

# ASM game
snake_asm_start: start.o snake.o helpers.o workaround.o
	gcc $^ -o $@ -lncursesw -ltinfo -lc -nostdlib

clean:
	rm -f *~
	rm -f *.o
	rm -f snake snake_asm
