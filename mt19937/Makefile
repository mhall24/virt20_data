CPPFLAGS	= -I /usr/local/src/boost_1_61_0/ -g

default: run

generate: generate.cpp
	g++ $(CPPFLAGS) -o generate generate.cpp

.PHONY: run
run: generate
	./generate

.PHONY: clean
clean:
	rm -f generate
	rm -f mt19937_states.dat
