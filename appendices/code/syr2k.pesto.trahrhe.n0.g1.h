#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>

#ifndef ceild
#define ceild(n,d)  (((n)<0) ? -((-(n))/(d)) : ((n)+(d)-1)/(d))
#endif
#ifndef floord
#define floord(n,d) (((n)<0) ? -((-(n)+(d)-1)/(d)) : (n)/(d))
#endif
#ifndef max
#define max(x,y)    ((x) > (y)? (x) : (y))
#endif
#ifndef min
#define min(x,y)    ((x) < (y)? (x) : (y))
#endif

/******************************** n0_g1_t4_Ehrhart Polynomials ********************************/
static inline long int n0_g1_t4_Ehrhart(long int _PB_N,long int _PB_M)
{
    if((-1 + _PB_M >= 0 && -1 + _PB_N >= 0) )
    {
        return (((_PB_N + _PB_N*_PB_N))/2) ;
    }
    fprintf(stderr,"Error n0_g1_t4_Ehrhart: no corresponding domain: (,_PB_N,_PB_M) = (,%ld,%ld)\n",_PB_N,_PB_M);
    exit(1);
}  /* end n0_g1_t4_Ehrhart */

/******************************** n0_g1_t4_Ranking Polynomials ********************************/
static inline long int n0_g1_t4_Ranking(long int n0_g1_t4,long int n0_g1_t5,long int _PB_N,long int _PB_M)
{
    if((-1 + _PB_M >= 0 && -1 + n0_g1_t4 >= 0 && -1 + _PB_N - n0_g1_t4 >= 0 && n0_g1_t5 >= 0 && n0_g1_t4 - n0_g1_t5 >= 0) )
    {
        return ((((2 + n0_g1_t4 + n0_g1_t4*n0_g1_t4) + 2 * n0_g1_t5))/2) ;
    }
    if((-1 + _PB_M >= 0 && -1 + _PB_N - n0_g1_t4 >= 0 && n0_g1_t5 >= 0 && n0_g1_t4 - n0_g1_t5 >= 0 && -n0_g1_t4 >= 0) )
    {
        return ((1 + n0_g1_t5)) ;
    }
    fprintf(stderr,"Error n0_g1_t4_Ranking: no corresponding domain: (n0_g1_t4,n0_g1_t5,_PB_N,_PB_M) = (%ld,%ld,%ld,%ld)\n",n0_g1_t4,n0_g1_t5,_PB_N,_PB_M);
    exit(1);
}  /* end n0_g1_t4_Ranking */

/************************************** n0_g1_t4_trahrhe_n0_g1_t4 **************************************/
static inline long int n0_g1_t4_trahrhe_n0_g1_t4(long int pc,long int _PB_N,long int _PB_M)
{
	long int n0_g1_t4, n0_g1_t5;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    n0_g1_t4 = 0;

    upper_bound = _PB_N - 1;
    fixed_upper_bound = _PB_N - 1;

	while (n0_g1_t4+1 < upper_bound)
	{
		m = (n0_g1_t4 + upper_bound)/2;

    n0_g1_t5 = 0;

		rank = n0_g1_t4_Ranking(m, n0_g1_t5, _PB_N, _PB_M);

		if (rank <= pc) {
			n0_g1_t4 = m;
		} else {
			upper_bound = m;
		}
	}
	if (n0_g1_t4+1==fixed_upper_bound) {
		m=n0_g1_t4+1;

    n0_g1_t5 = 0;
		rank = n0_g1_t4_Ranking(m, n0_g1_t5, _PB_N, _PB_M);
		if (rank<=pc) n0_g1_t4++;
	}
	return n0_g1_t4;
}
/******************************** n0_g1_t5_Ehrhart Polynomials ********************************/
static inline long int n0_g1_t5_Ehrhart(long int _PB_N,long int _PB_M,long int lbn0_g1_t4,long int ubn0_g1_t4)
{
    if((-1 + _PB_M >= 0 && -lbn0_g1_t4 + ubn0_g1_t4 >= 0 && lbn0_g1_t4 >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0) )
    {
        return ((((2 - lbn0_g1_t4 - lbn0_g1_t4*lbn0_g1_t4) + 3 * ubn0_g1_t4 + ubn0_g1_t4*ubn0_g1_t4))/2) ;
    }
    fprintf(stderr,"Error n0_g1_t5_Ehrhart: no corresponding domain: (,_PB_N,_PB_M,lbn0_g1_t4,ubn0_g1_t4) = (,%ld,%ld,%ld,%ld)\n",_PB_N,_PB_M,lbn0_g1_t4,ubn0_g1_t4);
    exit(1);
}  /* end n0_g1_t5_Ehrhart */

