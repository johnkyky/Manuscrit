#import "../src/common.typ": *

= État de l'Art <sec:stateoftheart>

L'évolution de la complexité matérielle des supercalculateurs modernes a conduit
à une augmentation massive à la fois du nombre de coeurs disponibles et de leur
puissance de calcul. Ces architectures multi-coeurs sont fréquemment couplées à
des accélérateurs matériels spécialisés, faisant du développement de codes
scientifiques un véritable défi. Pour répondre à cette problématique, les
développeurs ont inventé différentes approches de programmation. Dans cette
thèse étudierons deux d'entre eux, les frameworks de portabilité des
performances de haut niveau, conçus pour abstraire le matériel et maintenir un
code source unique pour de multiples architectures, et les compilateurs
spécialisés dédiés à l'optimisation de code.

D'une part, les frameworks de portabilité des performances de haut niveau visent
à fournir aux développeurs une interface unifiée pour gérer le parallélisme et
la mémoire. D'autre part, les compilateurs spécialisés, tels que les
compilateurs polyédriques, se concentrent sur la rigueur mathématique de
l'optimisation des boucles et l'exposition d'un parallélisme à grain fin à
travers des transformations avancées basées sur le code source ou sur une IR.

Bien que ces deux domaines coexistent, les faire interopérer de manière
transparente reste un défi majeur pour la communauté de la compilation. Extraire
un modèle mathématique à partir d'un code fortement abstrait par les structures
C++ de haut niveau de ces frameworks est extrêmement difficile, car le
compilateur perd des informations sémantiques critiques au cours du processus
d'abaissement. À l'inverse, les frameworks eux-mêmes manquent de
l'infrastructure interne nécessaire pour effectuer des analyses statiques
complexes et des transformations structurelles automatiques de boucles.

Ce chapitre passe en revue la littérature existante autour de ces deux
écosystèmes. Il explore d'abord dans @sec:stateoftheart:frameworks, comment les
frameworks de portabilité des performances de haut niveau atteignent des
performances indépendamment de l'architecture cible. Il analyse ensuite
l'évolution des compilateurs polyédriques, des outils source-à-source jusqu'aux
frameworks IR modernes, en mettant en évidence leurs limitations inhérentes
lorsqu'ils sont confrontés à de fortes abstractions
(@sec:stateoftheart:polyhedral). Enfin @sec:stateoftheart:hybrid, explore les
approches hybrides et les langages dédiés qui tentent de combler ce fossé,
démontrant in fine la nécessité de la nouvelle approche proposée dans cette
thèse.

== Frameworks de Portabilité des Performances <sec:stateoftheart:frameworks>

Les développeurs de calcul haute performance en C++ s'appuient sur des
frameworks de portabilité des performances comme Kokkos
(@sec:scientificbackground:kokkos), RAJA~@raja, ou sur des standards émergents
comme SYCL~@sycl et le standard de parallélisme C++ (`std::par`)~@isostdpar.
Tous ces outils partagent une philosophie commune : la séparation stricte entre
l'expression de l'algorithme et son modèle d'exécution. Pour y parvenir, ils
s'appuient fortement sur les fonctionnalités modernes du C++, en particulier les
expressions lambda et les foncteurs, pour encapsuler les noyaux de calcul. Ils
utilisent également des espaces d'exécution et des espaces mémoire pour gérer la
distribution des calculs et la localité des données à travers des architectures
hétérogènes. Pour illustrer cela, @fig:stateoftheart:frameworks_syntax compare
les différentes façons d'écrire le même code (une multiplication
matrice-vecteur) en utilisant ces différents frameworks.

