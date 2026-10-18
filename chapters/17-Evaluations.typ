#import "../src/common.typ": *

= Évaluations <sec:evaluations>

Ce chapitre a pour vocation de quantifier et d'analyser l'impact des
contributions présentées dans les chapitres précédents. L'enjeu principal est de
démontrer que la restauration de la visibilité sémantique et structurelle au
niveau du compilateur, sans exiger de modification du code source portable
Kokkos, permet de débloquer des optimisations polyédriques de pointe. À travers
une évaluation exhaustive sur la suite de benchmarks PolyBench, nous mettrons à
l'épreuve notre chaîne de compilation sur des architectures hétérogènes (CPU
multicoeurs et accélérateurs GPU). Nous détaillerons les accélérations obtenues
par rapport à du code idiomatique, étudierons l'impact des différentes
architectures et ordonnanceurs.

== Protocole expérimental <sec:evaluations:setup>

*Version de référence.* Les performances sont mesurées par rapport à une
implémentation idiomatique des noyaux de PolyBench en #box[C++] avec Kokkos,
telle que l'écrirait un utilisateur standard de la bibliothèque : les nids de
boucles sont exprimés par des `parallel_for` simples ou imbriqués sur des
`Kokkos::View`, sans optimisation spécifique à l'architecture, comme la fusion
ou la fission de boucles, la réécriture du calcul pour exposer davantage de
parallélisme ou l'usage explicite de la mémoire partagée. Cette version est
compilée avec la même chaîne Clang, sans Polly, sur les backends standards de
Kokkos : OpenMP pour les CPU et CUDA pour les GPU. L'objectif n'est donc pas de
surpasser des codes experts optimisés pour une architecture donnée, mais de
mesurer ce que les transformations polyédriques apportent à un code Kokkos
idiomatique, sans intervention de l'utilisateur.

*Version optimisée.* La version évaluée exprime les mêmes calculs, sous la forme
attendue par notre chaîne de compilation : chaque noyau est écrit en entier dans
un `parallel_for` annoté par l'option `usePolyOpt`, y compris ses boucles
externes non parallèles. La politique d'exécution ne décrit alors plus le
parallélisme à exploiter : elle délimite l'espace d'itération du noyau et
désigne le backend ciblé. Polly analyse l'ensemble comme un nid de boucles
séquentiel, en calcule les dépendances, puis décide lui-même des boucles à
paralléliser. Le même code sert ainsi pour les deux cibles, seul l'espace
d'exécution de la politique changeant.

*Plates-formes.* Les expérimentations sont menées sur deux machines, décrites
dans le @table:evaluations:hardware : une machine bi-socket équipée de deux
processeurs AMD EPYC 7502, et une machine combinant un processeur Intel Core
Ultra 7 265 et une carte graphique NVIDIA RTX 5090. Disposer de deux
architectures CPU permet de distinguer les gains propres aux transformations de
ceux qui dépendent d'une machine particulière.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      [], [*AMD EPYC 7502*], [*Intel Core Ultra 7 265*],
      table.hline(stroke: 0.5pt),
    ),
    [Micro-architecture], [Zen 2], [Arrow Lake],
    [Fréquence de base], [2.5 GHz], [2.4 GHz (coeurs P)],
    [Fréquence maximale], [3.35 GHz], [5.3 GHz],
    [Coeurs], [64 (2 sockets $times$ 32)], [20 (8 P + 12 E)],
    [Cache L1 par coeur \ (données + instructions)],
    [32 Ko + 32 Ko],
    [48 Ko + 64 Ko (P), \ 32 Ko + 64 Ko (E)],
    [Cache L2],
    [512 Ko par coeur],
    [3 Mo par coeur P, \ 4 Mo par groupe de 4 coeurs E],
    [Cache L3],
    [$8 times 16$ Mo par socket, \ un par groupe de 4 coeurs],
    [30 Mo, partagé],
    [Mémoire], [756 Go DDR4], [32 Go DDR5],
    [Noeuds NUMA], [2, un par socket], [1],
    [Unités vectorielles], [256 bits], [256 bits],
    [Noyau Linux], [5.15.0-142-generic], [6.17.0-1030-oem],
    table.hline(stroke: 0.5pt),
    [GPU], [--], [NVIDIA RTX 5090 (Blackwell)],
    [SM / coeurs CUDA], [--], [170 / 21 760],
    [Mémoire GPU], [--], [32 Go GDDR7],
    [Mémoire partagée par SM], [--], [128 Ko],
    [Registres par SM], [--], [256 Ko],
    table.hline(stroke: 1pt),
  ),
  caption: [Caractéristiques des deux plates-formes d'évaluation.],
) <table:evaluations:hardware>

*Chaîne de compilation.* Les deux machines utilisent une version de
développement de LLVM/Clang 23.0.0 intégrant nos contributions, la version
4.6.99 de Kokkos, modifiée comme décrit dans les chapitres précédents, et PPCG
0.09.3 pour la génération de code GPU, avec les pilotes NVIDIA 595.99. Tous les
codes sont compilés en mode `Release` (`CMAKE_BUILD_TYPE=Release`).

*Mesures.* Chaque temps est la moyenne de 5 exécutions consécutives, dont la
dispersion relative reste inférieure à 4 %. Sur CPU, chaque thread OpenMP est
fixé sur un coeur et les threads sont répartis uniformément sur l'ensemble des
coeurs, et donc sur les deux sockets de la machine AMD (`OMP_PROC_BIND=spread`,
`OMP_PLACES=threads`). Chaque exécution est en outre validée : les résultats de
la version optimisée sont comparés élément par élément à ceux de la version de
référence, avec une tolérance absolue de $10^(-8)$.

*Noyaux évalués.* L'évaluation porte sur 27 des 30 noyaux de la suite
PolyBench/C~@polybench. Les trois noyaux écartés, `correlation`, `nussinov` et
`floyd-warshall`, sortent du cadre du modèle polyédrique statique : leur flot de
contrôle dépend de valeurs calculées pendant l'exécution, ce qui produit dans
l'IR LLVM des structures non affines que Polly ne peut pas représenter. Les jeux
de données ont été agrandis afin d'obtenir des temps d'exécution significatifs.
Le @table:evaluations:problemsizes donne, pour chaque noyau, sa catégorie dans
PolyBench et la taille utilisée.

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, auto, 1fr),
      align: (left + horizon, left + horizon, left + horizon),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header(
        [*Catégorie*], [*Noyau*], [*Paramètres du problème*],
        table.hline(stroke: 0.5pt),
      ),
      [Datamining], [`covariance`], [$M = 4700, N = 5000$],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 7)[BLAS],
      [`gemm`], [$N I = 5000, N J = 5500, N K = 6000$],
      [`gemver`], [$N = 20000$],
      [`gesummv`], [$N = 35800$],
      [`symm`], [$M = 1000, N = 1200$],
      [`syr2k`], [$M = 5000, N = 5200$],
      [`syrk`], [$M = 5000, N = 5200$],
      [`trmm`], [$M = 2000, N = 2600$],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Kernels],
      [`2mm`], [$N I = 5024, N J = 5048, N K = 5072, N L = 5096$],
      [`3mm`], [$N I = 5024, N J = 5048, N K = 5072, N L = 5096, N M = 5120$],
      [`atax`], [$M = 10024, N = 10048$],
      [`bicg`], [$M = 22400, N = 24800$],
      [`doitgen`], [$N Q = 656, N R = 664, N P = 672$],
      [`mvt`], [$N = 20028$],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Solvers],
      [`cholesky`], [$N = 2048$],
      [`durbin`], [$N = 15048$],
      [`gramschmidt`], [$M = 2000, N = 2600$],
      [`lu`], [$N = 2048$],
      [`ludcmp`], [$N = 2048$],
      [`trisolv`], [$N = 35048$],
      table.hline(stroke: 0.3pt),

      [Medley], [`deriche`], [$W = 1024, H = 880$],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Stencils],
      [`adi`], [$N = 1000, T = 250$],
      [`fdtd-2d`], [$N X = 900, N Y = 1100, T = 250$],
      [`heat-3d`], [$N = 256, T = 250$],
      [`jacobi-1d`], [$N = 50000, T = 10000$],
      [`jacobi-2d`], [$N = 10000, T = 250$],
      [`seidel-2d`], [$N = 10000, T = 250$],
      table.hline(stroke: 1pt),
    ),
    caption: [Catégories et tailles des 27 noyaux PolyBench évalués.],
  ) <table:evaluations:problemsizes>
]


