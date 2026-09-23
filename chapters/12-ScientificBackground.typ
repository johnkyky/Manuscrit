#import "../src/common.typ": *

= Contexte Scientifique <sec:scientificbackground>

Cette thèse se concentre sur l'application du modèle polyédrique pour optimiser
statiquement les nids de boucles exprimés en Kokkos @kokkos. Étant donné que ces
travaux font le pont entre les frameworks de portabilité des performances de
haut niveau et les transformations mathématiques de boucles de bas niveau, une
solide compréhension de ces deux domaines est requise.

Ce chapitre fournit les bases théoriques nécessaires pour la suite du manuscrit.
Tout d'abord, le @sec:scientificbackground:loopnests présente le concept de nid
de boucles. Ensuite, le @sec:scientificbackground:kokkos introduit le modèle de
programmation Kokkos, en détaillant ses abstractions de mémoire et d'exécution.
Le @sec:scientificbackground:polyhedral explore la représentation polyédrique et
le @sec:scientificbackground:polyhedralecosystem décrit les outils et
compilateurs de l'écosystème polyédrique, avec une attention particulière portée
dans le @sec:scientificbackground:polly à l'outil Polly qui constitue la base de
notre implémentation.


== Nids de Boucles <sec:scientificbackground:loopnests>

En programmation comme en mathématiques, une boucle fondamentale est
caractérisée par une variable d'itération $i$ (souvent appelée itérateur ou
indice), une borne inférieure, une borne supérieure et un pas (stride).

Lorsqu'une ou plusieurs boucles sont imbriquées dans une autre boucle, la
structure résultante est appelée un *nid de boucles*. Le nombre de boucles
imbriquées définit la *profondeur* du nid. À toute étape d'exécution donnée,
l'état d'un nid de boucles de profondeur $n$ est identifié de manière unique par
son *vecteur d'itération* $arrow(i) = (i_1, i_2, dots, i_n)^T$, qui regroupe les
valeurs actuelles de tous les indices des boucles englobantes.

À l'intérieur de ces boucles, une *instruction* représente l'opération ou
l'instruction de calcul réelle qui est exécutée à un point d'itération donné.

Ces structures sont largement utilisées dans le calcul haute performance (HPC)
et les codes scientifiques, car elles fournissent le mécanisme principal pour
parcourir et manipuler de grandes structures de données multidimensionnelles
telles que les vecteurs, les matrices et les tenseurs.

=== Boucles Parfaitement Imbriquées

Un nid de boucles est considéré comme *parfaitement imbriqué* si toutes les
instructions de calcul sont situées exclusivement dans la boucle la plus
interne. Il n'y a pas de code exécuté entre les instructions `for` des boucles
externes et internes.

Le @code:scientificbackground:perfectnest illustre une boucle parfaitement
imbriquée de profondeur 2 avec une seule instruction `S1`.

#figure(
  ```cpp
  for (int i = 0; i < N; i++) {
      for (int j = 0; j < M; j++) {
          C[i][j] = A[i][j] + B[i][j];  // Instruction S1 (Profondeur 2)
      }
  }
  ```,
  caption: [Exemple d'un nid de boucles parfaitement imbriqué de profondeur 2.],
) <code:scientificbackground:perfectnest>

=== Boucles Imparfaitement Imbriquées

En pratique, de nombreux algorithmes scientifiques ne peuvent pas être écrits
sous forme de boucles parfaitement imbriquées. Nous généralisons le concept aux
*boucles imparfaitement imbriquées*, qui se produisent lorsque des instructions
de calcul existent à différents niveaux d'imbrication. En d'autres termes, les
instructions sont intercalées entre les boucles.

Le @code:scientificbackground:imperfectnest présente un nid de boucles imparfait
où une instruction d'initialisation `S1` est exécutée à l'intérieur de la boucle
externe `i`, mais à l'extérieur de la boucle interne `j` qui contient la seconde
instruction `S2`.

#figure(
  ```cpp
  for (int i = 0; i < N; i++) {
      row_sum[i] = 0;                  // Instruction S1 (Profondeur 1)
      for (int j = 0; j < M; j++) {
          row_sum[i] += A[i][j];       // Instruction S2 (Profondeur 2)
      }
  }
  ```,
  caption: [Exemple d'un nid de boucles imparfaitement imbriqué où les
    instructions existent à des profondeurs différentes.],
) <code:scientificbackground:imperfectnest>

Bien que les nids de boucles imparfaits soient naturels à écrire pour les
développeurs, ils posent un défi important pour les frameworks de
parallélisation comme Kokkos, détaillés dans le
@sec:scientificbackground:kokkos. L'extraction du parallélisme et l'optimisation
de la localité des données dans ces nids imparfaits nécessitent des
transformations de code complexes. Cette complexité mathématique est précisément
ce que le modèle polyédrique, introduit dans le
@sec:scientificbackground:polyhedral suivant, vise à résoudre.



== Le Modèle de Programmation Kokkos <sec:scientificbackground:kokkos>

Initialement développé pour abstraire le parallélisme matériel, le modèle de
programmation Kokkos s'est imposé comme un framework de référence dans le calcul
haute performance (HPC) et la simulation scientifique. Il fournit une interface
C++ unifiée pour la programmation parallèle hétérogène, avec un accent principal
sur la portabilité des performances. En offrant des abstractions de haut niveau
pour la gestion de la mémoire et le contrôle de l'exécution, Kokkos simplifie le
processus de développement tout en garantissant l'obtention de performances,
quelle que soit l'architecture cible.

=== Espaces : Exécution et Mémoire

Pour cibler avec succès diverses architectures matérielles, Kokkos introduit le
concept d'espaces pour abstraire les unités d'exécution complexes et les
hiérarchies de mémoire des supercalculateurs modernes. Un noeud HPC typique est
hétérogène, couplant souvent un processeur hôte (CPU) avec un ou plusieurs
accélérateurs (GPU), chacun possédant sa propre mémoire physique distincte.
Kokkos gère cette hétérogénéité en découplant clairement l'endroit où le code
s'exécute de l'endroit où résident les données :

- *Espaces d'Exécution* définissent où les noyaux de calcul sont exécutés. Ils
  mappent les opérations parallèles vers un backend matériel spécifique et de
  l'implémentation du modèle de programmation. Par exemple, `Kokkos::Serial` ou
  `Kokkos::OpenMP` dictent que le code s'exécutera sur le CPU hôte, tandis que
  `Kokkos::Cuda` ou `Kokkos::HIP` ciblent les accélérateurs GPU.
- *Espaces Mémoire* définissent où les données sont physiquement allouées. Ils
  abstraient la hiérarchie de la mémoire de la machine cible. Des exemples
  courants incluent `Kokkos::HostSpace` pour la RAM CPU standard,
  `Kokkos::CudaSpace` pour la mémoire du périphérique GPU Cuda, ou
  `Kokkos::CudaUVMSpace` pour la mémoire virtuelle unifiée (UVM).

Ce concept d'espaces est étroitement lié aux abstractions de données et aux
motifs d'exécution parallèle de Kokkos, qui sont abordés dans les sections
suivantes.

=== Abstraction des Données

Pour simplifier la gestion des données à travers des architectures hétérogènes,
Kokkos fournit une abstraction de données fondamentale : la structure
`Kokkos::View`. Cette structure de données C++ template agit comme un tableau
multidimensionnel léger à comptage de références. Une `Kokkos::View` encapsule
le pointeur de données, ses dimensions, l'espace mémoire cible et sa disposition
en mémoire, abstrayant efficacement les allocations matérielles.

