#import "../src/common.typ": *


= Rendre les kernels Kokkos visibles <sec:kokkosvisibility>

Dans ce chapitre, nous présentons la première contribution majeure de cette
thèse : une chaîne de compilation qui comble le fossé sémantique entre le
framework de portabilité de performance Kokkos et l'optimiseur polyédrique
Polly. Nous y détaillons l'ensemble de notre approche de bout en bout.

Tout d'abord, nous exposons les motivations scientifiques et techniques qui
justifient ce travail, ainsi que les principes de la stratégie de co-design mise
en place (@sec:kokkosvisibility:motivations). Ensuite, nous détaillons les
modifications apportées à Kokkos : l'introduction du paramètre de template
`usePolyOpt` pour cibler l'optimisation à grain fin, la réécriture et
l'isolation des backends pour fournir des nids de boucles épurés, et l'injection
d'annotations sémantiques dans l'IR LLVM
(@sec:kokkosvisibility:kokkos_modifications). Puis, nous décrivons les passes de
restructuration et d'analyse intégrées dans Polly
(@sec:kokkosvisibility:restructuration). Celles-ci incluent l'extraction des
annotations (@sec:kokkosvisibility:annotations), la simplification et
l'assainissement du flot de contrôle (@sec:kokkosvisibility:cfg_simplification),
la canonicalisation des registres de tableaux
(@sec:kokkosvisibility:array_canonicalization), ainsi que la délinéarisation des
accès mémoire (@sec:kokkosvisibility:delinearization). Enfin, nous présentons le
mécanisme de synchronisation du backend, permettant à Polly d'adapter sa
génération de code aux différents espaces d'exécution matériels ciblés par les
noyaux Kokkos (@sec:kokkosvisibility:backendsync).

== Motivations <sec:kokkosvisibility:motivations>

Comme observé dans l'état de l'art @sec:stateoftheart, les technique de C++
moderne utilisé par Kokkos (métaprogrammation, lambdas, foncteurs, arithmétique
de pointeurs internes) crée un fossé sémantique entre le code source et la
représentation intermédiaire (IR) de LLVM. Lorsque le code Kokkos est abaissé au
niveau de l'IR, où opèrent l'outil d'analyse et d'optimisation tel que Polly, la
structure originale simple des nids de boucles multidimensionnels est délaissé
au profit de structures complexes nécessaires au fonctionnement de Kokkos. Le
compilateur ne perçoit alors que des pointeurs représentant les bornes de
boucles et des accès mémoire via des pointeurs unidimensionnels complexes.
Manquant d'informations et craignant des risques d'aliasing, il se retrouve dans
l'incapacité de réaliser ses analyses pour créer une représentation polyédrique
et appliquer ses optimisations.

L'objectif de ce travail est donc d'offrir aux développeurs Kokkos l'accès aux
optimisations polyédriques avancées (telles que la fusion/fission de boucles, le
loop skewing ou le tiling automatique) sur du code Kokkos, sans pour autant
briser ses promesses de performance et de portabilité. Le développeur doit
pouvoir continuer à écrire ses noyaux de calcul de manière agnostique à
l'architecture avec une intervention minimale.

Pour atteindre cet objectif, nous proposons une stratégie de co-design entre le
framework et le compilateur (@fig:kokkosvisibility:polykokkos_pipeline). Puisque
le compilateur Polly ne peut pas deviner l'intention de haut niveau du
développeur qui est masquée par le framework, et que le framework Kokkos n'est
pas conçu pour effectuer des transformations mathématiques complexes, les deux
doivent coopérer. Cette approche consiste à instrumenter Kokkos pour qu'il
injecte des indices sémantiques via des annotations dans le code généré et
d'utiliser un code clair et simple à optimiser, et à adapter Polly pour qu'il
soit capable de lire ces informations depuis l'IR. Cela permet au compilateur de
reconstruire un modèle polyédrique complet et d'appliquer des transformations
statiques, tout en tirant parti de la connaissance de la structure initiale
fournie par Kokkos.

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node(
        (0, 0),
        [*Kokkos Code*],
        fill: rgb("#3298cf"),
        corner-radius: 3pt,
      ),
      fletcher.edge((0, 0), (0, 1), text(size: 0.8em)[Annotations], "-|>"),
      fletcher.node((0, 1), [Clang Frontend], corner-radius: 3pt),
      fletcher.edge(
        (0, 1),
        (0, 2),
        text(size: 0.8em)[LLVM IR + Annotations],
        "-|>",
      ),
      fletcher.node(
        (0, 2),
        [*Polly* (with Kokkos specific passes)],
        fill: rgb("#da3d3d"),
        corner-radius: 3pt,
      ),
      fletcher.edge(
        (0, 2),
        (0, 3),
        text(size: 0.8em)[Polyhedral Optimized IR],
        "-|>",
      ),
      fletcher.node((0, 3), [Clang / LLVM Backend], corner-radius: 3pt),

      fletcher.node((-0.5, 4), [CPU target], corner-radius: 3pt),
      fletcher.edge((0, 3), (-0.5, 4), "-|>"),
      fletcher.node((0.5, 4), [GPU target], corner-radius: 3pt),
      fletcher.edge((0, 3), (0.5, 4), "-|>"),
    ),
    caption: [Chaîne de compilation proposée, issue du co-design entre Kokkos et
      Polly.],
  ) <fig:kokkosvisibility:polykokkos_pipeline>
]

Comme l'illustre la @fig:kokkosvisibility:polykokkos_pipeline, cette chaîne de
compilation s'articule autour de deux volets complémentaires : d'une part,
l'instrumentation en amont de Kokkos pour injecter et préserver les informations
sémantiques jusqu'à l'IR LLVM ainsi que de modifier les backends Kokkos pour
transmettre le code le plus propre possible à Polly, et d'autre part,
l'intégration de passes spécialisées au sein de Polly pour exploiter ces
annotations et émettre du code adapté tant aux CPU qu'aux GPU. Les sections
suivantes détaillent la mise en oeuvre de ces deux piliers, en débutant par les
adaptations apportées à Kokkos.


