#include <iostream>
#include <fstream>
#include <string>
#include <regex>
int main(int argc, char* argv[]) {
    std::string filename = argc > 1 ? argv[1] : "../../data/regex_input.txt";
    std::regex re(R"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
    std::ifstream file(filename);
    std::string line;
    int count = 0;
    while (std::getline(file, line)) {
        if (std::regex_search(line, re)) count++;
    }
    std::cout << count << "\n";
}
