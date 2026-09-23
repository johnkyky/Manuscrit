#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node


#show raw: set text(size: 5pt)
#let diagram = diagram.with(
  spacing: 15pt,
  node-shape: rect,
  node-stroke: 0.7pt,
  edge-stroke: 0.7pt,
  node-corner-radius: 4pt,
)
//#figure(
#table(
  columns: (0.8fr, 1fr, 1fr),
  align: (left + top, center + horizon, center + horizon),
  stroke: 0.5pt + luma(200),
  [#text(size: 1.2em)[*Description du type de dépendance*]],
  [#text(size: 1.2em)[*Pseudo IR avant*]],
  [#text(
    size: 1.2em,
  )[*Pseudo IR après*]],

  [*Dépendance scalaire sortante de la boucle :* \
    dépendance liée à la valeur de `NewVal`, calculée au sein de la boucle mais
    utilisée après son exécution.
  ],
  diagram(
    node((0, 0), box(width: 11em, align(left)[
      *entry :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      Store val to ArrayAddr
      ```])),

    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        phi = [Val, NewVal]
        ...
        NewVal = fadd ....
        store NewVal to ArrayAddr
        ...
        ```
      ]),
      name: <body_node>,
    ),

    node((0, 2), box(width: 11em, align(left)[
      *end :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      foo = fadd NewVal + ....
      ...
      ```
    ])),
    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
  diagram(
    node((0, 0), box(width: 11em, align(left)[
      *entry :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      Store val to ArrayAddr
      ```])),

    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        phi = [Val, NewVal]
        ...
        NewVal = fadd ....
        store NewVal to ArrayAddr
        ...
        ```
      ]),
      name: <body_node>,
    ),

    node((0, 2), box(width: 11em, align(left)[
      *end :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      load NewValReloaded ArrayAddr
      foo = fadd NewVal + ....
      ...
      ```
    ])),
    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),

  [*Dépendance scalaire inter-itérations :* \
    à chaque itération du corps de la boucle `body`, une nouvelle valeur
    `NewVal` est calculée pour être exploitée lors de l'itération suivante.
  ],
  diagram(
    node((0, 0), box(width: 11em, align(left)[
      *entry :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      Val = A[i][0]
      ```])),

    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        j = [1, j+1]
        phi = [Val, NewVal]
        ...
        NewVal = fadd ....
        store NewVal to A[i][j]
        ...
        ```
      ]),
      name: <body_node>,
    ),

    //node((0, 2), box(width: 11em, align(left)[
    //  *end :*
    //  #v(-10pt)
    //  #line(length: 100%, stroke: 0.5pt + gray)
    //  #v(-10pt)
    //  ```llvm
    //  ...
    //  ```
    //])),
    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
  diagram(
    node((0, 0), box(width: 11em, align(left)[
      *entry :*
      #v(-10pt)
      #line(length: 100%, stroke: 0.5pt + gray)
      #v(-10pt)
      ```llvm
      ...
      ```])),

    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        j = [1, j+1]
        load ValReloaded A[i][j-1]
        ...
        NewVal = fadd ....
        store NewVal to A[i][j]
        ...
        ```
      ]),
      name: <body_node>,
    ),

    //node((0, 2), box(width: 11em, align(left)[
    //  *end :*
    //  #v(-10pt)
    //  #line(length: 100%, stroke: 0.5pt + gray)
    //  #v(-10pt)
    //  ```llvm
    //  ...
    //  ```
    //])),
    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),

  [*Dépendance scalaire intra-bloc :* \
    la valeur `val` est chargée et utilisée à de multiples reprises au sein du
    même bloc, induisant des dépendances entre les instructions si celui-ci est
    scindé en plusieurs statements.
  ],
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        ...
        %val = load %addr
        %x = fadd %val, %a
        %y = fmul %val, %b
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        ...
        %val = load %addr
        %x = fadd %val, %a
        ...
        %val.split.1 = load %addr
        %y = fmul %val.split.1, %b
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),

  [*Dépendance scalaire intra-bloc :* \
    la valeur `val` est écrite à plusieurs reprises à des adresses distinctes,
    générant des dépendances inter-instructions si le bloc est scindé en
    plusieurs statements.
  ],
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        ...
        %val = fadd %a, %b
        store %val, %ptr1
        ...
        store %val, %ptr2
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        ...
        %val = fadd %a, %b
        store %val, %ptr1
        ...
        %val.reload = load %ptr1
        store %val.reload, %ptr2
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),

  [*Dépendance scalaire étendue :* \
    le chargement de `%val` est dissocié de son utilisation, ce qui crée des
    dépendances inter-instructions si le bloc est scindé en plusieurs
    statements.
  ],
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        phi = [...]
        %val = load %addr
        %x = fadd %a, %b
        %y = load %other_addr
        %res = fadd %val, %y
        store %res, %ptr2
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
  diagram(
    node(
      (0, 1),
      box(width: 11em, align(left)[
        *body :*
        #v(-10pt)
        #line(length: 100%, stroke: 0.5pt + gray)
        #v(-10pt)
        ```llvm
        phi = [...]
        %x = fadd %a, %b
        %y = load %other_addr
        %val = load %addr
        %res = fadd %val, %y
        store %res, %ptr2
        ...
        ```
      ]),
      name: <body_node>,
    ),

    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (0, 2), "->"),
    edge(<body_node>, <body_node>, "->", bend: -105deg, loop-angle: 180deg),
  ),
)