#[
  #show figure: set block(breakable: true)
  #show raw.where(block: true): it => block(breakable: false, it)
  #figure(
    table(
      columns: (auto, 1fr),
      align: (center + horizon, left + horizon),
      stroke: 0.5pt + luma(200),
      [*Framework*], [*Exemple de Syntaxe (Multiplication Matrice-Vecteur)*],
      [*`Kokkos`*],
      ```cpp
      void matVecMult_kokkos(int N, int M, View<float**> A,
                             View<float*> x, View<float*> y) {
        auto policy = Kokkos::RangePolicy<>(0, N);

        Kokkos::parallel_for(policy, KOKKOS_LAMBDA(const int i) {
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A(i, j) * x(j);
          y(i) = sum;
        });
      }
      ```,

      [*`RAJA`*],
      ```cpp
      void matVecMult_raja(int N, int M, const float* A,
                           const float* x, float* y) {
        using ExecPolicy = RAJA::omp_parallel_for_exec;

        RAJA::forall<ExecPolicy>(RAJA::RangeSegment(0, N), [=](int i) {
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A[i * M + j] * x[j];
          y[i] = sum;
        });
      }
      ```,

      [*`SYCL`*],
      ```cpp
      void matVecMult_sycl(sycl::queue& q, int N, int M,
                           const float* A, const float* x, float* y) {
        auto policy = sycl::range<1>(N);

        q.parallel_for(policy, [=](sycl::id<1> idx) {
          int i = idx[0];
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A[i * M + j] * x[j];
          y[i] = sum;
        }).wait();
      }
      ```,

      [*`std::par`*],
      ```cpp
      void matVecMult_std(int N, int M, const float* A,
                          const float* x, float* y) {
        std::vector<int> rows(N);
        std::iota(rows.begin(), rows.end(), 0);

        std::for_each(std::execution::par_unseq, rows.begin(), rows.end(),
          [=](int i) {
            float sum = 0.0f;
            for (int j = 0; j < M; ++j)
              sum += A[i * M + j] * x[j];
            y[i] = sum;
        });
      }
      ```,
    ),
    caption: [Comparaison syntaxique des boucles parallèles entre différents
      frameworks C++ de portabilité des performances.],
  ) <fig:stateoftheart:frameworks_syntax>
]

Bien que l'objectif principal de ces frameworks soit la portabilité, ils offrent
tout de même certaines capacités d'optimisation structurelle. Par exemple, le
pavage de boucles est disponible dans Kokkos, RAJA et SYCL. Cela permet aux
développeurs d'appliquer un pavage statique sur les nids de boucles, ce qui
améliore la localité des données dans les caches de l'architecture cible. Kokkos
dispose d'un algorithme pour choisir automatiquement des tailles de tuiles
efficaces en fonction de l'architecture, mais celui-ci est très limité en raison
du manque d'informations statiques récoltées au sein de Kokkos. Des travaux ont
été réalisés dans Kokkos pour ajouter `kokkos-tools`~@kokkostools, une extension
qui permet de surveiller et de tracer le code, mais aussi d'autotuner les noyaux
à l'aide d'outils externes comme Apex~@apex ou Apollo~@apollotuning afin de
spécialiser le code en quête de performances encore plus élevées.

Cependant, la limitation fondamentale de ces frameworks réside dans leur nature
déclarative. Ils agissent principalement comme des moteurs de mapping : ils
mappent aveuglément les itérations de boucles sur les threads CPU ou les blocs
GPU, en faisant confiance au code écrit par le développeur. Ces bibliothèques ne
possèdent pas de moteur d'analyse statique interne capable d'analyser les
dépendances de données du noyau de calcul.

Par conséquent, il leur est techniquement et mathématiquement impossible de
restructurer le code automatiquement. Les transformations complexes qui
modifient l'ordre d'exécution des itérations de boucles (ex: fission, fusion)
sont hors de portée de ces outils. En d'autres termes, si le développeur écrit
un nid de boucles structurellement sous-optimal, le framework le parallélisera
fidèlement, mais de manière sous-optimale. L'optimisation du code reste donc la
seule responsabilité du développeur, ce qui limite les performances maximales
potentielles pouvant être atteintes de manière automatique.

== Modèle Polyédrique et Implémentations <sec:stateoftheart:polyhedral>

