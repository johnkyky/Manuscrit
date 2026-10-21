#import "../src/common.typ": *

= Évaluations <sec:evaluations>

Ce chapitre quantifie et analyse l'impact des contributions présentées. Le but
principal est de démontrer que la restauration de la visibilité sémantique et
structurelle au niveau du compilateur permet de débloquer des optimisations de
boucles agressives grâce au modèle polyédrique. À travers une évaluation sur la
suite de benchmarks PolyBench~@polybench, nous mettons à l'épreuve notre chaîne
de compilation sur des architectures hétérogènes (CPU multicoeurs et
accélérateurs GPU). Nous détaillons les accélérations obtenues par rapport à une
implémentation Kokkos idiomatique et étudions l'impact avec différentes
architectures et ordonnanceurs.

== Protocole expérimental <sec:evaluations:setup>

*Version de référence.* Les performances sont mesurées par rapport à une
implémentation idiomatique (parallèle lorsque cela est possible) des noyaux de
la suite de benchmarks PolyBench en #box[C++] avec Kokkos, telle que l'écrirait
un utilisateur standard de la bibliothèque. Les nids de boucles sont exprimés à
l'aide de `parallel_for` et utilisent les structures Kokkos comme les vues
`Kokkos::View`, sans optimisation spécifique, comme par exemple la fusion ou la
fission de boucles, la réécriture du calcul pour exposer davantage de
parallélisme ou l'usage explicite de la mémoire rapide (`Kokkos::ScratchSpace`).
Cette version est compilée avec la même chaîne de compilation Clang, mais en
activant ou en désactivant l'utilisation de Polly, sur les backends standards de
Kokkos : OpenMP pour les CPU et CUDA pour les GPU.

*Version optimisée.* La version évaluée exprime les mêmes calculs, mais sous la
forme attendue par notre chaîne de compilation. Chaque noyau est écrit en entier
dans un `parallel_for` (ou `parallel_for` variadique, voir
@sec:complexexecutionpatterns:variadicparallelfor) annoté par l'option
`usePolyOpt`, y compris ses boucles externes non parallèles. La politique
d'exécution ne décrit plus le parallélisme à exploiter mais elle délimite
l'espace d'itération du noyau et désigne le backend ciblé. Polly analyse
l'ensemble comme un seul noyau puis décide lui-même des boucles à paralléliser.
Le même code sert ainsi pour les deux cibles (CPU, GPU), seul change l'espace
d'exécution de la politique.

*Plateformes.* Les expérimentations sont menées sur deux machines, décrites dans
le @table:evaluations:hardware : une machine bi-socket équipée de deux
processeurs AMD EPYC 7502, et une machine combinant un processeur Intel Core
Ultra 7 265 et une carte graphique NVIDIA RTX 5090.

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
    [Pilote NVIDIA], [--], [595.99],
    table.hline(stroke: 1pt),
  ),
  caption: [Caractéristiques des deux plateformes d'évaluation.],
) <table:evaluations:hardware>

*Chaîne de compilation.* Les deux machines utilisent une version de
développement de LLVM/Clang 23.0.0 intégrant nos contributions, la version
4.6.99 de Kokkos, modifiée comme décrit dans les chapitres précédents, et PPCG
0.09.3 pour la génération de code GPU. Tous les codes sont compilés en mode
`Release` (`CMAKE_BUILD_TYPE=Release`).

*Mesures.* Chaque temps est la moyenne de 5 exécutions consécutives, dont la
dispersion relative reste inférieure à 5 %. Sur CPU, chaque thread OpenMP est
fixé sur un coeur et les threads sont répartis uniformément sur l'ensemble des
coeurs, et donc sur les deux sockets de la machine AMD (`OMP_PROC_BIND=spread`,
`OMP_PLACES=threads`). Chaque exécution est validée en comparant les résultats
des calculs de la version optimisée élément par élément à ceux de la version de
référence, avec une tolérance absolue de $10^(-8)$.

*Noyaux évalués.* L'évaluation porte sur 27 des 30 noyaux de la suite PolyBench.
Les trois noyaux écartés, `correlation`, `nussinov` et `floyd-warshall`, sortent
du cadre du modèle polyédrique statique, car leur flot de contrôle dépend de
valeurs calculées pendant l'exécution par le biais d'opérations ternaires, ce
qui produit dans l'IR LLVM des accès non affines que Polly ne peut pas
représenter. Les jeux de données ont été agrandis afin d'obtenir des temps
d'exécution significatifs. Le @table:evaluations:problemsizes donne, pour chaque
noyau de la suite PolyBench, la taille utilisée.

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
ordonnanceurs polyédriques sont confrontés, l'ordonnanceur natif de Polly,
reposant sur ISL, et l'ordonnanceur Pluto (@sec:schedulingheterogeneous:pluto).
Dans les deux cas, le tuilage est appliqué avec une taille de tuile fixe de 32
sur chaque dimension, et Polly parallélise le code généré au moyen du support
d'exécution OpenMP. Notons que l'utilisateur peut choisir d'autres tailles de
tuiles en utilisant le flag de compilation `--polly-tile-size`
(@sec:conclusion:perspectives).

=== Étude des résultats CPU <sec:evaluations:cpu:global>

La @fig:evaluations:cpu-amd et la @fig:evaluations:cpu-intel présentent les
accélérations obtenues par rapport à la version de référence sur chacune des
deux machines. Le @table:evaluations:cpu-geomean en extrait des statistiques par
famille de noyaux et globalement.

