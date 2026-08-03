#include <complex.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef ceild
#define ceild(n, d) (((n) < 0) ? -((-(n)) / (d)) : ((n) + (d) - 1) / (d))
#endif
#ifndef floord
#define floord(n, d) (((n) < 0) ? -((-(n) + (d) - 1) / (d)) : (n) / (d))
#endif
#ifndef max
#define max(x, y) ((x) > (y) ? (x) : (y))
#endif
#ifndef min
#define min(x, y) ((x) < (y) ? (x) : (y))
#endif

/******************************** i_Ehrhart Polynomials
 * ********************************/
static inline long int i_Ehrhart(long int N, long int M) {
  if ((-1 + N >= 0 && -1 + M >= 0)) {
    return (N * M);
  }
  fprintf(stderr,
          "Error i_Ehrhart: no corresponding domain: (,N,M) = (,%ld,%ld)\n", N,
          M);
  exit(1);
} /* end i_Ehrhart */

/******************************** i_Ranking Polynomials
 * ********************************/
static inline long int i_Ranking(long int i, long int j, long int N,
                                 long int M) {
  if ((-1 + i >= 0 && -1 + N - i >= 0 && j >= 0 && -1 + M - j >= 0)) {
    return (((1 + M * i) + j));
  }
  if ((i == 0 && -1 + N >= 0 && j >= 0 && -1 + M - j >= 0)) {
    return ((1 + j));
  }
  fprintf(stderr,
          "Error i_Ranking: no corresponding domain: (i,j,N,M) = "
          "(%ld,%ld,%ld,%ld)\n",
          i, j, N, M);
  exit(1);
} /* end i_Ranking */

/************************************** i_trahrhe_i
 * **************************************/
static inline long int i_trahrhe_i(long int pc, long int N, long int M) {
  long int i;

  if ((((1 + M)) <= pc) && (pc <= (N * M)) && ((-2 + N >= 0 && -1 + M >= 0))) {
    i = floorl(creall(((long double)pc - 1.L) / (long double)M) + 0.00000001);
    if (-1 + M >= 0 && -1 + i >= 0 && -1 + N - i >= 0)
      return i;
  }
  if (((1) <= pc) && (pc <= (M)) && ((-1 + N >= 0 && -1 + M >= 0))) {
    i = 0;
    if (i == 0 && -1 + N >= 0 && -1 + M >= 0)
      return i;
  }
  fprintf(stderr, "Error i_trahrhe_i: no corresponding domain\n");
  exit(1);
}
/******************************** j_Ehrhart Polynomials
 * ********************************/
static inline long int j_Ehrhart(long int N, long int M, long int lbi,
                                 long int ubi) {
  if ((lbi >= 0 && -lbi + ubi >= 0 && -1 + N - ubi >= 0 && -1 + M >= 0)) {
    return (((M + -M * lbi) + M * ubi));
  }
  fprintf(stderr,
          "Error j_Ehrhart: no corresponding domain: (,N,M,lbi,ubi) = "
          "(,%ld,%ld,%ld,%ld)\n",
          N, M, lbi, ubi);
  exit(1);
} /* end j_Ehrhart */

/******************************** j_Ranking Polynomials
 * ********************************/
static inline long int j_Ranking(long int j, long int i, long int N, long int M,
                                 long int lbi, long int ubi) {
  if ((lbi >= 0 && -1 + N - ubi >= 0 && -1 + j >= 0 && -1 + M - j >= 0 &&
       -lbi + i >= 0 && ubi - i >= 0)) {
    return ((((1 - lbi) + ((1 - lbi) + ubi) * j) + i));
  }
  if ((j == 0 && -1 + M >= 0 && lbi >= 0 && -1 + N - ubi >= 0 &&
       -lbi + i >= 0 && ubi - i >= 0)) {
    return (((1 - lbi) + i));
  }
  fprintf(stderr,
          "Error j_Ranking: no corresponding domain: (j,i,N,M,lbi,ubi) = "
          "(%ld,%ld,%ld,%ld,%ld,%ld)\n",
          j, i, N, M, lbi, ubi);
  exit(1);
} /* end j_Ranking */

/************************************** j_trahrhe_j
 * **************************************/
static inline long int j_trahrhe_j(long int pc, long int N, long int M,
                                   long int lbi, long int ubi) {
  long int j;

  if (((((2 - lbi) + ubi)) <= pc) && (pc <= (((M + -M * lbi) + M * ubi))) &&
      ((-2 + M >= 0 && lbi >= 0 && -lbi + ubi >= 0 && -1 + N - ubi >= 0))) {
    j = floorl(creall(((long double)pc - 1.L) /
                      ((long double)ubi - (long double)lbi + 1.L)) +
               0.00000001);
    if (lbi >= 0 && -lbi + ubi >= 0 && -1 + N - ubi >= 0 && -1 + j >= 0 &&
        -1 + M - j >= 0)
      return j;
  }
  if (((1) <= pc) && (pc <= (((1 - lbi) + ubi))) &&
      ((-1 + M >= 0 && lbi >= 0 && -lbi + ubi >= 0 && -1 + N - ubi >= 0))) {
    j = 0;
    if (j == 0 && -1 + M >= 0 && lbi >= 0 && -lbi + ubi >= 0 &&
        -1 + N - ubi >= 0)
      return j;
  }
  fprintf(stderr, "Error j_trahrhe_j: no corresponding domain\n");
  exit(1);
}