== Kokkos Modifications <sec:kokkosvisibility:kokkos_modifications>

Le co-design entre Kokkos et Polly implique d'instrumenter le framework afin
qu'il injecte des informations sémantiques supplémentaires (telles que les
bornes de boucles, des informations sur les tableaux ou encore le backend
utilisé) lors de la génération du code. Ces informations, préservées sous forme
d'annotations jusqu'à la représentation intermédiaire (IR) de LLVM, sont ensuite
exploitées par Polly pour reconstruire un #gls("scop") complet et exact.

Outre ce système d'annotations, les modifications apportées à Kokkos s'appuient
sur des mécanismes de métaprogrammation. Ces derniers permettent d'introduire
une option de configuration de compilation à granularité fine (à l'échelle du
noyau) et d'adapter les backends afin délimiter le code destiné à être analysé
par Polly. L'objectif est d'isoler les boucles et de produire une représentation
structurellement simplifiée représentable par Polly, optimisant ainsi la
détection des #glspl("scop") par le modèle polyédrique, tout en garantissant que
le reste de l'application conserve son comportement initial.

=== Option usePolyOpt

Par défaut, Polly analyse l'ensemble de l'#gls("ir") d'un module à la recherche
de #glspl("scop"). Cette approche globale manque de granularité, augmentant
inutilement les temps de compilation et risquant de transformer des parties de
l'application qui ne le nécessitent pas en augmentant implicitement le risque
d'erreur.

Pour retrouver un niveau de contrôle fin, similaire à celui offert nativement
par Kokkos, où le développeur paramètrise l'exécution noyau par noyau, et pour
garantir que les applications Kokkos existantes restent strictement inchangées
si l'utilisateur ne cherche pas à avoir ce genre d'optimisation, nous avons
introduit le paramètre optionnel de template `usePolyOpt`.
@fig:kokkosvisibility:usepolyopt_functionsignature présente ainsi la nouvelle
signature de `parallel_for` modifiée à cet effet.

#figure(
  ```cpp
  template <bool usePolyOpt = false,
            class ExecPolicy,
            class FunctorType,
            class Enable = std::enable_if_t<is_execution_policy<ExecPolicy>::value>
            >
  inline void parallel_for(const std::string& str, const ExecPolicy& policy,
                           const FunctorType& functor);
  ```,
  caption: [Nouvelle signature de `parallel_for` avec le paramètre
    `usePolyOpt`.],
) <fig:kokkosvisibility:usepolyopt_functionsignature>

Cette option s'ajoute simplement lors de l'appel à la fonction `parallel_for`
(voir @code:kokkosvisibility:usepolyopt). Grâce à la métaprogrammation C++, elle
permet de déclencher statiquement le chemin de génération de code "annoté et
isolé" uniquement pour les noyaux ciblés. Si l'option est omise, le comportement
de compilation standard de Kokkos est conservé sans aucune pénalité sur la
portabilité ou les performances.

#figure(
  ```cpp
  Kokkos::parallel_for<Kokkos::usePolyOpt>(policy,
                                           KOKKOS_LAMBDA(long i, long j) {
      B(i, j) = A(i, j) + A(i, j - 1) + A(i, j + 1) +
                          A(i - 1, j) + A(i + 1, j);
    });
  ```,
  caption: [Exemple d'utilisation du paramètre `usePolyOpt` pour activer
    l'analyse polyédrique sur un noyau Kokkos spécifique.],
) <code:kokkosvisibility:usepolyopt>

=== Backend Rewriting et Isolation

Pour cibler un backend spécifique, Kokkos s'appuie sur une interface de
métaprogrammation structurée autour d'une définition générique de la fonction
`parallel_for` (déclarée dans la
@fig:kokkosvisibility:usepolyopt_functionsignature). Cette fonction est
surchargée par chaque backend afin d'adapter l'exécution aux différentes
architectures matérielles. Lors de la compilation, Kokkos redirige
automatiquement le code vers le backend approprié en fonction de la politique
d'exécution et des types de données templates spécifiés par l'utilisateur. La
@fig:kokkosvisibility:backendselection illustre cette architecture de sélection
et de redirection du code.

#[
  #figure(
    scale(60%, reflow: true)[
      #fletcher.diagram(
        node-stroke: 1pt,
        edge-stroke: 1pt,
        node-inset: 8pt,
        spacing: (2em, 7em),

        // Row Titles
        fletcher.node(
          (-2, 0),
          text(size: 1.2em, weight: "bold")[Interface],
          stroke: none,
        ),
        fletcher.node(
          (-2, 1),
          text(size: 1.2em, weight: "bold")[Backend],
          stroke: none,
        ),
        fletcher.node(
          (-2, 2),
          text(size: 1.2em, weight: "bold")[Policy],
          stroke: none,
        ),

        // Interface
        fletcher.node(
          (1, 0),
          align(left)[#raw(
            "template<class Policy, class Backend>\nparallel_for(Policy<backend>, ...)",
            lang: "cpp",
          )],
          fill: rgb("#dae8fc"),
          stroke: rgb("#6c8ebf"),
          corner-radius: 2pt,
        ),

        // Backend
        fletcher.node(
          (0, 1),
          align(left)[#raw(
            "template<class Policy>\nparallel_for(Policy<Serial>, ...)",
            lang: "cpp",
          )],
          fill: rgb("#d5e8d4"),
          stroke: rgb("#82b366"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (1, 1),
          align(left)[#raw(
            "template<class Policy>\nparallel_for(Policy<OpenMP>, ...)",
            lang: "cpp",
          )],
          fill: rgb("#f8cecc"),
          stroke: rgb("#b85450"),
          corner-radius: 2pt,
        ),
        fletcher.node(
          (2, 1),
          align(left)[#raw(
            "template<class Policy>\nparallel_for(Policy<Cuda>, ...)",
            lang: "cpp",
          )],
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
  ) <fig:kokkosvisibility:backendselection>
]