Il existe différentes implémentations de compilateurs et d'outils basés sur le
modèle polyédrique. Historiquement, ces outils s'appuyaient sur des approches
source-à-source et étaient limités à l'analyse d'un sous-ensemble du langage C.
L'un des compilateurs les plus renommés pour la qualité de son ordonnanceur est
Pluto~@plutoscheduler. Il permet la compilation source-à-source de code C en
explorant un vaste espace de transformations (comme le pavage en diamant). Un
autre outil de référence est PPCG (Polyhedral Parallel Code Generator)~@ppcg, un
compilateur source-à-source conçu pour générer du code GPU optimisé à partir de
code C séquentiel. Ces approches purement textuelles facilitent l'extraction du
modèle : les accès mémoire, tels que les tableaux multidimensionnels (par
exemple, A[i][j]), sont directement visibles sous forme d'indices, ce qui
simplifie grandement l'analyse mathématique (@fig:stateoftheart:polyhedral_s2s).

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node((0, 0), [Code Source \ (C/C++)], corner-radius: 3pt),
      fletcher.edge((0, 0), (1, 0), "-|>"),
      fletcher.node(
        (1, 0),
        [Source-à-Source \ (Pluto, PPCG)],
        fill: rgb("eef5ff"),
        corner-radius: 3pt,
      ),
      fletcher.edge((1, 0), (2, 0), "-|>"),
      fletcher.node((2, 0), [C/C++ \ Optimisé], corner-radius: 3pt),
      fletcher.edge((2, 0), (3, 0), "-|>"),
      fletcher.node((3, 0), [Compilateur], corner-radius: 3pt),
    ),
    caption: [Chaîne de compilation polyédrique source-à-source.],
  ) <fig:stateoftheart:polyhedral_s2s>
]


Bien que ces outils atteignent d'excellentes performances, leur champ
d'application reste très limité. S'appuyant sur des parseurs rudimentaires, ils
n'ont absolument pas été conçus pour analyser des codes complexes provenant de
frameworks de portabilité des performances, qui font un usage intensif de la
métaprogrammation et des structures C++ modernes.

Pour surmonter la complexité liée à l'analyse syntaxique des langages de haut
niveau, la communauté de la compilation polyédrique a adopté une nouvelle
approche : abaisser le niveau d'analyse. En s'appuyant sur des Représentations
Intermédiaires (IR) telles que celle de LLVM, les outils polyédriques
parviennent à s'abstraire du langage source (C, C++, Fortran) et des complexités
du parser du compilateur.

Graphite~@graphite a été l'un des premiers compilateurs polyédriques largement
adoptés à utiliser cette méthode, s'intégrant directement dans l'IR de GCC
@gccir. Au sein de l'écosystème LLVM, l'outil Polly~@polly1 utilise l'IR LLVM
pour reconstruire et appliquer le modèle polyédrique. Plus récemment, des outils
comme Polygeist~@Polygeist s'appuient sur MLIR @mlir, une représentation IR LLVM
de plus haut niveau qui permet de conserver certaines informations structurelles
(telles que la sémantique des boucles `for`) sans avoir à les reconstruire à
partir d'un graphe de flot de contrôle plus proche de la machine. Cette chaîne
de compilation moderne au niveau de l'IR est illustrée en
@fig:stateoftheart:polyhedral_ir.

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node((0, 1), [Code Source \ (C/C++)], corner-radius: 3pt),
      fletcher.edge((0, 1), (1, 1), "-|>"),
      fletcher.node((1, 1), [Front-End \ (Clang/GCC)], corner-radius: 3pt),
      fletcher.edge((1, 1), (2, 1), "-|>"),
      fletcher.node(
        (2, 1),
        [Niveau IR \ (Polly, Polygeist)],
        fill: rgb("eef5ff"),
        corner-radius: 3pt,
      ),
      fletcher.edge((2, 1), (3, 1), "-|>"),
      fletcher.node((3, 1), [Back-End], corner-radius: 3pt),
    ),
    caption: [Chaîne de compilation polyédrique au niveau de l'IR.],
  ) <fig:stateoftheart:polyhedral_ir>
]

Pourtant, malgré l'utilisation de l'IR, les outils modernes comme Polly ou
Polygeist échouent à optimiser les codes générés par des bibliothèques telles
que Kokkos. Cette limitation découle du fossé sémantique. L'architecture de ces
frameworks, conçue pour offrir la meilleure portabilité et généralisation
possible à l'utilisateur, s'appuie en interne sur un réseau complexe
d'expressions lambda, de foncteurs et d'arithmétique de pointeurs. Lors de la
compilation, ces abstractions masquent la linéarité des accès mémoire, génèrent
des incertitudes liées à l'aliasing, et brisent catégoriquement les heuristiques
nécessaires à la construction du modèle polyédrique.

