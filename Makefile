## -*- mode: makefile-gmake -*-

DIRS	    = lib lisp site-lisp
SUBDIRS     = $(shell find $(DIRS) -maxdepth 2 ! -name .git -type d -print)
LIB_SOURCE  = $(wildcard override/*.el) $(wildcard lib/*.el) \
	      $(wildcard lisp/*.el) $(wildcard site-lisp/*.el)
TARGET	    = $(patsubst %.el,%.elc, $(LIB_SOURCE)) \
              $(patsubst %.el,%.elc, init.el)
EMACS	    = emacs
EMACS_BATCH = $(EMACS) -Q -batch
MY_LOADPATH = -L . $(patsubst %,-L %, $(SUBDIRS))
BATCH_LOAD  = $(EMACS_BATCH) $(MY_LOADPATH)

all: $(TARGET)

compile:
	for i in $(DIRS); do \
		$(BATCH_LOAD) --eval '(batch-byte-recompile-directory 0)' $$i; \
	done

init.elc: init.el
	@rm -f $@
	@echo Compiling file init.el
	@$(BATCH_LOAD) -f batch-byte-compile init.el

%.elc: %.el
	@echo Compiling file $<
	@$(BATCH_LOAD) -f batch-byte-compile $<

clean:
	rm -f *.elc
	find . -name '*.elc' | while read file ; do \
	    if ! test -f $$(echo $$file | sed 's/\.elc$$/.el/'); then \
		echo Removing old file: $$file ; \
		rm $$file ; \
	    fi ; \
	done

### Makefile ends here