L'implémentation de ces backends étant masquée pour l'utilisateur, elle offre
l'opportunité d'adapter le code généré de manière transparente. Cette couche
d'abstraction permet de réécrire la structure des noyaux en supprimant la
complexité introduite par les optimisations matérielles natives ou les pragmas,
produisant ainsi un code source intermédiaire plus accessible pour l'analyse
polyédrique par Polly.

Lors de l'utilisation de `MDRangePolicy` pour itérer sur des espaces
multidimensionnels, les backends standards de Kokkos appliquent des mécanismes
statiques de découpage en blocs pour appliquer un tuillage. Bien que ces
transformations statiques soient essentielles pour exposer le parallélisme et
optimiser l'exécution sur les architectures cibles, elles saturent le code
généré de niveaux de boucles supplémentaires et d'une arithmétique d'indexation
complexe dans l'IR. Cela rend opaque les SCoP que Polly tente de reconstruire.

Or, le modèle polyédrique est conçu pour effectuer lui-même ces transformations
(tiling, mapping) de manière optimale selon le matériel. Afin de maximiser la
détection et d'offrir à Polly un nid de boucles canonique et régulier, la
politique `MDRangePolicy` a été réécrite pour désactiver ces optimisations
lorsqu'elle est utilisée dans notre pipeline. Concrètement, une variante de la
structure responsable du tuilage, nommée `HostIterate`, a été ajoutée et
remplace `HostIterateTile` lors de l'utilisation du paramètre `usePolyOpt`. Cela
garantit un code épuré pour Polly, tout en préservant le fonctionnement par
défaut du framework pour le reste de l'application, sans nécessiter aucun
changement des utilisateurs Kokkos.


Par ailleurs, un noyau Kokkos n'est pas une simple boucle isolée : il est
accessible à travers une pile de fonctions imbriquées souvent inlinées à la
compilation. Une fois que ces fonctions sont inlinées, le corps de la boucle se
retrouve noyé dans une vaste région de l'IR complexe contenant des portions de
code à ne pas transformer avec le modèle polyédrique. De plus, l'architecture de
Kokkos rend difficile l'analyse de cette région pour les dévelopeurs qui
travaille sur l'optimisation de ses noyaux avec Polly. Pour résoudre cela, nous
attribuons un attribut `noinline` à la fonction "feuille" de cette pile
d'appels, ou se trouve le calcul réel, et nous la marquons avec un attribut de
fonction dédié `findscop`. Ainsi, Polly peut identifier sans ambiguïté les
noyaux pertinents que l'utilisateur souhaite optimiser. De plus, nous limitons
l'analyse de Polly uniquement aux fonctions portant cet attribut. Cela permet
d'accélérer la compilation et de garantir que le reste de l'application Kokkos
n'est pas altéré par les transformations polyédriques.


=== Annotations

Pour préserver la sémantique de haut niveau tout au long du processus
d'abaissement vers la représentation intermédiaire, il est essentiel d'intégrer
des informations directement au sein du code de Kokkos. En effet, à travers ses
multiples couches d'abstraction, certaines informations explicites dans le code
source (telles que les bornes de boucles, les dimensions ou encore les accès aux
tableaux) sont perdues, masquées par des structures complexes ou par des calculs
d'adresses. Cette perte d'information contraint le compilateur à adopter une
approche conservative, limitant drastiquement les transformations applicables.

Afin de pallier ce problème de manière transparente, notre approche exploite la
fonction intrinsèque suivante du compilateur LLVM :

```cpp
typeof(expr) __builtin_annotation (typeof(expr) e, const char *string);
```