#figure(
  image(fig.evaluation-polybench-trahrhe-cpu, width: 95%),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    (backend OpenMP) avec les ordonnanceurs ISL et Pluto sur processeur Dual AMD
    EPYC 7502 ($2 times 32$ coeurs, 64 threads sans hyperthreading, taille de
    tuile : 32).],
) <fig:evaluations:cpu-amd>

#figure(
  image(fig.evaluation-polybench-eugene-cpu, width: 95%),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    (backend OpenMP) avec les ordonnanceurs ISL et Pluto sur processeur Intel
    Core Ultra 7 265 (20 threads sans hyperthreading, taille de tuile : 32).],
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
  caption: [Moyennes géométriques des accélérations sur CPU par catégorie de
    benchmark et par ordonnanceur. Entre parenthèses figure le nombre de noyaux
    accélérés sur le nombre de noyaux évalués.],
) <table:evaluations:cpu-geomean>

Le premier constat est que les transformations permises par nos contributions
profitent à la grande majorité des noyaux. Sur chacune des deux machines, 24 des
27 noyaux sont accélérés par au moins l'un des deux ordonnanceurs. En retenant
pour chaque noyau le meilleur des deux ordonnanceurs, la moyenne géométrique des
accélérations atteint 5.32$times$ sur la machine AMD et 4.36$times$ sur la
machine Intel. L'accélération maximale, 118.26$times$, est obtenue sur `lu` avec
l'ordonnanceur ISL sur la machine AMD. Ces résultats confirment qu'une fois la
structure des boucles rendue visible à Polly, les transformations polyédriques
exploitent efficacement la localité et le parallélisme laissés inexploités par
une écriture Kokkos idiomatique des noyaux.

Ces gains dépendent avant tout de la manière dont la version de référence est
écrite, et proviennent de deux sources : la localité, lorsque la référence est
déjà parallèle mais réutilise mal ses données, et le parallélisme, lorsqu'elle
exécute une partie du calcul séquentiellement. Le choix de l'ordonnanceur compte
surtout dans ce second cas, car seul Pluto expose un parallélisme en front
d'onde, ce qui explique son avantage moyen (4.44$times$ contre 2.21$times$ sur
AMD, 3.74$times$ contre 1.88$times$ sur Intel), concentré sur les _stencils_ et
les _solvers_. Les sections suivantes examinent ces deux sources de gain, puis
les noyaux pour lesquels le code généré reste moins performant que la référence.

Sur les 54 variantes compilées (27 noyaux $times$ 2 ordonnanceurs), 53
produisent des résultats conformes à la référence. Seul le noyau `atax` avec
l'ordonnanceur Pluto produit un résultat erroné, en raison d'un ordonnancement
invalide. L'erreur provient de l'outil Pluto lui-même. En reproduisant le noyau
sans la première boucle (remplacée par un `memset` par LLVM lors de la
compilation), on obtient le même résultat incorrect.

=== Gains de localité <sec:evaluations:cpu:locality>

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
stocké par lignes, avec un grand pas mémoire entre deux accès successifs. Or
Kokkos ne tuile que les dimensions d'une `MDRangePolicy`, jamais les boucles
écrites dans la lambda. La plupart de ces versions reposent sur une
`RangePolicy` et ne sont pas tuilées du tout, et seules celles de `2mm` et `3mm`
découpent l'espace `(i, j)` en tuiles de $32 times 32$, sans toucher à la boucle
de réduction. Le tuilage polyédrique porte au contraire sur l'ensemble du nid,
boucle de réduction comprise, comme l'illustrent `symm` dans le paragraphe
suivant et `covariance` (@sec:evaluations:cpu:sensitivity).

Le cas de `symm` illustre la combinaison de transformations à l'origine de ces
gains. Pour chaque élément `(i, j)`, ce noyau accumule une somme partielle
`tmp(i, j)` tout en mettant à jour les éléments `C(k, j)` des lignes précédentes
(@code:evaluations:symm-kokkos). Ces mises à jour relient entre elles toutes les
itérations de `i`, si bien que seule la boucle `j` est parallèle dans le nid
d'origine. ISL sépare le corps du nid en plusieurs nids de boucles distincts,
chacun parallèle et tuilé par blocs de 32 (@code:evaluations:symm-isl).
L'accumulation de `tmp` et la mise à jour finale de `C(i, j)` sont parallélisées
sur~`i`, et les mises à jour de `C(k, j)` sur `j`.

L'ampleur du gain tient à la version de référence. Celle-ci exécute la boucle
`i` séquentiellement sur l'hôte et lance, à chacune des itérations, un
`parallel_for` sur `j`.

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
  Kokkos::parallel_for<Kokkos::usePolyOpt>(
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
    boucles internes aux tuiles sont omises.],
) <code:evaluations:symm-isl>

=== Gains de parallélisme <sec:evaluations:cpu:parallelism>

Sur plusieurs noyaux, le gain provient du parallélisme que la version de
référence n'exploite pas : `seidel-2d` (18.56$times$ et 15.66$times$ avec
Pluto), `cholesky` (14.52$times$ et 7.31$times$), `ludcmp` (14.20$times$ et
8.75$times$) et `trisolv` (2.30$times$ et 3.67$times$), ainsi que `lu`, discuté
dans la @sec:evaluations:cpu:sensitivity. Ces noyaux présentent des dépendances
portées par toutes les dimensions du nid de boucles, de sorte qu'aucune boucle
n'est directement parallélisable sans transformation préalable. Leur version de
référence exécute donc tout ou partie du calcul séquentiellement. En appliquant
des transformations de torsion de boucle, Pluto rend le nid tuilable et expose
un parallélisme en front d'onde entre les tuiles.