Une caractéristique cruciale pour la portabilité des performances est la
disposition en mémoire. Étant donné que les CPU et les GPU gèrent les accès
mémoire différemment, Kokkos définit des traits de disposition spécifiques :
- `Kokkos::LayoutRight` (row-major) : Optimise la localité spatiale et
  l'utilisation des lignes de cache pour les CPU.
- `Kokkos::LayoutLeft` (column-major) : Assure la coalescence des accès mémoire,
  ce qui est critique pour les performances des GPU.

Par défaut, Kokkos sélectionne automatiquement la disposition optimale à la
compilation en fonction de l'espace d'exécution, bien qu'elle puisse être
spécifiée explicitement par le programmeur.

@code:scientificbackground:viewexample illustre un flux de travail de gestion de
mémoire hétérogène basique. À la ligne 2, une vue 2D de flottants est allouée
directement dans la mémoire du GPU (`Kokkos::CudaSpace`), en utilisant
explicitement une disposition `Kokkos::LayoutLeft`. La ligne 4 démontre la
création d'une vue miroir accessible par l'hôte (`Kokkos::create_mirror_view`).
Cette fonction alloue un tableau équivalent dans l'espace mémoire de l'hôte,
permettant au CPU de manipuler les données en toute sécurité.

L'opérateur parenthèse surchargé `operator()` fournit une syntaxe d'accès
multidimensionnelle intuitive, gérant automatiquement la linéarisation complexe
des indices (ligne 7). Enfin, la synchronisation explicite des données entre les
espaces mémoire de l'hôte et du périphérique est effectuée à l'aide de
`Kokkos::deep_copy` (ligne 9).

#figure(
  ```cpp
  // ...
  Kokkos::View<float **, Kokkos::CudaSpace, Kokkos::LayoutLeft> tab_device("tab_device", N, N);

  auto tab_host = Kokkos::create_mirror_view(tab_device);

  for(int i = 0; i < N; i++)
      tab_host(i, i) = static_cast<float>(i);

  Kokkos::deep_copy(tab_device, tab_host);
  // ...
  ```,
  caption: [Exemple d'allocation standard de `Kokkos::View` et de transferts de
    mémoire hétérogènes.],
) <code:scientificbackground:viewexample>

Kokkos fournit plusieurs types de vues spécialisées pour des cas d'utilisation
avancés (exemple : `DualView`, `DynRankView`, `OffsetView`). Cependant, cette
thèse se concentrera exclusivement sur les vues standards.

=== Exécution Parallèle

Dans le modèle de programmation Kokkos, le lancement d'un noyau de calcul
nécessite de combiner un motif d'exécution, une politique d'exécution et le
corps du noyau (généralement défini via une fonction lambda C++ ou un foncteur).
Cette séparation des concepts permet aux développeurs d'exprimer la sémantique
de leur algorithme indépendamment du mapping matériel.

==== Motifs d'Exécution

Pour abstraire les modèles de programmation parallèle spécifiques au matériel
(ex: OpenMP, CUDA), Kokkos fournit trois motifs d'exécution parallèle
fondamentaux. Un motif d'exécution dicte la sémantique de l'opération :

- `Kokkos::parallel_for` : Mappe une opération indépendante sur un espace
  d'itération. Il représente les boucles standards de parallélisme de données où
  aucune dépendance n'existe entre les itérations.
- `Kokkos::parallel_reduce` : Calcule une réduction (ex: somme, min, max, ou
  réductions personnalisées) sur un espace d'itération. Kokkos gère
  automatiquement les accès concurrents spécifiques à l'architecture.
- `Kokkos::parallel_scan` : Effectue un préfixe somme sur un espace d'itération,
  fournissant une brique de base parallèle.

==== Politiques d'Exécution

Alors que le motif définit quelle opération est effectuée, la politique
d'exécution définit comment et où elle est exécutée. Elle définit le domaine
d'itération, donne des paramètres d'ordonnancement et spécifie l'espace
d'exécution cible.

===== RangePolicy et MDRangePolicy
`Kokkos::RangePolicy` et `Kokkos::MDRangePolicy` décrivent les espaces
d'itération pour les boucles unidimensionnelles et les boucles parfaitement
imbriquées à $n$ dimensions. Sous le capot, `MDRangePolicy` applique
automatiquement un pavage spécifique à l'architecture pour maximiser la localité
du cache ou la coalescence des accès mémoire.

===== TeamPolicy
Pour des algorithmes plus complexes, les espaces d'itération unidimensionnels ou
multidimensionnels et l'ordonnancement de base sont souvent insuffisants.
`Kokkos::TeamPolicy` résout ce problème en exposant le parallélisme
hiérarchique, ce qui est utile pour exploiter des topologies matérielles
spécifiques, en particulier sur les GPU. Il divise logiquement l'espace
d'itération en un tableau unidimensionnel de _Ligues_, où chaque ligue est
constituée de plusieurs _Équipes_ de threads. Lors d'un mapping sur un GPU, une
ligue correspond typiquement à une grille de blocs de threads, tandis qu'une
équipe correspond à un bloc individuel de threads. Sur un CPU, une ligue peut
correspondre aux coeurs physiques disponibles, avec des équipes utilisant des
threads matériels ou des voies vectorielles. Avec cette approche plus avancée,
les développeurs obtiennent un contrôle fin sur les ressources matérielles, tel
que l'exploitation de la mémoire partagée gérée par l'utilisateur sur les GPU ou
la gestion explicite de la mémoire cache sur les CPU, au détriment de la
simplicité de développement.

Pour illustrer comment Kokkos expose des espaces d'itération multidimensionnels,
@code:scientificbackground:mdrangeexample montre une addition de matrices 2D
implémentée avec une `Kokkos::MDRangePolicy`. Dans cet exemple, la politique
définit explicitement un domaine d'itération bidimensionnel (indiqué par
`Kokkos::Rank<2>`) allant de $(0, 0)$ à $(N, M)$. Le troisième argument de
`Kokkos::parallel_for` est la fonction lambda, qui décrit le noyau de calcul
lui-même. En tant qu'arguments, cette fonction lambda prend les indices
d'itération $i$ et $j$ pour effectuer les opérations élément par élément sur les
vues multidimensionnelles.

#figure(
  ```cpp
  Kokkos::View<double**> A("A", N, M);
  Kokkos::View<double**> B("B", N, M);
  Kokkos::View<double**> C("C", N, M);

  Kokkos::parallel_for("MatrixAddition",
      Kokkos::MDRangePolicy<Kokkos::Rank<2>>({0, 0}, {N, M}),
      KOKKOS_LAMBDA(const int i, const int j) {
          C(i, j) = A(i, j) + B(i, j);
      }
  );```,
  caption: [Exemple d'une addition de matrices parallèle utilisant une
    `MDRangePolicy`],
) <code:scientificbackground:mdrangeexample>




== Modèle Polyédrique <sec:scientificbackground:polyhedral>

Le modèle polyédrique est un framework mathématique permettant l'analyse et la
transformation précises des nids de boucles. Contrairement aux compilateurs
traditionnels qui appliquent des transformations syntaxiques locales directement
sur une #gls("ir") ou un #gls("ast"), le modèle polyédrique s'appuie entièrement
sur des abstractions algébriques. Cette fondation mathématique garantit la
correction sémantique des transformations appliquées. Pour représenter les nids
de boucles, le modèle utilise une représentation géométrique des domaines
d'itération, des accès mémoire, des dépendances de données et des
ordonnancements d'instructions, tous exprimés par des ensembles et des relations
mathématiques.

