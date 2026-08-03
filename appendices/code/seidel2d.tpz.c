
#include <math.h>
#define ceild(n, d) (((n) < 0) ? -((-(n)) / (d)) : ((n) + (d) - 1) / (d))
#define floord(n, d) (((n) < 0) ? -((-(n) + (d) - 1) / (d)) : (n) / (d))
#define max(x, y) (((x) > (y)) ? (x) : (y))
#define min(x, y) (((x) < (y)) ? (x) : (y))
#ifndef DIV0
#define DIV0 8
#endif
#ifndef DIV1
#define DIV1 8
#endif
#ifndef DIV2
#define DIV2 8
#endif
#ifndef DIV3
#define DIV3 8
#endif
#include "seidel-2d.pesto.tpz.trahrhe.n0.h"
#include <omp.h>
/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* seidel-2d.c: this file is part of PolyBench/C */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "seidel-2d.h"

/* Array initialization. */
static void init_array(int n, DATA_TYPE POLYBENCH_2D(A, N, N, n, n)) {
  int i, j;

  for (i = 0; i < n; i++)
    for (j = 0; j < n; j++)
      A[i][j] = ((DATA_TYPE)i * (j + 2) + 2) / n;
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n, DATA_TYPE POLYBENCH_2D(A, N, N, n, n))