Le code généré par Pluto pour `seidel-2d` illustre ce mécanisme
(@code:evaluations:seidel-pluto). Chaque instance d'instruction $(t, i, j)$ est
ordonnancée en $(t, t + i, 2t + i + j)$. Cette torsion rend les trois dimensions
tuilables. Les tuiles sont ensuite parcourues par fronts d'onde. Les fronts sont
traités l'un après l'autre, et les tuiles d'un même front, indépendantes,
s'exécutent en parallèle. Pluto applique le même mécanisme à `ludcmp`.

L'écriture des versions de référence explique l'ampleur de ces gains. La version
de `seidel-2d` est entièrement séquentielle, la mise à jour en place du tableau
interdisant toute parallélisation directe. La version de `cholesky` est
également entièrement séquentielle. Les accélérations de Pluto (18.56$times$ et
15.66$times$) mesurent donc à la fois le parallélisme par front d'onde et le
gain de localité apporté par le tuilage des boucles. La version de référence de
`ludcmp` n'est que partiellement parallèle. La boucle externe de la
factorisation s'exécute séquentiellement, et à chacune de ses itérations, seule
la partie supérieure de la ligne est parallélisée, la partie inférieure restant
séquentielle. En transformant l'ensemble de la factorisation par fronts d'onde,
Pluto lève cette limitation de parallélisation.

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