#definition(
  title: "Ensemble",
)[
  Un _ensemble_ (set) est une collection de coordonnées dans un espace unique
  $E$ de dimension $k$. Dans le contexte du modèle polyédrique, un ensemble peut
  être formellement considéré comme un cas particulier de relation où l'espace
  d'entrée est de dimension zéro.

  Un ensemble peut être représenté comme un polyèdre paramétrique restreignant
  les coordonnées valides :
  $
    S(arrow(p)) = { arrow(x) in E mid(|) A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0)}
  $
  où :
  - $arrow(p)$ est un vecteur de $N$ paramètres,
  - $arrow(x) in E$ est un vecteur de coordonnées,
  - $A$ est une matrice d'entiers de taille $m times (k + N + 1)$ qui encode les
    $m$ contraintes affines définissant les frontières de l'ensemble.
]

#definition(
  title: "Relation",
)[
  Une _relation_ #box($R : E -> F$) est une correspondance depuis un ensemble de
  coordonnées d'entrée dans un espace d'entrée $E$ de dimension $k$ vers un
  ensemble de coordonnées de sortie dans un espace de sortie $F$ de dimension
  $l$.

  #box($x in E$) est dit en relation avec #box($y in F$) #box([si
    $(x, y) in E times F$]). On le note couramment $x space R space y$ ou
  $R space x space y$. Une relation peut également être représentée comme un
  polyèdre paramétrique :
  $
    R(arrow(p)) = { arrow(x)_"in" -> arrow(x)_"out" in E times F mid(|) A dot.op vec(arrow(x)_"out", arrow(x)_"in", arrow(p), 1) polyrelcst arrow(0)}
  $
  où :
  - $arrow(p)$ est un vecteur de $N$ paramètres,
  - $arrow(x)_"in" in E$ est une coordonnée d'entrée,
  - $arrow(x)_"out" in F$ est une coordonnée de sortie,
  - $A$ est une matrice d'entiers de taille $m times (k + l + N + 1)$ qui encode
    les $m$ contraintes affines de la relation.
]

En modélisant les nids de boucles sous cette forme, le modèle polyédrique
raisonne exclusivement sur des objets mathématiques, offrant une plus grande
liberté pour appliquer des transformations complexes en toute sécurité. À
l'inverse, les représentations traditionnelles en #gls("ast") ou en #gls(
  "ir",
) se prêtent bien aux passes de compilation standards, mais leur manque
d'abstraction mathématique limite drastiquement l'application d'optimisations
structurelles avancées sur les boucles. Cette rigueur formelle restreint
néanmoins le domaine d'application de l'approche polyédrique : elle ne peut
cibler que les nids de boucles dont les bornes et les accès mémoires sont
affines, formellement regroupés sous l'appellation de #glspl("scop").

#definition(
  title: "Partie à Contrôle Statique (SCoP)",
)[
  Un #gls("scop") est une région de code sans appels de fonctions ou
  arithmétique de pointeurs, où les bornes des boucles, les conditions et les
  indices des tableaux sont soit constants, soit des fonctions affines des
  itérateurs des boucles englobantes et des paramètres globaux.
]

Au sein d'un #gls("scop"), chaque itération de boucle peut être représentée
comme un point entier à l'intérieur d'un polyèdre convexe de dimension $d$, où
$d$ correspond à la profondeur maximale de la boucle. Les dépendances de données
sont modélisées comme des relations affines entre les vecteurs d'itération des
instructions source et cible. Par conséquent, optimiser un segment de code
équivaut à appliquer des transformations affines à ces espaces d'itération pour
exposer le parallélisme ou améliorer la localité des données. De telles
transformations incluent la réorganisation d'instructions, le pavage de boucles,
le skewing, et la fusion ou fission de boucles.

Pour illustrer ces concepts tout au long de cette section, la
@fig:scientificbackground:scopexample présente un exemple simple d'un #gls(
  "scop",
) comprenant deux instructions, $S_1$ et $S_2$, imbriquées dans deux boucles
différentes sera utilisé comme exemple.

#figure(
  ```cpp
  for (int i = 0; i < N; i++)
    for (int j = 0; j < M; j++)
      C[i][j] = A[i][j] + B[i][j];      // Instruction S1

  for (int i = 1; i < N; i++)
    for (int j = 0; j < M; j++)
      C[i][j] = C[i][j] + C[i - 1][j];  // Instruction S2
  ```,
  caption: [Exemple d'un nid de boucles simple avec deux instructions.],
) <fig:scientificbackground:scopexample>

=== Polyèdre

#definition(
  title: "Polyèdre/Polytope Rationnel",
)[
  Un _polyèdre de dimension $d$_ rationnel $cal(P)$ est un sous-espace de
  $bb(Q)^d$ qui peut être défini par un système de $n in bb(N)^+$ inégalités
  affines :
  #math.equation(
    block: true,
    alt: "P est un ensemble de x dans les rationnels contraints par n inégalités",
    $
      cal(P) = { arrow(x) in bb(Q)^d | A dot.op arrow(x) + a >= arrow(0) }
    $,
  )
  où $A$ est une matrice d'entiers de taille $n times d$ et $a in bb(Z)^n$.
  Cette formulation est connue sous le nom de _représentation implicite_ d'un
  polyèdre.

  Étant donné qu'un polyèdre peut s'étendre indéfiniment dans certaines
  directions, un polyèdre convexe strictement borné est spécifiquement appelé un
  _polytope_.
]

Dans la grande majorité des applications du monde réel, les bornes des boucles
ne sont pas explicitement définies par des constantes statiques. Pour résoudre
ce problème, des paramètres symboliques sont introduits pour représenter les
bornes dynamiques et les tailles des données. Par conséquent, le modèle
polyédrique étend les polytopes standards en polytopes paramétriques.

#definition(
  title: "Polytope Paramétrique",
)[
  Un _polytope de dimension $d$_ paramétrique $cal(P)(arrow(p))$ est un polyèdre
  paramétrique borné défini par :
  $
    cal(P)(arrow(p)) = { arrow(x) in bb(Q)^d | A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0) }
  $
  où $arrow(p)$ est le _vecteur $p$_ symbolique des paramètres, et $A$ est une
  matrice d'entiers de taille $m times (d + p + 1)$ encodant les $m$
  contraintes. \
  Notez que ces contraintes peuvent exprimer à la fois des inégalités et des
  égalités. Par exemple, la paire d'inégalités $x_i >= 0$ et $-x_i >= 0$ est
  naturellement utilisée pour représenter l'égalité stricte $x_i = 0$.
]

=== Instruction

#definition(
  title: "Instance d'Instruction ou Statement",
)[
  Une _instance d'instruction_ est une exécution spécifique d'une instruction
  donnée $S$ lors d'une itération particulière de ses $k$ boucles englobantes.
  Chaque instance d'instruction est identifiée de manière unique par les valeurs
  des itérateurs de ses boucles englobantes au moment de l'exécution.
]

En reprenant la @fig:scientificbackground:scopexample, le #gls("scop") fourni
présente deux instructions distinctes imbriquées dans deux boucles. Dans ce
contexte, une instance de l'instruction $S_1$ se produit pour chaque combinaison
valide des itérateurs $i$ et $j$.


=== Domaine d'Itération

Une instruction est associée à un ensemble d'instances d'instruction bornées à
l'intérieur d'un polytope. Chaque instance individuelle est caractérisée de
manière unique par un vecteur composé des itérateurs de ses boucles englobantes.

#definition(
  title: "Vecteur d'Itération",
)[
  Un _vecteur d'itération_ $arrow(x)$ est un vecteur colonne de dimension $k$
  qui représente les valeurs des $k$ itérateurs de boucle caractérisant une
  exécution spécifique d'une instruction $S$. Il est défini comme :
  $
    arrow(x) = vec(x_1, x_2, ..., x_k)
  $
  où $x_i$ est l'indice de la boucle à la profondeur $i$, et $k$ est la
  profondeur totale des boucles englobant l'instruction.
]

