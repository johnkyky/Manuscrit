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

/******************************** t1_Ehrhart Polynomials ********************************/
static inline long int t1_Ehrhart(long int _PB_TSTEPS,long int _PB_N)
{
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0) )
    {
        return ((4 * _PB_TSTEPS + -4 * _PB_TSTEPS * _PB_N + _PB_TSTEPS * _PB_N*_PB_N)) ;
    }
    fprintf(stderr,"Error t1_Ehrhart: no corresponding domain: (,_PB_TSTEPS,_PB_N) = (,%ld,%ld)\n",_PB_TSTEPS,_PB_N);
    exit(1);
}  /* end t1_Ehrhart */

/******************************** t1_Ranking Polynomials ********************************/
static inline long int t1_Ranking(long int t1,long int t2,long int t3,long int _PB_TSTEPS,long int _PB_N)
{
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 1 - _PB_N + t1 >= 0 && -2 + 2*_PB_TSTEPS - t1 >= 0 && -3 - t1 + 2*t2 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && t1 - t2 >= 0 && -1 + _PB_TSTEPS - t1 + t2 >= 0) )
    {
        return ((((((((16 - 18 * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 - 8 * _PB_N + 2 * _PB_N*_PB_N) * t1) + (-8 + 4 * _PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(t1, 2)) + (4 - 2 * _PB_N) * floord(_PB_N + t1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 1 - 2*_PB_TSTEPS + t1 >= 0 && 1 - _PB_N + t1 >= 0 && 2*_PB_TSTEPS - t1 >= 0 && -2 + _PB_TSTEPS - t1 + t2 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 - t1 + 2*t2 >= 0 && t1 - t2 >= 0) )
    {
        return ((((((((16 - 4 * _PB_TSTEPS) + (-18 + 2 * _PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (8 - 10 * _PB_N + 2 * _PB_N*_PB_N) * t1) + (-8 + 4 * _PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(_PB_N + t1, 2)))/4) ;
    }
    if(((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 1 - _PB_N + t1 >= 0 && -2 + 2*_PB_TSTEPS - t1 >= 0 && -1 - t1 + 2*t2 >= 0 && 2 + t1 - 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && t1 - t2 >= 0 && -1 + _PB_TSTEPS - t1 + t2 >= 0) || (-1 + _PB_TSTEPS - t1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 1 - 2*_PB_TSTEPS + t1 >= 0 && 1 - _PB_N + t1 >= 0 && 2*_PB_TSTEPS - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - t1 >= 0)) )
    {
        return (((((((12 - 16 * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 - 8 * _PB_N + 2 * _PB_N*_PB_N) * t1) + (-4 + 2 * _PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(_PB_N + t1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + _PB_N - t1 >= 0 && -2 + 2*_PB_TSTEPS - t1 >= 0 && t1 - t2 >= 0 && -3 - t1 + 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -1 + _PB_TSTEPS - t1 + t2 >= 0) )
    {
        return (((((((8 - 4 * _PB_N) + (-2 - _PB_N) * t1 + (-2 + _PB_N) * t1*t1) + (-8 + 4 * _PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(t1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && 1 - 2*_PB_TSTEPS + t1 >= 0 && -2 + _PB_N - t1 >= 0 && 2*_PB_TSTEPS - t1 >= 0 && -2 + _PB_TSTEPS - t1 + t2 >= 0 && t1 - t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -10 + _PB_N >= 0 && -1 - t1 + 2*t2 >= 0) )
    {
        return (((((((8 - 4 * _PB_TSTEPS) + (-4 + 2 * _PB_TSTEPS) * _PB_N) + (2 - 3 * _PB_N) * t1 + (-2 + _PB_N) * t1*t1) + (-8 + 4 * _PB_N) * t2) + 4 * t3))/4) ;
    }
    if(((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + t1 >= 0 && -2 + _PB_N - t1 >= 0 && -2 + 2*_PB_TSTEPS - t1 >= 0 && -1 - t1 + 2*t2 >= 0 && 2 + t1 - 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && t1 - t2 >= 0 && -1 + _PB_TSTEPS - t1 + t2 >= 0) || (-1 + _PB_TSTEPS - t1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && 1 - 2*_PB_TSTEPS + t1 >= 0 && -2 + _PB_N - t1 >= 0 && 2*_PB_TSTEPS - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - t1 >= 0 && -10 + _PB_N >= 0)) )
    {
        return ((((((4 - 2 * _PB_N) + (-2 - _PB_N) * t1 + (-2 + _PB_N) * t1*t1) + (-4 + 2 * _PB_N) * t2) + 4 * t3))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 - 2*_PB_TSTEPS + t1 >= 0 && 1 - _PB_N + t1 >= 0 && -2 + _PB_TSTEPS - t1 + t2 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 - t1 + 2*t2 >= 0 && t1 - t2 >= 0) )
    {
        return ((((((((16 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-18 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((10 - 8 * _PB_TSTEPS) + (-11 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * t1 + (2 - _PB_N) * t1*t1) + (-8 + 4 * _PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(_PB_N + t1, 2)))/4) ;
    }
    if((-1 + _PB_TSTEPS - t1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 - 2*_PB_TSTEPS + t1 >= 0 && 1 - _PB_N + t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0) )
    {
        return (((((((8 + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-14 - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((2 - 8 * _PB_TSTEPS) + (-7 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * t1 + (2 - _PB_N) * t1*t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(_PB_N + t1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 - 2*_PB_TSTEPS + t1 >= 0 && -2 + _PB_N - t1 >= 0 && -2 + _PB_TSTEPS - t1 + t2 >= 0 && t1 - t2 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N + t1 - 2*t2 >= 0 && -10 + _PB_N >= 0 && -1 - t1 + 2*t2 >= 0) )
    {
        return ((((((2 - 2 * _PB_TSTEPS + 2 * _PB_TSTEPS*_PB_TSTEPS) + (-1 + _PB_TSTEPS - _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + ((1 - 2 * _PB_TSTEPS) + (-1 + _PB_TSTEPS) * _PB_N) * t1) + (-2 + _PB_N) * t2) + t3)) ;
    }
    if((-1 + _PB_TSTEPS - t1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -1 - 2*_PB_TSTEPS + t1 >= 0 && -2 + _PB_N - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - t1 >= 0 && -10 + _PB_N >= 0) )
    {
        return ((((2 * _PB_TSTEPS*_PB_TSTEPS + -_PB_TSTEPS*_PB_TSTEPS * _PB_N) + ((-1 - 2 * _PB_TSTEPS) + _PB_TSTEPS * _PB_N) * t1) + t3)) ;
    }
    if((-1 + t2 == 0 && -1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + t3 >= 0 && -1 + _PB_N - t3 >= 0) )
    {
        return ((-t1 + t3)) ;
    }
    fprintf(stderr,"Error t1_Ranking: no corresponding domain: (t1,t2,t3,_PB_TSTEPS,_PB_N) = (%ld,%ld,%ld,%ld,%ld)\n",t1,t2,t3,_PB_TSTEPS,_PB_N);
    exit(1);
}  /* end t1_Ranking */

/************************************** t1_trahrhe_t1 **************************************/
static inline long int t1_trahrhe_t1(long int pc,long int _PB_TSTEPS,long int _PB_N)
{
	long int t1, t2, t3;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    t1 = 1;

    upper_bound = 2 * _PB_TSTEPS + _PB_N - 4;
    fixed_upper_bound = 2 * _PB_TSTEPS + _PB_N - 4;

	while (t1+1 < upper_bound)
	{
		m = (t1 + upper_bound)/2;

    if(m + 1 >= 2 * _PB_TSTEPS ){
        t2 =  -_PB_TSTEPS + m + 1 ;
    }else{
        t2 =  m - (m + 1) / 2 + 1;
}
    t3 = m + 1;

		rank = t1_Ranking(m, t2, t3, _PB_TSTEPS, _PB_N);

		if (rank <= pc) {
			t1 = m;
		} else {
			upper_bound = m;
		}
	}
	if (t1+1==fixed_upper_bound) {
		m=t1+1;

    if(m + 1 >= 2 * _PB_TSTEPS ){
        t2 =  -_PB_TSTEPS + m + 1 ;
    }else{
        t2 =  m - (m + 1) / 2 + 1;
}
    t3 = m + 1;
		rank = t1_Ranking(m, t2, t3, _PB_TSTEPS, _PB_N);
		if (rank<=pc) t1++;
	}
	return t1;
}
/******************************** t2_Ehrhart Polynomials ********************************/
static inline long int t2_Ehrhart(long int _PB_TSTEPS,long int _PB_N,long int lbt1,long int ubt1)
{
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -2*_PB_TSTEPS + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0) )
    {
        return (((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + ((14 - 8 * _PB_TSTEPS) + (-11 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((((((8 - 8 * _PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS) * _PB_N) + ((-6 + 8 * _PB_TSTEPS) + (7 - 4 * _PB_TSTEPS) * _PB_N - 2 * _PB_N*_PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((14 - 8 * _PB_TSTEPS) + (-11 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -2*_PB_TSTEPS + ubt1 >= 0 && 2 - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return ((((((((16 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-18 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((14 - 8 * _PB_TSTEPS) + (-11 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 2 - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0 && -10 + _PB_N >= 0) )
    {
        return (((((((16 - 8 * _PB_TSTEPS) + (-18 + 4 * _PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (8 * _PB_TSTEPS + -4 * _PB_TSTEPS * _PB_N) * lbt1) + ((14 - 8 * _PB_TSTEPS) + (-11 + 4 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (-4 + 2 * _PB_N) * floord(_PB_N + ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -2*_PB_TSTEPS + ubt1 >= 0 && -3 + _PB_N - ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -10 + _PB_N >= 0) )
    {
        return (((((((-8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (-8 * _PB_TSTEPS + 4 * _PB_TSTEPS * _PB_N) * ubt1) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -3 + _PB_N - ubt1 >= 0 && -1 + 2*_PB_TSTEPS - ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return (((((((-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (-6 + 3 * _PB_N) * ubt1 + (-2 + _PB_N) * ubt1*ubt1) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 2 - _PB_N + ubt1 >= 0 && -1 + 2*_PB_TSTEPS - ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return ((((((((16 - 18 * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (8 - 8 * _PB_N + 2 * _PB_N*_PB_N) * ubt1) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -1 + 2*_PB_TSTEPS - ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0) )
    {
        return (((((((((4 - 2 * _PB_N) + (-4 + 4 * _PB_N - _PB_N*_PB_N) * lbt1) + (4 - 4 * _PB_N + _PB_N*_PB_N) * ubt1) + (2 - _PB_N) * floord(lbt1, 2)) + (-2 + _PB_N) * floord(_PB_N + lbt1, 2)) + (2 - _PB_N) * floord(ubt1, 2)) + (-2 + _PB_N) * floord(_PB_N + ubt1, 2)))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -3 + _PB_N - ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((-2 * _PB_TSTEPS + _PB_TSTEPS * _PB_N) + (2 * _PB_TSTEPS + -_PB_TSTEPS * _PB_N) * lbt1) + (-2 * _PB_TSTEPS + _PB_TSTEPS * _PB_N) * ubt1)) ;
    }
    fprintf(stderr,"Error t2_Ehrhart: no corresponding domain: (,_PB_TSTEPS,_PB_N,lbt1,ubt1) = (,%ld,%ld,%ld,%ld)\n",_PB_TSTEPS,_PB_N,lbt1,ubt1);
    exit(1);
}  /* end t2_Ehrhart */

/******************************** t2_Ranking Polynomials ********************************/
static inline long int t2_Ranking(long int t2,long int t1,long int t3,long int _PB_TSTEPS,long int _PB_N,long int lbt1,long int ubt1)
{
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return (((((((((((24 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-22 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && 2 - _PB_N + t2 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return ((((((((((-8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-2 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((-8 - 8 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -_PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((((32 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-36 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 14 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -_PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return (((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-16 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((-8 - 8 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -4 + _PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -10 + _PB_N >= 0 && -3 + 2*_PB_N - t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((24 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-24 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((20 - 8 * _PB_TSTEPS) + (-18 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + 2*t2 - t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return ((((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((-4 + 2 * _PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -_PB_N + ubt1 >= 0 && -4 + _PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0)) )
    {
        return ((((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((-12 + 6 * _PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return ((((((((((24 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-20 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + (((8 - 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return ((((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (2 - _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + (((-8 + 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return ((((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((8 - 4 * _PB_N) * lbt1 + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -lbt1 + ubt1 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -lbt1 + ubt1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && lbt1 - t2 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0)) )
    {
        return ((((((((((8 - 8 * _PB_TSTEPS + 8 * _PB_TSTEPS*_PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + (((-8 + 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0) )
    {
        return ((((((((((24 - 8 * _PB_TSTEPS) + (-22 + 4 * _PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((-6 + 8 * _PB_TSTEPS) + (7 - 4 * _PB_TSTEPS) * _PB_N - 2 * _PB_N*_PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_N + t2 >= 0) )
    {
        return ((((((((-8 * _PB_TSTEPS + (-2 + 4 * _PB_TSTEPS) * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((-6 + 8 * _PB_TSTEPS) + (7 - 4 * _PB_TSTEPS) * _PB_N - 2 * _PB_N*_PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) * ubt1 + (4 - 2 * _PB_N) * ubt1*ubt1) + ((-8 - 8 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + 4 * t3) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -_PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0) )
    {
        return (((((((((16 - 4 * _PB_TSTEPS) + (-18 + 2 * _PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((8 - 8 * _PB_N + 2 * _PB_N*_PB_N) + (-4 + 2 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -_PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return ((((((((4 - 4 * _PB_TSTEPS) + (-8 + 2 * _PB_TSTEPS) * _PB_N + 5 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-4 - 4 * _PB_N + 2 * _PB_N*_PB_N) + (-4 + 2 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) + 2 * t3))/2) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -4 + _PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -3 + 2*_PB_N - t1 >= 0) )
    {
        return ((((((((12 - 4 * _PB_TSTEPS) + (-12 + 2 * _PB_TSTEPS) * _PB_N + 5 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((10 - 4 * _PB_TSTEPS) + (-9 + 2 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -2 - lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return (((((((((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-2 + _PB_N) + (-4 + 2 * _PB_N) * ubt1) * t2 + (2 - _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -2 - lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -_PB_N + ubt1 >= 0 && -4 + _PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0)) )
    {
        return (((((((((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-6 + 3 * _PB_N) + (-4 + 2 * _PB_N) * ubt1) * t2 + (2 - _PB_N) * t2*t2) - 2 * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0) )
    {
        return (((((((((12 - 4 * _PB_TSTEPS) + (-10 + 2 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((4 - 2 * _PB_N) + (4 - 2 * _PB_N) * lbt1) + (-4 + 2 * _PB_N) * ubt1) * t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return (((((((((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) + ((2 + 4 * _PB_TSTEPS) + (-1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((-4 + 2 * _PB_N) + (4 - 2 * _PB_N) * lbt1) + (-4 + 2 * _PB_N) * ubt1) * t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return (((((((((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((4 - 2 * _PB_N) * lbt1 + (-4 + 2 * _PB_N) * ubt1) * t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + 2*t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && lbt1 - t2 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -lbt1 + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 1 - _PB_N + t2 >= 0 && -3 + _PB_TSTEPS - ubt1 + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0)) )
    {
        return (((((((((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((-4 + 2 * _PB_N) + (4 - 2 * _PB_N) * lbt1) + (-4 + 2 * _PB_N) * ubt1) * t2) - 2 * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -1 + lbt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((16 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) + (-18 - 2 * _PB_TSTEPS + 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((-6 + 8 * _PB_TSTEPS) + (7 - 4 * _PB_TSTEPS) * _PB_N - 2 * _PB_N*_PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((28 - 8 * _PB_TSTEPS) + (-22 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && 2 - _PB_N + t2 >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((((((-8 + 4 * _PB_TSTEPS - 4 * _PB_TSTEPS*_PB_TSTEPS) + (2 - 2 * _PB_TSTEPS + 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + ((-6 + 8 * _PB_TSTEPS) + (7 - 4 * _PB_TSTEPS) * _PB_N - 2 * _PB_N*_PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((4 - 8 * _PB_TSTEPS) + (-14 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + 4 * t3) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -_PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((12 + 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-16 - _PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((14 - 4 * _PB_TSTEPS) + (-11 + 2 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * t2 + (2 - _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -_PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return (((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-6 - _PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 5 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((2 - 4 * _PB_TSTEPS) + (-7 + 2 * _PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) * t2 + (2 - _PB_N) * t2*t2) + 2 * t3))/2) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 3 - _PB_TSTEPS - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -3 + 2*_PB_N - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((6 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (4 - 7 * _PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N + (-2 + 2 * _PB_TSTEPS) * _PB_N*_PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-_PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + ((4 - 4 * _PB_TSTEPS) + (-2 + 2 * _PB_TSTEPS) * _PB_N) * t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && ubt1 - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -1 + t2 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 3 - _PB_TSTEPS - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -_PB_N + ubt1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0)) )
    {
        return ((((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-_PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (4 * _PB_TSTEPS + -2 * _PB_TSTEPS * _PB_N) * lbt1) + (-4 * _PB_TSTEPS + 2 * _PB_TSTEPS * _PB_N) * t2) - 2 * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -1 + lbt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((8 + 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-8 - _PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 2 * _PB_N*_PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((10 - 4 * _PB_TSTEPS) + (-5 + 2 * _PB_TSTEPS) * _PB_N) + (4 - 2 * _PB_N) * lbt1) * t2 + (-2 + _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -1 + lbt1 >= 0 && -t2 + t1 >= 0) )
    {
        return ((((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-_PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + ((2 + 4 * _PB_TSTEPS) + (-1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((2 - 4 * _PB_TSTEPS) + (-1 + 2 * _PB_TSTEPS) * _PB_N) + (4 - 2 * _PB_N) * lbt1) * t2 + (-2 + _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-_PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((6 - 4 * _PB_TSTEPS) + (-3 + 2 * _PB_TSTEPS) * _PB_N) + (4 - 2 * _PB_N) * lbt1) * t2 + (-2 + _PB_N) * t2*t2) + (-6 + 2 * _PB_N) * t1) + 2 * t3))/2) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 + _PB_TSTEPS - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -lbt1 + ubt1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && ubt1 - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -1 + t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -2 + _PB_TSTEPS - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -lbt1 + ubt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -1 + lbt1 >= 0 && lbt1 - t2 >= 0) || (-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -1 + lbt1 >= 0)) )
    {
        return ((((((((2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) + (-_PB_TSTEPS + _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + ((-2 + 4 * _PB_TSTEPS) + (1 - 2 * _PB_TSTEPS) * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((2 - 4 * _PB_TSTEPS) + (-1 + 2 * _PB_TSTEPS) * _PB_N) + (4 - 2 * _PB_N) * lbt1) * t2 + (-2 + _PB_N) * t2*t2) - 2 * t1) + 2 * t3))/2) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return (((((((((((24 - 22 * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && 2 - _PB_N + t2 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return ((((((((((-2 * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-8 - 8 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -_PB_N + t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((((32 - 36 * _PB_N + 14 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -_PB_N + t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return (((((((((8 - 16 * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-8 - 8 * _PB_N + 4 * _PB_N*_PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (8 - 4 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -6 + 2*_PB_N - ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -3 + 2*_PB_N - t1 >= 0 && -lbt1 + t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) )
    {
        return (((((((((24 - 24 * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (14 - 15 * _PB_N + 4 * _PB_N*_PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && -2 + _PB_N - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((((8 - 4 * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-4 + 2 * _PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -_PB_N + ubt1 >= 0 && -6 + 2*_PB_N - ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0)) )
    {
        return ((((((((((8 - 4 * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((-12 + 6 * _PB_N) + (-8 + 4 * _PB_N) * ubt1) * t2 + (4 - 2 * _PB_N) * t2*t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return ((((((((((24 - 20 * _PB_N + 4 * _PB_N*_PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((8 - 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -t2 + t1 >= 0) )
    {
        return ((((((((((8 - 4 * _PB_N) + (2 - _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((-8 + 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -lbt1 + t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 + 2*t2 - t1 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0) )
    {
        return ((((((((((8 - 4 * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + ((8 - 4 * _PB_N) * lbt1 + (-8 + 4 * _PB_N) * ubt1) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -lbt1 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -lbt1 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -1 - lbt1 + 2*t2 >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && lbt1 - t2 >= 0) || (-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -lbt1 + t2 >= 0 && ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -4 - ubt1 + 2*t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 >= 0)) )
    {
        return ((((((((((8 - 4 * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (6 - 3 * _PB_N) * ubt1 + (2 - _PB_N) * ubt1*ubt1) + (((-8 + 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) + (-8 + 4 * _PB_N) * ubt1) * t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (4 - 2 * _PB_N) * floord(ubt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -t2 + t1 >= 0 && -lbt1 + t1 >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((((((16 - 16 * _PB_N + 4 * _PB_N*_PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((24 - 12 * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-8 + 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -3 - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -t2 + t1 >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((((((2 - _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((8 - 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-8 + 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -3 - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -1 - t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0 && -1 + lbt1 >= 0) )
    {
        return ((((((((-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((16 - 8 * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-8 + 4 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -1 + lbt1 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -3 - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -lbt1 + ubt1 >= 0 && -1 + lbt1 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 - _PB_N + t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -3 - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -lbt1 + ubt1 >= 0 && -1 + lbt1 >= 0 && lbt1 - t2 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t2 >= 0 && ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -3 - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && -1 + t2 >= 0 && -1 + lbt1 >= 0)) )
    {
        return ((((((((-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + ((8 - 4 * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-8 + 4 * _PB_N) * t2*t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 1 - _PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -1 + lbt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((16 + 4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-16 - 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((20 - 8 * _PB_TSTEPS) + (-10 + 4 * _PB_TSTEPS) * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-4 + 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -1 + lbt1 >= 0 && -t2 + t1 >= 0) )
    {
        return (((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (2 - _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((4 - 8 * _PB_TSTEPS) + (-2 + 4 * _PB_TSTEPS) * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-4 + 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((12 - 8 * _PB_TSTEPS) + (-6 + 4 * _PB_TSTEPS) * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-4 + 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + 2*t2 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 1 - _PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0 && -1 + _PB_TSTEPS - lbt1 + t2 >= 0 && -lbt1 + ubt1 >= 0 && -1 + lbt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && lbt1 - t2 >= 0) || (-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 + lbt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && ubt1 - t2 >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -1 + t2 >= 0) || (-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 1 - _PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && 1 - _PB_N - lbt1 + 2*t2 >= 0 && _PB_N + lbt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -1 + lbt1 >= 0)) )
    {
        return (((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-6 + 3 * _PB_N) * lbt1 + (-2 + _PB_N) * lbt1*lbt1) + (((4 - 8 * _PB_TSTEPS) + (-2 + 4 * _PB_TSTEPS) * _PB_N) + (8 - 4 * _PB_N) * lbt1) * t2 + (-4 + 2 * _PB_N) * t2*t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -1 + lbt1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((((16 + 4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-18 - 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + ((28 - 8 * _PB_TSTEPS) + (-22 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && 2 - _PB_N + t2 >= 0 && -1 + lbt1 >= 0) )
    {
        return (((((((((-8 + 4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (2 - 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + ((4 - 8 * _PB_TSTEPS) + (-14 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -_PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((24 + 4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-32 - 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 14 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((28 - 8 * _PB_TSTEPS) + (-22 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -_PB_N + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return ((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-12 - 2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((4 - 8 * _PB_TSTEPS) + (-14 + 4 * _PB_TSTEPS) * _PB_N + 4 * _PB_N*_PB_N) * t2 + (4 - 2 * _PB_N) * t2*t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -3 - _PB_TSTEPS + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 3 - _PB_TSTEPS - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -3 + 2*_PB_N - t1 >= 0 && -10 + _PB_N >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((12 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (8 - 14 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N + (-4 + 4 * _PB_TSTEPS) * _PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -2 - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -1 + 2*t2 - t1 >= 0 && -10 + _PB_N >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + ((8 - 8 * _PB_TSTEPS) + (-4 + 4 * _PB_TSTEPS) * _PB_N) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -1 + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - _PB_TSTEPS + t2 >= 0 && -2 - lbt1 + t2 >= 0 && 2 - _PB_TSTEPS + ubt1 - t2 >= 0 && -2 + _PB_N - t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && ubt1 - t2 >= 0 && -10 + _PB_N >= 0 && -1 + t2 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -3 - _PB_TSTEPS + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 3 - _PB_TSTEPS - _PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -_PB_N + ubt1 >= 0 && -10 + _PB_N >= 0)) )
    {
        return (((((((((4 * _PB_TSTEPS + 4 * _PB_TSTEPS*_PB_TSTEPS) + (-2 * _PB_TSTEPS - 2 * _PB_TSTEPS*_PB_TSTEPS) * _PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (-8 * _PB_TSTEPS + 4 * _PB_TSTEPS * _PB_N) * t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -_PB_N + t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((24 - 32 * _PB_N + 14 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (32 - 24 * _PB_N + 4 * _PB_N*_PB_N) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -_PB_N + t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && 2 - _PB_N - lbt1 + 2*t2 >= 0) )
    {
        return (((((((-12 * _PB_N + 10 * _PB_N*_PB_N - 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (8 - 16 * _PB_N + 4 * _PB_N*_PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 + _PB_TSTEPS - _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 5 - 2*_PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t1 >= 0 && ubt1 - t1 >= 0 && -3 + 2*_PB_N - t1 >= 0 && -2 + _PB_TSTEPS + _PB_N - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -lbt1 + t1 >= 0) )
    {
        return (((((((-8 + 24 * _PB_N - 14 * _PB_N*_PB_N + 2 * _PB_N*_PB_N*_PB_N) + (-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && -2 + _PB_N - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -1 - t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -2 + _PB_N - 2*t2 + t1 >= 0 && -lbt1 + t1 >= 0) )
    {
        return ((((((((-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (12 - 6 * _PB_N) * t2 + (-4 + 2 * _PB_N) * t2*t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if(((-t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -1 + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - lbt1 + t2 >= 0 && -2 + _PB_N - t2 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -1 - t2 + t3 >= 0 && -2 + _PB_N + t2 - t3 >= 0 && ubt1 - t2 >= 0 && -1 + t2 >= 0) || (-_PB_N + t1 == 0 && 1 - _PB_N + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 + _PB_TSTEPS - _PB_N >= 0 && -1 + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && 5 - 2*_PB_N + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - _PB_N + t3 >= 0 && -2 + 2*_PB_N - t3 >= 0 && -_PB_N + ubt1 >= 0)) )
    {
        return ((((((((-2 + _PB_N) * lbt1 + (2 - _PB_N) * lbt1*lbt1) + (4 - 2 * _PB_N) * t2 + (-4 + 2 * _PB_N) * t2*t2) - 4 * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)))/4) ;
    }
    if((-10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t1 >= 0 && -1 + 2*t2 - t1 >= 0 && ubt1 - t1 >= 0 && -1 + _PB_TSTEPS + t2 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && -t2 + t1 >= 0 && -lbt1 + t1 >= 0 && -1 + lbt1 >= 0) )
    {
        return (((((((((16 - 18 * _PB_N + 7 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + (32 - 24 * _PB_N + 4 * _PB_N*_PB_N) * t2) + (-12 + 4 * _PB_N) * t1) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if((-2 + _PB_N - 2*t2 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && 1 + _PB_TSTEPS - t2 >= 0 && -1 - _PB_N - lbt1 + 2*t2 >= 0 && 3 + ubt1 - 2*t2 >= 0 && -3 + _PB_N - 2*t2 + t3 >= 0 && 2*t2 - t3 >= 0 && -3 + _PB_TSTEPS + _PB_N - t2 >= 0 && -2 + _PB_N + ubt1 - 2*t2 >= 0 && -1 + lbt1 >= 0 && 2 - _PB_N + t2 >= 0) )
    {
        return ((((((((-8 + 2 * _PB_N + 3 * _PB_N*_PB_N - _PB_N*_PB_N*_PB_N) + (-8 + 8 * _PB_N - 2 * _PB_N*_PB_N) * lbt1) + (8 - 16 * _PB_N + 4 * _PB_N*_PB_N) * t2) + 4 * t3) + (4 - 2 * _PB_N) * floord(lbt1, 2)) + (-4 + 2 * _PB_N) * floord(_PB_N + lbt1, 2)))/4) ;
    }
    if(((-1 - lbt1 + t1 == 0 && -2 - lbt1 + 2*t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + lbt1 >= 0 && -1 - lbt1 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -2 - lbt1 + t3 >= 0 && -1 + _PB_N + lbt1 - t3 >= 0 && -2 + 2*_PB_TSTEPS - lbt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-1 - lbt1 + t1 == 0 && -2 - lbt1 + 2*t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -4 + lbt1 >= 0 && -2 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -1 - lbt1 + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -2 - lbt1 + t3 >= 0 && -1 + _PB_N + lbt1 - t3 >= 0)) )
    {
        return ((((-3 + _PB_N) - lbt1) + t3)) ;
    }
    if(((-3 + t1 == 0 && -2 + t2 == 0 && -2 + lbt1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -3 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -4 + t3 >= 0 && 1 + _PB_N - t3 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0) || (-3 + t1 == 0 && -2 + t2 == 0 && -2 + lbt1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -4 + t3 >= 0 && 1 + _PB_N - t3 >= 0 && -3 + ubt1 >= 0)) )
    {
        return (((-5 + _PB_N) + t3)) ;
    }
    if(((-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && 2 + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0) || (-lbt1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - lbt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -lbt1 + t1 >= 0 && ubt1 - t1 >= 0 && -1 + 2*lbt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && 2 - t1 >= 0) || (-lbt1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -lbt1 + t1 >= 0 && -1 + 2*lbt1 - t1 >= 0 && -1 - t1 + t3 >= 0 && -2 + _PB_N + t1 - t3 >= 0 && 2 - t1 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -3 + _PB_N - lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -2 + 2*_PB_TSTEPS - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && -1 - lbt1 + 2*t2 >= 0 && 2 + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && 2 - _PB_N + lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - lbt1 + 2*t2 >= 0 && 2 + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0) || (-lbt1 + t1 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -3 + _PB_N - lbt1 >= 0 && -1 + 2*_PB_TSTEPS - lbt1 >= 0 && 1 - 2*_PB_TSTEPS + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 + lbt1 - t2 >= 0 && -1 - lbt1 + 2*t2 >= 0 && 2 + lbt1 - 2*t2 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0) || (-lbt1 + t1 == 0 && -1 + _PB_TSTEPS - lbt1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && -3 + _PB_N - lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0) || (-lbt1 + t1 == 0 && -1 + _PB_TSTEPS - lbt1 + t2 == 0 && -10 + _PB_TSTEPS >= 0 && -10 + _PB_N >= 0 && -2*_PB_TSTEPS + lbt1 >= 0 && 2 - _PB_N + lbt1 >= 0 && -lbt1 + ubt1 >= 0 && -4 + 2*_PB_TSTEPS + _PB_N - ubt1 >= 0 && -1 - lbt1 + t3 >= 0 && -2 + _PB_N + lbt1 - t3 >= 0)) )
    {
        return ((-t1 + t3)) ;
    }
    fprintf(stderr,"Error t2_Ranking: no corresponding domain: (t2,t1,t3,_PB_TSTEPS,_PB_N,lbt1,ubt1) = (%ld,%ld,%ld,%ld,%ld,%ld,%ld)\n",t2,t1,t3,_PB_TSTEPS,_PB_N,lbt1,ubt1);
    exit(1);
}  /* end t2_Ranking */

/************************************** t2_trahrhe_t2 **************************************/
static inline long int t2_trahrhe_t2(long int pc,long int _PB_TSTEPS,long int _PB_N,long int lbt1,long int ubt1)
{
	long int t2, t1, t3;
	long int upper_bound;
	long int fixed_upper_bound;
	long int m, rank;

    if(lbt1 + 1 >= 2 * _PB_TSTEPS ){
        t2 =  -_PB_TSTEPS + lbt1 + 1 ;
    }else{
        t2 =  lbt1 - (lbt1 + 1) / 2 + 1;
}

    if(_PB_N >= ubt1 + 2 ){
        upper_bound =  ubt1 ;
    }else{
        upper_bound =  (_PB_N + ubt1) / 2 - 1;
}
    if(_PB_N >= ubt1 + 2 ){
        fixed_upper_bound =  ubt1 ;
    }else{
        fixed_upper_bound =  (_PB_N + ubt1) / 2 - 1;
}

	while (t2+1 < upper_bound)
	{
		m = (t2 + upper_bound)/2;

    if(lbt1 >= m && _PB_N + lbt1 >= 2 * m + 2 ){
        t1 =  lbt1 ;
    }else{
    if( _PB_N >= m + 2 && m >= lbt1 + 1 ){
        t1 =  m ;
    }else{
        t1 =  -_PB_N + 2 * m + 2;
}}
    if(lbt1 >= m && _PB_N + lbt1 >= 2 * m + 2 ){
        t3 =  lbt1 + 1 ;
    }else{
    if( _PB_N >= m + 2 && m >= lbt1 + 1 ){
        t3 =  m + 1 ;
    }else{
        t3 =  -_PB_N + 2 * m + 3;
}}

		rank = t2_Ranking(m, t1, t3, _PB_TSTEPS, _PB_N, lbt1, ubt1);

		if (rank <= pc) {
			t2 = m;
		} else {
			upper_bound = m;
		}
	}
	if (t2+1==fixed_upper_bound) {
		m=t2+1;

    if(lbt1 >= m && _PB_N + lbt1 >= 2 * m + 2 ){
        t1 =  lbt1 ;
    }else{
    if( _PB_N >= m + 2 && m >= lbt1 + 1 ){
        t1 =  m ;
    }else{
        t1 =  -_PB_N + 2 * m + 2;
}}
    if(lbt1 >= m && _PB_N + lbt1 >= 2 * m + 2 ){
        t3 =  lbt1 + 1 ;
    }else{
    if( _PB_N >= m + 2 && m >= lbt1 + 1 ){
        t3 =  m + 1 ;
    }else{
        t3 =  -_PB_N + 2 * m + 3;
}}
		rank = t2_Ranking(m, t1, t3, _PB_TSTEPS, _PB_N, lbt1, ubt1);
		if (rank<=pc) t2++;
	}
	return t2;
}
