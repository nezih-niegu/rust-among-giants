// B8: JSON Parsing (100MB file) — measures full JSON parse + tree walk.
//
// Uses nlohmann::json (vendored under vendor/json.hpp, MIT-licensed) to
// match the "full-parse" semantics used by the other 8 languages'
// implementations. The previous single-pass byte-scanner implementation
// was ~30x faster but solved a different problem (token counting without
// parsing), making cross-language results incomparable. See README
// §"Known limitations (B8)".
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include "vendor/json.hpp"

using json = nlohmann::json;

struct Stats { long o=0, a=0, s=0, n=0, b=0, nl=0; };

static void count(const json& v, Stats& st) {
    if (v.is_object()) {
        st.o++;
        for (auto it = v.begin(); it != v.end(); ++it) count(it.value(), st);
    } else if (v.is_array()) {
        st.a++;
        for (const auto& el : v) count(el, st);
    } else if (v.is_string())   st.s++;
    else if (v.is_boolean())    st.b++;   // must come before is_number()
    else if (v.is_number())     st.n++;
    else if (v.is_null())       st.nl++;
}

int main(int argc, char* argv[]) {
    std::string fn = argc > 1 ? argv[1] : "../../data/json_input.json";
    std::ifstream f(fn);
    if (!f) { std::cerr << "cannot open " << fn << "\n"; return 1; }
    json root;
    f >> root;
    Stats st;
    count(root, st);
    std::cout << "objects=" << st.o << " arrays=" << st.a << " strings=" << st.s
              << " numbers=" << st.n << " bools=" << st.b << " nulls=" << st.nl << "\n";
    return 0;
}
