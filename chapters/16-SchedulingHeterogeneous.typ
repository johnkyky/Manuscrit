#import "../src/common.typ": *

= Ordonnancement et Génération Hétérogène <sec:schedulingheterogeneous>

L'extraction de la représentation polyédrique et la génération de code optimisé
constituent deux phases fondamentales du flot de compilation polyédrique. Dans
son fonctionnement par défaut, Polly orchestre ces étapes en s'appuyant sur
l'ordonnanceur de la bibliothèque ISL
(@sec:scientificbackground:scopoptimization) avant la reconstruction de la
représentation intermédiaire LLVM optimisée (@sec:scientificbackground:islast,
@sec:scientificbackground:codegen).

Cependant, cette infrastructure standard présente des limitations vis-à-vis des
objectifs de notre chaîne de compilation, tant en matière de support matériel
que de diversité des optimisations. D'une part, l'abstraction de programmation
Kokkos tire une part essentielle de ses performances de son exécution sur
accélérateurs graphiques (GPU), tandis que le flot standard de Polly cible
exclusivement les processeurs multi-coeurs (CPU). D'autre part, Polly se limite
aux heuristiques d'un unique ordonnanceur, restreignant l'espace des
transformations de code explorées.

Afin de pallier ces limitations, nous avons étendu le compilateur en y intégrant
un nouveau moteur d'ordonnancement. Ce chapitre expose cette démarche visant à
diversifier les approches d'optimisation et les architectures cibles.
@sec:schedulingheterogeneous:pluto détaille l'intégration de Pluto pour étendre
les stratégies d'ordonnancement sur architectures CPU. Ensuite, la
@sec:schedulingheterogeneous:ppcg présente l'intégration de PPCG, un outil
permettant la génération de code pour accélérateurs matériels (GPU), répondant
ainsi aux exigences de portabilité des performances inhérentes à Kokkos.

== Intégration de Pluto <sec:schedulingheterogeneous:pluto>

Dans le modèle polyédrique, l'ordonnancement associe chaque instance
d'instruction à des dimensions temporelles et spatiales afin d'établir un ordre
d'exécution global. La détermination d'un ordonnancement optimal sous
contraintes étant un problème NP-complet, les compilateurs recourent
nécessairement à des heuristiques. L'ordonnanceur d'ISL, utilisé par défaut dans
Polly, est une évolution de l'approche de Pluto. Alors que l'algorithme
classique de Pluto opère globalement pour extraire des bandes de boucles
permutables favorisant intrinsèquement le tuilage et le parallélisme par front
d'onde, ISL adopte une approche incrémentale. Tout en cherchant également à
minimiser les distances de dépendance, ISL compose l'ordonnancement par
sous-graphes et intègre l'algorithme de Feautrier comme solution de repli.

De plus, Pluto supporte nativement des transformations géométriques avancées, à
l'instar du tuilage en losange (diamond tiling) @diamond, non réalisables
directement via ISL. Ces dernières permettent de maximiser la localité et
l'exécution concurrente, particulièrement au sein des schémas de calcul de type
stencil. Comme le souligne l'étude @surveypolyedric, Pluto démontre
régulièrement une capacité supérieure à extraire des opportunités de
parallélisation sur des codes aux accès réguliers. Son intégration constitue
ainsi une extension particulièrement pertinente pour notre flot de compilation.

Afin d'interfacer Pluto avec l'infrastructure de Polly, nous avons développé une
passerelle d'exportation et d'importation reposant sur le format *OpenSCoP*
@openscop. Ce choix de conception est motivé par deux raisons fondamentales.
Premièrement, Pluto étant conçu comme un compilateur source-à-source opérant sur
du code C, il est agnostique à la représentation intermédiaire de LLVM.
L'utilisation d'OpenSCoP permet de franchir cette barrière d'abstraction en
fournissant un format d'échange formel et standardisé. Secondement, cette
standardisation induit un découplage fort entre l'infrastructure interne de
Polly et le moteur d'ordonnancement externe. Une telle architecture garantit non
seulement une interopérabilité robuste avec Pluto, mais assure également
l'extensibilité du flot de compilation en vue de l'intégration future d'autres
ordonnanceurs polyédriques. En pratique, une fois le SCoP extrait de l'IR LLVM,
Polly sérialise ce dernier au format OpenSCoP et délègue l'étape
d'ordonnancement à Pluto. Ce dernier produit un nouvel ordonnancement optimisé
qui est réimporté dans Polly, se substituant à d'ordonnancement classiquement
généré par ISL.

