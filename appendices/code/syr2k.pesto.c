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
#include "syr2k.pesto.trahrhe.n0.g0.h"
#include "syr2k.pesto.trahrhe.n0.g1.h"
/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* syr2k.c: this file is part of PolyBench/C */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "syr2k.h"

/* Array initialization. */
static void init_array(int n, int m, DATA_TYPE *alpha, DATA_TYPE *beta, DATA_TYPE POLYBENCH_2D(C, N, N, n, n),
					   DATA_TYPE POLYBENCH_2D(A, N, M, n, m), DATA_TYPE POLYBENCH_2D(B, N, M, n, m)) {
	int i, j;

	*alpha = 1.5;
	*beta = 1.2;
	for (i = 0; i < n; i++)
		for (j = 0; j < m; j++) {
			A[i][j] = (DATA_TYPE)((i * j + 1) % n) / n;
			B[i][j] = (DATA_TYPE)((i * j + 2) % m) / m;
		}
	for (i = 0; i < n; i++)
		for (j = 0; j < n; j++) {
			C[i][j] = (DATA_TYPE)((i * j + 3) % n) / m;
		}
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n, DATA_TYPE POLYBENCH_2D(C, N, N, n, n)) {
	int i, j;

	POLYBENCH_DUMP_START;
	POLYBENCH_DUMP_BEGIN("C");
	for (i = 0; i < n; i++)
		for (j = 0; j < n; j++) {
			if ((i * n + j) % 20 == 0)
				fprintf(POLYBENCH_DUMP_TARGET, "\n");
			fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, C[i][j]);
		}
	POLYBENCH_DUMP_END("C");
	POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_syr2k(int n, int m, DATA_TYPE alpha, DATA_TYPE beta, DATA_TYPE POLYBENCH_2D(C, N, N, n, n),
						 DATA_TYPE POLYBENCH_2D(A, N, M, n, m), DATA_TYPE POLYBENCH_2D(B, N, M, n, m)) {
	int i, j, k;

	// BLAS PARAMS
	// UPLO  = 'L'
	// TRANS = 'N'
	// A is NxM
	// B is NxM
	// C is NxN

	long int lbp;
	long int ubp;
	long int lbv;
	long int ubv;
	long int t2;
	long int t3;
	long int t4;
	long int t5;
	long int t6;
	long int t7;
	long int t1;
	long int g0_t5_pcmax;
	long int g0_TARGET_VOL_L0;
	long int g0_ubt2;
	long int g0_lbt5;
	long int g0_ubt5;
	long int g0_t6_pcmax;
	long int g0_TARGET_VOL_L1;
	long int g0_ubt3;
	long int g0_lbt6;
	long int g0_ubt6;
	long int g0_t7_pcmax;
	long int g0_TARGET_VOL_L2;
	long int g0_ubt4;
	long int g0_lbt7;
	long int g0_ubt7;
	long int g1_t4_pcmax;
	long int g1_TARGET_VOL_L0;
	long int g1_ubt2;
	long int g1_lbt4;
	long int g1_ubt4;
	long int g1_t5_pcmax;
	long int g1_TARGET_VOL_L1;
	long int g1_ubt3;
	long int g1_lbt5;
	long int g1_ubt5;
	g1_ubt2 = DIV0 - 1;
	g1_t4_pcmax = n0_g1_t4_Ehrhart(_PB_N, _PB_M);
	g1_TARGET_VOL_L0 = g1_t4_pcmax / DIV0;
	lbp = 0;
	ubp = g1_ubt2;
#pragma omp parallel for firstprivate(g1_ubt2, g1_t4_pcmax, g1_TARGET_VOL_L0) private(                                 \
		lbv, ubv, t3, t4, t5, t6, t7, g1_lbt4, g1_ubt4, g1_ubt3, g1_t5_pcmax, g1_TARGET_VOL_L1, g1_lbt5, g1_ubt5)
	for (t2 = lbp; t2 <= ubp; t2++) {
		g1_lbt4 = n0_g1_t4_trahrhe_n0_g1_t4(max(1, (t2)*g1_TARGET_VOL_L0), _PB_N, _PB_M);
		g1_ubt4 = n0_g1_t4_trahrhe_n0_g1_t4(min(g1_t4_pcmax, (t2 + 1) * g1_TARGET_VOL_L0), _PB_N, _PB_M) - 1;
		if (t2 == g1_ubt2) {
			g1_ubt4 = _PB_N - 1;
		};
		g1_ubt3 = DIV1 - 1;
		g1_t5_pcmax = n0_g1_t5_Ehrhart(_PB_N, _PB_M, g1_lbt4, g1_ubt4);
		g1_TARGET_VOL_L1 = g1_t5_pcmax / DIV1;
		for (t3 = 0; t3 <= g1_ubt3; t3++) {
			g1_lbt5 = n0_g1_t5_trahrhe_n0_g1_t5(max(1, (t3)*g1_TARGET_VOL_L1), _PB_N, _PB_M, g1_lbt4, g1_ubt4);
			g1_ubt5 = n0_g1_t5_trahrhe_n0_g1_t5(min(g1_t5_pcmax, (t3 + 1) * g1_TARGET_VOL_L1), _PB_N, _PB_M, g1_lbt4,
												g1_ubt4) -
					  1;
			if (t3 == g1_ubt3) {
				g1_ubt5 = g1_ubt4;
			};
			for (t4 = g1_lbt4; t4 <= min(_PB_N - 1, g1_ubt4); t4++) {
				lbv = g1_lbt5;
				ubv = min(t4, g1_ubt5);
#pragma GCC ivdep
				for (t5 = lbv; t5 <= ubv; t5++) {
					C[t4][t5] *= beta;
					;
				}
			}
		}
	}
	g0_ubt2 = DIV0 - 1;
	g0_t5_pcmax = n0_g0_t5_Ehrhart(_PB_N, _PB_M);
	g0_TARGET_VOL_L0 = g0_t5_pcmax / DIV0;
	lbp = 0;
	ubp = g0_ubt2;
