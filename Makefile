all: ext/fuse.so

ext/Makefile:
	sh -c "cd ext && ruby extconf.rb"

ext/fuse.so: ext/Makefile ext/fuse.c
	sh -c "cd ext && make fuse.so"

clean:
	rm -f ext/Makefile ext/fuse.so

test:
	rspec -c spec/*_spec.rb

.PHONY: all clean test