L'ensemble exhaustif de tous les vecteurs d'itération pour lesquels une
instruction donnée est exécutée est appelé le domaine d'itération de cette
instruction.

#definition(
  title: "Domaine d'Itération",
)[
  Le domaine d'itération d'une instruction $S$ est l'ensemble de tous les
  vecteurs d'itération $arrow(x)$ possibles pour lesquels l'instruction $S$ est
  exécutée. Il peut être représenté comme un polyèdre convexe défini par un
  système d'inégalités affines. Cet ensemble peut être représenté par les points
  entiers d'un polytope paramétrique :
  $
    cal(D)_(S)(arrow(p)) = { arrow(x) in bb(Z)^k | A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0) }
  $
  où $arrow(p)$ est un vecteur de $N$ paramètres, $arrow(x)$ est un vecteur
  d'itération de dimension $k$, et $A$ est une matrice d'entiers de taille
  $m times (k times N + 1)$ qui encode les $m$ contraintes du polytope.
]

La @fig:scientificbackground:iterationdomain illustre le domaine d'itération de
l'instruction $S_1$ dérivé du #gls("scop") de la
@fig:scientificbackground:scopexample. Le domaine d'itération de $S_1$ est
représenté géométriquement comme un polyèdre convexe dans l'espace
bidimensionnel défini par les indices de boucle $i$ et $j$. Chaque point entier
à l'intérieur de ce polyèdre correspond à une instance unique de l'instruction,
tandis que les limites du polyèdre sont strictement déterminées par les bornes
des boucles et par toute instruction conditionnelle présente dans le code.


#figure(
  block(height: 5.5cm, align(bottom, fig.scientificbackground-scopexample)),
  caption: [Représentation géométrique du domaine d'itération pour l'instruction
    $S_1$.],
) <fig:scientificbackground:iterationdomain>


=== Dépendances de Données

Pour que le modèle polyédrique génère des transformations valides produisant
exactement les mêmes résultats que le code original, il doit respecter
strictement les dépendances de données initiales du programme. Les dépendances
de données agissent comme des contraintes qui restreignent l'ordre d'exécution
légal des instances d'instruction. Elles sont introduites lorsque plusieurs
instances d'instruction accèdent au même emplacement mémoire.

#definition(
  title: "Dépendance de Données",
)[
  Deux instances d'instruction $S_1(arrow(x)_1)$ et $S_2(arrow(x)_2)$ sont dites
  dépendantes si les deux instances accèdent exactement au même emplacement
  mémoire, qu'au moins l'un des accès est une opération d'écriture, et qu'une
  instance s'exécute avant l'autre dans l'ordre original du programme.
]

Il existe trois principaux types de dépendances de données qui restreignent le
réordonnancement des instructions :
- *Lecture-Après-Écriture :* Une instruction source écrit dans un emplacement
  mémoire qui est ensuite lu par une instruction cible.
- *Écriture-Après-Lecture :* Une instruction source lit un emplacement mémoire
  avant qu'il ne soit écrasé par une instruction cible.
- *Écriture-Après-Écriture :* Une instruction source écrit dans un emplacement
  mémoire qui est ensuite écrasé par une instruction cible.

Le modèle polyédrique représente géométriquement ces dépendances de données
comme des relations affines entre les vecteurs d'itération des instructions
source et cible.

#definition(
  title: "Relation de dépendance",
)[
  Les dépendances entre les instances d'une instruction source $S$ et d'une
  instruction cible $T$ peuvent être représentées comme des relations entre des
  vecteurs d'itération. Un couple de points entiers dans le polyèdre associé à
  la relation représente une dépendance entre les vecteurs d'itération source et
  cible correspondants. Cette relation peut être représentée par le polytope
  paramétrique suivant :
  $
    delta_(S,T)(arrow(p)) = {arrow(x)_S -> arrow(x)_T | R_(S,T) op(dot) vec(arrow(x)_S, arrow(x)_T, arrow(p), 1) >= arrow(0)}
  $
  où $R_(S,T)$ est une matrice d'entiers de taille $m times (k + l + N + 1)$,
  avec $m$ le nombre de contraintes, $k = "dim"(arrow(x)_S)$ la profondeur de
  l'instruction source, $l = "dim"(arrow(x)_T)$ la profondeur de l'instruction
  cible et $N = "dim"(arrow(p))$ le nombre de paramètres.
]

En reprenant l'exemple du @fig:scientificbackground:scopexample, nous pouvons
observer une dépendance RAW sur l'instruction $S_2$ à travers les itérations de
la boucle externe. Spécifiquement, l'instruction $S_2$ à l'itération $(i', j')$
lit la valeur `C[i' - 1][j']`, qui a été précédemment écrite par $S_2$ à
l'itération $(i, j)$ où $i = i' - 1$ et $j = j'$. Cette dépendance de flot
portée par la boucle peut être formellement exprimée en utilisant notre
représentation matricielle :

$
  delta_(S_2,S_2)(arrow(p)) & = { vec(i, j) -> vec(i', j') mid(|) i = i' - 1 "et" j = j' } \
  & = { vec(i, j) -> vec(i', j') mid(|)
    mat(
      1, 0, -1, 0, 0, 0, 1;
      0, 1, 0, -1, 0, 0, 0
    )
    dot.op vec(i, j, i', j', N, M, 1) = arrow(0) }
$


=== Ordonnancement

Un ordonnancement dicte l'ordre d'exécution chronologique des instances
d'instruction au sein de l'espace d'itération. Dans le modèle polyédrique, cet
ordonnancement est représenté comme une relation affine mappant le vecteur
d'itération d'une instruction vers un vecteur de date logique
multidimensionnelle.

#definition(
  title: "Relation d'Ordonnancement",
)[
  Étant donné une instruction $S$, une _relation d'ordonnancement_ $theta_S$
  détermine l'ordre d'exécution de ses instances. Pour ce faire, elle mappe
  chaque instance $arrow(x)$ d'une instruction $S$ vers un _temps d'exécution
  logique_ (ou _date logique_) $arrow(t)$ :
  $
    theta_S (arrow(p)) = { arrow(x) -> arrow(t) mid(|) T dot.op vec(arrow(x), arrow(t), arrow(p), 1) polyrelcst arrow(0)}
  $
  où $arrow(p)$ est un vecteur de $N$ paramètres, $arrow(x)$ est un vecteur
  d'itération de dimension $k$ de l'instruction $S$, $arrow(t)$ est un vecteur
  d'ordonnancement logique de dimension $d$, et $T$ est une matrice d'entiers de
  taille $m times (k + d + N + 1)$ qui encode les $m$ contraintes affines du
  polyèdre.
]

L'abstraction d'ordonnancement permet aux compilateurs de raisonner sur le temps
en utilisant des dates logiques multidimensionnelles plutôt que des ordres
d'exécution linéaires explicites. Pour comparer l'ordre d'exécution de deux
instances d'instruction sur la base de leurs dates logiques, le modèle s'appuie
sur l'ordre lexicographique.