Cette construction associe une chaîne de caractères `string` (faisant office
d'étiquette sémantique) à une expression `e`, générant un noeud `llvm.annotate`
au sein de l'IR. Elle établit ainsi un pont sémantique robuste entre les
abstractions C++ de haut niveau et la représentation de bas niveau.

L'injection de ces annotations est réalisée directement au sein des différents
backends de Kokkos, mais aussi dans les méthodes d'accès aux données
multidimensionnelles. Ainsi, le processus demeure totalement transparent pour
l'utilisateur final, dont le code applicatif reste inchangé.

Ces annotations sont notamment employées pour garantir la détection des SCoPs et
appliquer de manière sécurisée les nouvelles passes de restructuration
(@sec:kokkosvisibility:restructuration) spécifiques à Kokkos au sein de Polly.
Elles jouent également un rôle fondamental pour assurer la délinéarisation des
tableaux multidimensionnels, dont les détails de mise en oeuvre et le
fonctionnement sont exposés dans la @sec:kokkosvisibility:delinearization.



== Préparation du code et restructuration de l'IR <sec:kokkosvisibility:restructuration>

L'approche de co-design nécessite également d'adapter Polly afin de lui
permettre non seulement d'interpréter les informations injectées par Kokkos,
mais également d'appliquer des transformations basées sur des heuristiques
spécifiques au framework Kokkos. En effet, le nettoyage des backend Kokkos et la
présence d'annotations et de leur interprétation directe s'avère insuffisante :
l'IR LLVM générée à partir du code Kokkos reste obstruée par des constructions
complexes (telles que des bornes de boucles lues dynamiquement depuis la
mémoire) que le compilateur peine à identifier comme invariantes. Afin de
préparer ce code pour l'analyse polyédrique, plusieurs passes de restructuration
dédiées doivent être exécutées en amont. Celles-ci garantissent l'obtention
d'une représentation intermédiaire sémantiquement équivalente, mais dont la
structure épurée expose clairement les informations nécessaires à Polly pour la
construction du SCoP.

Au sein de la chaîne de compilation, l'exécution des transformations de
restructuration nécessite d'établir un point d'ancrage précis dans la séquence
de passes de Polly. Dans son fonctionnement par défaut, le pipeline de Polly
débute par une étape préparatoire `CodePreparation` dont le rôle est d'isoler
les allocations mémoires locales (`alloca`) des opérations arithmétiques et
d'accès aux données, afin de simplifier les analyses subséquentes. Nous mettons
à profit cette phase précoce pour ajouter juste après notre propre suite de
passes de prétraitement.

À ce stade du pipeline, l'IR LLVM brute résultant de l'abaissement des modèles
C++ de Kokkos doit faire l'objet d'un assainissement. Cette préparation poursuit
un double objectif :
- D'une part, extraire et exploiter les annotations sémantiques injectées par
  les backends de Kokkos, afin d'exposer clairement à Polly les informations
  pour construire le modèle (@sec:kokkosvisibility:annotations) ;
- D'autre part, assainir la topologie du graphe de flot de contrôle en éliminant
  les branchements inutiles pour la structure de boucle provenant de code
  Kokkos. (@sec:kokkosvisibility:cfg_simplification).

=== Extraction et exploitation des annotations <sec:kokkosvisibility:annotations>

Afin d'établir une passerelle sémantique entre les abstractions C++ de haut
niveau et le modèle polyédrique, notre approche repose sur l'extraction
systématique des annotations injectées au sein des backends de Kokkos via les
intrinsèques `__builtin_annotation`. Ce mécanisme, totalement transparent pour
l'utilisateur, permet à Polly de récupérer les informations fondamentales pour
le modèle polyédrique :
- Les bornes de l'espace d'itération des boucles ;
- Les pointeurs de base des structures de données (`View`) ;
- Les dimensions spatiales des tableaux multidimensionnels.

L'accès à ces informations constitue une condition préalable absolue pour
permettre au compilateur de construire un domaine d'itération et de délinéariser
fidèlement les accès mémoires.

*Résilience des métadonnées face aux optimisations de bas niveau.*
Cette extraction soulève un défi : la *résilience* des métadonnées tout au long
de la chaîne LLVM. En effet, entre l'émission initiale de l'IR par le
compilateur frontend Clang et l'exécution des passes polyédriques de Polly, le
code intermédiaire traverse une multitude de passes d'optimisation (combinaison
d'instructions, élimination de sous-expressions communes, propagation de
constantes, simplification du flot de contrôle).

Lorsqu'une annotation est émise dans l'IR par le frontend Clang, elle est
systématiquement placée à la suite de l'instruction ciblée. Au cours des passes
d'optimisation préalables, bien que les appels à l'intrinsèque `llvm.annotate`
soient ignorés et préservés par le compilateur, ces derniers sont susceptibles
de référencer des valeurs ayant été altérées ou supprimées. Il est donc
indispensable que le système d'extraction des annotations intègre un mécanisme
capable de remonter l'arbre des dépendances afin de retrouver les valeurs
originales, comme les chargements mémoires définissant les bornes de boucles qui
peuvent être annotés après des opérations arithmétiques sur des boucle avec une
borne de `N - 1` par exemple et le bon tableau.


*Élévation des bornes de boucles et invariants.*
Le modèle d'exécution de Kokkos s'appuie sur des politiques de parcours
(`RangePolicy`, `MDRangePolicy`) qui, au lieu de manipuler de simples variables
scalaires immédiates, encapsulent les bornes d'itération dans des structures de
données complexes sous forme de tableaux. Lors de l'abaissement vers l'IR LLVM,
l'évaluation de ces bornes se matérialise souvent par des chargements mémoires
répétés (`getelementptr` suivi de `load`) qui peuvent se situer à l'intérieur
même du nid de boucles.

Cette situation est hautement pénalisante à deux égards :
1. *Pénalité de performance :* À chaque itération, le processeur exécute une
  lecture mémoire redondante pour recharger une valeur que le programmeur sait
  invariante sur l'ensemble du noyau. L'analyse d'alias conservatrice de LLVM ne
  parvenant pas à prouver qu'aucune écriture dans le corps de boucle ne modifie
  la structure de la politique d'exécution, la passe standard de déplacement de
  code invariant (*Loop Invariant Code Motion*, LICM) échoue à hisser cette
  instruction hors de la boucle en évitant tout risque d'aliasing.
2. *Incompatibilité avec le modèle polyédrique :* La théorie polyédrique impose
  que les bornes régissant le domaine d'itération soient des paramètres
  invariants définis strictement en amont du #gls("scop"). La présence d'un
  chargement dynamique au sein du corps de boucle disqualifie immédiatement le
  nid d'itération lors de la phase de détection de SCoP.

L'extraction des métadonnées relatives aux bornes permet à notre passe de
préparation d'identifier sans ambiguïté la nature invariante de ces accès et de
forcer leur élévation (*hoisting*) hors du nid de boucles
(@fig:kokkosvisibility:loop_hoisting). Une fois déportées juste après les
assignments des valeurs, ces dernières sont reconnues par Polly comme des
paramètres invariants légitimes, satisfaisant ainsi aux prérequis formels de
l'analyse polyédrique.

