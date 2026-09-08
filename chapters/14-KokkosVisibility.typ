#import "../src/common.typ": *


= Making Kokkos Kernels Visible <chapter:kokkosvisibility>

In this chapter, we present the core contribution of this thesis: a hybrid compilation toolchain that bridges the gap between high-level performance portability frameworks and low-level polyhedral optimizers grace a l'outil de LLVM Polly. We detail the end-to-end implementation of our solution. First, we present... Then, we explain... Finally, we describe...
Le chapitre @chapter:evaluations présente les résultats obtenus avec à cette approche.

== Motivations

Comme conclu dans l'état de l'art, le C++ moderne utilisé par Kokkos (lambdas, foncteurs, arithmétique de pointeurs internes) crée un fossé sémantique massif entre le code source et la représentation intermédiaire (IR) de LLVM. Lorsque le code Kokkos est abaissé au niveau de l'IR, où opèrent des outils d'analyse et d'optimisation comme Polly, la structure originale simple des nids de boucles multidimensionnels est écrasée au profit de structures complexes nécessaires au fonctionnement de Kokkos. Le compilateur ne perçoit alors que des pointeurs représentant les bornes de boucles et des accès mémoire via des pointeurs unidimensionnels complexes. Craignant des problèmes d'aliasing, il se retrouve dans l'incapacité de réaliser une analyse polyédrique de manière automatique.

L'objectif de ce travail est donc d'offrir aux développeurs Kokkos l'accès aux optimisations polyédriques avancées (telles que la fusion de boucles, le *loop skewing* ou le *tiling* automatique) sur du code Kokkos, sans pour autant briser ses promesses de performance et de portabilité. Le développeur doit pouvoir continuer à écrire ses noyaux de calcul de manière agnostique à l'architecture (un seul code source) avec une intervention minimale, par exemple en ajoutant des paramètres pour activer l'optimisation.

Pour atteindre cet objectif, nous proposons une stratégie de co-design entre le framework et le compilateur (@fig:polykokkos_pipeline). Puisque le compilateur (Polly) ne peut pas deviner l'intention haut niveau du développeur masquée par le framework, et que le framework (Kokkos) n'est pas conçu pour effectuer des transformations mathématiques complexes, les deux doivent coopérer. Cette approche consiste à instrumenter Kokkos pour qu'il injecte des indices sémantiques (annotations et métadonnées) dans le code généré, et à adapter Polly pour qu'il soit capable de lire ces informations depuis l'IR. Cela permet au compilateur de reconstruire un modèle polyédrique complet et d'appliquer des transformations statiques, tout en tirant parti de la connaissance de la structure initiale fournie par Kokkos.

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node((0, 0), [*Kokkos Code*], fill: rgb("#3298cf"), corner-radius: 3pt),
      fletcher.edge((0, 0), (0, 1), "-|>"),
      fletcher.node((0, 1), [Clang Frontend], corner-radius: 3pt),
      fletcher.edge((0, 1), (0, 2), text(size: 0.8em)[LLVM IR + Annotations], "-|>"),
      fletcher.node((0, 2), [*Polly* (with Kokkos specific passes)], fill: rgb("#da3d3d"), corner-radius: 3pt),
      fletcher.edge((0, 2), (0, 3), text(size: 0.8em)[Polyhedral Optimized IR], "-|>"),
      fletcher.node((0, 3), [Clang / LLVM Backend], corner-radius: 3pt),

      fletcher.node((-0.5, 4), [CPU target], corner-radius: 3pt),
      fletcher.edge((0, 3), (-0.5, 4), "-|>"),
      fletcher.node((0.5, 4), [GPU target], corner-radius: 3pt),
      fletcher.edge((0, 3), (0.5, 4), "-|>"),
    ),
    caption: [Proposed Kokkos-Polly co-design compilation pipeline.],
  ) <fig:polykokkos_pipeline>
]

Puisque Kokkos n'est pas concu pour effectuer des analyses et des transformations complexes et que Polly ne peut effecter les ses transformations sur des codes Kokkos. Ce travail propose une approche de co-design entre Kokkos et Polly permettant de rendre les boucles Kokkos lisibles par Polly.
En injectant des informations manquante directement dans le code source via l'instrumentation des backends Kokkos. Du coté de Polly, il faut qu'il puisse comprendre le code d'entré provenant de kokkos pour construire le modele mathématique en se bassant sur les informations injectés par Kokkos ainsi que des transformations statiques possibles en connaissance de la structure de Kokkos.


== Kokkos Modifications