#definition(
  title: "Ordre lexicographique",
)[
  Étant donné deux vecteurs d'itération $arrow(x)$ et $arrow(x)'$ de même
  dimension, l'ordre lexicographique $lexordersym$ est défini par :
  $
    vec(x_1, x_2, ..., x_n) lexordersym vec(x'_1, x'_2, ..., x'_n)
    & <==> exists k, 1 <= k <= n : (forall j : 1 <= j < k | x_j = x'_j) and x_k <= x'_k \
    & <==> cases(
      x_1 <= x'_1,
      "ou", x_1 = x'_1 and x_2 <= x'_2,
      "ou", ...,
      "ou", (forall i in bracket.l.stroked 1"," n bracket.l.stroked "," space x_i = x'_i) and x_n <= x'_n,
    )\
  $
]

En revenant à notre exemple @fig:scientificbackground:scopexample,
l'ordonnancement d'exécution original mappe le domaine d'itération 2D vers un
espace de temps logique 3D. La première dimension ($t_0$) encode l'ordre lexical
des instructions, tandis que les dimensions restantes encodent les itérateurs.
Les relations d'ordonnancement correspondantes sont :

$
  theta_(S_1)(arrow(p)) & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|) t_0 = 0 "et" t_1 = i "et" t_2 = j } \
  & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|)
    mat(
      0, 0, -1, 0, 0, 0, 0, 0;
      1, 0, 0, -1, 0, 0, 0, 0;
      0, 1, 0, 0, -1, 0, 0, 0
    )
    dot.op vec(i, j, t_0, t_1, t_2, N, M, 1) = arrow(0) }
$

$
  theta_(S_2)(arrow(p)) & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|) t_0 = 1 "et" t_1 = i "et" t_2 = j } \
  & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|)
    mat(
      0, 0, -1, 0, 0, 0, 0, 1;
      1, 0, 0, -1, 0, 0, 0, 0;
      0, 1, 0, 0, -1, 0, 0, 0
    )
    dot.op vec(i, j, t_0, t_1, t_2, N, M, 1) = arrow(0) }
$

En transformant le domaine spatial 2D en un domaine temporel 3D,
l'ordonnancement isole l'ordre d'exécution. Ici, $S_1$ est toujours exécutée
avant $S_2$ à toute itération donnée car sa dimension temporelle externe est
statiquement plus petite ($t_0 = 0$ pour $S_1$, tandis que $t_0 = 1$ pour
$S_2$). Au sein de leurs blocs respectifs, les deux instructions sont exécutées
séquentiellement en suivant le vecteur d'itération original $(i, j)$ puisque
$t_1$ et $t_2$ reflètent exactement les itérateurs de la boucle.



== L'Écosystème Polyédrique <sec:scientificbackground:polyhedralecosystem>

Bien que les abstractions mathématiques du modèle polyédrique offrent un cadre
de travail puissant pour l'optimisation des boucles, l'application automatique
de ces transformations à des programmes du monde réel nécessite des
infrastructures logicielles robustes. Au cours des dernières décennies, la
communauté de la compilation a développé un écosystème riche pour manipuler les
représentations polyédriques, analyser les dépendances et générer du code
optimisé.

Cette section explore les composants principaux de cet écosystème, en les
catégorisant en outils polyédriques et en compilateurs.

=== Outils Polyédriques

L'application du modèle polyédrique repose fortement sur des bibliothèques
mathématiques capables de résoudre des systèmes complexes d'inégalités affines.

==== Integer Set Library (isl) <sec:scientificbackground:isl>

Pour manipuler les polyèdres, la #gls("isl"), développée par Sven
Verdoolaege~@ISL, est largement utilisée dans la communauté polyédrique. isl est
une bibliothèque C conçue pour manipuler des ensembles et des relations de
points entiers bornés par des contraintes affines.

- *Sets :* Utilisés pour représenter les domaines d'itération.
- *Maps :* Utilisées pour représenter les fonctions d'accès, les dépendances et
  les ordonnancements en mappant les éléments d'un ensemble vers un autre.

#gls("isl") fournit des implémentations hautement optimisées pour les opérations
polyédriques essentielles, y compris l'intersection, l'union, la différence
d'ensembles et le calcul de minimums ou maximums lexicographiques.

Au-delà des opérations d'ensembles basiques, l'une des fonctionnalités d'isl est
son *moteur d'ordonnancement* intégré. Basé sur une variante de l'algorithme
Pluto~@pluto1, isl peut calculer automatiquement des ordonnancements affines qui
respectent toutes les dépendances de données tout en maximisant conjointement la
localité des données et en exposant le parallélisme.

Enfin, une fois que l'ordonnancement optimal a été calculé, isl dispose d'un
générateur d'AST (Abstract Syntax Tree). Ce composant traduit la représentation
polyédrique transformée en une structure classique de nid de boucles. Parce
qu'elle encapsule la totalité de la chaîne de compilation mathématique, isl sert
de moteur fondamental derrière la quasi-totalité des compilateurs polyédriques
modernes. La @fig:scientificbackground:isl_syntax_example illustre comment un
nid de boucles C standard est modélisé mathématiquement à l'aide de la syntaxe
des ensembles et des maps d'#gls("isl").


#subpar.super(
  grid(
    columns: 1,
    rows: 2,
    inset: 0.5cm,
    [
      #figure(
        ```C
        for (int i = 0; i < N; i++)
          for (int j = 0; j < M; j++)
            A[i][j] = B[i] + C[j]; // S1
        ```,
        caption: [Code source en entrée],
      )
    ],
    [
      #figure(
        ```text
        // Domaine de l'ensemble d'itération
        [N, M] -> { S1[i, j] : 0 <= i < N and 0 <= j < M }

        // Ordonnancement d'exécution (Map)
        [N, M] -> { S1[i, j] -> [i, j] }

        // Accès mémoire (Maps)
        [N, M] -> { S1[i, j] -> A[i, j] } // Écriture
        [N, M] -> { S1[i, j] -> B[i] }    // Lecture
        [N, M] -> { S1[i, j] -> C[j] }    // Lecture
        ```,
        caption: [Représentation isl du domaine d'itération, de l'ordonnancement
          et des fonctions d'accès pour le code donné en exemple.],
      )
    ],
  ),
  caption: [Exemple d'un nid de boucles simple et de sa représentation isl
    correspondante.],
  label: <fig:scientificbackground:isl_syntax_example>,
)

==== Représentation Standardisée OpenScop

OpenScop~@openscop est une spécification ouverte conçue pour garantir
l'interopérabilité en permettant à différents outils polyédriques d'échanger une
représentation standardisée d'un #gls("scop"). Elle modélise les systèmes
mathématiques d'inégalités affines (domaines, fonctions d'accès et
ordonnancements) à l'aide d'un format matriciel structuré, où les colonnes
correspondent aux itérateurs de boucles, aux paramètres globaux et aux termes
constants, et où les lignes représentent les contraintes affines. Le
@code:scientificbackground:openscopexample_source montre un nid de boucles
simple, tandis que sa représentation OpenScop correspondante est détaillée dans
le @code:scientificbackground:openscopexample_representation.


#subpar.super(
  grid(
    columns: 1,
    rows: 2,
    inset: 0.5cm,
    [
      #figure(
        ```C
        for (int i = 0; i < N; i++)
          for (int j = 0; j < M; j++)
            A[i][j] = 0;               // Instruction S1
        ```,
        caption: [Code source en entrée],
      ) <code:scientificbackground:openscopexample_source>
    ],
    [
      #figure(
        ```openscop
        <OpenScop>
        ...
        DOMAIN
        6 6 2 0 0 2
        # e/i|  i    j |  N    M |  1
           1    1    0    0    0    0    ## i >= 0
           1   -1    0    1    0   -1    ## -i+N-1 >= 0
           1    0    0    1    0   -1    ## N-1 >= 0
           1    0    1    0    0    0    ## j >= 0
           1    0   -1    0    1   -1    ## -j+M-1 >= 0
           1    0    0    0    1   -1    ## M-1 >= 0
        # ----------------------------------------------  1.2 Scattering
        SCATTERING
        5 11 5 2 0 2
        # e/i| c1   c2   c3   c4   c5 |  i    j |  N    M |  1
           0   -1    0    0    0    0    0    0    0    0    0    ## c1 == 0
           0    0   -1    0    0    0    1    0    0    0    0    ## c2 == i
           0    0    0   -1    0    0    0    0    0    0    0    ## c3 == 0
           0    0    0    0   -1    0    0    1    0    0    0    ## c4 == j
           0    0    0    0    0   -1    0    0    0    0    0    ## c5 == 0
        # ----------------------------------------------  1.3 Access
        WRITE
        3 9 3 2 0 2
        # e/i| Arr  [1]  [2]|  i    j |  N    M |  1
           0   -1    0    0    0    0    0    0    5    ## Arr == A
           0    0   -1    0    1    0    0    0    0    ## [1] == i
           0    0    0   -1    0    1    0    0    0    ## [2] == j
        ...
        </OpenScop>
        ```,
        caption: [Représentation OpenScop du domaine d'itération, de
          l'ordonnancement (scattering) et des fonctions d'accès pour le code
          donné en exemple.],
      ) <code:scientificbackground:openscopexample_representation>
    ],
  ),
  caption: [Exemple d'un nid de boucles simple et de sa représentation OpenScop
    correspondante.],
  label: <fig:scientificbackground:openscop>,
)