#[
  #show raw: set text(size: 5pt)
  #let diagram = diagram.with(
    spacing: 15pt,
    node-shape: rect,
    node-stroke: 0.7pt,
    edge-stroke: 0.7pt,
    node-corner-radius: 4pt,
  )
  #subpar.super(
    grid(
      columns: 2,
      rows: 1,
      inset: 0.5cm,
      align: bottom,
      [
        #figure(
          diagram(
            node((0, 0), box(width: 10em, align(left)[
              *for.preheader :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```llvm
              ...
              br label %for.body
              ```
            ])),
            node(
              (0, 1),
              box(width: 12em, align(left)[
                *for.body :*
                #v(-15pt)
                #line(length: 100%, stroke: 0.5pt + gray)
                #v(-15pt)
                ```llvm
                %i = phi i64 [ 0, %for.preheader ], [ %i.next, %for.body ]
                ; ... exécution du corps du noyau ...

                ; Chargement mémoire de la borne à chaque itération
                %ptr = getelementptr %Policy, ptr %P, i32 0, i32 1
                %upper = load i64, ptr %ptr

                %i.next = add nuw nsw i64 %i, 1
                %cmp = icmp slt i64 %i.next, %upper
                br i1 %cmp, label %for.body, label %for.end
                ```
              ]),
              name: <body_before>,
            ),
            node((0, 2), box(width: 10em, align(left)[
              *for.end :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```llvm
              ...
              ```
            ])),
            edge((0, 0), (0, 1), "->"),
            edge((0, 1), (0, 2), "->"),
            edge(
              <body_before>,
              <body_before>,
              "->",
              bend: -105deg,
              loop-angle: 180deg,
            ),
          ),
          caption: [Code IR initial avant la passe de hoisting.],
        )<fig:kokkosvisibility:loop_hoisting_before>
      ],
      [
        #figure(
          diagram(
            node((0, 0), box(width: 10em, align(left)[
              *for.preheader :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```llvm
              ; La lecture de la borne est hissée (hoisted) en amont
              %ptr = getelementptr %Policy, ptr %P, i32 0, i32 1
              %upper = load i64, ptr %ptr
              br label %for.body
              ```
            ])),
            node(
              (0, 1),
              box(width: 12em, align(left)[
                *for.body :*
                #v(-15pt)
                #line(length: 100%, stroke: 0.5pt + gray)
                #v(-15pt)
                ```llvm
                %i = phi i64 [ 0, %for.preheader ], [ %i.next, %for.body ]
                ; ... exécution du corps du noyau ...

                %i.next = add nuw nsw i64 %i, 1
                %cmp = icmp slt i64 %i.next, %upper
                br i1 %cmp, label %for.body, label %for.end
                ```
              ]),
              name: <body_after>,
            ),
            node((0, 2), box(width: 10em, align(left)[
              *for.end :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```llvm
              ...
              ```
            ])),
            edge((0, 0), (0, 1), "->"),
            edge((0, 1), (0, 2), "->"),
            edge(
              <body_after>,
              <body_after>,
              "->",
              bend: -105deg,
              loop-angle: 180deg,
            ),
          ),
          caption: [Code IR assaini après élévation de la borne invariante.],
        )<fig:kokkosvisibility:loop_hoisting_after>
      ],
    ),
    caption: [Élévation (*hoisting*) du chargement de la borne de boucle dans le
      pré-en-tête du SCoP.],
    label: <fig:kokkosvisibility:loop_hoisting>,
  )
]

Le nom statique des étiquettes sert principalement à déterminer le type
d'annotation, mais il peut également être exploité pour extraire des métadonnées
de plus fine granularité. Il permet, par exemple, d'identifier avec précision à
quelle profondeur dimensionnelle d'un tableau correspond une valeur (dépassant
ainsi la simple reconnaissance d'une dimension générique), ou encore d'associer
chaque borne de boucle à sa dimension correspondante au sein de la politique
d'exécution employée. L'exploitation approfondie de ces informations sera
détaillée dans le @sec:complexexecutionpatterns.

*Annotations contextuelles étendues.*
Au-delà des des annotations des bornes de boucles et des tableaux, les
annotations sont également exploitées pour transmettre des propriétés
sémantiques de haut niveau indispensables à la prise en charge de motifs de
calcul complexes, qui seront examinés en détail dans les chapitres suivants.

- Le *backend d'exécution cible* : transmission de l'architecture matérielle
  assignée au noyau Kokkos (`Serial`, `OpenMP`, `Cuda`), permettant à Polly de
  sélectionner la stratégie de génération de code adéquate à l'échelle de chaque
  SCoP individuel (@sec:kokkosvisibility:backendsync) ;
- Le *nommage statique des tableaux* : assignation d'un identifiant statique aux
  structures `View`, permettant de rétablir l'identité commune de pointeurs
  distincts capturés par des lambdas différentes lors de la fusion inter-noyaux
  (@sec:complexexecutionpatterns:globalloopvision) ;
- Les *contraintes d'assomption * : formulation textuelle de relations
  algébriques (égalités, inégalités) entre paramètres de boucles, injectées sous
  forme d'hypothèses dans le domaine polyédrique
  (@sec:complexexecutionpatterns:assumptions).


=== Simplification et assainissement du CFG <sec:kokkosvisibility:cfg_simplification>

Bien que l'extraction des annotations sémantiques
(@sec:kokkosvisibility:annotations) fournisse les informations de haut niveau
indispensables, elles peuvent ne pas suffire à elles seules pour garantir une
analyse polyédrique fructueuse.

En effet, pour qu'une région de code puisse être formellement reconnue comme un
#gls("scop"), l'IR LLVM doit impérativement satisfaire des critères de
régularité stricts : des bornes de boucles et des conditions de branchement
exprimées sous forme de fonctions affines des itérateurs et paramètres, un flot
de contrôle statique, des accès mémoires déterministes et explicites, ainsi que
l'absence d'aliasing.

Afin de garantir le respect de ces contraintes, nous avons conçu et intégré une
suite de passes de restructuration s'exécutant directement lors de la phase de
préparation de Polly. Lors des phases d'optimisation préliminaires de LLVM, les
boucles sont réorganisées (via des passes comme `loop-rotate`) afin d'adopter
une structure de type `do-while` facilitant les optimisations. Cette
transformation canonique impose l'insertion de branchements conditionnels en
amont, visant à vérifier dynamiquement la validité des bornes avant d'autoriser
l'entrée dans le corps de la boucle.