=== Représentation OpenSCoP

Bien que Polly et Pluto modélisent tous deux les programmes selon le formalisme
polyédrique, leurs représentations internes en mémoire divergent
structurellement. La bibliothèque ISL, noyau mathématique de Polly, encode les
domaines d'itération et les fonctions d'ordonnancement sous forme d'ensembles et
de relations paramétrés, décrits par des formules algébriques. À l'inverse,
OpenSCoP repose sur une représentation matricielle de ces contraintes linéaires.

Afin de concevoir une passerelle fiable entre les structures ISL et le format
OpenSCoP, nous nous appuyons sur la bibliothèque `libopenscop`. Durant la phase
d'exportation, notre interface traverse récursivement les structures de données
d'ISL afin d'en extraire contraintes géométriques, reformulant ainsi un SCoP
sémantiquement équivalent sous la forme de matrices OpenSCoP.

À titre d'illustration, considérons le domaine d'itération et l'ordonnancement
canonique d'une boucle parfaitement imbriquée parcourant un espace
bidimensionnel. Au sein d'ISL, cette modélisation s'exprime selon une syntaxe
quasi-littérale, comme l'illustre la @fig:schedulingheterogeneous:isl_orig.

#figure(
  ```isl
  Domain: { Stmt[i, j] : 0 <= i < N and 0 <= j < N }
  Schedule: { Stmt[i, j] -> [i, j] }
  ```,
  caption: [Représentation ensembliste et relationnelle d'un domaine et de son
    ordonnancement sous ISL.],
) <fig:schedulingheterogeneous:isl_orig>

Lors de la conversion, cette représentation géométrique est abaissée sous forme
de matrices d'entiers, dont le résultat est détaillé dans la
@fig:schedulingheterogeneous:openscop_mat. Concernant le domaine d'itération,
chaque ligne de la matrice correspond à une contrainte affine. Les colonnes
décrivent successivement : le type de contrainte (1 pour une inégalité $\geq 0$,
0 pour une égalité), les coefficients associés aux variables d'itération
($i, j$), les coefficients rattachés aux paramètres globaux ($N$), et enfin la
constante de la fonction affine. L'ordonnancement fait l'objet d'une
transformation analogue, traduite au sein d'une matrice d'ordonnancement. Les
colonnes additionnelles y représentent les nouvelles dimensions temporelles ou
spatiales ($t_1, t_2$).

#figure(
  ```openscop
  <DOMAIN>
  4 5
  # e/i   i    j    N    1
    1     1    0    0    0    # i >= 0
    1    -1    0    1   -1    # N - i - 1 >= 0
    1     0    1    0    0    # j >= 0
    1     0   -1    1   -1    # N - j - 1 >= 0

  <SCATTERING>
  2 7
  # e/i  t1   t2    i    j    N    1
    0     1    0   -1    0    0    0    # t1 - i == 0
    0     0    1    0   -1    0    0    # t2 - j == 0
  ```,
  caption: [Traduction matricielle du domaine et de l'ordonnancement au format
    OpenSCoP.],
) <fig:schedulingheterogeneous:openscop_mat>

==== Conversion du tuilage

Un verrou technique majeur lors de la réimportation de l'ordonnancement optimisé
réside dans l'incompatibilité sémantique de la gestion des domaines d'itération
entre les deux outils à la suite du tuilage de boucles. En effet, pour exprimer
mathématiquement les tuiles, Pluto augmente explicitement la dimensionnalité du
domaine d'itération en y introduisant de nouvelles variables représentant les
tuiles. L'importation naïve de ces dimensions supplémentaires au sein de Polly
entraînerait une corruption de la représentation interne, ces itérateurs
fantômes n'ayant aucune correspondance dans la représentation intermédiaire LLVM
d'origine. À l'opposé de cette approche, le flot natif de Polly (basé sur les
arbres d'ordonnancement d'ISL) maintient une séparation stricte : le domaine
d'itération demeure invariant aux transformations. Les transformations telles
que le tuilage y sont encodées de manière purement relationnelle au sein de la
fonction d'ordonnancement. Les nouvelles dimensions sont instanciées localement
dans la structure arborescente, par l'intermédiaire de noeuds spécifiques de
type *band*.

