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

/******************************** n0_g0_t5_Ehrhart Polynomials ********************************/
static inline long int n0_g0_t5_Ehrhart(long int _PB_N,long int _PB_M)
{
    if((-1 + _PB_N >= 0 && -1 + _PB_M >= 0) )
    {
        return (((_PB_N + _PB_N*_PB_N) * _PB_M)/2) ;
    }
    fprintf(stderr,"Error n0_g0_t5_Ehrhart: no corresponding domain: (,_PB_N,_PB_M) = (,%ld,%ld)\n",_PB_N,_PB_M);
    exit(1);
}  /* end n0_g0_t5_Ehrhart */

/******************************** n0_g0_t5_Ranking Polynomials ********************************/
static inline long int n0_g0_t5_Ranking(long int n0_g0_t5,long int n0_g0_t6,long int n0_g0_t7,long int _PB_N,long int _PB_M)
{
    if((-1 + _PB_N - n0_g0_t5 >= 0 && -1 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0) )
    {
        return (((((2 + _PB_M * n0_g0_t5 + _PB_M * n0_g0_t5*n0_g0_t5) + 2 * _PB_M * n0_g0_t6) + 2 * n0_g0_t7))/2) ;
    }
    if((n0_g0_t6 == 0 && -1 + n0_g0_t5 >= 0 && -1 + _PB_N - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0) )
    {
        return ((((2 + _PB_M * n0_g0_t5 + _PB_M * n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t7))/2) ;
    }
    if((n0_g0_t6 == 0 && n0_g0_t5 == 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 + _PB_N >= 0 && n0_g0_t7 >= 0) )
    {
        return ((1 + n0_g0_t7)) ;
    }
    fprintf(stderr,"Error n0_g0_t5_Ranking: no corresponding domain: (n0_g0_t5,n0_g0_t6,n0_g0_t7,_PB_N,_PB_M) = (%ld,%ld,%ld,%ld,%ld)\n",n0_g0_t5,n0_g0_t6,n0_g0_t7,_PB_N,_PB_M);
    exit(1);
}  /* end n0_g0_t5_Ranking */

/************************************** n0_g0_t5_trahrhe_n0_g0_t5 **************************************/
static inline long int n0_g0_t5_trahrhe_n0_g0_t5(long int pc,long int _PB_N,long int _PB_M)
{
	long int n0_g0_t5, n0_g0_t6, n0_g0_t7;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    n0_g0_t5 = 0;

    upper_bound = _PB_N - 1;
    fixed_upper_bound = _PB_N - 1;

	while (n0_g0_t5+1 < upper_bound)
	{
		m = (n0_g0_t5 + upper_bound)/2;

    n0_g0_t6 = 0;
    n0_g0_t7 = 0;

		rank = n0_g0_t5_Ranking(m, n0_g0_t6, n0_g0_t7, _PB_N, _PB_M);

		if (rank <= pc) {
			n0_g0_t5 = m;
		} else {
			upper_bound = m;
		}
	}
	if (n0_g0_t5+1==fixed_upper_bound) {
		m=n0_g0_t5+1;

    n0_g0_t6 = 0;
    n0_g0_t7 = 0;
		rank = n0_g0_t5_Ranking(m, n0_g0_t6, n0_g0_t7, _PB_N, _PB_M);
		if (rank<=pc) n0_g0_t5++;
	}
	return n0_g0_t5;
}
/******************************** n0_g0_t6_Ehrhart Polynomials ********************************/
static inline long int n0_g0_t6_Ehrhart(long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5)
{
    if((lbn0_g0_t5 >= 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 + _PB_M >= 0) )
    {
        return ((((2 * _PB_M + -_PB_M * lbn0_g0_t5 + -_PB_M * lbn0_g0_t5*lbn0_g0_t5) + 3 * _PB_M * ubn0_g0_t5 + _PB_M * ubn0_g0_t5*ubn0_g0_t5))/2) ;
    }
    fprintf(stderr,"Error n0_g0_t6_Ehrhart: no corresponding domain: (,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5) = (,%ld,%ld,%ld,%ld)\n",_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5);
    exit(1);
}  /* end n0_g0_t6_Ehrhart */

/******************************** n0_g0_t6_Ranking Polynomials ********************************/
static inline long int n0_g0_t6_Ranking(long int n0_g0_t6,long int n0_g0_t5,long int n0_g0_t7,long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5)
{
    if((lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -2 - lbn0_g0_t5 + n0_g0_t6 >= 0 && -1 - n0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && n0_g0_t6 >= 0) )
    {
        return ((((((2 + -_PB_M * lbn0_g0_t5 + -_PB_M * lbn0_g0_t5*lbn0_g0_t5) + (_PB_M + 2 * _PB_M * ubn0_g0_t5) * n0_g0_t6 + -_PB_M * n0_g0_t6*n0_g0_t6) + 2 * _PB_M * n0_g0_t5) + 2 * n0_g0_t7))/2) ;
    }
    if((-n0_g0_t6 + n0_g0_t5 == 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -2 - lbn0_g0_t5 + n0_g0_t6 >= 0 && ubn0_g0_t5 - n0_g0_t6 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && n0_g0_t6 >= 0) )
    {
        return (((((2 + -_PB_M * lbn0_g0_t5 + -_PB_M * lbn0_g0_t5*lbn0_g0_t5) + (3 * _PB_M + 2 * _PB_M * ubn0_g0_t5) * n0_g0_t6 + -_PB_M * n0_g0_t6*n0_g0_t6) + 2 * n0_g0_t7))/2) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && -1 + n0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - n0_g0_t6 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && lbn0_g0_t5 >= 0 && -n0_g0_t6 + n0_g0_t5 >= 0) )
    {
        return (((((1 + -_PB_M * lbn0_g0_t5) + ((_PB_M + -_PB_M * lbn0_g0_t5) + _PB_M * ubn0_g0_t5) * n0_g0_t6) + _PB_M * n0_g0_t5) + n0_g0_t7)) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && -lbn0_g0_t5 + n0_g0_t6 >= 0 && -1 + n0_g0_t6 >= 0 && 1 + lbn0_g0_t5 - n0_g0_t6 >= 0 && -1 - n0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && lbn0_g0_t5 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0) )
    {
        return ((((1 + (-_PB_M * lbn0_g0_t5 + _PB_M * ubn0_g0_t5) * n0_g0_t6) + _PB_M * n0_g0_t5) + n0_g0_t7)) ;
    }
    if(((-lbn0_g0_t5 + n0_g0_t5 == 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 + n0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - n0_g0_t6 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && lbn0_g0_t5 >= 0) || (-n0_g0_t6 + n0_g0_t5 == 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -lbn0_g0_t5 + n0_g0_t6 >= 0 && -1 + n0_g0_t6 >= 0 && ubn0_g0_t5 - n0_g0_t6 >= 0 && 1 + lbn0_g0_t5 - n0_g0_t6 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && lbn0_g0_t5 >= 0)) )
    {
        return (((1 + ((_PB_M + -_PB_M * lbn0_g0_t5) + _PB_M * ubn0_g0_t5) * n0_g0_t6) + n0_g0_t7)) ;
    }
    if((n0_g0_t6 == 0 && -1 + lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && n0_g0_t5 >= 0) )
    {
        return ((((1 + -_PB_M * lbn0_g0_t5) + _PB_M * n0_g0_t5) + n0_g0_t7)) ;
    }
    if((n0_g0_t6 == 0 && lbn0_g0_t5 == 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0) )
    {
        return (((1 + _PB_M * n0_g0_t5) + n0_g0_t7)) ;
    }
    if(((-lbn0_g0_t5 + n0_g0_t5 == 0 && n0_g0_t6 == 0 && -1 + lbn0_g0_t5 >= 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0) || (n0_g0_t5 == 0 && n0_g0_t6 == 0 && lbn0_g0_t5 == 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && ubn0_g0_t5 >= 0 && n0_g0_t7 >= 0)) )
    {
        return ((1 + n0_g0_t7)) ;
    }
    fprintf(stderr,"Error n0_g0_t6_Ranking: no corresponding domain: (n0_g0_t6,n0_g0_t5,n0_g0_t7,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5) = (%ld,%ld,%ld,%ld,%ld,%ld,%ld)\n",n0_g0_t6,n0_g0_t5,n0_g0_t7,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5);
    exit(1);
}  /* end n0_g0_t6_Ranking */

