
#include <iostream>
#include "hello_world.hpp"

void say_hello() {
	std::cout << "Hello, world!" << std::endl;
}

/**
 * Run the example.
 */
int main(int argc, char * argv[]) {
	say_hello();
	return 1;
}