Le co-design entre Kokkos et Polly implique d'instrumenter le framework afin qu'il injecte des informations sémantiques supplémentaires (telles que les bornes de boucles, les dimensions des tableaux ou le backend utilisé) lors de la génération du code. Ces métadonnées, préservées sous forme d'annotations jusqu'à la représentation intermédiaire (IR) de LLVM, sont ensuite exploitées par Polly pour reconstruire un modèle polyédrique complet et exact.

Outre ce système d'annotations, les modifications apportées à Kokkos s'appuient sur des mécanismes de métaprogrammation. Ces derniers permettent d'introduire des options de configuration de compilation à granularité fine (à l'échelle du noyau) et d'adapter les backends afin delimiter le code destiné à être analysé par Polly. De plus, la fonction `parallel_for` a été modifiée pour offrir une plus grande flexibilité, facilitant l'analyse globale des noyaux avec une nouvelle définition statiquement nommée des `View`. L'objectif est d'isoler les boucles et de produire une représentation structurellement simplifiée, optimisant ainsi la détection des régions statiques (SCoP) par le modèle polyédrique, tout en garantissant que le reste de l'application conserve son comportement standard.

=== usePolyOpt

Par défaut, Polly analyse l'ensemble de la représentation intermédiaire (IR) d'un module à la recherche de Static Control Parts (SCoP). Cette approche globale manque de granularité, augmentant inutilement les temps de compilation et risquant de transformer des parties de l'application qui ne le nécessitent pas en augmentant implicitement le risque d'erreur.

Pour retrouver un niveau de contrôle fin, similaire à celui offert nativement par Kokkos, où le développeur paramètre l'exécution noyau par noyau, et pour garantir que les applications Kokkos existantes restent strictement standards, nous avons introduit le paramètre optionnel de template `usePolyOpt`.

```cpp
template <bool Polly = false,
          StringAssumption StrAssumption = "",
          class ExecPolicy,
          class FunctorType,
          class Enable = std::enable_if_t<is_execution_policy<ExecPolicy>::value>
          >
inline void parallel_for(const std::string& str, const ExecPolicy& policy,
                         const FunctorType& functor);
```

Cette option s'ajoute simplement lors de l'appel à la fonction `parallel_for` (voir @code:usepolyopt). Grâce à la métaprogrammation C++, elle permet de déclencher statiquement le chemin de génération de code "annoté et isolé" uniquement pour les noyaux ciblés (généralement les plus coûteux en temps de calcul). Si l'option est omise, le comportement de compilation standard de Kokkos est conservé sans aucune pénalité.

#figure(
  ```cpp
  Kokkos::parallel_for<Kokkos::usePolyOpt>(policy,
                                           KOKKOS_LAMBDA(long i, long j) {
      B(i, j) = A(i, j) + A(i, j - 1) + A(i, j + 1) +
                          A(i - 1, j) + A(i + 1, j);
    });
  ```,
  caption: [Exemple d'utilisation du paramètre `usePolyOpt` pour activer l'analyse polyédrique sur un noyau Kokkos spécifique.],
) <code:usepolyopt>


=== Backend Rewriting

Pour cibler un backend spécifique, Kokkos s'appuie sur une interface de métaprogrammation structurée autour d'une définition générique de la fonction `parallel_for`. Cette fonction est surchargée par chaque backend afin d'adapter l'exécution aux différentes architectures matérielles. Lors de la compilation, Kokkos redirige automatiquement le code vers le backend approprié en fonction de la politique d'exécution (`Policy`) et des types de données spécifiés par l'utilisateur. La @fig:backendselection illustre cette architecture de sélection et de redirection du code.

L'implémentation de ces backends étant masquée à l'utilisateur, elle offre l'opportunité d'adapter le code généré de manière transparente. Cette couche d'abstraction nous permet de réécrire les noyaux en supprimant la complexité introduite par les optimisations matérielles natives ou les pragmas, produisant ainsi un code source intermédiaire plus accessible pour l'analyse polyédrique par Polly.

Lors de l'utilisation de `MDRangePolicy` pour itérer sur des espaces multidimensionnels, les backends standards de Kokkos appliquent des mécanismes de découpage en blocs. Bien que ces transformations statiques soient essentielles pour exposer le parallélisme et optimiser l'exécution sur l'architecture cible, elles saturent le code généré de niveaux de boucles supplémentaires et d'une arithmétique d'indexation complexe dans l'IR. Cela rend opaque l'espace d'itération originel que la détection de SCoP de Polly tente de reconstruire.

