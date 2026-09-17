#include <cmrc/cmrc.hpp>

#include <cstddef>
#include <iostream>

#ifndef WEBP_TEST_NS
#error "WEBP_TEST_NS must be defined to the resource library namespace"
#endif

#define CMRC_DECLARE_NS_I(ns) CMRC_DECLARE(ns)
#define CMRC_DECLARE_NS(ns) CMRC_DECLARE_NS_I(ns)
CMRC_DECLARE_NS(WEBP_TEST_NS);

#define WEBP_NS_I(ns) cmrc::ns
#define WEBP_NS(ns) WEBP_NS_I(ns)

static bool is_webp(const char* data, std::size_t size) {
    return size >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F' &&
           data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P';
}

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: webp_embed <resource-path>\n";
        return 2;
    }
    const char* path = argv[1];
    auto fs = WEBP_NS(WEBP_TEST_NS)::get_filesystem();
    if (!fs.is_file(path)) {
        std::cerr << "Embedded webp resource not found: " << path << "\n";
        return 1;
    }
    auto file = fs.open(path);
    if (!is_webp(file.begin(), file.size())) {
        std::cerr << "Embedded resource is not webp (size=" << file.size() << "): " << path << "\n";
        return 1;
    }
    return 0;
}