== Évaluation sur CPU <sec:evaluations:cpu>

Cette section évalue l'efficacité de notre chaîne de compilation sur processeurs
multicoeurs. Pour chacun des 27 noyaux retenus, la version de référence Kokkos
est comparée à sa version optimisée (@sec:evaluations:setup). Les deux
ordonnanceurs polyédriques sont confrontés : l'ordonnanceur natif de Polly,
reposant sur ISL, et l'ordonnanceur Pluto (@sec:schedulingheterogeneous:pluto).
Dans les deux cas, le tuilage est appliqué avec une taille de tuile fixe de 32
sur chaque dimension, et Polly parallélise le code généré au moyen du support
d'exécution OpenMP.

=== Étude des résultats CPU <sec:evaluations:cpu:global>

La @fig:evaluations:cpu-amd et la @fig:evaluations:cpu-intel présentent les
accélérations obtenues par rapport à la version de référence sur chacune des
deux machines, sur une échelle logarithmique. Le @table:evaluations:cpu-geomean
en extrait des statistiques par famille de noyaux et globalement.

#figure(
  image(fig.evaluation-polybench-trahrhe-cpu, width: 95%),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    avec les ordonnanceurs ISL et Pluto sur processeur Dual AMD EPYC 7502
    ($2 times 32$ coeurs, 64 threads sans hyperthreading, 756 Go DDR4, taille de
    tuile : 32).],
) <fig:evaluations:cpu-amd>

#figure(
  image(fig.evaluation-polybench-eugene-cpu, width: 95%),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    avec les ordonnanceurs ISL et Pluto sur processeur Intel Core Ultra 7 265
    (20 threads sans hyperthreading, 32 Go DDR5, taille de tuile : 32).],
) <fig:evaluations:cpu-intel>

#let speedup-cell(value, count) = [#value$times$ #text(size: 0.8em)[(#count)]]

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (
      left + horizon,
      center + horizon,
      center + horizon,
      center + horizon,
      center + horizon,
      center + horizon,
    ),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      table.cell(rowspan: 2)[*Catégorie*],
      table.cell(rowspan: 2)[*Noyaux*],
      table.cell(colspan: 2)[*AMD EPYC 7502*],
      table.cell(colspan: 2)[*Intel Core Ultra 7 265*],
      [*Pluto*], [*ISL*], [*Pluto*], [*ISL*],
      table.hline(stroke: 0.5pt),
    ),
    [Datamining], [1],
    speedup-cell("11.15", "1/1"), speedup-cell("11.15", "1/1"),
    speedup-cell("19.19", "1/1"), speedup-cell("21.97", "1/1"),

    [BLAS], [7],
    speedup-cell("4.69", "5/7"), speedup-cell("4.27", "6/7"),
    speedup-cell("4.74", "6/7"), speedup-cell("3.57", "6/7"),

    [Kernels], [6],
    speedup-cell("3.99", "5/5"), speedup-cell("3.89", "6/6"),
    speedup-cell("4.37", "5/5"), speedup-cell("4.62", "5/6"),

    [Solvers], [6],
    speedup-cell("5.80", "5/6"), speedup-cell("3.48", "3/6"),
    speedup-cell("4.77", "6/6"), speedup-cell("1.57", "3/6"),

    [Medley], [1],
    speedup-cell("0.49", "0/1"), speedup-cell("0.35", "0/1"),
    speedup-cell("0.50", "0/1"), speedup-cell("0.35", "0/1"),

    [Stencils], [6],
    speedup-cell("4.31", "5/6"), speedup-cell("0.38", "2/6"),
    speedup-cell("2.08", "5/6"), speedup-cell("0.38", "1/6"),

    table.hline(stroke: 0.5pt),
    [*Ensemble*], [27],
    speedup-cell("4.44", "21/26"), speedup-cell("2.21", "18/27"),
    speedup-cell("3.74", "23/26"), speedup-cell("1.88", "16/27"),
    table.hline(stroke: 1pt),
  ),
  caption: [Moyennes des accélérations sur CPU par catégorie de benchmark et par
    ordonnanceur. Entre parenthèses figure le nombre de noyaux accélérés sur
    nombre de noyaux évalués.],
) <table:evaluations:cpu-geomean>

Le premier constat est que les transformations débloquées par nos contributions
profitent à la grande majorité des noyaux : sur chacune des deux machines, 24
des 27 noyaux sont accélérés par au moins l'un des deux ordonnanceurs. En
retenant pour chaque noyau le meilleur des deux ordonnanceurs, la moyenne
géométrique des accélérations atteint 5.32$times$ sur la machine AMD et
4.36$times$ sur la machine Intel. L'accélération maximale, 118.26$times$, est
obtenue sur `lu` avec l'ordonnanceur ISL sur la machine AMD. Ces résultats
confirment qu'une fois la structure des boucles rendue visible à Polly, les
transformations polyédrique exploite efficacement la localité et le parallélisme
laissés inexploités par une écriture Kokkos idiomatique des noyaux.

Le second constat est que l'ordonnanceur Pluto surpasse l'ordonnanceur ISL en
moyenne : 4.44$times$ contre 2.21$times$ sur AMD, 3.74$times$ contre 1.88$times$
sur Intel. Comme le montre le @table:evaluations:cpu-geomean, cet écart se
concentre sur deux catégories. Sur les _stencils_, l'ordonnanceur ISL dégrade
systématiquement les performances (0.38$times$ sur les deux machines, contre
4.31$times$ et 2.08$times$ pour Pluto). Sur les _solvers_, il n'accélère que la
moitié des noyaux (3.48$times$ et 1.57$times$, contre 5.80$times$ et 4.77$times$
pour Pluto). Sur les catégories _datamining_, _blas_ et _kernels_, en revanche,
les deux ordonnanceurs restent comparables, ISL prenant même l'avantage sur les
_kernels_ et sur `covariance` sur la machine Intel.

Sur les 54 variantes compilées (27 noyaux $times$ 2 ordonnanceurs), 53
produisent des résultats conformes à la référence. Seul le noyau `atax` avec
l'ordonnanceur Pluto produit un résultat erroné, en raison d'un ordonnancement
invalide. L'erreur provient de l'outil Pluto lui-même. En reproduisant le noyau
sans la première boucle (remplacée par un `memset` par LLVM lors de la
compilation), on obtient le même résultat incorrect.


=== Comportements stables entre architectures <sec:evaluations:cpu:invariants>

Cette section isole les comportements observés de manière identique sur les deux
machines. Ils caractérisent les transformations elles-mêmes, indépendamment du
matériel.