Ainsi, au niveau de la représentation intermédiaire, deux constructions
idiomatiques entravent particulièrement la détection des SCoPs : les
branchements qui encadrent préventivement les boucles, ainsi que les mécanismes
de versionnage de boucles.

Bien que Polly ait été conçu pour gérer certaines de ces structures complexes, à
l'instar de la @fig:kokkosvisibility:versionning, le code intermédiaire généré
par Kokkos empêche la détection systématique des #gls("scop"). Cette limitation
s'explique par le fait que le code généré ne préserve pas les mêmes garanties
algorithmiques qu'un code séquentiel classique. Par conséquent, les analyses
d'évolution scalaire (SCEV) deviennent excessivement conservatrices, rompant
ainsi la validité du #gls("scop"). Il s'avère donc indispensable d'introduire
des passes de restructuration dédiées afin d'assainir et de simplifier le CFG en
amont.

#[
  #show raw: set text(size: 6pt)

  #figure(
    diagram(
      spacing: 20pt,
      node-shape: rect,
      node-stroke: 0.7pt,
      edge-stroke: 0.7pt,
      node-corner-radius: 4pt,
      node((0, 0), align(left)[
        *entry :*
      ]),

      node((0, 1), align(left)[
        *pre.header.loop1 :*
      ]),

      node((0, 2), align(left)[
        *header.loop1 :*
      ]),

      node((-0.6, 3), align(left)[
        *header.loop2 :*
      ]),

      node((0.6, 3.5), align(left)[
        *header.loop3 :*
      ]),

      node((-0.6, 4), align(left)[
        *body.loop4 :*
      ]),

      node((-0.6, 5), align(left)[
        *exit.loop2 :*
      ]),

      node((0.6, 4.5), align(left)[
        *exit.loop3 :*
      ]),

      node((0, 6), align(left)[
        *exit.loop1 :*
      ]),
      node((0, 7), align(left)[
        *exit :*
      ]),
      edge((0, -1), (0, 0), "->"),
      edge((0, 0), (0, 1), "->"),
      edge((0, 1), (0, 2), "->"),
      edge((0, 2), (-0.6, 3), "->"),
      edge((0, 2), (0.6, 3.5), "->"),
      edge((-0.6, 3), (-0.6, 4), "->"),
      edge((-0.6, 4), (-0.6, 5), "->"),
      edge((0.6, 3.5), (0.6, 4.5), "->"),
      edge((0.6, 4.5), (0, 6), "->"),
      edge((-0.6, 5), (0, 6), "->"),
      edge((0, 6), (0, 7), "->"),
      edge((-0.6, 4), (-0.6, 4), "->", bend: -100deg, loop-angle: 180deg),
      edge((0.6, 4.5), (0.6, 3.5), "->", bend: -80deg, loop-angle: 180deg),
      edge((0, 6), (0, 2), "->", bend: -95deg, loop-angle: 180deg),
      edge((-0.6, 5), (-0.6, 3), "->", bend: -75deg, loop-angle: 180deg),
    ),
    caption: [Exemple de graphe de flot de contrôle (CFG) complexifié par des
      branchements conditionnels et du versionnage de boucles, entravant la
      détection du SCoP.],
  )<fig:kokkosvisibility:versionning>
]

*Élimination des vérifications conditionnelles de bornes.*
Grâce aux modifications apportées aux backends de Kokkos, il est désormais
garanti que l'appel du noyau de calcul s'effectue systématiquement avec un
espace d'itération valide lors de l'exécution. Il devient dès lors possible de
supprimer en toute sécurité ces vérifications conditionnelles de bornes, qui
polluent inutilement le graphe de flot de contrôle.

*Suppression du versionnage de boucles.*
De manière analogue, le versionnage de boucles introduit par LLVM génère des
variantes d'exécution redondantes, protégées par des gardes. Puisque notre
approche délègue le réordonnancement et la parallélisation au moteur
polyédrique, ce versionnage prématuré démultiplie inutilement les arêtes du CFG.
Une passe dédiée est ainsi chargée de les éliminer, ramenant le nid de boucles à
une forme unique, simplifiée et analysable par Polly.




=== Canonicalisation des registres de tableaux <sec:kokkosvisibility:array_canonicalization>
L'analyse et la transformation de la représentation intermédiaire LLVM soulèvent
des problématiques que l'on ne rencontre pas avec les outils opérant de source à
source. Au niveau de l'IR, les registres employés pour stocker les données
obéissent à la forme #gls("ssa"). Cette propriété impose l'immutabilité et
l'assignation unique de chaque registre, par opposition au code source où une
même variable peut être réassignée de multiples fois. Dans le contexte de l'IR,
cette contrainte engendre non seulement une multiplication des registres
définissant une même donnée, mais introduit également des dépendances entre les
blocs de base par l'intermédiaire de noeuds PHI, le code étant compilé pour une
exécution séquentielle. La @fig:kokkosvisibility:polly_scalar_dep illustre ce
phénomène. La @fig:kokkosvisibility:polly_scalar_dep_nodep présente le code
source avec des accès consécutifs à `array[i]`, dépourvus de dépendance scalaire
entre les statements. À l'inverse, la @fig:kokkosvisibility:polly_scalar_dep_dep
expose le pseudo-code LLVM équivalent, révélant une dépendance stricte entre le
_statement 1_ et le _statement 2_. Dans cet exemple, le _statement 1_ charge la
donnée dans le registre `a` et l'utilise pour une opération. Le _statement 2_
réutilisant ce même registre `a` pour un calcul distinct, son exécution est par
conséquent conditionnée à la complétion préalable du _statement 1_.