ISL n'applique pas cette transformation en front d'onde. Sur `seidel-2d`, il
produit un code tuilé mais toujours séquentiel, qui ne gagne que par la localité
des données (#box[2.43$times$] et #box[2.92$times$]). Sur les autres noyaux de
ce groupe, il ne fait au mieux qu'égaler la référence, comme le détaille la
section suivante.

=== Régressions <sec:evaluations:cpu:regressions>

À l'inverse, plusieurs noyaux ne gagnent rien ou régressent, de manière
identique sur les deux machines. Dans la plupart des cas, le code généré
exploite moins de parallélisme que la version de référence.

*Les noyaux sans réutilisation de données.* `gesummv` reste neutre quels que
soient l'ordonnanceur et la machine (entre #box[0.91$times$] et
#box[0.99$times$]), et `doitgen` comme `mvt` n'obtiennent que des gains
modestes. Ces noyaux de type matrice-vecteur lisent chaque élément de matrice
une seule fois. Leur performance est bornée par la bande passante mémoire et le
tuilage n'a aucune localité à exploiter.

*Les fausses dépendances dues aux scalaires.* Le noyau `deriche` régresse sur
les deux machines avec les deux ordonnanceurs (de #box[0.35$times$] à
#box[0.50$times$]). Ce noyau parcourt une image ligne par ligne, puis colonne
par colonne. Le long d'une ligne, chaque pixel dépend des pixels déjà traités,
dont les valeurs sont transmises d'une itération à l'autre par des variables
scalaires remises à zéro au début de chaque ligne. Les lignes, comme les
colonnes, restent donc indépendantes les unes des autres, et la version de
référence les traite en parallèle.

Le modèle polyédrique ne voit pas cette indépendance. Polly représente chaque
scalaire par un emplacement mémoire unique, partagé par toutes les lignes. Du
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

*Le parallélisme limité à la boucle la plus interne.* Avec ISL, le code généré
s'effondre sur `heat-3d` (0.01$times$ et 0.02$times$) et dégrade `jacobi-1d`
(0.23$times$ et 0.20$times$), `jacobi-2d` (0.70$times$ et 0.74$times$) et
`fdtd-2d` (0.47$times$ et 0.67$times$). Sur ces noyaux, chaque pas de temps
dépend du précédent, ce qui interdit de paralléliser directement les boucles
externes. ISL parvient pourtant à tuiler le nid, y compris la dimension
temporelle, grâce à une torsion des boucles (@code:evaluations:heat3d-isl). Mais
il n'exécute pas en parallèle les tuiles indépendantes. La seule boucle qu'il
identifie comme parallèle est la plus interne mais Polly ne génère pas de
parallélisation de threads pour une boucle interne. Le code généré s'exécute sur
un seul coeur, alors que la version de référence parallélise chaque pas de
temps. Le même phénomène se produit sur `jacobi-1d`, `jacobi-2d` et `fdtd-2d`.
Sur `jacobi-1d`, cette explication n'est toutefois que partielle, car
l'essentiel de la régression vient d'une vectorisation défavorable du code
généré, détaillée dans la @sec:evaluations:vanilla. Sans cette vectorisation, le
code séquentiel produit par ISL atteint 0.99$times$ de la version de référence
parallèle sur la machine Intel.

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
    `heat-3d` sur CPU. La boucle la plus interne est marquée comme pouvant être
    parallélisée avec l'annotation `#pragma known-parallel`.],
) <code:evaluations:heat3d-isl>

Pluto, au contraire, exécute en parallèle les tuiles indépendantes parcourues
par fronts d'onde, et accélère ces mêmes noyaux, par exemple `jacobi-2d`
(18.63$times$ et 8.70$times$).

ISL échoue également sur les solveurs triangulaires `ludcmp` (0.76$times$ et
0.95$times$) et `trisolv` (0.96$times$ et 0.92$times$). Sur `trisolv`, il
échange les deux boucles du nid, mais la seule boucle parallèle obtenue est à
nouveau la plus interne. Comme pour les stencils, le code généré est entièrement
séquentiel. La version de référence n'est pas efficace, elle lance une réduction
parallèle pour chacune des lignes de la matrice, dont le coût de lancement pèse
lourdement face au peu de travail confié à chaque thread. Ces deux inefficacités
se compensent, d'où des performances proches de la référence.

Sur `ludcmp`, ISL conserve la structure d'origine du nid, sans tuilage, et
reproduit la parallélisation de la version de référence, là où Pluto parallélise
l'ensemble de la factorisation par fronts d'onde. Faute de gain de localité, le
code généré ne peut au mieux qu'égaler la référence et les surcoûts des calculs
d'indices polyédriques créent un léger ralentissement.

Le noyau `durbin` régresse sur la machine AMD (#box[0.51$times$]) mais accélère
légèrement sur la machine Intel (#box[1.28$times$] et #box[1.32$times$]). Ce
noyau comporte une boucle externe intrinsèquement séquentielle, dont chaque
itération ne contient que de petites boucles. La version de référence
parallélise ces petites boucles, au prix de trois synchronisations par
itération, tandis que le code généré par ISL comme par Pluto est entièrement
séquentiel. Le résultat dépend donc du matériel. Le code séquentiel profite de
la fréquence élevée d'un coeur Intel, mais ne rivalise pas, sur la machine AMD
et ses coeurs plus lents, avec une version parallèle répartie sur 64 coeurs.

*Une fusion défavorable.* Avec Pluto, le code généré régresse fortement sur
`adi` sur les deux machines (0.12$times$ et 0.03$times$), alors qu'ISL
l'accélère sur la machine AMD (1.64$times$). Chaque pas de temps de ce noyau
enchaîne deux balayages de la grille, l'un selon les colonnes et l'autre selon
les lignes. Ces colonnes et ces lignes étant indépendantes les unes des autres,
la version de référence parallélise chacune des quatre phases, et ISL préserve
ce parallélisme.

Pluto fusionne deux de ces phases, comme l'une parcourt la grille par colonnes
et l'autre par lignes, le nid fusionné est parcouru diagonale par diagonale
(@code:evaluations:adi-pluto). Seule une partie du calcul reste alors parallèle,
le long de chaque diagonale et au prix d'une synchronisation à chacune d'elles.
Ces deux phases perdent ainsi l'essentiel de la parallélisation de la version de
référence.

#figure(
  ```cpp
  // Remontée en colonnes et descente en lignes, fusionnées
  #pragma minimal dependence distance: 1
  for (int c3 = 0; c3 < 2 * N - 5; c3 += 1) {  // anti-diagonales
    if (c3 < N - 2)
      #pragma minimal dependence distance: 1
      for (int c8 = 0; c8 < N - 2; c8 += 1)
        Stmt4(...);   // remontée en colonnes : séquentielle
    #pragma omp parallel for
    for (int c8 = ...; c8 <= ...; c8 += 1)
      #pragma simd
      for (int c9 = ...; c9 <= ...; c9 += 1)
        Stmt8b(...);  // descente en lignes, 1re partie : parallèle
    if (c3 < N - 2)
      #pragma minimal dependence distance: 1
      for (int c8 = 0; c8 < N - 2; c8 += 1)
        Stmt8(...);   // descente en lignes, 2e partie : séquentielle
  }
  ```,
  caption: [Extrait simplifié de l'AST généré par Polly avec l'ordonnanceur
    Pluto pour `adi` sur CPU : le nid fusionné, à l'intérieur de la boucle
    temporelle. Les bornes et les indices sont omis, et le paramètre `p_0` a été
    renommé `N`.],
) <code:evaluations:adi-pluto>

Ces régressions se reproduisent à l'identique sur les deux machines. Aucun des
deux ordonnanceurs ne dispose d'un modèle de coût capable de détecter qu'une
transformation réduit le parallélisme ou la localité par rapport au code
d'origine.

=== Sensibilité au matériel <sec:evaluations:cpu:sensitivity>

Au-delà de ces comportements stables, plusieurs noyaux présentent des écarts
importants entre les deux machines, qui révèlent la sensibilité des
transformations aux caractéristiques matérielles.

==== Le cas de la factorisation #text(0.75em, font: "FiraCode Nerd Font Mono")[lu]

Le noyau `lu` présente un écart important d'exécution sur la machine AMD, ISL
atteint #box[118.26$times$] et Pluto #box[18.45$times$] contre #box[5.27$times$]
et #box[9.21$times$] sur la machine Intel. Deux effets se combinent.

Un premier effet provient de la version de référence. Comme celle de `ludcmp`,
elle n'est parallèle que pour moitié. La boucle externe s'exécute
séquentiellement et à chacune de ses itérations seule la partie supérieure de la
ligne est calculée en parallèle. Sur la machine AMD, un profilage avec `perf`
montre que cette moitié séquentielle détermine à elle seule la durée de
l'exécution. Les 63 threads secondaires passent l'essentiel de leur temps à
attendre le thread principal, la référence s'exécute donc pratiquement à la
vitesse d'un seul coeur. Or ce coeur est nettement plus lent que celui de la
machine Intel. La référence est donc nettement moins efficace sur la machine AMD
que sur la machine Intel.

Le second effet tient à la manière dont chaque code généré exploite la machine.
Le code ISL parallélise en une succession d'étapes propice au grand nombre de
coeurs de la machine AMD. Sur la machine Intel, les étapes sont réparties en
blocs égaux entre les coeurs P (performance) et E (efficacité énergétique). Les
coeurs E, moins rapides, terminent leur bloc en dernier et déterminent ainsi la
durée du calcul. Pluto parcourt au contraire le calcul par fronts d'onde. Il
réutilise mieux les données, mais chaque front de charges inégales compte un
nombre limité de tuiles qui ne suffisent pas à occuper les 64 coeurs de la
machine AMD. Le code tire davantage parti de la fréquence élevée des coeurs
Intel que du nombre de coeurs de la machine AMD.


==== Régressions liées au tuilage fixe

Pour `cholesky` et `adi`, ISL obtient 4.68$times$ et 1.64$times$ sur la machine
AMD, mais régresse à 0.74$times$ et 0.52$times$ sur la machine Intel.
L'accélération de Pluto sur `cholesky` est elle aussi divisée par deux (de
14.52$times$ à 7.31$times$). Les deux ordonnanceurs utilisent une taille de
tuile fixe de 32. Or le cache L2 de la machine Intel contient déjà une grande
partie des données manipulées par la version de référence. Le tuilage n'apporte
pas de gain de localité et son surcoût le rend contre-productif. Sur la machine
AMD le tuilage reste bénéfique.


=== Bilan de l'évaluation sur CPU <sec:evaluations:cpu:summary>

Cette évaluation montre que la visibilité restaurée par nos contributions permet
à Polly d'optimiser des codes Kokkos avec des gains en performance non
négligeables, puisque 24 des 27 noyaux sont accélérés sur chaque machine. Ces
gains ont deux origines : une amélioration de la localité mémoire, des
transformations créant des boucles sans dépendance parallèles comme le front
d'onde de Pluto.

Les régressions surviennent lorsque le code généré exploite moins de
parallélisme que la référence (fausses dépendances dues aux scalaires,
parallélisme limité à la boucle la plus interne ou fusion défavorable). S'y
ajoute une sensibilité au matériel avec la taille de tuile fixe et l'absence de
modèle de coût prenant en compte la hiérarchie de caches provoquant des
régressions sur certaines architectures.

La section suivante étend cette évaluation aux accélérateurs GPU, où la
génération de code repose sur PPCG.

== Évaluation sur GPU <sec:evaluations:gpu>

Cette section évalue la génération de code GPU rendue possible par la
réintégration de PPCG dans Polly (@sec:schedulingheterogeneous:ppcg). La version
de référence suit la même démarche que sur CPU : une implémentation Kokkos
idiomatique, compilée avec le backend CUDA de Kokkos, qui parallélise
directement les boucles parallèles de l'algorithme d'origine. La version
optimisée est celle décrite dans la @sec:evaluations:setup, dont la politique
d'exécution désigne cette fois le backend CUDA.

Les mesures sont réalisées sur la carte NVIDIA RTX 5090 de la machine Intel
(@table:evaluations:hardware) et incluent, dans les deux versions, les
transferts de données entre l'hôte et le GPU. Kokkos choisit dynamiquement la
taille des blocs de threads de la version de référence. PPCG découpe au
contraire chaque noyau en tuiles de 32 itérations fixes par dimension, confiées
à des blocs de 32 threads pour un noyau à une dimension et de $4 times 32$
threads pour un noyau à deux dimensions. La promotion des données en mémoire
partagée (limitée à 16 Ko par bloc) et la privatisation en registres des données
sont activées.

=== Étude des résultats GPU <sec:evaluations:gpu:global>

Sur les 27 noyaux évalués, 24 sont compilés et produisent des résultats corrects
avec PPCG. Les trois noyaux restants, `adi`, `fdtd-2d` et `heat-3d`, n'ont pas
pu être compilés, car l'ordonnancement calculé par PPCG ne termine pas en un
temps raisonnable, en raison du nombre considérable de contraintes générées pour
ces nids de boucles.

La @fig:evaluations:gpu présente les accélérations obtenues sur les 24 noyaux
restants, et le @table:evaluations:gpu-geomean en résume les moyennes
géométriques par catégorie.

#figure(
  image(fig.evaluation-polybench-eugene-gpu),
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Kokkos
    (backend CUDA) avec l'ordonnanceur PPCG sur accélérateur NVIDIA RTX 5090 (32
    Go VRAM, hôte Intel Core Ultra 7 265, 20 threads sans hyperthreading, taille
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

    [Stencils], [3], speedup-cell("5.08", "1/3"),

    table.hline(stroke: 0.5pt),
    [*Ensemble*], [24], speedup-cell("7.25", "16/24"),
    table.hline(stroke: 1pt),
  ),
  caption: [Moyennes géométriques des accélérations sur GPU par catégorie de
    benchmark. Entre parenthèses figure le nombre de noyaux accélérés sur le
    nombre de noyaux évalués.],
) <table:evaluations:gpu-geomean>