==== Succès systématiques

Plusieurs noyaux bénéficient d'accélérations importantes avec les deux
ordonnanceurs et sur les deux machines. Le cas le plus marquant est `symm`, qui
atteint 34.19$times$ (Pluto) et 27.75$times$ (ISL) sur la machine AMD, et
24.27$times$ et 26.10$times$ sur la machine Intel. Les produits matriciels `2mm`
et `3mm` (de 7.08$times$ à 12.23$times$), `covariance` (de 11.15$times$ à
21.97$times$), `syr2k`, `gramschmidt` et `bicg` présentent un profil similaire.
Ces noyaux partagent une forte réutilisation des données, avec un volume de
calcul en $O(n^3)$ pour des données en $O(n^2)$, que la version de référence
n'exploite pas. Dans ces versions de référence, la boucle la plus interne,
écrite dans le corps de la lambda, parcourt une colonne d'au moins un tableau
stocké par lignes, avec un grand pas entre deux accès successifs. Or Kokkos ne
tuile que les dimensions d'une `MDRangePolicy`, jamais les boucles écrites dans
la lambda : la plupart de ces versions reposent sur une `RangePolicy` et ne sont
pas tuilées du tout, et seules celles de `2mm` et `3mm` découpent l'espace
`(i, j)` en tuiles de $32 times 32$, sans toucher à la boucle de réduction. Le
tuilage polyédrique porte au contraire sur l'ensemble du nid, boucle de
réduction comprise, comme l'illustrent `symm` ci-dessous et `covariance`
(@sec:evaluations:cpu:sensitivity) : les accès à grand pas sont confinés à des
blocs de petite taille, réutilisés depuis les caches.

Le cas de `symm` illustre la combinaison de transformations à l'origine de ces
gains. Pour chaque élément `(i, j)`, ce noyau accumule une somme partielle
`tmp(i, j)` tout en mettant à jour les éléments `C(k, j)` des lignes précédentes
(@code:evaluations:symm-kokkos). Ces mises à jour relient entre elles toutes les
itérations de `i`, si bien que seule la boucle `j` est parallèle dans le nid
d'origine. ISL sépare le corps du nid en plusieurs nids distincts, chacun
parallèle et tuilé par blocs de 32 (@code:evaluations:symm-isl) : l'accumulation
de `tmp` et la mise à jour finale de `C(i, j)` sont parallélisées sur `i`, et
les mises à jour de `C(k, j)` sur `j`. Cette séparation n'est possible que parce
que `tmp` est un tableau : chaque itération dispose de son propre emplacement,
contrairement aux scalaires de `deriche` discutés plus loin. Elle repose aussi
sur nos contributions : la boucle sur `k` étant triangulaire, le nid n'est
reconnu comme un SCoP que grâce à l'épluchage de sa première itération
(@sec:complexexecutionpatterns:triangularloop).

L'ampleur du gain tient à la version de référence. Celle-ci exécute la boucle
`i` séquentiellement sur l'hôte et lance, à chacune de ses $M = 1000$
itérations, un `parallel_for` sur `j`. Chaque lancement relit les `i` premières
lignes de `C` et de `B` colonne par colonne : ces matrices de 9.6 Mo ne tiennent
pas dans les caches privés, et leurs éléments sont rechargés à chaque itération
de `i`. Le tuilage supprime ce trafic : chaque bloc de `C` reste en cache le
temps de recevoir toutes ses mises à jour.

#figure(
  ```cpp
  // Version de référence
  const auto policy = Kokkos::RangePolicy<Kokkos::OpenMP>(0, n);
  for (INT_TYPE i = 0; i < m; i++) {
    Kokkos::parallel_for(
        policy, KOKKOS_LAMBDA(const INT_TYPE j) {
          tmp(i, j) = 0;
          for (INT_TYPE k = 0; k < i; k++) {
            C(k, j) += alpha * B(i, j) * A(i, k);
            tmp(i, j) += B(k, j) * A(i, k);
          }
          C(i, j) = beta * C(i, j) + alpha * B(i, j) * A(i, i) + alpha * tmp(i, j);
        });
  }

  // Version analysée par Polly
  Kokkos::parallel_for<Kokkos::usePolyOpt, "p0.l==0, p0.u0>10, p0.u1>15">(
      policy, KOKKOS_LAMBDA(const INT_TYPE i, const INT_TYPE j) {
        tmp(i, j) = 0;
        for (INT_TYPE k = 0; k < i; k++) {
          C(k, j) += alpha * B(i, j) * A(i, k);
          tmp(i, j) += B(k, j) * A(i, k);
        }
        C(i, j) = beta * C(i, j) + alpha * B(i, j) * A(i, i) + alpha * tmp(i, j);
      });
  ```,
  caption: [Implémentations Kokkos du noyau `symm` : version de référence,
    parallélisée sur `j` seul, et version analysée par Polly (`usePolyOpt`).],
) <code:evaluations:symm-kokkos>

#figure(
  ```cpp
  // Accumulation de tmp : parallèle sur i
  parallel for (tuiles de i)
    for (tuiles de j)
      for (tuiles de k)
        tmp(i, j) += B(k, j) * A(i, k);
  // Mise à jour finale de C(i, j) : parallèle sur i
  parallel for (tuiles de i)
    for (tuiles de j)
      C(i, j) = beta * C(i, j) + alpha * B(i, j) * A(i, i) + alpha * tmp(i, j);
  // Mises à jour de C(k, j) : parallèle sur j
  parallel for (tuiles de j)
    for (tuiles de k)
      for (tuiles de i)
        C(k, j) += alpha * B(i, j) * A(i, k);
  ```,
  caption: [Structure simplifiée du code généré par Polly avec l'ordonnanceur
    ISL pour `symm` : les trois nids principaux, parcourus par tuiles de 32. Les
    boucles internes aux tuiles et les instructions secondaires sont omises.],
) <code:evaluations:symm-isl>

L'ordonnanceur Pluto obtient également des gains stables sur plusieurs noyaux où
l'ordonnanceur ISL échoue ou reste nettement en retrait : `seidel-2d`
(18.56$times$ et 15.66$times$), `cholesky` (14.52$times$ et 7.31$times$),
`ludcmp` (14.20$times$ et 8.75$times$) et `trisolv` (2.30$times$ et
3.67$times$). Ces noyaux présentent des dépendances portées par toutes les
dimensions du nid de boucles, de sorte qu'aucune boucle n'est directement
parallélisable sans transformation préalable. En appliquant des transformations
de torsion de boucle, Pluto rend le nid de boucle tuilable et expose un
parallélisme en front d'onde entre les tuiles.

Le code généré par Pluto pour `seidel-2d` illustre ce mécanisme
(@code:evaluations:seidel-pluto). Chaque instance $(t, i, j)$ y est placée en
$(t, t + i, 2t + i + j)$ : cette torsion rend les trois dimensions tuilables.
Les tuiles sont ensuite parcourues par fronts d'onde : les fronts sont traités
l'un après l'autre, et les tuiles d'un même front, indépendantes, s'exécutent en
parallèle. Pluto applique le même mécanisme à `ludcmp`.

L'écriture des versions de référence explique l'ampleur de ces gains. La version
de `seidel-2d` est entièrement séquentielle, la mise à jour en place du tableau
interdisant toute parallélisation directe. Les accélérations de Pluto
(18.56$times$ et 15.66$times$) mesurent directement le parallélisme par front
d'onde et le gain de localité grâce au tuilage des boucles. `ludcmp` n'est que
partiellement parallèle. La boucle externe de la factorisation s'exécute
séquentiellement tandis que la partie supérieure de chaque ligne, est
parallélisée. En parallélisant l'ensemble de la factorisation par fronts d'onde,
Pluto lève cette limite.