/************************************** n0_g0_t6_trahrhe_n0_g0_t6 **************************************/
static inline long int n0_g0_t6_trahrhe_n0_g0_t6(long int pc,long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5)
{
	long int n0_g0_t6, n0_g0_t5, n0_g0_t7;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    n0_g0_t6 = 0;

    upper_bound = ubn0_g0_t5;
    fixed_upper_bound = ubn0_g0_t5;

	while (n0_g0_t6+1 < upper_bound)
	{
		m = (n0_g0_t6 + upper_bound)/2;

    if(lbn0_g0_t5 >= m ){
        n0_g0_t5 =  lbn0_g0_t5 ;
    }else{
        n0_g0_t5 =  m;
}
    n0_g0_t7 = 0;

		rank = n0_g0_t6_Ranking(m, n0_g0_t5, n0_g0_t7, _PB_N, _PB_M, lbn0_g0_t5, ubn0_g0_t5);

		if (rank <= pc) {
			n0_g0_t6 = m;
		} else {
			upper_bound = m;
		}
	}
	if (n0_g0_t6+1==fixed_upper_bound) {
		m=n0_g0_t6+1;

    if(lbn0_g0_t5 >= m ){
        n0_g0_t5 =  lbn0_g0_t5 ;
    }else{
        n0_g0_t5 =  m;
}
    n0_g0_t7 = 0;
		rank = n0_g0_t6_Ranking(m, n0_g0_t5, n0_g0_t7, _PB_N, _PB_M, lbn0_g0_t5, ubn0_g0_t5);
		if (rank<=pc) n0_g0_t6++;
	}
	return n0_g0_t6;
}
/******************************** n0_g0_t7_Ehrhart Polynomials ********************************/
static inline long int n0_g0_t7_Ehrhart(long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5,long int lbn0_g0_t6,long int ubn0_g0_t6)
{
    if((lbn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && ubn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + _PB_M >= 0 && lbn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0) )
    {
        return ((((2 * _PB_M + 3 * _PB_M * ubn0_g0_t5 + _PB_M * ubn0_g0_t5*ubn0_g0_t5) + (-3 * _PB_M + -2 * _PB_M * ubn0_g0_t5) * lbn0_g0_t6 + _PB_M * lbn0_g0_t6*lbn0_g0_t6))/2) ;
    }
    if((lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -lbn0_g0_t6 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && lbn0_g0_t6 >= 0) )
    {
        return (((((2 * _PB_M + 2 * _PB_M * ubn0_g0_t5) + (-3 * _PB_M + -2 * _PB_M * ubn0_g0_t5) * lbn0_g0_t6 + _PB_M * lbn0_g0_t6*lbn0_g0_t6) + (_PB_M + 2 * _PB_M * ubn0_g0_t5) * ubn0_g0_t6 + -_PB_M * ubn0_g0_t6*ubn0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t5 + ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0) )
    {
        return (((((2 * _PB_M + -_PB_M * lbn0_g0_t5 + -_PB_M * lbn0_g0_t5*lbn0_g0_t5) + 3 * _PB_M * ubn0_g0_t5 + _PB_M * ubn0_g0_t5*ubn0_g0_t5) + ((-2 * _PB_M + 2 * _PB_M * lbn0_g0_t5) + -2 * _PB_M * ubn0_g0_t5) * lbn0_g0_t6))/2) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return ((((((2 * _PB_M + -_PB_M * lbn0_g0_t5 + -_PB_M * lbn0_g0_t5*lbn0_g0_t5) + 2 * _PB_M * ubn0_g0_t5) + ((-2 * _PB_M + 2 * _PB_M * lbn0_g0_t5) + -2 * _PB_M * ubn0_g0_t5) * lbn0_g0_t6) + (_PB_M + 2 * _PB_M * ubn0_g0_t5) * ubn0_g0_t6 + -_PB_M * ubn0_g0_t6*ubn0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -lbn0_g0_t6 + ubn0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((_PB_M + -_PB_M * lbn0_g0_t5) + _PB_M * ubn0_g0_t5) + ((-_PB_M + _PB_M * lbn0_g0_t5) + -_PB_M * ubn0_g0_t5) * lbn0_g0_t6) + ((_PB_M + -_PB_M * lbn0_g0_t5) + _PB_M * ubn0_g0_t5) * ubn0_g0_t6)) ;
    }
    fprintf(stderr,"Error n0_g0_t7_Ehrhart: no corresponding domain: (,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5,lbn0_g0_t6,ubn0_g0_t6) = (,%ld,%ld,%ld,%ld,%ld,%ld)\n",_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5,lbn0_g0_t6,ubn0_g0_t6);
    exit(1);
}  /* end n0_g0_t7_Ehrhart */

/******************************** n0_g0_t7_Ranking Polynomials ********************************/
static inline long int n0_g0_t7_Ranking(long int n0_g0_t7,long int n0_g0_t5,long int n0_g0_t6,long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5,long int lbn0_g0_t6,long int ubn0_g0_t6)
{
    if((lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -2 - ubn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((((2 - 3 * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) - ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) + (((2 + 2 * ubn0_g0_t5) + (-3 - 2 * ubn0_g0_t5) * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7) + ((2 - 2 * lbn0_g0_t6) + 2 * ubn0_g0_t6) * n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 - lbn0_g0_t6 + n0_g0_t5 >= 0 && 1 + ubn0_g0_t6 - n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && lbn0_g0_t6 >= 0) )
    {
        return ((((((2 - 3 * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + (((2 + 2 * ubn0_g0_t5) + (-3 - 2 * ubn0_g0_t5) * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t6 + n0_g0_t6 == 0 && -lbn0_g0_t6 + n0_g0_t5 == 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -lbn0_g0_t6 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && ubn0_g0_t5 - lbn0_g0_t6 >= 0 && lbn0_g0_t6 >= 0) )
    {
        return (((2 + (((2 + 2 * ubn0_g0_t5) + (-3 - 2 * ubn0_g0_t5) * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7))/2) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -2 - ubn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return ((((((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + (-2 + 2 * lbn0_g0_t5) * lbn0_g0_t6) - ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) + ((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + 2 * ubn0_g0_t5) + ((-2 + 2 * lbn0_g0_t5) - 2 * ubn0_g0_t5) * lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7) + ((2 - 2 * lbn0_g0_t6) + 2 * ubn0_g0_t6) * n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && 1 + ubn0_g0_t6 - n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + (-2 + 2 * lbn0_g0_t5) * lbn0_g0_t6) + ((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + 2 * ubn0_g0_t5) + ((-2 + 2 * lbn0_g0_t5) - 2 * ubn0_g0_t5) * lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t5 + n0_g0_t5 == 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && lbn0_g0_t5 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((2 - 2 * lbn0_g0_t6) + ((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + 2 * ubn0_g0_t5) + ((-2 + 2 * lbn0_g0_t5) - 2 * ubn0_g0_t5) * lbn0_g0_t6) + (1 + 2 * ubn0_g0_t5) * ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) * n0_g0_t7) + 2 * n0_g0_t6))/2) ;
    }
    if((lbn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 - lbn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0) )
    {
        return ((((((2 - 3 * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + ((2 + 3 * ubn0_g0_t5 + ubn0_g0_t5*ubn0_g0_t5) + (-3 - 2 * ubn0_g0_t5) * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) * n0_g0_t7) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t6 + n0_g0_t6 == 0 && -lbn0_g0_t6 + n0_g0_t5 == 0 && lbn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && ubn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -lbn0_g0_t6 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0) )
    {
        return (((2 + ((2 + 3 * ubn0_g0_t5 + ubn0_g0_t5*ubn0_g0_t5) + (-3 - 2 * ubn0_g0_t5) * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) * n0_g0_t7))/2) ;
    }
    if((lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0) )
    {
        return (((((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + (-2 + 2 * lbn0_g0_t5) * lbn0_g0_t6) + (((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + 3 * ubn0_g0_t5 + ubn0_g0_t5*ubn0_g0_t5) + ((-2 + 2 * lbn0_g0_t5) - 2 * ubn0_g0_t5) * lbn0_g0_t6) * n0_g0_t7) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((-lbn0_g0_t5 + n0_g0_t5 == 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && lbn0_g0_t5 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0) )
    {
        return (((((2 - 2 * lbn0_g0_t6) + (((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + 3 * ubn0_g0_t5 + ubn0_g0_t5*ubn0_g0_t5) + ((-2 + 2 * lbn0_g0_t5) - 2 * ubn0_g0_t5) * lbn0_g0_t6) * n0_g0_t7) + 2 * n0_g0_t6))/2) ;
    }
    if((-1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((((1 - lbn0_g0_t5) + (-1 + lbn0_g0_t5) * lbn0_g0_t6) + -lbn0_g0_t5 * ubn0_g0_t6) + ((((1 - lbn0_g0_t5) + ubn0_g0_t5) + ((-1 + lbn0_g0_t5) - ubn0_g0_t5) * lbn0_g0_t6) + ((1 - lbn0_g0_t5) + ubn0_g0_t5) * ubn0_g0_t6) * n0_g0_t7) + ((1 - lbn0_g0_t6) + ubn0_g0_t6) * n0_g0_t5) + n0_g0_t6)) ;
    }
    if((-lbn0_g0_t5 + n0_g0_t5 == 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 + n0_g0_t7 >= 0 && -1 + _PB_M - n0_g0_t7 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && lbn0_g0_t5 - n0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return ((((1 - lbn0_g0_t6) + ((((1 - lbn0_g0_t5) + ubn0_g0_t5) + ((-1 + lbn0_g0_t5) - ubn0_g0_t5) * lbn0_g0_t6) + ((1 - lbn0_g0_t5) + ubn0_g0_t5) * ubn0_g0_t6) * n0_g0_t7) + n0_g0_t6)) ;
    }
    if((n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -2 - ubn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return ((((((2 - 3 * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) - ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) + ((2 - 2 * lbn0_g0_t6) + 2 * ubn0_g0_t6) * n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t6 >= 0 && -2 - ubn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return (((((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + (-2 + 2 * lbn0_g0_t5) * lbn0_g0_t6) - ubn0_g0_t6 - ubn0_g0_t6*ubn0_g0_t6) + ((2 - 2 * lbn0_g0_t6) + 2 * ubn0_g0_t6) * n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if(((n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 - lbn0_g0_t6 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0) || (n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 - lbn0_g0_t6 + n0_g0_t5 >= 0 && 1 + ubn0_g0_t6 - n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + n0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && lbn0_g0_t6 >= 0)) )
    {
        return (((((2 - 3 * lbn0_g0_t6 + lbn0_g0_t6*lbn0_g0_t6) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if(((n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0) || (n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && lbn0_g0_t5 - lbn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && 1 + ubn0_g0_t6 - n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0)) )
    {
        return ((((((2 - lbn0_g0_t5 - lbn0_g0_t5*lbn0_g0_t5) + (-2 + 2 * lbn0_g0_t5) * lbn0_g0_t6) + (1 - 2 * lbn0_g0_t6) * n0_g0_t5 + n0_g0_t5*n0_g0_t5) + 2 * n0_g0_t6))/2) ;
    }
    if((n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - ubn0_g0_t6 >= 0 && -1 - lbn0_g0_t5 + n0_g0_t5 >= 0 && ubn0_g0_t5 - n0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && lbn0_g0_t5 >= 0 && n0_g0_t5 - n0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) )
    {
        return ((((((1 - lbn0_g0_t5) + (-1 + lbn0_g0_t5) * lbn0_g0_t6) + -lbn0_g0_t5 * ubn0_g0_t6) + ((1 - lbn0_g0_t6) + ubn0_g0_t6) * n0_g0_t5) + n0_g0_t6)) ;
    }
    if(((-lbn0_g0_t5 + n0_g0_t5 == 0 && n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 + lbn0_g0_t5 - ubn0_g0_t6 >= 0 && ubn0_g0_t6 - n0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0) || (-lbn0_g0_t5 + n0_g0_t5 == 0 && n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -lbn0_g0_t5 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && lbn0_g0_t5 - n0_g0_t6 >= 0) || (-lbn0_g0_t5 + n0_g0_t5 == 0 && n0_g0_t7 == 0 && -1 + _PB_M >= 0 && -lbn0_g0_t5 + ubn0_g0_t5 >= 0 && lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0 && -lbn0_g0_t6 + n0_g0_t6 >= 0 && lbn0_g0_t5 - n0_g0_t6 >= 0) || (-lbn0_g0_t6 + n0_g0_t6 == 0 && -lbn0_g0_t6 + n0_g0_t5 == 0 && n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && ubn0_g0_t5 - lbn0_g0_t6 >= 0 && -1 - ubn0_g0_t5 + ubn0_g0_t6 >= 0 && -1 + _PB_N - ubn0_g0_t6 >= 0) || (-lbn0_g0_t6 + n0_g0_t6 == 0 && -lbn0_g0_t6 + n0_g0_t5 == 0 && n0_g0_t7 == 0 && -1 + _PB_M >= 0 && lbn0_g0_t5 >= 0 && -1 + _PB_N - ubn0_g0_t5 >= 0 && -1 - lbn0_g0_t5 + lbn0_g0_t6 >= 0 && -lbn0_g0_t6 + ubn0_g0_t6 >= 0 && ubn0_g0_t5 - ubn0_g0_t6 >= 0)) )
    {
        return (((1 - lbn0_g0_t6) + n0_g0_t6)) ;
    }
    fprintf(stderr,"Error n0_g0_t7_Ranking: no corresponding domain: (n0_g0_t7,n0_g0_t5,n0_g0_t6,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5,lbn0_g0_t6,ubn0_g0_t6) = (%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld)\n",n0_g0_t7,n0_g0_t5,n0_g0_t6,_PB_N,_PB_M,lbn0_g0_t5,ubn0_g0_t5,lbn0_g0_t6,ubn0_g0_t6);
    exit(1);
}  /* end n0_g0_t7_Ranking */

/************************************** n0_g0_t7_trahrhe_n0_g0_t7 **************************************/
static inline long int n0_g0_t7_trahrhe_n0_g0_t7(long int pc,long int _PB_N,long int _PB_M,long int lbn0_g0_t5,long int ubn0_g0_t5,long int lbn0_g0_t6,long int ubn0_g0_t6)
{
	long int n0_g0_t7, n0_g0_t5, n0_g0_t6;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    n0_g0_t7 = 0;

    upper_bound = _PB_M - 1;
    fixed_upper_bound = _PB_M - 1;

	while (n0_g0_t7+1 < upper_bound)
	{
		m = (n0_g0_t7 + upper_bound)/2;

    if(lbn0_g0_t5 >= lbn0_g0_t6 ){
        n0_g0_t5 =  lbn0_g0_t5 ;
    }else{
        n0_g0_t5 =  lbn0_g0_t6;
}
    n0_g0_t6 = lbn0_g0_t6;

		rank = n0_g0_t7_Ranking(m, n0_g0_t5, n0_g0_t6, _PB_N, _PB_M, lbn0_g0_t5, ubn0_g0_t5, lbn0_g0_t6, ubn0_g0_t6);

		if (rank <= pc) {
			n0_g0_t7 = m;
		} else {
			upper_bound = m;
		}
	}
	if (n0_g0_t7+1==fixed_upper_bound) {
		m=n0_g0_t7+1;

    if(lbn0_g0_t5 >= lbn0_g0_t6 ){
        n0_g0_t5 =  lbn0_g0_t5 ;
    }else{
        n0_g0_t5 =  lbn0_g0_t6;
}
    n0_g0_t6 = lbn0_g0_t6;
		rank = n0_g0_t7_Ranking(m, n0_g0_t5, n0_g0_t6, _PB_N, _PB_M, lbn0_g0_t5, ubn0_g0_t5, lbn0_g0_t6, ubn0_g0_t6);
		if (rank<=pc) n0_g0_t7++;
	}
	return n0_g0_t7;
}