#[
  #show raw: set text(size: 6pt)
  #show figure: set block(breakable: true)
  #show raw.where(block: true): it => block(breakable: false, it)
  #let diagram = diagram.with(
    spacing: 15pt,
    node-shape: rect,
    node-stroke: 0.7pt,
    edge-stroke: 0.7pt,
    node-corner-radius: 4pt,
  )
  #subpar.super(
    grid(
      columns: (1fr, 1fr),
      align: bottom + center,
      [
        #figure(
          diagram(
            node((0, 0), box(width: 11em, align(left)[
              *Statement 1 :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```
              ...
              b = array[i] * 2
              ...
              ```])),

            node((0, 1), box(width: 11em, align(left)[
              *Statement 2 :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```
              ...
              c = array[i] + 2
              ...
              ```
            ])),
            edge((0, -1), (0, 0), "->"),
            edge((0, 0), (0, 1), "->"),
            edge((0, 1), (0, 2), "->"),
          ),
          caption: [Accès mémoire directs sans dépendance scalaire entre
            statements.],
        )<fig:kokkosvisibility:polly_scalar_dep_nodep>
      ],
      [
        #figure(
          diagram(
            node((0, 0), box(width: 11em, align(left)[
              *Statement 1 :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```
              ...
              load a from array[i]
              b = a * 2
              ...
              ```])),

            node((0, 1), box(width: 11em, align(left)[
              *Statement 2 :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```
              ...
              c = a + 2
              ...
              ```
            ])),
            edge((0, -1), (0, 0), "->"),
            edge((0, 0), (0, 1), "->"),
            edge((0, 1), (0, 2), "->"),
          ),
          caption: [Dépendance scalaire sur le registre `a` partagé entre les
            deux _statements_.],
        )<fig:kokkosvisibility:polly_scalar_dep_dep>
      ],
    ),
    caption: [Exemple de dépendance scalaire sur `a` entre deux _statements_
      dans le modèle IR de Polly.],
    label: <fig:kokkosvisibility:polly_scalar_dep>,
  )
]

La passe `ForwardOpTree` de Polly a pour objectif de rompre ces dépendances
entre statements afin d'élargir l'espace de recherche de l'ordonnanceur. Son
mécanisme repose sur la remontée d'arbres d'opérandes : au lieu de calculer une
valeur scalaire dans un statement producteur puis de la transmettre à un
statement consommateur via un registre ou un noeud PHI, la passe identifie
l'arbre d'instructions générant cette valeur et le duplique directement au sein
du statement consommateur.

Néanmoins, la portée de la passe `ForwardOpTree` demeure limitée, ce qui
entrave, dans certains cas complexes, la capacité de l'ordonnanceur à optimiser
les boucles efficacement.

Afin de pallier cette limitation, nous avons conçu et implémenté la passe
`ArrayReg2MemPass`. Son objectif est de rétrograder les registres optimisés sous
la forme #gls("ssa") des tableaux préalablement annotés vers des accès mémoire
explicites. L'idée est de briser les dépendances scalaires directement au niveau
de l'IR afin de rétablir une structure sémantique plus proche de celle du code
source original. Cette passe cible spécifiquement quatre structures de
dépendance au sein des boucles :
- la dépendance scalaire sortante d'une boucle ;
- la dépendance scalaire inter-itérations ;
- la dépendance scalaire intra-bloc ;
- la dépendance scalaire étendue.
@ex:array_reg_to_mem illustre ces différents types de structures de dépendances
ainsi que l'impact de l'application de notre passe sur l'IR.

#[
  #show figure: set block(breakable: true)
  #show raw.where(block: true): it => block(breakable: false, it)
  #figure(
    fig.kokkosvisibility-arrayreg2mem,
    caption: [Liste de transformations de dépendances scalaires vers des accès
      mémoires explicites, appliquées par la passe `ArrayReg2MemPass`.],
  )<ex:array_reg_to_mem>
]


En définitive, l'application de la passe `ArrayReg2MemPass` s'avère essentielle
pour lever les verrous structurels induits par les abstractions de Kokkos. En
substituant ces dépendances scalaires artificielles par des accès mémoires
explicites, cette transformation affranchit l'ordonnanceur polyédrique de
contraintes de séquencement superflues. Elle rend ainsi possible l'optimisation
de codes qui, autrement, auraient été bridés par la présence de fausses
dépendances.

=== Délinéarisation <sec:kokkosvisibility:delinearization>

Afin de construire le domaine d'exécution, le modèle polyédrique doit
impérativement reconstruire une représentation multidimensionnelle exacte des
accès mémoires (exprimée sous forme de fonctions affines des itérateurs) à
partir des calculs de pointeurs linéarisés, présents sous forme polynomiale dans
l'IR. Polly confie cette tâche à l'analyse d'évolution scalaire (*Scalar
Evolution*, SCEV) de LLVM, qui modélise l'évolution des adresses d'accès via une
chaîne récursive d'additions (*AddRec*) indexée sur les variables de boucle. Ce
mécanisme repose ensuite sur une division itérative de l'expression d'accès par
les tailles des dimensions successives du tableau
(@sec:scientificbackground:delinearization).

Dans le cas d'un accès complet impliquant l'ensemble des dimensions (par exemple
`A[i][j][k]`, pour des éléments de 8 octets), la SCEV produit une expression
polynomiale imbriquée (@fig:kokkosvisibility:scev_failure_full). L'algorithme
standard de délinéarisation décompose ensuite ce polynôme via des divisions
successives par les tailles respectives des dimensions afin de recouvrer les
indices affines canoniques `[i][j][k]`.

