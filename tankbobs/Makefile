# Simple makefile for Tankbobs
# TODO: remove this hack makefile

CC = gcc
LD = ld
LK = ln -s
LC = luac
RM = rm
CP = cp
LS = ls
WC = wc
FIND = find
EGREP = egrep
ECHO = echo
MKDIR = mkdir

OUTS := `$(shell) $(FIND) . -name \*\.[ocdh]`
TRMS := `$(shell) $(FIND) . -name \*\.trm`
SERVEROBJS := `$(FIND) ./src/server -name \*\.lua`
CLIENTOBJS := `$(shell) $(FIND) ./src/client -name \*\.lua`
COMMONOBJS := ./src/common/common.lua `$(shell) $(FIND) ./src/common -name \*\.lua` # common.lua needs to be firrst
COMMONSRCS := `$(shell) $(FIND) ./src/common -name m_\*\.c`
COMMONPPSRCS := `$(shell) $(FIND) ./src/common -name m_\*\.cpp`
SHAREDSRCS := `$(shell) $(FIND) ./src/common -name \*\.c | $(EGREP) -v "m_"`
SHAREDOBJS := `$(shell) $(FIND) ./src/common -name \*\.o | $(EGREP) -v "m_"`
COMMONOUTS := `$(shell) $(FIND) ./src/common -name m_\*\.o`
LIBSRCS    := `$(shell) $(FIND) ./src/lib    -name \*\.c`
LIBOBJS    := `$(shell) $(FIND) ./src/lib    -name \*\.o`
SERVER     := `$(shell) $(FIND) ./src/server -name \*\.c`
CLIENT     := `$(shell) $(FIND) ./src/client -name \*\.c`
TSTROBJS   := `$(shell) $(FIND) ./src/lib/tstr   -name \*\.o`
TRMC       := `$(shell) $(FIND) ./src/trmc   -name \*\.c`
SRCS       := `$(shell) $(FIND) ./src        -name \*\.c` `$(shell) $(FIND) ./src -name \*\.h` `$(shell) $(FIND) ./src -name \*\.lua` [Mm]akefile

DLLFLAGS := -fpic -shared-libgcc -shared
LDDLLFLAGS := -shared
MODULEFLAGS := -R./ -G
CCMODULEFLAGS := -shared
CFLAGS := -Wall -pedantic -pedantic-errors -Werror `sdl-config --cflags` `freetype-config --cflags`
OBJFLAGS := -c
ifeq ($(DEBUG),1)
    CFLAGS := $(CFLAGS) -g -D TDEBUG
    LFLAGS := 
    RMMAKEFILE := [Mm]akefile
    RMOUTS := 
    RMSERVEROBJS := 
    RMCLIENTOBJS := 
    RMCOMMONOBJS := 
    RMTRMS := 
    RMDATASRC := 
    RMSRC := 
else
    CFLAGS := $(CFLAGS) -ansi -O2
    LFLAGS := -s
    RMMAKEFILE := [Mm]akefile
    RMOUTS := $(OUTS)
    RMSERVEROBJS := $(SERVEROBJS)
    RMCLIENTOBJS := $(CLIENTOBJS)
    RMCOMMONOBJS := $(COMMONOBJS)
    RMTRMS := $(TRMS)
    RMDATASRC := -r data-src
    RMSRC := -r src
endif
INCLUDES := -I./src/lib -I./src/lib/tstr -I./src/common -I/usr/include/lua5.1
SERVERINCLUDES := -I./src/server
CLIENTINCLUDES := -I./src/client
LIBS := -L. -llua5.1 -lSDL -lSDL_mixer -lSDL_image -lfreetype -lGL -lGLU  -lz

prep :
	`$(shell) if [ -d "./build" ]; then $(RM) -r ./build; fi`
	$(MKDIR) build
	for FILE in `$(LS) -rA | $(EGREP) -v "^build$$"`; do $(CP) --preserve=all -R $${FILE} ./build/$${FILE}; done
	make -C ./build/ tankbobs
	make -C ./build/ suff

suff :
	if ! $(RM) $(RMMAKEFILE); then $(ECHO) -ne; fi
	if ! $(RM) $(RMOUTS); then $(ECHO) -ne; fi
	if ! $(RM) $(RMSERVEROBJS); then $(ECHO) -ne; fi
	if ! $(RM) $(RMCLIENTOBJS); then $(ECHO) -ne; fi
	if ! $(RM) $(RMCOMMONOBJS); then $(ECHO) -ne; fi
	if ! $(RM) $(RMTRMS); then $(ECHO) -ne; fi
	if ! $(RM) $(RMDATASRC); then $(ECHO) -ne; fi
	if ! $(RM) $(RMSRC); then $(ECHO) -ne; fi

trmc : tstr
	$(CC) $(CFLAGS) $(INCLUDES) -o trmc $(TRMC)

tstr :
	$(CC) -o tstr.so $(DLLFLAGS) $(CFLAGS) $(INCLUDES) $(SHAREDSRCS) $(LIBSRCS)

tankbobslib : tstr
	$(CC) -o tankbobs.so $(CCMODULEFLAGS) $(CFLAGS) $(INCLUDES) $(COMMONSRCS) $(SHAREDSRCS) $(LIBSRCS) $(LIBS)

tcm : trmc
	./trmc $(TRMS)

server : tstr
	$(LC) $(LFLAGS) -o ./server $(SERVEROBJS) $(COMMONOBJS)
	$(CC) $(CFLAGS) $(INCLUDES) $(SERVERINCLUDES) -o tankbobs-server $(SERVER) $(SHAREDSRCS) $(LIBS)

client : tstr
	$(LC) $(LFLAGS) -o ./client $(CLIENTOBJS) $(COMMONOBJS)
	$(CC) $(CFLAGS) $(INCLUDES) $(CLIENTINCLUDES) -o tankbobs $(CLIENT) $(SHAREDSRCS) $(LIBS)

tankbobs : tcm server client tankbobslib

all : prep

clean :
	`$(shell) if [ -d "./build" ]; then $(RM) -r ./build; fi`

count :
	$(WC) -c $(SRCS)
	$(WC) -w $(SRCS)
	$(WC) -m $(SRCS)
	$(WC) -L $(SRCS)
	$(WC) -l $(SRCS)

love :
	@echo $(SHAREDSRCS)
	@echo $(COMMONSRCS)