L'écriture des versions de référence explique l'ampleur de ces gains. La version
de `seidel-2d` est entièrement séquentielle, la mise à jour en place du tableau
interdisant toute parallélisation directe. Les accélérations de Pluto
(18.56$times$ et 15.66$times$) mesurent donc à la fois le parallélisme par front
d'onde et le gain de localité apporté par le tuilage des boucles. La version de
référence de `ludcmp` n'est que partiellement parallèle : la boucle externe de
la factorisation s'exécute séquentiellement, et à chacune de ses itérations
seule la partie supérieure de la ligne est parallélisée, la partie inférieure
restant séquentielle. En transformant l'ensemble de la factorisation par fronts
d'onde, Pluto lève cette limitation de parallélisation.

#figure(
  ```cpp
  // Fronts d'onde de tuiles : séquentiels
  #pragma minimal dependence distance: 1
  for (int c0 = 0; c0 <= floord(N + 2 * T - 5, 32); c0 += 1)
    // Tuiles d'un même front : parallèles
    #pragma omp parallel for
    for (int c1 = ...; c1 <= ...; c1 += 1)
      #pragma minimal dependence distance: 1
      for (int c2 = ...; c2 <= ...; c2 += 1)
        // Points de la tuile
        for (int c3 = ...; c3 <= ...; c3 += 1)          // t
          for (int c4 = ...; c4 <= ...; c4 += 1)        // t + i
            for (int c5 = ...; c5 <= ...; c5 += 1)      // 2t + i + j
              Stmt2(c3, -c3 + c4, -c3 - c4 + c5);
  ```,
  caption: [Structure de l'AST généré par Polly avec l'ordonnanceur Pluto pour
    `seidel-2d` sur CPU.],
) <code:evaluations:seidel-pluto>

==== Échecs récurrents

À l'inverse, quatre catégories d'échecs se reproduisent à l'identique sur les
deux machines.

*Les noyaux sans réutilisation de données.* `gesummv` reste neutre quels que
soient l'ordonnanceur et la machine (entre 0.91$times$ et 0.99$times$), et
`doitgen` comme `mvt` n'obtiennent que des gains modestes. Ces noyaux de type
matrice-vecteur lisent chaque élément de matrice une seule fois : leur
performance est bornée par la bande passante mémoire et le tuilage n'a aucune
localité à exploiter.

*Les récurrences portées par des scalaires.* Le noyau `deriche` régresse sur les
deux machines avec les deux ordonnanceurs (de 0.35$times$ à 0.50$times$). Ce
filtre parcourt l'image ligne par ligne, puis colonne par colonne. Le long d'une
ligne, chaque pixel dépend des pixels déjà traités, dont les valeurs sont
transmises d'une itération à l'autre par des variables scalaires remises à zéro
au début de chaque ligne. Les lignes, comme les colonnes, restent donc
indépendantes les unes des autres, et la version de référence les traite en
parallèle.

Le modèle polyédrique ne voit pas cette indépendance. Polly représente chaque
scalaire par un emplacement mémoire unique, partagé par toutes les lignes : du
point de vue du modèle, chaque ligne réécrit les valeurs laissées par la
précédente, ce qui crée de fausses dépendances entre les lignes. Les deux
ordonnanceurs exécutent alors séquentiellement les quatre passes récursives
(@code:evaluations:deriche-isl), et le parallélisme se réduit pour l'essentiel
aux deux passes qui combinent leurs résultats, dépourvues de scalaires.
Transformer ces scalaires en tableaux indexés par la ligne, ou les privatiser,
suffirait à lever ces fausses dépendances.

#figure(
  ```cpp
  // Passe récursive sur les lignes : séquentielle
  #pragma minimal dependence distance: 1
  for (int c0 = 0; c0 < w; c0 += 1) {      // lignes
    Stmt0(c0);                             // remise à zéro des scalaires
    #pragma minimal dependence distance: 1
    for (int c1 = 0; c1 < h; c1 += 1)      // pixels de la ligne
      Stmt1(c0, c1);
  }
  // Passe de combinaison : tuilée et parallèle
  #pragma omp parallel for
  for (int c0 = 0; c0 <= (w - 1) / 32; c0 += 1)
    for (int c1 = 0; c1 <= (h - 1) / 32; c1 += 1)
      for (int c2 = ...; c2 <= ...; c2 += 1)
        #pragma simd
        for (int c3 = ...; c3 <= ...; c3 += 1)
          Stmt8(32 * c0 + c2, 32 * c1 + c3);
  ```,
  caption: [Extrait de l'AST généré par Polly avec l'ordonnanceur ISL pour
    `deriche` sur CPU : une passe récursive et une passe de combinaison.],
) <code:evaluations:deriche-isl>

*L'ordonnanceur ISL sur les stencils.* L'ordonnanceur ISL s'effondre sur
`heat-3d` (0.01$times$ et 0.02$times$) et dégrade `jacobi-1d` (0.23$times$ et
0.20$times$), `jacobi-2d` (0.70$times$ et 0.74$times$) et `fdtd-2d` (0.47$times$
et 0.67$times$). Sur ces noyaux, chaque pas de temps dépend du précédent, ce qui
interdit de paralléliser directement les boucles externes. ISL parvient pourtant
à tuiler le nid, y compris selon la dimension temporelle, grâce à une torsion
des boucles (@code:evaluations:heat3d-isl). Mais il n'exécute pas en parallèle
les tuiles indépendantes. La seule boucle parallèle qu'il identifie comme
parallèle est la plus interne mais Polly ne génère pas de parallélisation pour
une telle boucle (rarement rentable). Le code généré s'exécute sur un seul
coeur, alors que la version de référence parallélise chaque pas de temps. Le
même phénomène se produit sur `jacobi-1d`, `jacobi-2d` et `fdtd-2d`.

#figure(
  ```cpp
  // Boucles de tuiles (t, i, j, k) : séquentielles
  #pragma minimal dependence distance: 1
  for (int c0 = 0; c0 <= (T - 1) / 32; c0 += 1)
    #pragma minimal dependence distance: 1
    for (int c1 = ...; c1 <= ...; c1 += 1)
      #pragma minimal dependence distance: 1
      for (int c2 = ...; c2 <= ...; c2 += 1)
        #pragma minimal dependence distance: 1
        for (int c3 = ...; c3 <= ...; c3 += 1)
          // Boucles de points : seule la plus interne est parallèle
          #pragma minimal dependence distance: 1
          for (int c4 = ...; c4 <= ...; c4 += 1)
            #pragma minimal dependence distance: 1
            for (int c5 = ...; c5 <= ...; c5 += 1)
              #pragma minimal dependence distance: 1
              for (int c6 = ...; c6 <= ...; c6 += 1)
                #pragma simd
                #pragma known-parallel
                for (int c7 = ...; c7 <= ...; c7 += 1) {
                  Stmt3(...);  // calcul de B à partir de A
                  Stmt9(...);  // calcul de A à partir de B
                }
  ```,
  caption: [Structure de l'AST généré par Polly avec l'ordonnanceur ISL pour
    `heat-3d` sur CPU. Les bornes des boucles, les indices et les gardes sont
    omis, et le paramètre `p_1` a été renommé `T`. Aucune boucle n'est annotée
    `omp parallel for` : la seule boucle parallèle, la plus interne, est
    uniquement vectorisée.],
) <code:evaluations:heat3d-isl>

