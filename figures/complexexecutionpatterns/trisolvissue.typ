#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#show raw: set text(size: 5pt)
#let diagram = diagram.with(
  spacing: 15pt,
  node-shape: rect,
  node-stroke: 0.7pt,
  edge-stroke: 0.7pt,
  node-corner-radius: 4pt,
)

#diagram(
  node((0, 0), box(width: 22em, align(left)[
    *Entry :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
    entry:
      ...
      br label %for.body1
    ```])),

  node((0, 1), box(width: 22em, align(left)[
    *for.body1 :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
      %i = phi i64 [ 0, %entry ], [ %i.next, %stmt3 ]

      %b_val = load float, ptr (%addr_b_i + %i)
      store float %b_val, ptr (%addr_x_i + %i)

      %gap_L = %i * %dim_L

      %skip_cond = icmp eq i64 %i, 0
      br i1 %skip_cond, label %for.body1.exit, label %for.body2.preheader
    ```
  ])),

  node((0, 2), box(width: 22em, align(left)[
    *for.body2.preheader :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
      %gap_L = %i * %dim_L
      br label %for.body2
    ```
  ])),

  node((0, 3), box(width: 22em, align(left)[
    *for.body2 :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
      %j = phi i64 [ 0, %stmt1.body ], [ %j.next, %stmt2 ]

      %x_i = load float, ptr (%addr_x + %i)
      %x_j = load float, ptr (%addr_x + %j)
      %L_ij = load float, ptr (%gap_L + %j)

      %mul = fmul float %L_ij, %x_j
      %sub = fsub float %x_i, %mul
      store float %sub, ptr (%addr_x + %i)

      %j.next = add i64 %j, 1
      %cmp = icmp ult i64 %j.next, %i
      br i1 %cmp, label %for.body2, label %for.body1.exit
    ```
  ])),

  node((0, 4), box(width: 22em, align(left)[
    *for.body1.exit :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
      %gap_L = phi[0, %statement1], [%gap_L, %statement2]
      %L_ii = load float, ptr (%gap_L + %i)
      %x_i = load float, ptr (%addr_x + %i)
      %div = fdiv float %x_i, %L_ii
      store float %div, ptr (%addr_x + %i)

      %i.next = add i64 %i, 1
      br label %for.body1
    ```
  ])),

  node((0, 5), box(width: 22em, align(left)[
    *exit :*
    #v(-15pt)
    #line(length: 100%, stroke: 0.5pt + gray)
    #v(-15pt)
    ```llvm
      ret void
    ```
  ])),

  edge((0, 0), (0, 1), "->"),
  edge((0, 1), (0, 2), "->"),
  edge((0, 2), (0, 3), "->"),
  edge((0, 3), (0, 4), "->"),
  edge((0, 4), (0, 5), "->"),
  //edge((0, 3), (0, 3), "->", bend: -100deg, loop-angle: 180deg),
  edge((0.905, 3.2), (0.905, 2.8), "->", bend: -40deg),
  edge((0.9, 1), (0.9, 4), "->", bend: 28deg),
  edge((0.9, 4.2), (0.9, 0.8), "->", bend: -30deg),
)