Pour faciliter l'intégration, elle est accompagnée de l'#gls("osl"), une API C
utilisée pour générer, lire et manipuler facilement cette représentation. De
plus, l'architecture extensible d'OpenScop prend en charge diverses extensions
spécifiques aux outils, permettant aux compilateurs d'intégrer des métadonnées
personnalisées sans rompre la compatibilité.


=== Compilateurs Polyédriques

La communauté de recherche a développé divers compilateurs pour automatiser les
optimisations de boucles. Bien qu'ils partagent tous la même base théorique, ils
ciblent différents niveaux de la pile de compilation et diverses architectures
matérielles. Parmi les frameworks polyédriques les plus notables, on trouve :

- *Pluto~@pluto1* : Un compilateur C source-à-source renommé pour son algorithme
  d'ordonnancement, qui calcule automatiquement les transformations affines pour
  maximiser simultanément la localité des données et exposer le parallélisme sur
  les CPU multicoeurs.
- *PPCG (Polyhedral Parallel Code Generator)~@ppcg :* Un compilateur
  source-à-source conçu spécifiquement pour les architectures hétérogènes,
  transformant les nids de boucles C séquentiels en code CUDA ou OpenCL optimisé
  pour l'exécution sur GPU.
- *Apollo (Automatic speculative POLyhedral Loop Optimizer)~@apollo :* Un
  framework qui étend le modèle statique traditionnel en appliquant des
  transformations dynamiquement à l'exécution (runtime), permettant
  l'optimisation des nids de boucles avec des accès mémoire non résolus
  statiquement ou un flux de contrôle dépendant des données.
- *Polygeist~@Polygeist :* Un frontend C/C++ moderne et un framework
  d'optimisation construit au-dessus de MLIR (Multi-Level Intermediate
  Representation), qui exploite le dialecte affine pour effectuer des
  transformations polyédriques au sein d'une chaîne de compilation LLVM.
- *LLVM Polly~@polly1 :* Un optimiseur de boucles intégré dans l'infrastructure
  du compilateur LLVM qui opère directement sur l'#gls("ir"), s'abstrayant du
  langage source pour effectuer des optimisations avancées.

Bien que chacun de ces outils optimise avec succès les performances des codes
transformés, les travaux présentés dans cette thèse s'appuient principalement
sur l'infrastructure LLVM, en utilisant Polly pour intercepter et optimiser les
codes Kokkos. Par conséquent, la section suivante propose une plongée
approfondie dans l'architecture et la chaîne de compilation de LLVM Polly.



== Plongée au Coeur de LLVM Polly <sec:scientificbackground:polly>

Polly~@polly2 est un framework d'analyse et d'optimisation polyédrique de
boucles de bas niveau, intégré dans l'optimiseur middle-end de LLVM. Il peut
être invoqué nativement via le frontend du compilateur Clang (en utilisant des
arguments de ligne de commande comme `-O3 -mllvm -polly`). Un avantage
stratégique clé de Polly est sa dépendance à l'#gls("ir") de LLVM. En opérant
strictement au niveau de l'#gls("ir"), Polly est complètement découplé du
langage source du frontend, lui permettant d'optimiser les boucles
indépendamment du code source original.

Cette architecture basée sur l'#gls("ir") est particulièrement avantageuse lors
du ciblage de frameworks parallèles modernes de haut niveau tels que Kokkos.
Kokkos s'appuie fortement sur des fonctionnalités C++ avancées, incluant la
métaprogrammation par templates, les fonctions lambda et les abstractions
d'objets complexes, qui sont impossible à analyser et à parser pour les
compilateurs polyédriques source-à-source traditionnels. En se positionnant dans
le middle-end, Polly n'intercepte le code qu'une fois que le frontend Clang a
complètement instancié les templates, résolu les abstractions de haut niveau et
effectué un inlining agressif des fonctions. Par conséquent, Polly opère sur une
représentation "nettoyée" et canonicalisée où les nids de boucles
multidimensionnels et les accès mémoire sont explicitement exposés, contournant
entièrement la complexité syntaxique du code source C++ original.

=== Architecture et Intégration dans la Chaîne de Compilation

Au sein de l'infrastructure du compilateur LLVM, les optimisations sont
appliquées comme une séquence de passes orchestrées par le gestionnaire de
passes. Polly s'intègre nativement dans cette chaîne de compilation middle-end,
et son point exact d'exécution peut être contrôlé via l'argument de ligne de
commande `-polly-position`.

Par défaut et utilisé lors de tous les travaux expérimentaux présentés dans
cette thèse, Polly est planifié à la position `before-vectorizer`. Ce placement
spécifique est hautement stratégique. Avant même que Polly n'inspecte le code,
l'#gls("ir") a déjà été fortement optimisée et canonicalisée par les passes
standards de LLVM. Des passes telles que `mem2reg` (qui promeut les allocations
mémoire en registres SSA), `simplifycfg` (qui nettoie le graphe de flot de
contrôle) et un inlining agressif des fonctions ont déjà supprimé le surcoût lié
à l'abstraction C++ de haut niveau. Par conséquent, Polly opère sur des
structures de boucles propres et normalisées et fournit sa sortie hautement
optimisée et parallélisable directement au vectoriseur natif de LLVM.

#figure(
  image(fig.scientificbackground-pollypipeline),
  caption: [Intégration des passes de Polly au sein de la chaîne d'optimisation
    middle-end de LLVM à la position `before-vectorizer`. (Source : #link(
      "https://polly.llvm.org/docs/Architecture.html",
    )[Documentation de LLVM Polly])],
) <fig:scientificbackground:pollypipeline>

Une fois invoqué, Polly exécute sa propre chaîne de compilation interne
spécialisée. Ce système présente le flux de travail polyédrique en une séquence
stricte de passes LLVM séquentielles, comme illustré dans la
@fig:scientificbackground:pollypipeline :

- *`CodePreparation` :* Prépare l'#gls("ir") en scindant le bloc d'entrée afin
  d'isoler les allocations mémoires locales (`alloca`) des opérations
  arithmétiques et des accès aux données, préparant ainsi le code à l'analyse et
  à la future génération de code.
- *`ScopDetect` :* Analyse le graphe de flot de contrôle pour identifier les
  régions valides à Entrée Unique et Sortie Unique (Single-Entry Single-Exit,
  SESE) qui sont appropriées pour la représentation polyédrique dans Polly.
- *`ScopInfo` :* Extrait les instructions de l'#gls("ir") des régions valides et
  les traduit en représentations mathématiques #gls("isl") (domaines, accès,
  dépendances de données, et ordonnancement original).
- *`ScheduleOptimizer` :* Invoque le moteur d'ordonnancement intégré d'isl pour
  calculer des transformations affines optimales qui maximisent la localité des
  données et exposent le parallélisme.