Pluto, au contraire, exécute en parallèle les tuiles indépendantes, parcourues
par fronts d'onde, et accélère ces mêmes noyaux, par exemple `jacobi-2d`
(18.63$times$ et 8.70$times$). Le cas de `seidel-2d`, entièrement séquentielle
pour la référence, illustre bien cette différence : ISL l'accélère (2.43$times$
et 2.92$times$) grâce à l'amélioration de la localité, puisque le code tuilé
reste séquentiel. Tandis que Pluto le parallélise par fronts d'onde
(@code:evaluations:seidel-pluto) atteint 18.56$times$ et 15.66$times$
d'accélération.

ISL échoue également sur les solveurs triangulaires `ludcmp` (0.76$times$ et
0.95$times$) et `trisolv` (0.96$times$ et 0.92$times$). Sur `trisolv`, il
échange les deux boucles du nid, mais la seule boucle parallèle obtenue est à
nouveau la plus interne : comme pour les stencils, le code généré est
entièrement séquentiel, et parcourt de plus la matrice colonne par colonne. La
version de référence n'est guère plus efficace : elle lance une réduction
parallèle pour chacune des 35 048 lignes de la matrice, dont le coût de
lancement pèse lourdement face au peu de travail confié à chaque thread. Ces
deux inefficacités se compensent vraisemblablement, d'où des performances
proches de la référence.

Sur `ludcmp`, ISL conserve la structure d'origine du nid, sans tuilage, et
reproduit la parallélisation de la version de référence, là où Pluto parallélise
l'ensemble de la factorisation par fronts d'onde. Faute de gain de localité, le
code généré ne peut au mieux qu'égaler la référence, et ses surcoûts propres se
traduisent par un léger ralentissement.

*L'ordonnanceur Pluto sur `adi`.* Symétriquement, Pluto régresse fortement sur
`adi` sur les deux machines (0.12$times$ et 0.03$times$), alors qu'ISL
l'accélère sur la machine AMD (1.64$times$). Chaque pas de temps de ce noyau
enchaîne deux balayages de la grille, l'un selon les colonnes et l'autre selon
les lignes. Chaque balayage se compose de deux phases, une descente puis une
remontée, qui sont des récurrences le long de chaque colonne, ou de chaque
ligne, de la grille. Ces colonnes et ces lignes étant indépendantes les unes des
autres, la version de référence parallélise chacune des quatre phases, et ISL
préserve ce parallélisme.

Pluto fusionne au contraire la remontée du balayage selon les colonnes avec la
descente du balayage selon les lignes, qui en consomme les résultats. Ces deux
phases parcourant la grille dans des ordres transposés, la fusion impose une
torsion : le nid fusionné est parcouru par anti-diagonales, l'une après l'autre
(@code:evaluations:adi-pluto). Seule une partie du calcul est alors
parallélisée, le long de chaque anti-diagonale, au prix d'une synchronisation
par anti-diagonale, soit près de 500 000 sur l'ensemble de l'exécution ; le
reste du nid fusionné s'exécute sur un seul cœur. Deux des quatre phases perdent
ainsi l'essentiel du parallélisme de la version de référence.

#figure(
  ```cpp
  // Remontée en colonnes et descente en lignes, fusionnées
  #pragma minimal dependence distance: 1
  for (int c3 = 0; c3 < 2 * N - 5; c3 += 1) {  // anti-diagonales
      #pragma minimal dependence distance: 1
      for (int c8 = 0; c8 < N - 2; c8 += 1)
      Stmt4(...);   // remontée en colonnes : séquentielle
    #pragma omp parallel for
    for (int c8 = ...; c8 <= ...; c8 += 1)
      #pragma simd
      for (int c9 = ...; c9 <= ...; c9 += 1)
        Stmt8b(...);  // descente en lignes, 1re partie : parallèle
      #pragma minimal dependence distance: 1
      for (int c8 = 0; c8 < N - 2; c8 += 1)
      Stmt8(...);   // descente en lignes, 2e partie : séquentielle
  }
  ```,
  caption: [Extrait de l'AST généré par Polly avec l'ordonnanceur Pluto pour
    `adi` sur CPU, à l'intérieur de la boucle temporelle. Les bornes, les
    indices et les gardes sont omis, et le paramètre `p_0` a été renommé `N`.],
) <code:evaluations:adi-pluto>

Ces échecs se reproduisent à l'identique sur les deux machines : ils proviennent
donc des ordonnanceurs ou du modèle lui-même, et non du matériel. Ni ISL ni
Pluto ne disposent d'un modèle de coût capable d'estimer le parallélisme
réellement exploité ou l'absence de réutilisation des données, et aucun des deux
ne domine l'autre sur l'ensemble des noyaux, ce qui justifie a posteriori
l'intégration de Pluto comme alternative à l'ordonnanceur natif.

=== Sensibilité au matériel <sec:evaluations:cpu:sensitivity>

Au-delà de ces invariants, plusieurs noyaux présentent des écarts importants
entre les deux machines, qui révèlent la sensibilité des transformations aux
caractéristiques matérielles.

==== Le cas de la factorisation `lu`

Le noyau `lu` présente l'écart le plus spectaculaire : sur la machine AMD, ISL
atteint 118.26$times$ et Pluto 18.45$times$, contre respectivement 5.27$times$
et 9.21$times$ sur la machine Intel. Deux effets se combinent.

Le premier, prépondérant, tient à la version de référence, six fois plus lente
sur la machine AMD (14.29 s) que sur la machine Intel (2.27 s). Comme celle de
`ludcmp`, elle n'est parallèle que pour moitié : la boucle externe s'exécute
séquentiellement, et à chacune de ses itérations seule la partie supérieure de
la ligne est calculée en parallèle. Cette moitié séquentielle pénalise
vraisemblablement davantage la machine AMD, dont les coeurs sont moins rapides
et dont chaque coeur ne dispose que d'une tranche de 16 Mo de cache L3, trop
petite pour la matrice de 32 Mo, alors qu'un coeur Intel accède aux 30 Mo du L3.
Chaque itération se termine en outre par une synchronisation, qui réunit sur la
machine AMD 64 threads répartis sur deux sockets.

Le second effet est l'inversion entre les deux ordonnanceurs, qui adoptent des
stratégies opposées. ISL réorganise la factorisation en une succession d'étapes
séquentielles, dont chacune met à jour en parallèle la sous-matrice restante,
avec des accès contigus et vectorisés. Pluto tuile au contraire l'ensemble du
calcul et le parcourt par fronts d'onde, comme pour `ludcmp` : il réutilise
mieux les données et se synchronise beaucoup moins souvent, mais chaque front ne
compte qu'au plus 64 tuiles, de charges inégales, et sa boucle la plus interne
n'est pas vectorisée. Les temps d'exécution traduisent ces différences. Le code
d'ISL tire parti du nombre de coeurs : il s'exécute en 0.12 s sur les 64 coeurs
de la machine AMD, contre 0.43 s sur les 20 coeurs de la machine Intel. Celui de
Pluto est au contraire plus rapide sur la machine Intel (0.25 s contre 0.77 s) :
ses fronts d'onde ne suffisent vraisemblablement pas à occuper les 64 coeurs de
la machine AMD, et sa boucle interne profite de la fréquence plus élevée des
coeurs Intel.