Une autre approche novatrice pour l'optimisation de code est celle utilisée par
Apollo @apollo. Elle consiste à s'appuyer sur l'IR de LLVM pour appliquer des
transformations polyédriques, mais se base sur le comportement à l'exécution du
programme pour déterminer si une région est polyédrique ou non. Cette méthode
s'affranchit de la complexité de l'analyse statique de l'IR, qui peut s'avérer
ardue pour déduire la structure et les accès mémoire du programme.
@fig:stateoftheart:apollo_architecture illustre le fonctionnement du logiciel
Apollo. Toutefois, cette approche engendre un surcoût non négligeable : elle
requiert un système d'instrumentation et d'analyse des données à l'exécution,
ainsi qu'une compilation juste-à-temps (JIT) pour appliquer les transformations.

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 2pt,
      node-inset: 8pt,
      spacing: (4em, 2em),

      // Nodes
      fletcher.node(
        (0, 0),
        align(center)[#text(size: 3em)[🧑‍💻] \ Programmer],
        stroke: none,
      ),
      fletcher.node(
        (1, 0),
        align(center)[Annotated \ source code],
        fill: rgb("#ffffb3"),
        corner-radius: 2pt,
      ),
      fletcher.node(
        (2, 0),
        align(center)[Apollo \ Static \ Component],
        fill: rgb("#99c2ff"),
        corner-radius: 4pt,
      ),
      fletcher.node(
        (3, 0),
        align(center)[Binary \ Executable],
        fill: rgb("#b3ffb3"),
        corner-radius: 2pt,
      ),
      fletcher.node(
        (4, 0),
        align(center)[Apollo \ Runtime \ System],
        fill: rgb("#d9b3ff"),
        corner-radius: 50pt,
      ),

      // Edges
      fletcher.edge((0, 0), (1, 0), "-|>"),
      fletcher.edge((1, 0), (2, 0), "-|>"),
      fletcher.edge((2, 0), (3, 0), "-|>"),
      fletcher.edge((3, 0), (4, 0), "-|>", bend: -20deg),
      fletcher.edge((4, 0), (3, 0), "-|>", bend: -20deg),

      // Compile-time brackets
      fletcher.edge((0, 0.8), (0, 1.2), (3, 1.2), (3, 0.8), stroke: (
        dash: "dotted",
        thickness: 1pt,
      )),
      fletcher.node((1.5, 1.2), [Compile-Time], stroke: none, fill: white),

      // Runtime brackets
      fletcher.edge((3.1, 0.8), (3.1, 1.2), (4, 1.2), (4, 0.8), stroke: (
        dash: "dotted",
        thickness: 1pt,
      )),
      fletcher.node((3.55, 1.2), [Runtime], stroke: none, fill: white),
    ),
    caption: [Architecture de l'outil Apollo, séparant la compilation statique
      et l'optimisation dynamique à l'exécution.],
  ) <fig:stateoftheart:apollo_architecture>
]

== Combiner Abstractions de Haut Niveau et Optimisation Polyédrique <sec:stateoftheart:hybrid>

Une autre approche pour atténuer les problèmes précédemment exposés consiste à
élever le niveau d'abstraction sémantique en utilisant des langages de plus haut
niveau tels que Python ou des langages dédiés (DSL), ou encore des bibliothèques
offrant une plus grande expressivité. Ainsi, la sémantique mathématique des
opérations devient beaucoup plus évidente à interpréter pour les outils de
compilation, ce qui réduit considérablement le fossé sémantique entre le code
source et l'application du modèle polyédrique.

Tiramisu~@tiramisu illustre parfaitement cette dynamique. Il s'agit d'un
framework C++ fonctionnant, dans sa conception, comme un langage dédié pour le
calcul haute performance, comme illustré en @fig:stateoftheart:tiramisu_syntax.
L'utilisateur déclare formellement les calculs, les tailles des données, le
domaine d'itération, ainsi que les transformations mathématiques à appliquer
(pavage, déroulage, parallélisation). En imposant cette déclaration explicite,
l'outil peut appliquer des transformations polyédriques et générer un code C++
hautement optimisé sans que le compilateur n'ait à deviner la structure du
programme.