{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("A");
  for (i = 0; i < n; i++)
    for (j = 0; j < n; j++) {
      if ((i * n + j) % 20 == 0)
        fprintf(POLYBENCH_DUMP_TARGET, "\n");
      fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, A[i][j]);
    }
  POLYBENCH_DUMP_END("A");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_seidel_2d(int tsteps, int n, DATA_TYPE POLYBENCH_2D(A, N, N, n, n)) {
  int t, i, j;

  long int lbp;
  long int ubp;
  long int lbv;
  long int ubv;
  long int t1;
  long int t2;
  long int t3;
  long int t4;
  long int t5;
  long int t6;
  long int zt1;
  long int lbzt1;
  long int ubzt1;
  long int zt2;
  long int lbzt2;
  long int ubzt2;
  long int zt3;
  long int lbzt3;
  long int ubzt3;
  long int NTHREADS;
  long int tile_offset;
  long int t1_pcmax;
  long int TARGET_VOL_L0;
  long int lbt1;
  long int ubt1;
  long int _tpzlb;
  long int _tpzub;
  long int t2_pcmax;
  long int TARGET_VOL_L1;
  long int lbt2;
  long int ubt2;
  long int t3_pcmax;
  long int TARGET_VOL_L2;
  long int lbt3;
  long int ubt3;
  lbzt1 = 0;
  ubzt1 = ceild((2 * _PB_TSTEPS + _PB_N - 4) - (1), DIV0) - 1;
  NTHREADS = omp_get_max_threads();
  ;
  for (zt1 = lbzt1; zt1 <= ubzt1; zt1++) {
    lbt1 = zt1 * DIV0 + 1;
    ubt1 = min((zt1 + 1) * DIV0 - 1 + 1, 2 * _PB_TSTEPS + _PB_N - 4);
    ;
    t2_pcmax = t2_Ehrhart(_PB_TSTEPS, _PB_N, lbt1, ubt1);
    lbzt2 = 0;
    long int NB = max(floord(t2_pcmax, D1_MIN_VOL), 1);
    if (NB < NTHREADS) {
      ubzt2 = NB - 1;
      TARGET_VOL_L1 = floord(t2_pcmax, NB);
    } else {
      ubzt2 = NB - (NB % NTHREADS) - 1;
      TARGET_VOL_L1 = floord(t2_pcmax, ubzt2 + 1);
    };
    lbp = lbzt2;
    ubp = ubzt2;
#pragma omp parallel for firstprivate(lbp, ubp, lbzt1, ubzt1, lbzt2, ubzt2, lbt1, ubt1, t2_pcmax,                      \
                                          TARGET_VOL_L1) private(t1, t2, t3, zt3, lbzt3, ubzt3, lbt2, ubt2, lbt3,      \
                                                                     ubt3, _tpzlb, _tpzub, tile_offset)
    for (zt2 = lbp; zt2 <= ubp; zt2++) {
      lbt2 = t2_trahrhe_t2(max(zt2 * TARGET_VOL_L1, 1), _PB_TSTEPS, _PB_N, lbt1, ubt1);
      ubt2 = t2_trahrhe_t2(min((zt2 + 1) * TARGET_VOL_L1, t2_pcmax), _PB_TSTEPS, _PB_N, lbt1, ubt1) - 1;
      if (zt2 == ubzt2) {
        ubt2 = _PB_N >= ubt1 + 2 ? ubt1 : (_PB_N + ubt1) / 2 - 1;
      }
      if (ubt2 - lbt2 + 1 < floord(1 * DIV0, 1) && (zt2 != ubzt2) && (ubzt2 > 0)) {
        fprintf(
            stderr,
            "Error: Target volume too small.\n(TARGET_VOL_L1, lbt1, ubt1, lbt2, ubt2) = (%ld, %ld, %ld, %ld, %ld)\n",
            TARGET_VOL_L1, lbt1, ubt1, lbt2, ubt2);
        exit(1);
      }
      tile_offset = max(floord((ubt2 - lbt2) - DIV0, 2), 0);
      ;
      lbzt3 = 0;
      ubzt3 = ceild(_PB_N + ubt1 - 2 - (lbt1 + 1), DIV2);
      ;
      for (zt3 = lbzt3; zt3 <= ubzt3; zt3++) {
        lbt3 = zt3 * DIV2 + lbt1 + 1;
        ubt3 = min((zt3 + 1) * DIV2 + lbt1 + 1 - 1, _PB_N + ubt1 - 2);
        ;
        for (t1 = max(lbt1, 1); t1 <= min(ubt1, 2 * _PB_TSTEPS + _PB_N - 4); t1++) {
          _tpzlb = max(max(t1 + 1 >= 2 * _PB_TSTEPS ? -_PB_TSTEPS + t1 + 1 : t1 - (t1 + 1) / 2 + 1, lbt2),
                       max(t1 + 1 >= 2 * _PB_TSTEPS ? -_PB_TSTEPS + t1 + 1 : t1 - (t1 + 1) / 2 + 1, lbt2) +
                           tile_offset + floord(1 * (t1 - lbt1), 1));
          _tpzub = min(_PB_N >= t1 + 2 ? t1 : (_PB_N + t1) / 2 - 1, ubt2);
          ;
          for (t2 = _tpzlb; t2 <= _tpzub; t2++) {
            ;
            for (t3 = max(lbt3, t1 + 1); t3 <= min(ubt3, t1 + _PB_N - 2); t3++) {
              ;
              A[(-t1 + 2 * t2)][(-t1 + t3)] =
                  (A[(-t1 + 2 * t2) - 1][(-t1 + t3) - 1] + A[(-t1 + 2 * t2) - 1][(-t1 + t3)] +
                   A[(-t1 + 2 * t2) - 1][(-t1 + t3) + 1] + A[(-t1 + 2 * t2)][(-t1 + t3) - 1] +
                   A[(-t1 + 2 * t2)][(-t1 + t3)] + A[(-t1 + 2 * t2)][(-t1 + t3) + 1] +
                   A[(-t1 + 2 * t2) + 1][(-t1 + t3) - 1] + A[(-t1 + 2 * t2) + 1][(-t1 + t3)] +
                   A[(-t1 + 2 * t2) + 1][(-t1 + t3) + 1]) /
                  SCALAR_VAL(9.0);
              ;
            }
          }
        }
      }
    }
    lbp = lbzt2;
    ubp = ubzt2;
#pragma omp parallel for firstprivate(lbp, ubp, lbzt1, ubzt1, lbzt2, ubzt2, lbt1, ubt1, t2_pcmax,                      \
                                          TARGET_VOL_L1) private(t1, t2, t3, zt3, lbzt3, ubzt3, lbt2, ubt2, lbt3,      \
                                                                     ubt3, _tpzlb, _tpzub, tile_offset)
    for (zt2 = lbp; zt2 <= ubp; zt2++) {
      lbt2 = t2_trahrhe_t2(max(zt2 * TARGET_VOL_L1, 1), _PB_TSTEPS, _PB_N, lbt1, ubt1);
      ubt2 = t2_trahrhe_t2(min((zt2 + 1) * TARGET_VOL_L1, t2_pcmax), _PB_TSTEPS, _PB_N, lbt1, ubt1) - 1;
      if (zt2 == ubzt2) {
        ubt2 = _PB_N >= ubt1 + 2 ? ubt1 : (_PB_N + ubt1) / 2 - 1;
      }
      if (ubt2 - lbt2 + 1 < floord(1 * DIV0, 1) && (zt2 != ubzt2) && (ubzt2 > 0)) {
        fprintf(
            stderr,
            "Error: Target volume too small.\n(TARGET_VOL_L1, lbt1, ubt1, lbt2, ubt2) = (%ld, %ld, %ld, %ld, %ld)\n",
            TARGET_VOL_L1, lbt1, ubt1, lbt2, ubt2);
        exit(1);
      }
      tile_offset = max(floord((ubt2 - lbt2) - DIV0, 2), 0);
      ;
      lbzt3 = 0;
      ubzt3 = ceild(_PB_N + ubt1 - 2 - (lbt1 + 1), DIV2);
      ;
      for (zt3 = lbzt3; zt3 <= ubzt3; zt3++) {
        lbt3 = zt3 * DIV2 + lbt1 + 1;
        ubt3 = min((zt3 + 1) * DIV2 + lbt1 + 1 - 1, _PB_N + ubt1 - 2);
        ;
        for (t1 = max(lbt1, 1); t1 <= min(ubt1, 2 * _PB_TSTEPS + _PB_N - 4); t1++) {
          _tpzlb = max(t1 + 1 >= 2 * _PB_TSTEPS ? -_PB_TSTEPS + t1 + 1 : t1 - (t1 + 1) / 2 + 1, lbt2);
          _tpzub = min(min(_PB_N >= t1 + 2 ? t1 : (_PB_N + t1) / 2 - 1, ubt2),
                       max(t1 + 1 >= 2 * _PB_TSTEPS ? -_PB_TSTEPS + t1 + 1 : t1 - (t1 + 1) / 2 + 1, lbt2) +
                           tile_offset + floord(1 * (t1 - lbt1), 1) - 1);
          ;
          for (t2 = _tpzlb; t2 <= _tpzub; t2++) {
            ;
            for (t3 = max(lbt3, t1 + 1); t3 <= min(ubt3, t1 + _PB_N - 2); t3++) {
              ;
              A[(-t1 + 2 * t2)][(-t1 + t3)] =
                  (A[(-t1 + 2 * t2) - 1][(-t1 + t3) - 1] + A[(-t1 + 2 * t2) - 1][(-t1 + t3)] +
                   A[(-t1 + 2 * t2) - 1][(-t1 + t3) + 1] + A[(-t1 + 2 * t2)][(-t1 + t3) - 1] +
                   A[(-t1 + 2 * t2)][(-t1 + t3)] + A[(-t1 + 2 * t2)][(-t1 + t3) + 1] +
                   A[(-t1 + 2 * t2) + 1][(-t1 + t3) - 1] + A[(-t1 + 2 * t2) + 1][(-t1 + t3)] +
                   A[(-t1 + 2 * t2) + 1][(-t1 + t3) + 1]) /
                  SCALAR_VAL(9.0);
              ;
            }
          }
        }
      }
    }
  }
}

int main(int argc, char **argv) {
  /* Retrieve problem size. */
  int n = N;
  int tsteps = TSTEPS;

  /* Variable declaration/allocation. */
  POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, N, N, n, n);

  /* Initialize array(s). */
  init_array(n, POLYBENCH_ARRAY(A));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_seidel_2d(tsteps, n, POLYBENCH_ARRAY(A));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(n, POLYBENCH_ARRAY(A)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(A);

  return 0;
}