Une exploration de la taille de tuile sur `lu` confirme enfin que la taille par
défaut de 32 est sous-optimale sur les deux machines, mais seulement modérément
: le meilleur choix (tuiles de $8 times 32 times 32$ sur la machine AMD, de
$32 times 64 times 4$ sur la machine Intel) n'apporte qu'un gain supplémentaire
de 1.24$times$ et 1.16$times$. #text(red)[Préciser l'ordonnanceur utilisé pour
  cette exploration.] Le réglage de la taille de tuile affine donc les
performances, mais n'explique pas l'écart entre les architectures.

==== Régressions liées au tuilage fixe

Pour `cholesky` et `adi`, ISL obtient 4.68$times$ et 1.64$times$ sur la machine
AMD, mais régresse à 0.74$times$ et 0.52$times$ sur la machine Intel ;
l'accélération de Pluto sur `cholesky` est elle aussi divisée par deux (de
14.52$times$ à 7.31$times$). Les deux ordonnanceurs utilisent une taille de
tuile fixe de 32. Or le cache L2 de 3 Mo de la machine Intel contient déjà une
grande partie des données manipulées par la version de référence : le tuilage
n'y apporte plus de gain de localité, et son surcoût le rend contre-productif.
Sur la machine AMD, dont le L2 ne fait que 512 Ko, le tuilage reste bénéfique.

==== Variations liées au goulot d'étranglement de la machine

Plusieurs noyaux voient leur rentabilité évoluer en sens opposés d'une machine à
l'autre.

Pour `gemm` et `syrk`, l'accélération diminue sur la machine Intel : `gemm`
passe d'environ 5.7$times$ à environ 2.5$times$ avec les deux ordonnanceurs, et
`syrk` d'environ 5.9$times$ à 4.0$times$. Le gain du tuilage vient ici de la
réutilisation des données en cache : la version de référence de `gemm`, par
exemple, relit une matrice entière pour chaque ligne du résultat. Sur la machine
Intel, la fréquence élevée des coeurs, le grand cache L2 et le préchargement
matériel permettent à la version de référence d'exploiter déjà une partie de
cette réutilisation, ce qui réduit la marge laissée au tuilage.

Inversement, `covariance` gagne en rentabilité sur la machine Intel (de
11.15$times$ à 19.19$times$ et 21.97$times$), de même que `atax` avec ISL (de
2.69$times$ à 9.51$times$), `gemver` (de 1.0$times$ à environ 2.0-2.5$times$) et
`trmm` avec Pluto (de 4.86$times$ à 9.96$times$). Pour `covariance`, ISL et
Pluto tuilent le calcul de la même manière, d'où des accélérations identiques
sur la machine AMD : les données, que la version de référence parcourt colonne
par colonne, sont alors traitées par petits blocs réutilisés depuis le cache. Ce
gain reste toutefois bridé par la répartition du travail. Le calcul étant
triangulaire, les premières lignes sont les plus coûteuses. La version de
référence distribue les lignes aux threads de manière cyclique, ce qui équilibre
la charge, alors que le code généré distribue des blocs contigus de lignes : le
premier thread reçoit les lignes les plus coûteuses, et sa charge atteint 2.6
fois la moyenne sur la machine AMD, contre 2.1 fois sur la machine Intel. Ce
déséquilibre, plus marqué avec 64 threads qu'avec 20, explique une partie de
l'écart entre les deux machines. #text(red)[À compléter : origine du reste de
  l'écart.]

Pour `atax`, la version de référence enchaîne plus de 20 000 lancements
parallèles, chacun ne portant que sur une seule ligne de la matrice. ISL sépare
au contraire le calcul en deux nids parallèles, qui ne nécessitent que deux
lancements, au prix d'une seconde lecture de la matrice. #text(red)[À compléter
  : expliquer l'écart entre les deux machines (2.69$times$ contre 9.51$times$).]

Enfin, `durbin` régresse sur la machine AMD (0.51$times$ et 0.56$times$) mais
s'accélère légèrement sur la machine Intel (1.28$times$ et 1.32$times$). Ce
noyau comporte une boucle externe intrinsèquement séquentielle, dont chaque
itération ne contient que de petites boucles. La version de référence
parallélise ces petites boucles, au prix de trois synchronisations par
itération, tandis que le code généré par ISL comme par Pluto est entièrement
séquentiel, Polly ne parallélisant ni la réduction ni les boucles les plus
internes. Le résultat dépend donc du matériel : le code séquentiel profite de la
fréquence élevée d'un coeur Intel, mais ne rivalise pas, sur la machine AMD et
ses coeurs plus lents, avec une version parallèle répartie sur 64 coeurs.


=== Bilan de l'évaluation sur CPU <sec:evaluations:cpu:summary>

Cette évaluation montre que la visibilité restaurée par nos contributions permet
à Polly d'optimiser des codes Kokkos non modifiés avec des gains substantiels :
24 des 27 noyaux sont accélérés sur chaque machine, avec une moyenne géométrique
atteignant 4.44$times$ avec Pluto sur la machine AMD.

Elle met également en évidence deux sources d'instabilité. La première est
algorithmique : aucun ordonnanceur ne domine sur l'ensemble des noyaux. Pluto
s'impose sur les stencils et les solveurs triangulaires, tandis qu'ISL l'emporte
sur `lu` (AMD), `adi` ou `covariance` (Intel). Disposer des deux ordonnanceurs
au sein de la même chaîne de compilation est donc un atout, et Pluto constitue
le choix par défaut le plus sûr pour la famille des stencils. La seconde est
matérielle : la taille de tuile fixe et l'absence de modèle de coût prenant en
compte la hiérarchie de caches provoquent des régressions sur certaines
architectures, comme `cholesky` et `adi` sur la machine Intel. Ces observations
motivent la sélection adaptative des paramètres de tuilage en fonction de
l'architecture cible, discutée en fin de chapitre.

La section suivante étend cette évaluation aux accélérateurs GPU, où la
génération de code repose sur PPCG.

== Évaluation sur GPU <sec:evaluations:gpu>

Cette section évalue la génération de code GPU rendue possible par la
réintégration de PPCG dans Polly (@sec:schedulingheterogeneous:ppcg). La version
de référence suit la même démarche que sur CPU : une implémentation Kokkos
idiomatique, compilée avec le backend CUDA de Kokkos, qui parallélise
directement les boucles parallèles de l'algorithme d'origine, à la manière des
implémentations de la suite PolyBench/GPU @polybenchgpu. La version optimisée
est celle décrite dans la @sec:evaluations:setup, dont la politique d'exécution
désigne cette fois le backend CUDA : le calcul de l'ordonnancement, le placement
mémoire et la projection sur la grille de blocs et de threads sont délégués à
PPCG.

Les mesures sont réalisées sur la carte NVIDIA RTX 5090 de la machine Intel
(@table:evaluations:hardware) et incluent, dans les deux versions, les
transferts de données entre l'hôte et le GPU. Kokkos choisit dynamiquement la
taille des blocs de threads de la version de référence. PPCG découpe au
contraire chaque noyau en tuiles de 32 itérations fixes par dimension, confiées
à des blocs de 32 threads pour un noyau à une dimension et de $4 times 32$
threads pour un noyau à deux dimensions. La promotion des données en mémoire
partagée, limitée à 16 Ko par bloc, et leur privatisation en registres sont
activées.

=== Étude des résultats GPU <sec:evaluations:gpu:global>

Sur les 27 noyaux évalués, 24 sont compilés et produisent des résultats corrects
avec PPCG. Les trois noyaux restants, `adi`, `fdtd-2d` et `heat-3d`, n'ont pas
pu être compilés : l'ordonnancement calculé par PPCG ne termine pas en un temps
raisonnable, en raison du nombre considérable de contraintes générées pour ces
nids de boucles.