/******************************** n0_g1_t5_Ranking Polynomials ********************************/
static inline long int n0_g1_t5_Ranking(long int n0_g1_t5,long int n0_g1_t4,long int _PB_N,long int _PB_M,long int lbn0_g1_t4,long int ubn0_g1_t4)
{
    if((-1 + _PB_M >= 0 && lbn0_g1_t4 >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0 && -2 - lbn0_g1_t4 + n0_g1_t5 >= 0 && -n0_g1_t5 + n0_g1_t4 >= 0 && ubn0_g1_t4 - n0_g1_t4 >= 0) )
    {
        return (((((2 - lbn0_g1_t4 - lbn0_g1_t4*lbn0_g1_t4) + (1 + 2 * ubn0_g1_t4) * n0_g1_t5 - n0_g1_t5*n0_g1_t5) + 2 * n0_g1_t4))/2) ;
    }
    if((-1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0 && -1 + n0_g1_t5 >= 0 && -1 + lbn0_g1_t4 - n0_g1_t5 >= 0 && -lbn0_g1_t4 + n0_g1_t4 >= 0 && -n0_g1_t5 + n0_g1_t4 >= 0 && ubn0_g1_t4 - n0_g1_t4 >= 0) )
    {
        return ((((1 - lbn0_g1_t4) + ((1 - lbn0_g1_t4) + ubn0_g1_t4) * n0_g1_t5) + n0_g1_t4)) ;
    }
    if((-1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0 && -1 + n0_g1_t5 >= 0 && 1 + lbn0_g1_t4 - n0_g1_t5 >= 0 && -lbn0_g1_t4 + n0_g1_t4 >= 0 && -n0_g1_t5 + n0_g1_t4 >= 0 && ubn0_g1_t4 - n0_g1_t4 >= 0 && -lbn0_g1_t4 + n0_g1_t5 >= 0 && lbn0_g1_t4 >= 0) )
    {
        return (((1 + (-lbn0_g1_t4 + ubn0_g1_t4) * n0_g1_t5) + n0_g1_t4)) ;
    }
    if((n0_g1_t5 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0 && ubn0_g1_t4 - n0_g1_t4 >= 0 && -1 + lbn0_g1_t4 >= 0 && -lbn0_g1_t4 + n0_g1_t4 >= 0) )
    {
        return (((1 - lbn0_g1_t4) + n0_g1_t4)) ;
    }
    if((-1 + _PB_M >= 0 && lbn0_g1_t4 >= 0 && -1 + _PB_N - ubn0_g1_t4 >= 0 && -lbn0_g1_t4 + n0_g1_t5 >= 0 && 1 + lbn0_g1_t4 - n0_g1_t5 >= 0 && -n0_g1_t5 + n0_g1_t4 >= 0 && ubn0_g1_t4 - n0_g1_t4 >= 0 && -n0_g1_t5 >= 0) )
    {
        return (((1 - n0_g1_t5) + n0_g1_t4)) ;
    }
    fprintf(stderr,"Error n0_g1_t5_Ranking: no corresponding domain: (n0_g1_t5,n0_g1_t4,_PB_N,_PB_M,lbn0_g1_t4,ubn0_g1_t4) = (%ld,%ld,%ld,%ld,%ld,%ld)\n",n0_g1_t5,n0_g1_t4,_PB_N,_PB_M,lbn0_g1_t4,ubn0_g1_t4);
    exit(1);
}  /* end n0_g1_t5_Ranking */

/************************************** n0_g1_t5_trahrhe_n0_g1_t5 **************************************/
static inline long int n0_g1_t5_trahrhe_n0_g1_t5(long int pc,long int _PB_N,long int _PB_M,long int lbn0_g1_t4,long int ubn0_g1_t4)
{
	long int n0_g1_t5, n0_g1_t4;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    n0_g1_t5 = 0;

    upper_bound = ubn0_g1_t4;
    fixed_upper_bound = ubn0_g1_t4;

	while (n0_g1_t5+1 < upper_bound)
	{
		m = (n0_g1_t5 + upper_bound)/2;

    if(lbn0_g1_t4 >= m ){
        n0_g1_t4 =  lbn0_g1_t4 ;
    }else{
        n0_g1_t4 =  m;
}

		rank = n0_g1_t5_Ranking(m, n0_g1_t4, _PB_N, _PB_M, lbn0_g1_t4, ubn0_g1_t4);

		if (rank <= pc) {
			n0_g1_t5 = m;
		} else {
			upper_bound = m;
		}
	}
	if (n0_g1_t5+1==fixed_upper_bound) {
		m=n0_g1_t5+1;

    if(lbn0_g1_t4 >= m ){
        n0_g1_t4 =  lbn0_g1_t4 ;
    }else{
        n0_g1_t4 =  m;
}
		rank = n0_g1_t5_Ranking(m, n0_g1_t4, _PB_N, _PB_M, lbn0_g1_t4, ubn0_g1_t4);
		if (rank<=pc) n0_g1_t5++;
	}
	return n0_g1_t5;
}