- *`IslAst` :* Génère un nouvel #gls("ast") #gls("isl") représentant la
  structure du nid de boucles ordonnancé de manière optimale.
- *`CodeGeneration` :* Parcourt l'#gls("ast") #gls("isl") pour construire
  l'#gls("ir") LLVM finale et optimisée, en y intégrant des vérifications à
  l'exécution (runtime checks) pour l'aliasing et les limites de tableaux
  lorsque cela est nécessaire.

Les mécanismes détaillés de chacune de ces passes internes sont explorés dans
les sous-sections suivantes.

==== Préparation du Code (`Code Preparation`)

Avant d'identifier les régions polyédriques, Polly exécute une étape
préparatoire via la passe `CodePreparation`. Dans son fonctionnement natif, son
rôle est de scinder le bloc d'entrée de la fonction afin d'isoler les
allocations mémoires locales (`alloca`) des opérations arithmétiques et d'accès
aux données. Cette séparation structurelle évite que les instructions
d'allocation de pile ne polluent les blocs de calcul et réserve l'espace
nécessaire à l'insertion de nouvelles allocations lors de la phase de
regénération du code.

==== Détection des SCoPs (`SCoP Detection`)

À la suite des transformations préparatoires, la passe `ScopDetect` est chargée
d'identifier les segments de l'#gls("ir") de LLVM qui peuvent être légalement
optimisés en utilisant le modèle polyédrique. Polly opère sur le graphe de flot
de contrôle (CFG) pour isoler les régions SESE maximales.

Pour qu'une région SESE soit validée comme un SCoP, Polly applique des critères
d'acceptation stricts. Il s'appuie fortement sur l'analyse d'évolution scalaire
(Scalar Evolution, SCEV) de LLVM pour inspecter les variables d'induction des
boucles, les bornes et les branchements conditionnels. La région n'est acceptée
que si `ScopDetect` peut prouver de manière formelle que toutes les bornes des
boucles et les conditions de flot de contrôle sont purement des expressions
affines.

Cette passe effectue une vérification rigoureuse de la légalité et de la
sécurité. La région SESE est immédiatement rejetée si elle contient des
instructions avec des effets de bord inconnus (comme des appels de fonctions
externes ou non inlinés), des indices de tableaux non affines, ou un aliasing de
pointeurs complexe qui ne peut pas être résolu statiquement.

==== Construction des SCoPs (`SCoP Building`)

Une fois qu'une région SESE valide est détectée avec succès, la passe `ScopInfo`
est exécutée pour traduire l'#gls("ir") de LLVM vers les abstractions
mathématiques du modèle polyédrique. Ce processus implique de mapper les
structures de code en objets #gls("isl").

Pour chaque bloc de base au sein de la région, `ScopInfo` définit une
instruction mathématique. Ensuite, il construit le *domaine d'itération* exact
en traduisant les contraintes affines des boucles englobantes obtenu la passe
SCEV en structure isl. De même, les instructions mémoire (telles que `load` et
`store`) sont converties en relations d'accès isl, mappant l'exécution logique
d'une instruction à des adresses mémoire spécifiques.

Cette phase extrait également l'ordonnancement original du programme non modifié
et effectue une analyse des dépendances de données. À la fin de cette passe,
Polly a construit une représentation mathématique complète du nid de boucles,
entièrement détachée de l'#gls("ir") de LLVM, prête à être optimisée par le
moteur polyédrique.

Toutefois, pour garantir la validité de cette représentation et capturer des
dépendances de données exactes, Polly doit préalablement reconstruire la
structure originelle des accès mémoire : c'est l'étape de délinéarisation.

===== Délinéarisation des accès mémoire <sec:scientificbackground:delinearization>

L'un des défis majeurs lors de l'extraction des SCoPs réside dans la traduction
des instructions mémoire de bas niveau de l'#gls("ir") de LLVM vers des
structures de tableaux multidimensionnels. Ce processus, appelé délinéarisation,
est absolument nécessaire pour pouvoir exprimer des fonctions d'accès affines et
effectuer les transformations polyédriques associées.

En effet, lors de la génération de l'#gls("ir"), les accès aux tableaux
multidimensionnels sont linéarisés en une arithmétique de pointeurs
unidimensionnelle. Le @code:scientificbackground:delinearization montre un
exemple où l'accès au tableau tridimensionnel `A[i][j][k]` est compilé avec un
décalage mémoire calculé par l'expression mathématique
$i times M times P + j times P + k$.

#figure(
  ```cpp
  void init(int N, int M, int P, double A[N][M][P]) {
      for (int i = 0; i < N; i++)
          for (int j = 0; j < M; j++)
              for (int k = 0; k < P; k++)
                  A[i][j][k] = 0.0;
  }
  ```,
  caption: [Exemple de code source en C avec un accès multidimensionnel 3D.],
) <code:scientificbackground:delinearization>

Si les tailles des dimensions $M$ et $P$ sont dynamiques, cette expression
$i times M times P + j times P + k$ devient non-affine car elle implique la
multiplication de variables d'induction par des paramètres, ce qui briserait les
conditions de validité du modèle polyédrique.

Pour pallier ce problème, Polly s'appuie sur un algorithme, détaillé dans
@Delinearization, qui se base sur l'analyse d'évolution scalaire (SCEV).
L'algorithme analyse l'expression de l'adresse mémoire calculée et factorise les
pas d'accès. Dans notre exemple, il observe que l'adresse avance d'un pas de
$M times P times 8$ à chaque itération de la boucle externe $i$, d'un pas de
$P times 8$ pour la boucle intermédiaire $j$, et d'un pas de $8$ pour la boucle
interne $k$ ($8$ correspondant à la taille en octets d'un type `double`).

#figure(
  ```llvm
  {{{ %A, +, (8*%m*%p)}<%for.i>, +, (8*%p)}<%for.j>, +, 8}<%for.k>
  ```,
  caption: [Représentation de l'évolution scalaire de l'adresse mémoire de
    `A[i][j][k]` issue de la @code:scientificbackground:delinearization],
)<code:scientificbackground:delinearization_scev>

Comme l'illustre la @code:scientificbackground:delinearization_scev, cette
représentation compacte met en évidence les pas d'accès associés à chaque
boucle. Pour reconstruire les accès multidimensionnels, l'algorithme de
délinéarisation procède à des opérations successives de division euclidienne sur
le polynôme de l'adresse mémoire. Ces divisions utilisent les tailles
identifiées pour chaque dimension (appelées _terms_), en remontant de la
dimension la plus interne vers la plus externe. Dans notre exemple, les _terms_
successifs extraits sont $8$, $P$, et $M$.

Soit $S$ l'expression de l'adresse mémoire linéarisée, qui correspond au
polynôme capturé par la SCEV :

$
  S(i,j,k) & = i times M times P times 8 + j times P times 8 + k times 8
$

La séparation des dimensions s'effectue alors étape par étape :