La @fig:evaluations:gpu présente les accélérations obtenues sur les 24 noyaux
restants, et le @table:evaluations:gpu-geomean en résume les moyennes
géométriques par catégorie.

#figure(
  image(fig.evaluation-polybench-eugene-gpu),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    avec l'ordonnanceur PPCG sur accélérateur NVIDIA RTX 5090 (32 Go VRAM, hôte
    Intel Core Ultra 7 265, 20 threads sans hyperthreading, 32 Go DDR5, taille
    de bloc : auto).],
) <fig:evaluations:gpu>

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    align: (
      left + horizon,
      center + horizon,
      center + horizon,
    ),
    stroke: none,
    table.hline(stroke: 1pt),
    table.header(
      table.cell(rowspan: 2)[*Catégorie*],
      table.cell(rowspan: 2)[*Noyaux*],
      [*NVIDIA RTX 5090*],
      [*PPCG*],
      table.hline(stroke: 0.5pt),
    ),
    [Datamining], [1], speedup-cell("7.31", "1/1"),

    [BLAS], [7], speedup-cell("5.58", "6/7"),

    [Kernels], [6], speedup-cell("0.82", "2/6"),

    [Solvers], [6], speedup-cell("189.10", "6/6"),

    [Medley], [1], speedup-cell("0.20", "0/1"),

    [Stencils], [6], speedup-cell("5.08", "1/3"),

    table.hline(stroke: 0.5pt),
    [*Ensemble*], [27], speedup-cell("7.25", "16/24"),
    table.hline(stroke: 1pt),
  ),
  caption: [Moyennes géométriques des accélérations sur GPU par catégorie de
    benchmark. Entre parenthèses figure le nombre de noyaux accélérés sur nombre
    de noyaux évalués.],
) <table:evaluations:gpu-geomean>

Les accélérations s'étendent sur plus de quatre ordres de grandeur, de
0.12$times$ sur `jacobi-1d` à 3581.16$times$ sur `lu`. Seize noyaux sont
accélérés, dont `gemver` de façon marginale (1.01$times$), quatre restent
pratiquement neutres (`gesummv`, `atax`, `bicg` et `mvt`, à 0.99$times$) et
quatre régressent (`doitgen`, `deriche`, `jacobi-1d` et `jacobi-2d`). La moyenne
géométrique globale de 7.25$times$ est tirée vers le haut par les six noyaux
dont la version de référence est limitée par une boucle externe séquentielle.
Sans eux, l'accélération moyenne est de 1.65$times$. Les résultats se
répartissent ainsi en trois groupes, détaillés ci-dessous.

=== Parallélisation des noyaux à dépendances <sec:evaluations:gpu:dependences>

