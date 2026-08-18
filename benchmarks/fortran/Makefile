# Fortran (gfortran) — MICAI AI suite: b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy.
#
# -ffp-contract=off is REQUIRED, not cosmetic: gfortran defaults to
# -ffp-contract=fast, which fuses a*b+c into a single fused-multiply-add with a
# different rounding than the separate mul+add the interpreted reference uses.
# Turning it off keeps every accumulation bit-identical to the C/Python checksums.
# Architecture flag: Homebrew GCC on Apple Silicon (arm64) rejects -march=native;
# -mcpu=native is the correct host-tuning flag there. x86 uses -march=native.
FC = gfortran
ARCH := $(shell uname -m)
ifneq (,$(filter arm64 aarch64,$(ARCH)))
  ARCHFLAG := -mcpu=native
else
  ARCHFLAG := -march=native
endif
FFLAGS = -O3 $(ARCHFLAG) -ffp-contract=off -std=f2008 -fopenmp -Wall

TARGETS = b1_fibonacci b2_bubble_sort b3_matrix_mul b4_monte_carlo b5_regex b6_file_io b7_concurrent b8_json_parse \
          b9_kmeans b10_knn b11_mlp b12_ga b13_fuzzy

all: $(TARGETS)

%: %.f90
	$(FC) $(FFLAGS) -o $@ $<

clean:
	rm -f $(TARGETS) *.mod

.PHONY: all clean
