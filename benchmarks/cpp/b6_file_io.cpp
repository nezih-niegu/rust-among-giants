// B6: Checkpoint I/O (durable write + read 4GB) — models PyTorch/Flax
// checkpoint save+load pattern. std::ofstream doesn't expose the file
// descriptor needed for fsync, so the write phase drops to POSIX. That's
// the idiomatic C++ workaround and itself a finding worth reporting.
#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>
#include <cstdio>
#include <unistd.h>
#include <fcntl.h>
int main(int argc, char* argv[]) {
    constexpr size_t CHUNK = 1024 * 1024, CHUNKS = 4096;
    const char* fname = argc > 1 ? argv[1] : "../../data/fileio_test_cpp.tmp";
    std::vector<char> buf(CHUNK, 'A');
    {
        int fd = open(fname, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        for (size_t i = 0; i < CHUNKS; i++) write(fd, buf.data(), CHUNK);
        fsync(fd);
        close(fd);
    }
    long long total = 0;
    { std::ifstream f(fname, std::ios::binary);
      while (f.read(buf.data(), CHUNK)) total += f.gcount();
      total += f.gcount(); }
    std::cout << total << "\n";
    std::remove(fname);
}