Les accélérations les plus élevées concernent les solveurs et les factorisations
: `lu` (#box[3581.16$times$]), `cholesky` (#box[3474.92$times$]), `durbin`
(#box[178.65$times$]), `ludcmp` (#box[123.25$times$]) et `trisolv`
(#box[105.62$times$]), ainsi que le stencil `seidel-2d` (#box[1823.46$times$]).
Ces noyaux ont en commun une boucle externe porteuse de dépendances, qui
interdit une projection directe de l'ensemble du nid sur la grille de threads.
Dans la version de référence, cette boucle externe s'exécute séquentiellement
sur l'hôte, et seules les boucles internes parallèles de l'algorithme d'origine
sont parallélisées. Les références de `cholesky` et `seidel-2d`, dont aucune
boucle n'est parallèle sans transformation préalable, sont même entièrement
séquentielles.

PPCG réorganise au contraire ces calculs pour en extraire le parallélisme. Pour
les factorisations `lu`, `ludcmp` et `cholesky`, il découpe le calcul en étapes
successives, lancées depuis l'hôte (@code:evaluations:lu-ppcg) : à chaque étape,
la mise à jour de la partie restante de la matrice est confiée à des noyaux
bidimensionnels, qui mobilisent des centaines de milliers de threads et chargent
en mémoire partagée les données réutilisées au sein d'un bloc. Pour `seidel-2d`,
il applique un front d'onde : environ 31 000 lancements successifs traitent
chacun en parallèle tous les points d'un même front, à travers l'espace et le
temps. Pour `trisolv` et `durbin`, le calcul reste organisé en étapes, mais
chaque étape enchaîne plusieurs noyaux sur le GPU sans retour vers l'hôte, même
lorsque, comme pour `durbin`, une réduction reste calculée par un seul thread.
La version de référence effectue au contraire, à chaque étape, une réduction
parallèle dont le résultat est rapatrié sur l'hôte, soit des dizaines de
milliers de synchronisations, ce qui explique vraisemblablement l'essentiel de
l'écart. Enfin, l'accélération plus faible de `ludcmp` que de `lu`, dont la
factorisation est identique, tient vraisemblablement à la dernière substitution
triangulaire, que le code généré exécute sur l'hôte au moyen d'une boucle
inefficace.

#figure(
  ```cpp
  cudaMemcpy(dev_A, A, N * N * sizeof(double), cudaMemcpyHostToDevice);
  for (int c0 = 0; c0 < N - 1; c0 += 1) {     // étapes successives
    // Mise à jour de la sous-matrice restante : 64 x 64 blocs de 4 x 32 threads
    kernel2 <<<dim3(64, 64), dim3(4, 32)>>> (dev_A, N, c0);
    kernel3 <<<dim3(64, 64), dim3(4, 32)>>> (dev_A, N, c0);
    // Division de la colonne courante par le pivot : 64 blocs de 32 threads
    kernel4 <<<dim3(64), dim3(32)>>> (dev_A, N, c0);
  }
  cudaMemcpy(A, dev_A, N * N * sizeof(double), cudaMemcpyDeviceToHost);
  ```,
  caption: [Extrait simplifié du code hôte généré par PPCG pour `lu`, avec les
    dimensions de grille et de bloc obtenues pour $N = 2048$.],
) <code:evaluations:lu-ppcg>

Le noyau `gramschmidt` n'obtient qu'un gain modeste (1.58$times$). Sa version de
référence parallélise déjà chacune des 2 600 étapes de son calcul. PPCG en
parallélise davantage, la mise à jour principale, mais calcule séquentiellement,
sur un seul thread, la norme nécessaire à chaque étape, ce qui limite le gain.

Ces ratios extrêmes doivent être interprétés avec précaution. Ils traduisent
l'écart entre une version de référence idiomatique et un ordonnancement qui en
extrait le parallélisme. Il permet d'illustrent l'intérêt principal de
l'approche : ce parallélisme est obtenu automatiquement, à partir d'un code
source portable et non modifié.

=== Exploitation de la hiérarchie mémoire <sec:evaluations:gpu:memory>

Sur les noyaux d'algèbre linéaire, les gains dépendent surtout du parallélisme
exploité par la version de référence. Celles de `syrk` (42.99$times$), `syr2k`
(21.17$times$) et `covariance` (7.31$times$) ne parallélisent qu'une seule
dimension, avec un thread par ligne du résultat. Celle de `symm` (34.13$times$)
enchaîne des lancements successifs d'un petit nombre de threads. C'est bien trop
peu pour occuper tous les coeurs de la carte. PPCG génère au contraire un noyau,
découpé en tuiles de $32 times 32$ éléments : chaque tuile est chargée en
mémoire partagée par les threads d'un bloc, puis réutilisée depuis cette mémoire
rapide. Pour `trmm` (2.86$times$), les dépendances du calcul limitent le code
généré à la même parallélisation que la référence, avec un thread par colonne,
et le gain provient essentiellement de la mémoire partagée. Enfin, `gemm`
(1.90$times$), `2mm` (1.41$times$) et `3mm` (1.09$times$) n'obtiennent que des
gains modérés : leur version de référence projette déjà un parallélisme
efficace.

À l'inverse, `gemver` (1.01$times$), `gesummv`, `atax`, `bicg` et `mvt`
(0.99$times$) restent neutres. Comme sur CPU, ces produits matrice-vecteur
lisent chaque élément de matrice une seule fois : leur performance est bornée
par la bande passante de la mémoire globale. PPCG reproduit la parallélisation
faite dans la version de référence.

=== Contre-performances <sec:evaluations:gpu:slowdowns>

Quatre noyaux régressent : `jacobi-1d` (0.12$times$), `doitgen` (0.20$times$),
`deriche` (0.20$times$) et `jacobi-2d` (0.60$times$). Dans les quatre cas, PPCG
n'expose aucun parallélisme supplémentaire et reproduit la parallélisation de la
version de référence. PPCG génère des gardes conditionnelles et des boucles
supplémentaires pour garantir la correction aux bords du domaine, dont le coût
devient sensible sur des noyaux aussi légers. Ces surcoûts, multipliés par le
nombre de lancements, expliquent l'ampleur des régressions.


=== Bilan de l'évaluation sur GPU <sec:evaluations:gpu:summary>

La réintégration de PPCG dans Polly permet de générer automatiquement, à partir
de code Kokkos, du code GPU qui accélère 16 des 24 noyaux compilés. Les gains
les plus importants, atteignant trois ordres de grandeur, sont obtenus sur les
noyaux à dépendances, dont PPCG réorganise le calcul en étapes ou en fronts
d'onde massivement parallèles, là où la version de référence exécute une partie
du calcul sur un seul thread. Sur les noyaux d'algèbre linéaire dont la
référence ne parallélise qu'une dimension, la projection du calcul sur
l'architecture GPU et l'utilisation de la mémoire partagée apportent des gains
d'environ un ordre de grandeur.

Cette évaluation met également en évidence les limites actuelles de la
génération de code GPU. Lorsque l'ordonnanceur ne parvient pas à trouver
d'avantage de parallélisme, le surcoût de contrôle rend le code généré moins
performant que celui du backend CUDA de Kokkos.


== Temps de compilation <sec:evaluations:compiletime>

Les algorithmes polyédriques ont une complexité qui croît de manière
exponentielle avec le nombre de paramètres et de contraintes du SCoP. Le gain
obtenu à l'exécution doit donc être mis en regard du surcoût qu'impose l'analyse
polyédrique lors de la compilation. Le @table:evaluations:compiletime rapporte,
pour chaque noyau, le temps de compilation de Clang avec Kokkos et Polly (option
`usePolyOpt`) relativement à celui de Clang avec Kokkos seul, mesuré sur la
machine Intel avec les ordonnanceurs ISL et Pluto pour la cible CPU et PPCG pour
la cible GPU.

#let ct-slow(value) = text(weight: "bold")[#value]

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, 1fr, 1fr, 1fr, 1fr),
      align: (
        left + horizon,
        left + horizon,
        center + horizon,
        center + horizon,
        center + horizon,
      ),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header(
        table.cell(rowspan: 2)[*Catégorie*],
        table.cell(rowspan: 2)[*Noyau*],
        table.cell(colspan: 2)[*CPU*],
        [*GPU*],
        [*ISL*], [*Pluto*], [*PPCG*],
        table.hline(stroke: 0.5pt),
      ),
      [Datamining], [`covariance`], [1.07], [1.70], [0.96],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 7)[BLAS],
      [`gemm`], ct-slow[2.55], [1.06], [0.97],
      [`gemver`], [1.03], [1.05], [0.81],
      [`gesummv`], [1.02], ct-slow[10.40], [0.89],
      [`symm`], [1.06], [1.09], [1.17],
      [`syr2k`], [1.02], [1.05], [0.99],
      [`syrk`], [1.02], ct-slow[10.40], [0.99],
      [`trmm`], [1.02], [1.06], [1.01],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Kernels],
      [`2mm`], [1.07], [1.17], [1.74],
      [`3mm`], ct-slow[28.82], [1.38], ct-slow[17.36],
      [`atax`], [1.01], [1.04], [0.91],
      [`bicg`], [1.01], [1.03], [0.90],
      [`doitgen`], [1.04], [1.09], [1.37],
      [`mvt`], [1.03], [1.04], [0.86],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Solvers],
      [`cholesky`], [1.04], [1.13], [1.05],
      [`durbin`], [1.00], [1.02], [1.01],
      [`gramschmidt`], [1.06], [1.14], [0.92],
      [`lu`], [1.05], [1.16], [1.05],
      [`ludcmp`], [1.09], [1.26], [1.03],
      [`trisolv`], [1.02], [1.03], [0.94],
      table.hline(stroke: 0.3pt),

      [Medley], [`deriche`], [1.10], [1.24], ct-slow[2.13],
      table.hline(stroke: 0.3pt),

      table.cell(rowspan: 6)[Stencils],
      [`adi`], [1.14], [1.38], [$infinity$],
      [`fdtd-2d`], [1.04], [1.51], [$infinity$],
      [`heat-3d`], [1.14], ct-slow[24.04], [$infinity$],
      [`jacobi-1d`], [1.13], [1.17], [0.93],
      [`jacobi-2d`], [1.05], ct-slow[2.60], ct-slow[88.28],
      [`seidel-2d`], [1.07], [1.92], [1.00],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Moyenne géométrique*], [1.23], [1.60], [1.41],
      table.cell(colspan: 2)[*Médiane*], [1.05], [1.16], [1.00],
      table.hline(stroke: 1pt),
    ),
    caption: [Temps de compilation relatif de Clang avec Kokkos + Polly
      (`usePolyOpt`) par rapport à Clang avec Kokkos, mesuré sur la machine
      Intel.],
  ) <table:evaluations:compiletime>
]

Pour la grande majorité des noyaux, le surcoût reste faible : les médianes
s'établissent à 1.05$times$ pour ISL, 1.16$times$ pour Pluto et 1.00$times$ pour
PPCG, et 25 des 27 noyaux se compilent en moins de 1.2$times$ le temps de
référence avec ISL. Ce résultat s'explique en partie par l'isolation des noyaux
(#chref(<sec:kokkosvisibility>)). Polly n'analyse que les fonctions marquées par
l'option `usePolyOpt`, et non l'ensemble du module mais aussi par la réduction
de l'usage intenssif de templates dans les backends modifiés. Le surcoût
légèrement plus élevé de Pluto provient de l'étapes d'ordonnancement et des
étapes d'export et d'import au format OpenScop
(@sec:schedulingheterogeneous:pluto).

Quelques noyaux font exception. Le plus marquant est `3mm`, dont la compilation
est 28.82$times$ plus longue avec ISL et 17.36$times$ avec PPCG. Pluto est quant
à lui pénalisé sur `gesummv`, `syrk` (10.40$times$) et `heat-3d` (24.04$times$),
et PPCG sur `jacobi-2d` (88.28$times$). Enfin, la compilation de `adi`,
`fdtd-2d` et `heat-3d` avec PPCG ne termine pas en un temps raisonnable. Ce
point est discuté dans l'évaluation sur GPU (@sec:evaluations:gpu:global).