Les accélérations s'étendent sur plus de quatre ordres de grandeur, de
0.12$times$ sur `jacobi-1d` à 3581.16$times$ sur `lu`. Quinze noyaux sont
accélérés, cinq restent pratiquement neutres (`gemver` à 1.01$times$, `gesummv`,
`atax`, `bicg` et `mvt` à 0.99$times$) et quatre régressent (`doitgen`,
`deriche`, `jacobi-1d` et `jacobi-2d`). La moyenne géométrique globale de
7.25$times$ est tirée vers le haut par les six noyaux dont la version de
référence est limitée par une boucle externe séquentielle. Sans eux,
l'accélération moyenne est de 1.65$times$. Les résultats se répartissent ainsi
en trois groupes, détaillés ci-dessous.

=== Parallélisation des noyaux à dépendances <sec:evaluations:gpu:dependences>

Les accélérations les plus élevées concernent les solveurs et les factorisations
: `lu` (#box[3581.16$times$]), `cholesky` (#box[3474.92$times$]), `durbin`
(#box[178.65$times$]), `ludcmp` (#box[123.25$times$]) et `trisolv`
(#box[105.62$times$]), ainsi que le stencil `seidel-2d` (#box[1823.46$times$]).
Ces noyaux ont en commun une boucle externe porteuse de dépendances, qui
interdit une parallélisation directe de l'ensemble du nid sur la grille de
threads. Dans la version de référence, cette boucle externe s'exécute
séquentiellement sur l'hôte, et seules les boucles internes parallèles de
l'algorithme d'origine sont parallélisées. Les références de `cholesky` et
`seidel-2d`, dont aucune boucle n'est parallèle sans transformation préalable,
sont même entièrement séquentielles.

PPCG réorganise au contraire ces calculs pour en extraire le parallélisme. Pour
les factorisations `lu`, `ludcmp` et `cholesky`, il découpe le calcul en étapes
successives, lancées depuis l'hôte (@code:evaluations:lu-ppcg). À chaque étape,
la mise à jour de la partie restante de la matrice est confiée à des noyaux
mobilisant des centaines de milliers de threads et chargeant en mémoire partagée
les données réutilisées au sein d'un bloc. Pour `seidel-2d`, il applique un
front d'onde qui à chaque lancement successif de blocs, traite en parallèle tous
les points d'un même front. Pour `trisolv` et `durbin`, le calcul reste organisé
en étapes, mais chaque étape enchaîne plusieurs noyaux sur le GPU sans retour
vers l'hôte, même lorsque, comme pour `durbin`, une réduction reste calculée par
un seul thread. La version de référence effectue au contraire, à chaque étape,
une réduction parallèle dont le résultat est rapatrié sur l'hôte, engendrant
énormément de synchronisations, ce qui explique l'écart de la performance.
Enfin, l'accélération plus faible de `ludcmp` que de `lu`, dont la factorisation
est identique, tient à la dernière substitution triangulaire, que le code généré
exécute sur l'hôte au moyen d'une boucle inefficace.

#figure(
  ```cpp
  cudaMemcpy(dev_A, A, N * N * sizeof(double), cudaMemcpyHostToDevice);
  for (int c0 = 0; c0 < N - 1; c0 += 1) {
    kernel2 <<<dim3(64, 64), dim3(4, 32)>>> (dev_A, N, c0);
    kernel3 <<<dim3(64, 64), dim3(4, 32)>>> (dev_A, N, c0);
    kernel4 <<<dim3(64), dim3(32)>>> (dev_A, N, c0);
  }
  cudaMemcpy(A, dev_A, N * N * sizeof(double), cudaMemcpyDeviceToHost);
  ```,
  caption: [Extrait simplifié du code hôte généré par PPCG pour `lu`.],
) <code:evaluations:lu-ppcg>

Le noyau `gramschmidt` n'obtient qu'un gain modeste (#box[1.58$times$]). Son
calcul se déroule en étapes successives, et sa version de référence parallélise
déjà l'essentiel du travail. PPCG parallélise plus largement l'opération
principale de la mise à jour de la matrice, mais il calcule sur un seul thread
la norme dont chaque étape a besoin, là où la référence l'obtient par une
réduction parallèle, ce qui limite le gain.


=== Exploitation de la hiérarchie mémoire <sec:evaluations:gpu:memory>

Sur les noyaux d'algèbre linéaire, les gains dépendent surtout du parallélisme
exploité par la version de référence. Celles de `syrk` (#box[42.99$times$]),
`syr2k` (#box[21.17$times$]) et `covariance` (#box[7.31$times$]) ne
parallélisent qu'une seule dimension, avec un thread par ligne du résultat.
Celle de `symm` (#box[34.13$times$]) enchaîne des lancements successifs d'un
petit nombre de threads. C'est bien trop peu pour occuper tous les coeurs de la
carte. PPCG génère au contraire un noyau, découpé en tuiles de $32 times 32$
éléments. Chaque tuile est chargée en mémoire partagée par les threads d'un
bloc, puis réutilisée depuis cette mémoire rapide. Pour `trmm`
(#box[2.86$times$]), les dépendances du calcul limitent le code généré à la même
parallélisation que la référence, avec un thread par colonne, et le gain
provient essentiellement de la mémoire partagée. Enfin, `gemm`
(#box[1.90$times$]), `2mm` (#box[1.41$times$]) et `3mm` (#box[1.09$times$])
n'obtiennent que des gains modérés grâce à la mémoire partagée et la
privatisation des variables, les versions de référence utilisant déjà un
parallélisme efficace.

À l'inverse, `gemver` (#box[1.01$times$]), `gesummv`, `atax`, `bicg` et `mvt`
(#box[0.99$times$]) restent neutres. Comme sur CPU, ces produits matrice-vecteur
lisent chaque élément de matrice une seule fois. Leur performance est bornée par
la bande passante de la mémoire globale. PPCG reproduit la parallélisation faite
dans la version de référence.

=== Contre-performances <sec:evaluations:gpu:slowdowns>

Quatre noyaux régressent : `jacobi-1d` (#box[0.12$times$]), `doitgen`
(#box[0.20$times$]), `deriche` (#box[0.20$times$]) et `jacobi-2d`
(#box[0.60$times$]). Dans les quatre cas, PPCG n'expose aucun parallélisme
supplémentaire et reproduit la parallélisation de la version de référence. PPCG
génère des gardes conditionnelles et des boucles supplémentaires pour garantir
la correction aux bords du domaine, dont le coût devient important sur des
noyaux aussi légers. Ces surcoûts, multipliés par le nombre de lancements,
expliquent l'ampleur des régressions.


=== Bilan de l'évaluation sur GPU <sec:evaluations:gpu:summary>

La réintégration de PPCG dans Polly permet de générer automatiquement, à partir
de code Kokkos, du code GPU qui accélère 16 des 24 noyaux compilés. Les gains
les plus importants, atteignant trois ordres de grandeur, sont obtenus sur les
noyaux à dépendances, dont PPCG réorganise le calcul en étapes ou en fronts
d'onde massivement parallèles, là où la version de référence exécute une partie
du calcul sur un seul thread. Sur les noyaux d'algèbre linéaire dont la
référence ne parallélise qu'une dimension, la projection du calcul sur
l'architecture GPU et l'utilisation de la mémoire partagée n'apportent qu'un
gain léger en performance.

Cette évaluation met également en évidence les limites actuelles de la
génération de code GPU. Lorsque l'ordonnanceur ne parvient pas à trouver
davantage de parallélisme, le surcoût de contrôle rend le code généré moins
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

Pour la grande majorité des noyaux, le surcoût reste faible. Les médianes
s'établissent à #box[1.05$times$] pour ISL, #box[1.16$times$] pour Pluto et
#box[1.00$times$] pour PPCG, et 25 des 27 noyaux se compilent en moins de
#box[1.2$times$] le temps de référence avec ISL. Ce résultat s'explique en
partie par l'isolation des noyaux (#chref(<sec:kokkosvisibility>)). Polly
n'analyse que les fonctions marquées par l'option `usePolyOpt`, et non
l'ensemble du module, mais aussi par la réduction de l'usage intensif de
templates dans les backends modifiés. Le surcoût légèrement plus élevé de Pluto
provient de l'étape d'ordonnancement et des étapes d'export et d'import au
format OpenScop (@sec:schedulingheterogeneous:pluto).

Quelques noyaux font exception. Le plus marquant est `3mm`, dont la compilation
est #box[28.82$times$] plus longue avec ISL et #box[17.36$times$] avec PPCG.
Pluto est quant à lui pénalisé sur `gesummv`, `syrk` (#box[10.40$times$]) et
`heat-3d` (#box[24.04$times$]), et PPCG sur `jacobi-2d` (#box[88.28$times$]).
Enfin, la compilation de `adi`, `fdtd-2d` et `heat-3d` avec PPCG ne termine pas
en un temps raisonnable. Ce point est discuté dans l'évaluation sur GPU
(@sec:evaluations:gpu:global).


== Comparaison avec Polly sur PolyBench <sec:evaluations:vanilla>

Les sections précédentes comparent notre chaîne de compilation à une
implémentation Kokkos idiomatique. Cette section la compare à l'usage habituel
de Polly, appliqué aux noyaux de la suite PolyBench écrits en C séquentiel. Elle
vérifie que l'abstraction Kokkos, une fois rendue visible au compilateur,
n'empêche pas Polly d'obtenir des performances comparables à celles qu'il
atteint sur le code C d'origine. La version de Polly utilisée est issue de la
même version de LLVM que notre chaîne de compilation, sans nos modifications.
Les mesures sont réalisées sur la machine Intel avec l'ordonnanceur ISL, une
taille de tuile de 32, 20 threads et les mêmes tailles de problème que dans le
reste du chapitre (@table:evaluations:problemsizes). Une accélération supérieure
à 1 signifie que notre version est plus rapide que Polly appliqué au code C. Le
noyau `deriche` est absent de la comparaison, car Polly s'arrête sur une erreur
lors de sa compilation. Les deux versions sont compilées en `-O3` avec les mêmes
options de Polly.

#figure(
  image(fig.evaluation-polybench-eugene-polly-vanilla, width: 100%),
  placement: auto,
  caption: [Accélération de Kokkos + Polly (usePolyOpt) par rapport à Polly
    appliqué à PolyBench/C, avec l'ordonnanceur ISL sur processeur Intel Core
    Ultra 7 265 (20 threads sans hyperthreading, taille de tuile : 32).],
) <fig:evaluations:vanilla>

Sur les 26 noyaux mesurés, la moyenne géométrique des accélérations est de
1.08$times$, et 14 noyaux restent à moins de 10 % de Polly appliqué au code C.
Pour plus de la moitié des noyaux, notre chaîne de compilation obtient donc des
performances proches de celles de Polly sur le code d'origine. Les écarts
restent toutefois importants sur quelques noyaux, dans les deux sens.

*Noyaux plus rapides avec notre version.* `symm` (9.52$times$), `adi`
(3.86$times$), `seidel-2d` (2.93$times$) et avec une accélération moins
importante, `gramschmidt` (1.18$times$) et `bicg` (1.15$times$). Sur les trois
premiers, les optimisations que LLVM applique avant Polly remplacent, dans le
code C, certaines lectures de tableaux par des valeurs scalaires, transmises
d'une itération ou d'une instruction à l'autre. Comme pour `deriche`
(@sec:evaluations:cpu:regressions), ces scalaires créent de fausses dépendances,
qui empêchent Polly de tuiler et de paralléliser le nid principal de `symm` et
deux des quatre phases d'`adi`, et de tuiler celui de `seidel-2d`. Dans notre
chaîne de compilation, la passe `ArrayReg2MemPass`
(@sec:kokkosvisibility:array_canonicalization), absente de Polly d'origine,
rétablit ces accès aux tableaux. Polly tuile et parallélise alors `symm` et
`adi`, et tuile `seidel-2d`, qui ne gagne que par la localité des données.

*Noyaux plus lents avec notre version.* `jacobi-1d` (0.24$times$), `2mm`
(0.73$times$), `syrk` (0.79$times$), `jacobi-2d` (0.80$times$), `doitgen`
(0.83$times$), `gemm` (0.85$times$) et `ludcmp` (0.89$times$). Sur tous ces
noyaux, comme sur `gramschmidt` et `bicg`, les deux versions appliquent les
mêmes transformations et parallélisent les mêmes boucles. Les tailles du
problème sont toutefois connues à la compilation dans le code C et passées en
paramètres dans notre version. L'écart ne provient donc pas des transformations
polyédriques elles-mêmes, mais du code généré ensuite par Polly et LLVM.

Sur `jacobi-1d`, l'écart vient d'une vectorisation défavorable. Dans notre
version, le vectoriseur SLP de LLVM lit en une seule fois deux éléments,
`B(i-2)` et `B(i-1)`, écrits séparément aux deux itérations précédentes. Le
processeur ne sait pas transmettre directement à une telle lecture des valeurs
venant de deux écritures distinctes. Chaque itération doit donc attendre que ces
écritures atteignent le cache. En désactivant ce vectoriseur
(`-fno-slp-vectorize`), notre version devient 1.10$times$ plus rapide que Polly
sur le code C, et atteint 0.99$times$ de la référence Kokkos, contre 0.20$times$
avec la vectorisation (@sec:evaluations:cpu:regressions).

Sur `gemm`, `syrk` et le premier produit de `2mm`, la boucle la plus interne
accumule un produit multiplié par `alpha` dans un élément du tableau résultat.
Dans la version C, LLVM garde `alpha` et cet accumulateur dans des registres.
Dans notre version, `alpha` est relu en mémoire et l'accumulateur y est écrit à
chaque itération. Le second produit de `2mm`, qui ne fait pas intervenir
`alpha`, garde au contraire son accumulateur dans un registre dans les deux
versions. Dans le code Kokkos, `alpha` est un membre de la lambda, lu au travers
d'un pointeur. LLVM ne parvient pas à prouver l'absence d'aliasing, ce qui
l'empêche à la fois de sortir sa lecture de la boucle et de garder
l'accumulateur dans un registre.

Sur `doitgen` et `jacobi-2d`, l'écart tient aux tailles du problème, connues à
la compilation dans le code C. Sur `doitgen`, LLVM peut alors dérouler et
vectoriser la boucle la plus interne, qui reste scalaire dans notre version. Sur
`jacobi-2d`, les adresses des lignes voisines se calculent par des décalages
constants dans le code C, alors que notre version doit les garder dans des
registres supplémentaires. Sa boucle la plus interne manque alors de registres
et exécute environ 50 % d'instructions en plus.

Enfin, sur `ludcmp`, la boucle la plus coûteuse est identique dans les deux
versions. L'écart vient de la taille $N = 2048$, une puissance de deux. En
parcourant une colonne de `A`, la boucle provoque alors de nombreux conflits
dans le cache. Les deux versions sont environ deux fois plus lentes qu'avec
$N = 2040$ ou $N = 2056$, tailles pour lesquelles l'écart entre elles disparaît
(0.96$times$ et 1.00$times$). Ces conflits dépendent de la position des tableaux
en mémoire, car l'adresse d'un élément détermine l'emplacement du cache où il
est rangé. Or cette position diffère entre les deux versions. Dans le code C,
PolyBench aligne chaque tableau sur le début d'une page mémoire. Dans notre
version, les données d'une vue Kokkos sont précédées d'un en-tête d'allocation,
ce qui les décale de quelques lignes de cache. Les éléments lus par la boucle ne
se répartissent donc pas de la même façon dans le cache, ce qui explique l'écart
restant pour $N = 2048$.

En résumé, l'abstraction Kokkos n'empêche pas Polly d'optimiser les noyaux.
Notre chaîne de compilation obtient en moyenne des performances légèrement
supérieures à celles de Polly sur le code C d'origine. Sur les noyaux où elle
l'emporte nettement, la passe `ArrayReg2MemPass` permet à Polly d'appliquer des
transformations qu'il ne peut pas appliquer au code C. Sur les noyaux où elle
est plus lente, les deux versions appliquent les mêmes transformations, et
l'écart vient du code que LLVM génère ensuite ou du placement des données en
mémoire, et non de la visibilité des noyaux Kokkos.