*Itération 1 (Extraction de la taille de l'élément, Term $8$) :* \
La première étape consiste à extraire la taille du type de donnée en divisant le
polynôme global par $8$ :
- Quotient :
  $Q_1 = floor(S / 8) = floor((i times M times P times 8 + j times P times 8 + k times 8) / 8) = i times M times P + j times P + k$

*Itération 2 (Dimension interne $k$, Term $P$) :* \
Le nouveau polynôme $Q_1$ est ensuite divisé par la dimension suivante ($P$)
pour en déduire l'indice le plus interne ($k$) :
- Indice :
  $"Index"_0 = Q_1 mod P = (i times M times P + j times P + k) mod P = k$
- Quotient :
  $Q_2 = floor(Q_1 / P) = floor((i times M times P + j times P + k) / P) = i times M + j$

*Itération 3 (Dimension intermédiaire $j$, Term $M$) :* \
Enfin, on divise le quotient restant $Q_2$ par la dernière dimension ($M$) pour
isoler les indices restants :
- Indice : $"Index"_1 = Q_2 mod M = (i times M + j) mod M = j$
- Quotient (Dimension externe $i$) :
  $"Index"_2 = floor(Q_2 / M) = floor((i times M + j) / M) = i$

Grâce à cette méthode itérative détaillée, Polly réussit à séparer les tailles
des différentes dimensions et à extraire les indices d'accès multidimensionnels
affines ($i$, $j$, $k$). Cette étape de reconstruction est primordiale car elle
restaure les accès multidimensionnels affines des tableaux indispensable pour le
modèle polyédrique.


==== Optimisation des SCoPs (`SCoP Optimization`)

Avec la représentation mathématique entièrement construite, la passe
`ScheduleOptimizer` délègue la charge principale de l'optimisation au moteur
d'ordonnancement intégré d'ISL. L'objectif premier du solveur est de calculer un
nouvel ordonnancement qui redéfinit l'ordre d'exécution des instances
d'instructions. Le planificateur recherche des transformations qui minimisent la
distance de réutilisation des accès mémoire et exposent le parallélisme.Le
moteur garantit mathématiquement l'équivalence sémantique du programme : tout
ordonnancement calculé doit strictement respecter les dépendances de données
exactes au niveau de l'instance extraites lors de la phase précédente.

La sortie de cette passe est un arbre d'ordonnancement optimisé. En isolant les
dimensions de boucles qui sont complètement dépourvues de dépendances cycliques
portées par la boucle, le solveur prouve mathématiquement l'absence de
concurence de données. Ce parallélisme exposé guide directement les phases
ultérieures de génération de l'#gls("ast") et d'émission du code pour appliquer
en toute sécurité la vectorisation ou le multithreading.

=== Génération de l'AST (`IslAst`)

En prenant l'arbre d'ordonnancement nouvellement optimisé comme entrée, la passe
`IslAst` génère un #gls("ast") qui représente logiquement la structure du nid de
boucles transformé. À ce stade, la passe analyse en profondeur les propriétés
mathématiques du nouvel ordonnancement pour intégrer des directives d'exécution
dans les noeuds de l'#gls("ast").

Spécifiquement, si le solveur #gls("isl") a prouvé mathématiquement que
certaines dimensions de boucles sont complètement dépourvues de dépendances
portées par la boucle, les noeuds correspondants de l'#gls("ast") sont
explicitement annotés comme étant parallèles. De même, les boucles internes sont
annotées comme vectorisables. Ces annotations sémantiques sont fondamentales,
car elles servent de directives pour guider la phase de génération de code,
permettant d'activer le multithreading et les instructions SIMD.

==== Génération de Code (`Code Generation`)

La passe `CodeGeneration` est chargée de reconstruire l'#gls("ir") LLVM finale
et optimisée à partir du nouvel #gls("ast") #gls("isl") généré. En parcourant
les noeuds de l'#gls("ast"), cette passe utilise l'`IRBuilder` de LLVM pour
construire les structures de boucles correspondantes et le #gls("cfg"). Si les
noeuds de l'#gls("ast") parcourus portent les annotations parallèles ou
vectorielles intégrées lors de la phase précédente, le générateur de code les
traduit en appels appropriés de la bibliothèque d'exécution OpenMP ou en
directives SIMD.

Plutôt que de générer les instructions de calcul à partir de zéro, le générateur
réutilise intelligemment le code d'origine. Il copie les anciennes instructions
de l'#gls("ir") de LLVM, en tant qu'opérations mathématiques et logique de
traitement de données sauvegardées lors de la passe `ScopInfo`, et les injecte
dans les corps des nouvelles boucles construites. Pendant ce processus de copie,
les instructions mémoire (`load` et `store`) sont mises à jour. Les indices de
leurs tableaux et l'arithmétique des pointeurs sont réécrits avec les nouvelles
fonctions d'accès affines et les nouvelles variables d'induction de boucle.

Enfin, pour garantir une correction sémantique absolue, Polly emploie un
mécanisme de versioning de boucle. Étant donné que l'analyse statique ne peut
pas toujours prouver définitivement l'absence d'aliasing de pointeurs ou d'accès
hors limites à la compilation, le générateur de code constuit si nécessaire un
bloc de vérifications de sécurité à l'exécution. Le nid de boucles original et
non modifié est préservé dans l'#gls("ir") en tant que chemin de secours. À
l'exécution, si ces vérifications de sécurité échouent, l'exécution bifurque
dynamiquement vers le code original, s'assurant que les transformations
polyédriques ne compromettent jamais la validité du programme.

=== Limites de Polly

Bien que LLVM Polly fournisse un mécanisme pour l'optimisation des boucles, son
choix architectural d'opérer exclusivement au niveau de l'#gls("ir") introduit
plusieurs limites inhérentes. Ces défis sont particulièrement marqués lors de
l'analyse de code C++ fortement abstrait comme Kokkos.

- *Le Fossé Sémantique et la Reconstruction de l'Information :* Opérer sur
  l'#gls("ir") de LLVM signifie que toutes les constructions du langage de haut
  niveau ont été abaissées et aplanies. Pour appliquer le modèle polyédrique,
  Polly doit reconstituer artificiellement la structure originale du programme à
  partir d'instructions de bas niveau. Cela implique la récupération des
  structures de tableaux multidimensionnels, la reconstruction des hiérarchies
  de boucles, et le regroupement logique des instructions en déclarations
  mathématiques. Si le code C++ original s'appuie sur des abstractions
  complexes, ce processus de reconstruction devient hautement fragile,
  provoquant l'échec de Polly à reconnaître des SCoPs valides.
- *Manque de Prise en Charge des GPU :* Polly est conçu pour optimiser la
  localité des données et le parallélisme pour les CPU multicoeurs (via OpenMP
  et la vectorisation SIMD). Bien que des extensions expérimentales comme
  Polly-ACC~@pollyacc aient été historiquement développées pour générer du code
  GPU, elles ne sont plus activement maintenues dans les versions récentes du
  framework LLVM. Par conséquent, Polly manque nativement de la capacité robuste
  à générer du code GPU optimisé pour les architectures hétérogènes modernes.

Ces deux limites, structurelle et matérielle, mettent en évidence
l'incompatibilité entre l'approche descendante classique de Polly et les
exigences des frameworks de portabilité de performance :

D'une part, le choix d'opérer exclusivement au niveau d'une représentation
intermédiaire de bas niveau crée un fossé sémantique majeur face aux
abstractions C++ modernes.

D'autre part, le fait que la génération de code de Polly soit nativement
restreinte aux seuls processeurs multicoeurs (via OpenMP) entre en contradiction
directe avec le modèle d'exécution de Kokkos, conçu pour cibler des
architectures hétérogènes et exploiter les accélérateurs matériels (GPU).

Ainsi, bien que le modèle polyédrique offre des garanties formelles puissantes
pour optimiser la localité et paralléliser les boucles, son utilisation directe
se heurte à une double impasse : une incapacité à percevoir la structure des
calculs issus de Kokkos au niveau de l'IR, et une incapacité à générer du code
pour les accélérateurs hétérogènes ciblés. Surmonter ce double verrou en
conciliant l'expressivité de Kokkos avec les capacités d'optimisation de Polly
constitue le coeur de cette thèse. Le @sec:stateoftheart dresse un panorama des
solutions proposées dans la littérature pour rapprocher ces deux mondes, avant
de détailler notre approche de co-design dans les chapitres suivants.