Cependant, cette heuristique algébrique présente une faille structurelle majeure
lorsqu'elle est confrontée à des accès dont certains indices sont statiquement
évalués à zéro (par exemple, `A[0][j][k]`). Dans une telle configuration,
l'indice de la dimension externe étant nul (`i = 0`), le terme polynomial
contenant la taille de la dimension sous-jacente (`%n`) s'annule lors des
simplifications algébriques opérées par LLVM
(@fig:kokkosvisibility:scev_failure_partial). L'expression SCEV résultante ne
contenant plus cette taille intermédiaire, le solveur s'avère incapable de la
déduire par factorisation. Cette perte d'information génère des accès mémoires
ambigus : un même pointeur peut alors être interprété avec un nombre variable de
dimensions selon le motif d'accès étudié.

#subpar.super(
  grid(
    columns: 1,
    rows: 2,
    inset: 0.5cm,
    [
      #figure(
        ```llvm
        ; Expression SCEV générée pour un accès complet A[i][j][k] :
        {{{ %A, +, (8 * %n * %o) }<%for.i>, +, (8 * %o) }<%for.j>, +, 8 }<%for.k>
        ```,
        caption: [Expression SCEV pour un accès complet (`A[i][j][k]`). Les
          tailles de dimensions `%n` et `%o` sont présentes et peuvent être
          déduites algébriquement.],
      )<fig:kokkosvisibility:scev_failure_full>
    ],
    [
      #figure(
        ```llvm
        ; Expression SCEV générée pour un accès partiel A[0][j][k] :
        {{ %A, +, (8 * %o) }<%for.j>, +, 8 }<%for.k>
        ```,
        caption: [Expression SCEV pour un accès partiel (`A[0][j][k]`). La
          disparition du terme contenant `%n` provoque l'échec de la
          délinéarisation standard.],
      )<fig:kokkosvisibility:scev_failure_partial>
    ],
  ),
  caption: [Comparaison des expressions d'évolution scalaire (SCEV) générées par
    LLVM pour un tableau tridimensionnel. Lors d'un accès partiel, la
    simplification algébrique entraîne une perte d'information structurelle que
    seules nos annotations permettent de restaurer.],
  label: <fig:kokkosvisibility:scev_failure>,
)

Le recours aux annotations sémantiques, introduites lors de la génération des
noyaux Kokkos, lève définitivement ce verrou. En communiquant explicitement au
compilateur la taille exacte de chaque dimension (par exemple `%m`, `%n` et
`%o`) sans dépendre de la reconstruction depuis l'IR, nous rendons ce processus
de délinéarisation entièrement déterministe et fiable. Cette approche présente
également un second avantage majeur pour le développeur : lors de l'analyse du
SCoP, les accès mémoires reconstruits correspondent fidèlement à la sémantique
multidimensionnelle du code source original, facilitant ainsi la traçabilité.


=== Synchronisation du backend <sec:kokkosvisibility:backendsync>

Dans son fonctionnement standard, le choix de la stratégie de génération de code
par Polly est dicté par une option de compilation globale (telle que
`-polly-parallel`). Comme l'illustre la
@fig:kokkosvisibility:backendchoise_polly, cette approche force l'application
uniforme du même modèle d'exécution à l'intégralité du module LLVM, en présumant
l'usage d'un CPU comme architecture cible unique. Cette vision monolithique
entre en conflit direct avec le modèle de Kokkos, où une même application peut
répartir l'exécution de ses noyaux de calcul sur des espaces d'exécution
hétérogènes (faisant par exemple cohabiter des calculs séquentiels sur CPU et
des calculs parallèles sur GPU), chaque noyau ciblant son propre backend
(@fig:kokkosvisibility:backendchoise_kokkos). Notre objectif est donc de
répliquer ce fonctionnement au sein de Polly afin de synchroniser la génération
de code de l'optimiseur avec les choix de backends définis dans le code source
Kokkos.

#subpar.super(
  grid(
    columns: 2,
    rows: 1,
    inset: 0.5cm,
    [
      #figure(
        image(fig.kokkosvisibility-pollybackendchoise),
        caption: [Sélection globale du backend dans Polly standard via une
          option de compilation unique.],
      )<fig:kokkosvisibility:backendchoise_polly>
    ],
    [
      #figure(
        image(fig.kokkosvisibility-kokkosbackendchoise),
        caption: [Sélection fine et individualisée du backend par noyau
          Kokkos.],
      )<fig:kokkosvisibility:backendchoise_kokkos>
    ],
  ),
  caption: [Comparaison de la sélection du modèle d'exécution entre l'approche
    globale monolithique de Polly et l'approche fine par noyau de Kokkos.],
  label: <fig:kokkosvisibility:backendchoise>,
)

Afin de s'affranchir de cette contrainte globale, l'indicateur `-polly-parallel`
étant désormais ignoré par notre chaîne de compilation un nouveau mécanisme de
contrôle à grain fin a été introduit. Par l'intermédiaire du système
d'annotations @sec:kokkosvisibility:annotations, c'est désormais chaque noyau
Kokkos qui informe explicitement le compilateur de l'architecture matérielle
cible qui lui est indiquée et qui définit si le SCoP correspondant doit être
exécuté en parallèle. Notre implémentation permet actuellement de cibler trois
environnements d'exécution distincts : *Serial* (exécution séquentielle),
*OpenMP* et *Cuda*. La génération de code pour l'architecture Cuda, qui n'existe
pas nativement au sein de Polly, a nécessité une intégration spécifique qui sera
détaillée ultérieurement dans la @sec:schedulingheterogeneous:ppcg.

Grâce à ces informations contextuelles, Polly acquiert la capacité d'isoler et
d'adapter sa stratégie de transformation pour chaque SCoP de manière
indépendante. Contrairement au comportement natif de Polly, cette
synchronisation autorise la cohabitation, au sein d'un même binaire, de noyaux
spécifiquement optimisés pour des architectures distinctes. Ce couplage préserve
ainsi l'un des engagements fondamentaux de Kokkos : l'intégrité et la
portabilité des performances.