#pragma omp parallel for firstprivate(g0_ubt2, g0_t5_pcmax, g0_TARGET_VOL_L0) private(                                 \
		lbv, ubv, t3, t4, t5, t6, t7, g0_lbt5, g0_ubt5, g0_ubt3, g0_t6_pcmax, g0_TARGET_VOL_L1, g0_lbt6, g0_ubt6,      \
			g0_ubt4, g0_t7_pcmax, g0_TARGET_VOL_L2, g0_lbt7, g0_ubt7)
	for (t2 = lbp; t2 <= ubp; t2++) {
		g0_lbt5 = n0_g0_t5_trahrhe_n0_g0_t5(max(1, (t2)*g0_TARGET_VOL_L0), _PB_N, _PB_M);
		g0_ubt5 = n0_g0_t5_trahrhe_n0_g0_t5(min(g0_t5_pcmax, (t2 + 1) * g0_TARGET_VOL_L0), _PB_N, _PB_M) - 1;
		if (t2 == g0_ubt2) {
			g0_ubt5 = _PB_N - 1;
		};
		g0_ubt3 = DIV1 - 1;
		g0_t6_pcmax = n0_g0_t6_Ehrhart(_PB_N, _PB_M, g0_lbt5, g0_ubt5);
		g0_TARGET_VOL_L1 = g0_t6_pcmax / DIV1;
		for (t3 = 0; t3 <= g0_ubt3; t3++) {
			g0_lbt6 = n0_g0_t6_trahrhe_n0_g0_t6(max(1, (t3)*g0_TARGET_VOL_L1), _PB_N, _PB_M, g0_lbt5, g0_ubt5);
			g0_ubt6 = n0_g0_t6_trahrhe_n0_g0_t6(min(g0_t6_pcmax, (t3 + 1) * g0_TARGET_VOL_L1), _PB_N, _PB_M, g0_lbt5,
												g0_ubt5) -
					  1;
			if (t3 == g0_ubt3) {
				g0_ubt6 = g0_ubt5;
			};
			g0_ubt4 = DIV2 - 1;
			g0_t7_pcmax = n0_g0_t7_Ehrhart(_PB_N, _PB_M, g0_lbt5, g0_ubt5, g0_lbt6, g0_ubt6);
			g0_TARGET_VOL_L2 = g0_t7_pcmax / DIV2;
			for (t4 = 0; t4 <= g0_ubt4; t4++) {
				g0_lbt7 = n0_g0_t7_trahrhe_n0_g0_t7(max(1, (t4)*g0_TARGET_VOL_L2), _PB_N, _PB_M, g0_lbt5, g0_ubt5,
													g0_lbt6, g0_ubt6);
				g0_ubt7 = n0_g0_t7_trahrhe_n0_g0_t7(min(g0_t7_pcmax, (t4 + 1) * g0_TARGET_VOL_L2), _PB_N, _PB_M,
													g0_lbt5, g0_ubt5, g0_lbt6, g0_ubt6) -
						  1;
				if (t4 == g0_ubt4) {
					g0_ubt7 = _PB_M - 1;
				};
				for (t5 = g0_lbt5; t5 <= min(_PB_N - 1, g0_ubt5); t5++) {
					for (t6 = g0_lbt6; t6 <= min(t5, g0_ubt6); t6++) {
						for (t7 = g0_lbt7; t7 <= min(_PB_M - 1, g0_ubt7); t7++) {
							C[t5][t6] += A[t6][t7] * alpha * B[t5][t7] + B[t6][t7] * alpha * A[t5][t7];
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
	int m = M;

	/* Variable declaration/allocation. */
	DATA_TYPE alpha;
	DATA_TYPE beta;
	POLYBENCH_2D_ARRAY_DECL(C, DATA_TYPE, N, N, n, n);
	POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, N, M, n, m);
	POLYBENCH_2D_ARRAY_DECL(B, DATA_TYPE, N, M, n, m);

	/* Initialize array(s). */
	init_array(n, m, &alpha, &beta, POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B));

	/* Start timer. */
	polybench_start_instruments;

	/* Run kernel. */
	kernel_syr2k(n, m, alpha, beta, POLYBENCH_ARRAY(C), POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(B));

	/* Stop and print timer. */
	polybench_stop_instruments;
	polybench_print_instruments;

	/* Prevent dead-code elimination. All live-out data must be printed
	   by the function call in argument. */
	polybench_prevent_dce(print_array(n, POLYBENCH_ARRAY(C)));

	/* Be clean. */
	POLYBENCH_FREE_ARRAY(C);
	POLYBENCH_FREE_ARRAY(A);
	POLYBENCH_FREE_ARRAY(B);

	return 0;
}