Afin de résoudre cette incompatibilité structurelle, nous avons conçu une passe
de conversion intermédiaire destinée à combler ce fossé sémantique. L'algorithme
de conversion procède à une rétro-ingénierie de la fonction de dispersion de
Pluto afin d'isoler les dimensions relatives aux tuiles, pour ensuite les
réinjecter sous forme de variables locales au sein de la relation
d'ordonnancement d'ISL. Cette méthodologie permet de garantir l'immutabilité du
domaine d'itération originel, tout en préservant scrupuleusement l'ordre
d'exécution lexicographique défini par Pluto.

La séquence de figures suivante illustre les différentes étapes de cette
transformation géométrique pour un statement extrait de `syr2k`:
- La @fig:schedulingheterogeneous:polly_orig expose le domaine d'itération et
  l'ordonnancement identité extraits initialement par Polly.
- La @fig:schedulingheterogeneous:pluto_tiled détaille l'ordonnancement optimisé
  restitué par Pluto. On y observe l'altération du domaine d'itération par
  l'ajout explicite des dimensions de tuiles (variables `fk0`, `fk1`, `fk2`).
- La @fig:schedulingheterogeneous:polly_converted présente l'ordonnancement
  final après l'application de notre passe de conversion. Le domaine d'itération
  d'origine est rigoureusement restauré. Les contraintes algébriques définissant
  les tuiles (identifiées par les variables `o1`, `o2`, `o3`) sont désormais
  confinées à la relation d'ordonnancement.

#figure(
  ```isl
  Domaine original :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[i0, i1, i2] : i0 < p_1 and 0 <= i1 < p_0 and 0 <= i2 <= i0
  }

  Ordonnancement original :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[i0, i1, i2] -> [i0, 1, i1, i2]
  }
  ```,
  caption: [Domaine et ordonnancement originaux générés par Polly avant
    optimisation.],
) <fig:schedulingheterogeneous:polly_orig>

#figure(
  ```openscop
  Domaine Pluto :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[fk0, fk1, fk2, i0, i1, i2] :
      32fk0 <= i0 <= 31 + 32fk0 and
      i0 < p_1 and
      i1 >= 32fk2 and
      0 <= i1 <= 31 + 32fk2 and
      i1 < p_0 and
      i2 >= 32fk1 and
      0 <= i2 <= i0 and
      i2 <= 31 + 32fk1
  }

  Ordonnancement Pluto :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[fk0, fk1, fk2, i0, i1, i2] -> [1, fk0, fk1, fk2, i0, i2, i1]
  }
  ```,
  caption: [Représentation après optimisation par Pluto, avec ajout de
    dimensions de tuilage (`fk0`, `fk1`, `fk2`) dans le domaine.],
) <fig:schedulingheterogeneous:pluto_tiled>

#figure(
  ```isl
  Domaine final :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[i0, i1, i2] : i0 < p_1 and 0 <= i1 < p_0 and 0 <= i2 <= i0
  }

  Ordonnancement final :
  [p_0, p_1, p_2, p_3, p_4, p_5] -> {
    Stmt[i0, i1, i2] -> [1, o1, o2, o3, i0, i2, i1] :
      -31 + i0 <= 32o1 <= i0 and
      -31 + i2 <= 32o2 <= i2 and
      -31 + i1 <= 32o3 <= i1
  }
  ```,
  caption: [Ordonnancement converti pour Polly : le domaine initial est restauré
    et les contraintes de tuilage sont déléguées à la relation
    d'ordonnancement],
) <fig:schedulingheterogeneous:polly_converted>

== Intégration de PPCG et Réhabilitation de Polly-ACC <sec:schedulingheterogeneous:ppcg>

