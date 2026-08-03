#import "../../plot.typ" as zplot: cetz

#zplot.pseudocode-list(
  linenumbering: true,
  [

    + *For* $x_(1,1)$ = $"lb"_(1,1)$ *to* $"ub"_(1,1)$ *step* $"step"_(1,1)$ *do*
      + $S_(1,1)(x_(1,1))$
      + *For* $x_(2,1)$ = $"lb"_(2,1)$ *to* $"ub"_(2,1)$ *step* $"step"_(2,1)$ *do*
        + $S_(2,1)(x_(1,1), x_(2,1))$
        + ...
          + *For* $x_(N,1)$ = $"lb"_(N,1)$ *to* $"ub"_(N,1)$ *step* $"step"_(N,1)$ *do*
            + $S_(N,1)(x_(1,1), x_(1,1), ..., x_(N,1))$
          + *EndFor*
        + ...
        + $S_(2,2)(x_(1,1), x_(2,1))$
        + ...
      + *EndFor*
      + $S_(1,2)(x_(1,1))$
      + ...
    + *EndFor*
  ],
)