#[
  #show figure: set block(breakable: true)
  #figure(
    ```cpp
    void matVecMul_tiramisu(int N, int M) {
        tiramisu::init("matVecMult");

        tiramisu::var i("i", 0, N);
        tiramisu::var j("j", 0, M);

        tiramisu::input A("A", {i, j}, tiramisu::p_float32);
        tiramisu::input x("x", {j}, tiramisu::p_float32);

        tiramisu::computation y_init("y_init", {i}, tiramisu::expr(0.0f));

        tiramisu::computation y_update("y_update", {i, j}, y_init(i) + A(i, j) * x(j));

        y_init.then(y_update, i);

        y_init.parallelize(i);
        y_update.parallelize(i);

        tiramisu::buffer b_A("b_A", {tiramisu::expr(N), tiramisu::expr(M)}, tiramisu::p_float32, tiramisu::a_input);
        tiramisu::buffer b_x("b_x", {tiramisu::expr(M)}, tiramisu::p_float32, tiramisu::a_input);
        tiramisu::buffer b_y("b_y", {tiramisu::expr(N)}, tiramisu::p_float32, tiramisu::a_output);

        A.store_in(&b_A);
        x.store_in(&b_x);

        y_init.store_in(&b_y, {i});
        y_update.store_in(&b_y, {i});

        tiramisu::codegen({&b_A, &b_x, &b_y}, "matvec_mult.o");
    }
    ```,
    caption: [Exemple de syntaxe déclarative dans Tiramisu, séparant proprement
      l'algorithme de son ordonnancement d'exécution.],
  ) <fig:stateoftheart:tiramisu_syntax>
]

Suivant cette même logique d'abstraction, d'autres travaux se sont tournés vers
l'écosystème Python pour s'affranchir de la gestion complexe de la mémoire en
C++. Par exemple, @ramon2018autoparallel a démontré l'efficacité de
l'application du modèle polyédrique directement sur les opérations NumPy~@numpy.
De même, des initiatives telles que PyKokkos~@pykokkos offrent des interfaces
Python de haut niveau. Ces couches d'abstraction permettent de capturer les
opérations mathématiques de manière hautement abstraite. Avoir accès à cette
information sémantique préservée serait extrêmement bénéfique pour extraire le
modèle polyédrique, tout en continuant à masquer la complexité matérielle. Un
exemple de cette syntaxe de haut niveau est fourni dans
@fig:stateoftheart:pykokkos_syntax.

#[
  #show figure: set block(breakable: false)
  #figure(
    ```python
    import pykokkos as pk

    @pk.workunit
    def matVecMult_kernel(i: int, M: int,
                            A: pk.View2D[pk.float],
                            x: pk.View1D[pk.float],
                            y: pk.View1D[pk.float]):
        sum_val: pk.float = 0.0
        for j in range(M):
            sum_val += A[i, j] * x[j]
        y[i] = sum_val

    def matvec_mult_pykokkos(N: int, M: int, A: pk.View2D, x: pk.View1D, y: pk.View1D):
        pk.parallel_for(N, matvec_kernel, M=M, A=A, x=x, y=y)
    ```,
    caption: [Exemple de multiplication matrice-vecteur utilisant l'interface
      Python de haut niveau PyKokkos.],
  ) <fig:stateoftheart:pykokkos_syntax>
]

Bien que ces approches apportent des solutions très efficaces aux problèmes de
performances, elles imposent un coût d'entrée prohibitif pour le monde du HPC.
En effet, elles exigent des scientifiques qu'ils réécrivent intégralement leurs
codes de simulation historiques et massifs dans de nouveaux langages ou via des
API hautement spécifiques.

Pour contourner cette barrière de réécriture, certains travaux ont exploré
l'approche inverse : utiliser les frameworks de portabilité comme cibles de
compilation. Par exemple, les auteurs de @polykokkosbackend ont utilisé des
outils polyédriques pour analyser du code C séquentiel afin de générer
automatiquement du code Kokkos. Cette stratégie combine l'optimisation
mathématique effectuée en amont avec la portabilité matérielle garantie par
Kokkos en aval.

Cependant, bien que cette méthode soit pertinente pour la modernisation des
anciens codes, elle ne résout absolument pas le problème central de l'écosystème
actuel : optimiser des codes déjà écrits nativement en Kokkos. À ce jour, il
n'existe aucun outil capable d'ingérer le code source Kokkos, de l'analyser
mathématiquement, et de restructurer ses boucles de l'intérieur de manière
transparente. C'est pour combler ce vide scientifique que cette thèse propose
une intégration du modèle polyédrique, capable d'opérer directement sous les
abstractions de Kokkos.