Le support de la génération de code pour accélérateurs matériels GPU constitue
un prérequis incontournable de nos travaux, initialement absent de notre flot de
compilation. En effet, une divergence fondamentale subsistait entre les modèles
d'exécution de Kokkos et les capacités de Polly en matière d'architectures
hétérogènes. Tandis que l'abstraction de Kokkos s'appuie structurellement sur
une compilation CPU/GPU visant la portabilité des performances, Polly s'est
historiquement restreint à l'optimisation pour architectures multi-coeurs CPU.
Or, un ordonnancement polyédrique taillé pour un processeur classique s'avère
profondément inadapté au modèle d'exécution massivement parallèle d'un GPU. Ce
dernier requiert une projection spatiale très contrainte des itérations sur une
hiérarchie matérielle stricte (grilles, blocs), doublée d'une gestion explicite
de la hiérarchie mémoire (mémoire globale, mémoire partagée, transferts
d'interface).

Afin de combler cette lacune architecturale sans avoir à concevoir un moteur de
génération de code GPU polyédrique, notre approche s'est portée sur la
réhabilitation du projet *Polly-ACC* @pollyacc. Ce framework exploitait
historiquement PPCG, un compilateur source-à-source polyédrique dédié à
l'optimisation et la génération de code pour accélérateurs. La délégation de
cette étape à PPCG, en substitution de la génération de code intrinsèque au
backend Kokkos, offre des perspectives d'optimisations supérieures. En effet, la
mécanique de Kokkos repose essentiellement sur un abaissement direct de
l'expression algorithmique écrite par l'utilisateur vers le modèle de
programmation cible (CUDA ou HIP), sans possibilité d'optimisation de la
structure de contrôle (pas de fusion de boucles ou d'échanges complexes). À
l'inverse, PPCG modélise le noyau de calcul et dérive algorithmiquement un
espace de transformations complexes. Il automatise notamment l'exploitation de
la mémoire partagée et la privatisation de registres, des mécanismes
indispensables pour masquer la latence d'accès mémoire et saturer la bande
passante sur GPU.

Cependant, le développement de Polly-ACC ayant été abandonné, le projet
souffrait d'un important retard de développement. En effet, l'évolution rapide
et continue des interfaces de programmation de LLVM et d'ISL avait rendu son
code source incompatible avec les versions modernes du compilateur.

Dans le cadre de cette thèse, un travail d'ingénierie conséquent a été mené pour
moderniser et réintégrer l'architecture conceptuelle de Polly-ACC au sein d'une
version récente de LLVM. L'un des principaux défis d'intégration inhérents à
PPCG réside dans sa conception originelle. Pensé comme un outil opérant
exclusivement sur du code source C, ses structures de représentation interne
fait pour gérer du code source ne prévoient nativement aucun mécanisme pour
sauvegarder la sémantique et les métadonnées requises par un IR bas niveau comme
celui de LLVM.

Pour surmonter ces obstacles structurels, une démarche minutieuse de
rétro-ingénierie a été entreprise : identifier, isoler puis transposer les
modifications effectuées à l'époque dans le PPCG historique de Polly-ACC vers la
base de code maintenue de PPCG. L'objectif étant de rétablir une chaîne de
compilation hétérogène complète, structurée selon trois axes principaux :

- *Adaptation de PPCG* : Enrichissement des structures de données de PPCG afin
  d'assurer la traçabilité des instructions de l'IR LLVM tout au long du
  processus, et mise en conformité avec les API récentes d'ISL.
- *Interface de communication Polly-PPCG* : Rétablissement des mécanismes
  permettant à Polly de déléguer l'analyse des SCoPs à PPCG. Cette interface
  permet à PPCG de produire un ordonnancement GPU, d'établir une stratégie de
  placement mémoire (promotion en mémoire partagée, privatisation) et de
  formuler la projection des itérations sur la topologie d'exécution du GPU
  (grilles et blocs).
- *Génération de code hybride* : Restauration des passes LLVM responsables de la
  synthèse du code final. Cette étape englobe à la fois le code exécuté sur
  l'hôte (orchestration des transferts mémoire et appels aux noyaux de calcul
  via l'API CUDA) et la génération du code PTX des noyaux spécifiques au
  périphérique matériel.

Dans l'architecture de notre pipeline, lorsqu'un noyau de calcul est identifié
(via les annotations du backend Kokkos) comme ciblant une architecture
matérielle GPU, le pipeline classique de Polly est dynamiquement reconfiguré.
Cette bifurcation intervient lors des phases de transformation et de synthèse de
code. Les passes classiques s'appuyant sur l'ordonnanceur natif ISL et le
générateur de code CPU sont désactivées. Le code est redirigé vers PPCG pour le
calcul de l'ordonnancement et la génération du code GPU.

Cette implémentation logicielle comble l'écart structurel entre le compilateur
et le modèle de programmation, dotant à nouveau Polly de la capacité de générer
du code pour les architectures hétérogènes. Le rétablissement de ce pipeline GPU
polyédrique dans Polly est indispensable pour permettre l'optimisation
performante de toutes les applications écrites en Kokkos compatibles avec le
modèle polyédrique.
