.PHONY: all clean

all: src/libz3.jl

src/libz3.jl:
	julia generator.jl

clean:
	rm -f src/libz3.jl