Or, le modèle polyédrique est conçu pour effectuer lui-même ces transformations (*tiling*, *mapping*) de manière optimale selon le matériel. Afin de maximiser la détection et d'offrir à Polly un nid de boucles canonique et régulier, nous avons réimplémenté la politique `MDRangePolicy` pour qu'elle désactive ces optimisations lorsqu'elle est dirigée vers notre pipeline. Concrètement, une variante de l'itérateur de tuiles, nommée `HostIterate`, a été ajoutée et remplace `HostIterateTile` lors de l'utilisation du paramètre `usePolyOpt`. Cela garantit un code épuré pour Polly, tout en préservant le fonctionnement par défaut du framework pour le reste de l'application sans aucun changement utilisateur.

#[
  #figure(
    scale(60%, reflow: true)[
      #fletcher.diagram(
        node-stroke: 1pt,
        edge-stroke: 1pt,
        node-inset: 8pt,
        spacing: (2em, 7em),

        // Row Titles
        fletcher.node((-2, 0), text(size: 1.2em, weight: "bold")[Interface], stroke: none),
        fletcher.node((-2, 1), text(size: 1.2em, weight: "bold")[Backend], stroke: none),
        fletcher.node((-2, 2), text(size: 1.2em, weight: "bold")[Policy], stroke: none),

        // Interface
        fletcher.node(
          (1, 0),
          align(left)[#raw("template<class Policy, class Backend>\nparallel_for(Policy<backend>, ...)", lang: "cpp")],
          fill: rgb("#dae8fc"),
          stroke: rgb("#6c8ebf"),
          corner-radius: 2pt,
        ),

        // Backend
        fletcher.node(
          (0, 1),
          align(left)[#raw("template<class Policy>\nparallel_for(Policy<Serial>, ...)", lang: "cpp")],
          fill: rgb("#d5e8d4"),
          stroke: rgb("#82b366"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (1, 1),
          align(left)[#raw("template<class Policy>\nparallel_for(Policy<OpenMP>, ...)", lang: "cpp")],
          fill: rgb("#f8cecc"),
          stroke: rgb("#b85450"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (2, 1),
          align(left)[#raw("template<class Policy>\nparallel_for(Policy<Cuda>, ...)", lang: "cpp")],
          fill: rgb("#e1d5e7"),
          stroke: rgb("#9673a6"),
          corner-radius: 2pt,
        ),

        // Policy
        fletcher.node(
          (-0.5, 2),
          align(left)[#raw("parallel_for(Range<Serial>, ...)", lang: "cpp")],
          fill: rgb("#d5e8d4"),
          stroke: rgb("#82b366"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (0.5, 2),
          align(left)[#raw("parallel_for(MDRange<Serial>, ...)", lang: "cpp")],
          fill: rgb("#d5e8d4"),
          stroke: rgb("#82b366"),
          corner-radius: 2pt,
        ),

        fletcher.node(
          (1.5, 2),
          align(left)[#raw("parallel_for(Range<OpenMP>, ...)", lang: "cpp")],
          fill: rgb("#f8cecc"),
          stroke: rgb("#b85450"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (2.5, 2),
          align(left)[#raw("parallel_for(MDRange<OpenMP>, ...)", lang: "cpp")],
          fill: rgb("#f8cecc"),
          stroke: rgb("#b85450"),
          corner-radius: 2pt,
        ),

        // Target
        fletcher.node(
          (1.5, 3),
          [#raw("HostIterateTile", lang: "cpp")],
          fill: rgb("#ffe6cc"),
          stroke: rgb("#d79b00"),
          corner-radius: 2pt,
        ),

        // Edges
        fletcher.edge((1, 0), (0, 1), "-|>"),
        fletcher.edge((1, 0), (1, 1), "-|>"),
        fletcher.edge((1, 0), (2, 1), "-|>"),

        fletcher.edge((0, 1), (-0.5, 2), "-|>"),
        fletcher.edge((0, 1), (0.5, 2), "-|>"),

        fletcher.edge((1, 1), (1.5, 2), "-|>"),
        fletcher.edge((1, 1), (2.5, 2), "-|>"),

        fletcher.edge((0.5, 2), (1.5, 3), "--|>"),
        fletcher.edge((2.5, 2), (1.5, 3), "--|>"),
      )
    ],
    caption: [Architecture de sélection des backends dans Kokkos.],
  ) <fig:backendselection>
]



=== Isolation des boucles

Un noyau Kokkos n'est pas une simple boucle isolée : il est accessible à travers une pile de fonctions d'expédition imbriquées. Une fois que ces fonctions sont intégrées (*inlinées*), le corps de la boucle se retrouve noyé dans une vaste région de l'IR que Polly ne peut pas délimiter.
Pour résoudre cela, nous attribuons un attribut `noinline` aux fonctions "feuilles" de cette pile d'appels — là où le calcul réel a lieu — et nous les marquons avec un attribut de fonction dédié. Ainsi, Polly peut identifier sans ambiguïté les noyaux pertinents. De plus, nous limitons l'analyse de Polly uniquement aux fonctions portant cet attribut. Cela permet d'accélérer la compilation et de garantir que le reste de l'application Kokkos n'est pas altéré par les passes polyédriques.



=== Annotations

Certainne informations sont absolument crutial pour le bon fonctionnement du modele. avec kokkos et son abstraction des structures, certaine donnée accessible simplement depuis un programme sont perdu, car caché derierre des elements de tableaux, dans des strucures, caché par l'acces a des pointeurs qui force le compilateur a etre prudent sur les transformations qu'il peut faire.

Avec le wrapping kokkos, on peut rajouter autant d'annotations utile que l'on veut de maniere transparante pour l'utilisateur, garantissant une bonne compréhensions des tableaux, des bornes de boucles, des dimmensions des tableaux, des acces sur chaque dimension au tableaux pour la délinéarisation de ceci.

le systeme d'annotations se fait grace a une instruction llvm

```cpp
  __builtin_annotation(int variable, char* name)
```

== Restructuration et analyse de l'IR

=== Code Preparation

Le gros du travail réside dans la préparation du code plutôt que dans l'application pure du modèle polyédrique. L'idée est de prendre un code en entrée enrichi par des annotations sémantiques de Kokkos, et d'y appliquer certaines transformations et arrangements pour qu'il puisse être traduit efficacement par Polly en une représentation polyédrique (SCoP).

Pour garantir une détection valide du SCoP, l'IR LLVM brut généré par Kokkos nécessite un nettoyage structurel, organisé autour de deux passes principales :
- *Loop Invariant Code Motion (LICM) :* Kokkos charge souvent de manière répétée les pointeurs de base des tableaux et leurs dimensions dans le corps de la boucle. Nous forçons la remontée (*hoisting*) de ces charges et lectures de dimensions à l'extérieur du nid de boucles. Cela élimine les accès redondants et satisfait l'exigence polyédrique selon laquelle les paramètres d'un SCoP doivent être définis de manière externe.
- *Nettoyage du graphe de flot de contrôle (CFG) :* Les compilateurs insèrent souvent des vérifications de sécurité (ex: `if(lower<upper)`) qui introduisent des branchements conditionnels brisant la détection de SCoP. Nous remplaçons ces vérifications par des intrinsèques `llvm.assume` directement dans l'IR LLVM. Polly utilise ces hypothèses lors de la construction du SCoP pour restreindre l'espace d'itération sans polluer le CFG.

Ces modifications sont cruciales dans la phase de préparation et lors de la construction du SCoP pour lier efficacement les annotations Kokkos à Polly (notamment pour la délinéarisation abordée ci-après). La partie dédiée à la génération de code sera approfondie dans le chapitre @chapter:schedulingheterogeneous.


=== Delinearization

parler du systele de delinéarisation @Delinearization existant, des limitations et de comment on peut le rendre fiables grace au wrapping des kernels par kokkos.

METTRE UN EXEMPLE

=== Annotations Reading

Dire que c'est pas si simple que ca, que les instructions peuvent disparaitre, etre réarangé, suffisionné et que pour avoir un bon systeme d'annotations on a besoin de pouvoir les lire efficacements.

== Backend synchronization

dire que polly par defaut fait un travail sur tout le code. pour simplifier le fonctionnement réduire le temps de compilation, evité les transformations de code non voulu on modifie le fonctionnement pour aavoir un controle plus précis de comment en choisi le backend a utilisé. Par defaut le backend est CPU (comme polly ne peut faire que ca) et pour tout le programme.

Comme on se focalise a un grain plus fin et que pour chaque kernel dans kokkos on peut avoir un backend différent (CPU, GPU) on a besoin d'un grain plus fin. Chaque kernel transmet l'information du backend a utilisé (CPU, GPU) et on ne fait la transformation que sur le kernel concerné. On peut donc avoir un kernel CPU et un kernel GPU dans le même programme contrairement a l'implémentation de Polly.


#figure(
  rect(width: 100%, height: 150pt, stroke: 1pt + black, align(center + horizon)[
    Polly's pipeline
  ]),
  caption: [Schema du fonctionnement du backend grace au annotations injectées par Kokkos et l'IR de LLVM],
)
