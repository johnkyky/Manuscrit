#import "../src/common.typ": *


= Rendre les noyaux de calcul de Kokkos visibles <sec:kokkosvisibility>

Dans ce chapitre, nous présentons la première contribution majeure de cette
thèse : une chaîne de compilation qui comble le fossé sémantique entre la
bibliothèque de portabilité des performances Kokkos et l'optimiseur polyédrique
Polly. Nous y détaillons l'ensemble de notre approche de bout en bout.

Tout d'abord, nous exposons les motivations scientifiques et techniques qui
justifient ce travail, ainsi que les principes de la stratégie de co-design mise
en place (@sec:kokkosvisibility:motivations). Ensuite, nous détaillons les
modifications apportées à Kokkos : l'introduction du paramètre de template
`usePolyOpt` pour cibler l'optimisation à grain fin, la réécriture et
l'isolation des _backends_ pour fournir des nids de boucles _épurés_, et
l'injection d'annotations sémantiques dans l'IR LLVM
(@sec:kokkosvisibility:kokkos_modifications). Puis, nous décrivons les passes de
restructuration et d'analyse intégrées dans Polly
(@sec:kokkosvisibility:restructuration). Celles-ci incluent l'extraction des
annotations (@sec:kokkosvisibility:annotations), la simplification et
l'_assainissement_ du flot de contrôle
(@sec:kokkosvisibility:cfg_simplification), la _canonicalisation_ des registres
de tableaux (@sec:kokkosvisibility:array_canonicalization), ainsi que la
_délinéarisation_ des accès mémoire (@sec:kokkosvisibility:delinearization).
Enfin, nous présentons le mécanisme de synchronisation du _backend_, permettant
à Polly d'adapter sa génération de code aux différents espaces d'exécution
matériels ciblés par les noyaux Kokkos (@sec:kokkosvisibility:backendsync).

== Motivations <sec:kokkosvisibility:motivations>

Comme observé dans l'état de l'art du @sec:stateoftheart, les techniques C++
modernes utilisées par Kokkos (métaprogrammation, lambdas, foncteurs,
arithmétique de pointeurs internes) créent un fossé sémantique entre le code
source et la représentation intermédiaire (IR) de LLVM. Lorsque le code Kokkos
est abaissé au niveau de l'IR, où opère l'outil d'analyse et d'optimisation
Polly, la structure originale simple des nids de boucles multidimensionnels est
délaissée au profit de structures complexes nécessaires au fonctionnement de
Kokkos. Le compilateur ne perçoit alors que des pointeurs représentant les
bornes de boucles et des accès mémoire via des pointeurs unidimensionnels
complexes. Manquant d'informations et craignant des risques d'_aliasing_, Polly
se retrouve dans l'incapacité de réaliser ses analyses pour créer une
représentation polyédrique et appliquer ses optimisations.

L'objectif de ce travail est donc d'offrir aux développeurs Kokkos l'accès aux
optimisations polyédriques avancées (telles que la fusion/fission de boucles)
sur du code Kokkos, sans pour autant briser ses promesses de performance et de
portabilité. Le développeur doit pouvoir continuer à écrire ses noyaux de calcul
de manière agnostique à l'architecture avec une intervention minimale.

Pour atteindre cet objectif, nous proposons une stratégie de co-design entre la
bibliothèque et le compilateur (@fig:kokkosvisibility:polykokkos_pipeline).
Puisque le compilateur Polly ne peut pas deviner l'intention de haut niveau du
développeur qui est masquée par la complexité du code, et que Kokkos n'est pas
conçu pour effectuer des transformations mathématiques complexes, les deux
doivent coopérer. Notre approche consiste à instrumenter Kokkos pour qu'il
injecte des indices sémantiques via des annotations dans le code généré afin de
produire un code clair et simple à optimiser, et à adapter Polly afin qu'il soit
capable de lire ces informations depuis l'IR. Ainsi, le compilateur pourra
reconstruire un modèle polyédrique complet et appliquer des transformations
statiques, tout en tirant parti de la connaissance de la structure initiale
fournie par Kokkos.

#[
  #figure(
    diagram(
      spacing: 30pt,
      node-shape: rect,
      node-stroke: 0.7pt,
      edge-stroke: 0.7pt,
      node-corner-radius: 4pt,
      node-inset: 13pt,
      node(
        (0, 0),
        [*Code Kokkos*],
        fill: color-blue,
        stroke: color-blue-stroke,
      ),
      edge((0, 0), (0, 1), text(size: 0.8em)[Annotations], "-|>"),
      node((0, 1), [Frontend Clang]),
      edge(
        (0, 1),
        (0, 2),
        text(size: 0.8em)[IR LLVM + annotations],
        "-|>",
      ),
      node(
        (0, 2),
        [*Polly* (avec passes spécifiques à Kokkos)],
        fill: color-red,
        stroke: color-red-stroke,
      ),
      edge(
        (0, 2),
        (0, 3),
        text(size: 0.8em)[IR optimisée],
        "-|>",
      ),
      node((0, 3), [Backend Clang / LLVM]),

      node((-0.5, 4), [Cible CPU]),
      edge((0, 3), (-0.5, 4), "-|>"),
      node((0.5, 4), [Cible GPU]),
      edge((0, 3), (0.5, 4), "-|>"),
    ),
    caption: [Chaîne de compilation proposée, issue du co-design entre Kokkos et
      Polly.],
  ) <fig:kokkosvisibility:polykokkos_pipeline>
]

Comme l'illustre la @fig:kokkosvisibility:polykokkos_pipeline, cette chaîne de
compilation s'articule autour de deux volets complémentaires : d'une part,
l'instrumentation en amont de Kokkos pour injecter et préserver les informations
sémantiques jusqu'à l'IR LLVM, ainsi que la modification des backends Kokkos
pour transmettre le code le plus clair possible à Polly, et d'autre part,
l'intégration de passes spécialisées au sein de Polly pour exploiter ces
annotations et émettre du code adapté tant aux CPU qu'aux GPU. Les sections
suivantes détaillent la mise en œuvre de ces deux piliers, en débutant par les
modifications apportées à Kokkos.


== Modifications de Kokkos <sec:kokkosvisibility:kokkos_modifications>

Le co-design entre Kokkos et Polly implique d'instrumenter Kokkos afin qu'il
injecte des informations sémantiques supplémentaires (telles que les bornes de
boucles, des informations sur les tableaux ou encore le backend utilisé) lors de
la génération du code. Ces informations, préservées sous forme d'annotations
jusqu'à la représentation intermédiaire de LLVM, sont ensuite exploitées par
Polly pour reconstruire un #gls("scop") complet et précis.

Outre ce système d'annotations, les modifications apportées à Kokkos s'appuient
sur des mécanismes de métaprogrammation. Ces derniers permettent d'introduire
une option de configuration de compilation à granularité fine (à l'échelle du
noyau) et d'adapter les backends afin de délimiter le code destiné à être
analysé par Polly. L'objectif est d'isoler les boucles et de produire une
représentation structurellement simplifiée représentable par Polly, optimisant
ainsi la détection des #glspl("scop"), tout en garantissant que le reste du
programme conserve son comportement initial.

=== Option _usePolyOpt_ <sec:kokkosvisibility:usepolyopt>

Par défaut, Polly analyse l'ensemble de l'#gls("ir") d'un module à la recherche
de #glspl("scop"). Cette approche globale manque de granularité, en augmentant
inutilement les temps de compilation, en risquant de transformer des parties de
l'application qui ne le nécessitent pas et en augmentant implicitement le risque
d'erreur.

Afin de retrouver un niveau de contrôle fin, similaire à celui offert nativement
par Kokkos, où le développeur structure l'exécution noyau par noyau, et afin de
garantir que les applications Kokkos existantes restent strictement inchangées
si les optimisations polyédriques ne sont pas activées, nous introduisons le
paramètre optionnel de template `usePolyOpt`. La
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

Cette option change toutefois le sens du `parallel_for`. Le backend génère des
boucles séquentielles, que Polly parallélise lui-même s'il le peut. La politique
d'exécution ne décrit donc plus le parallélisme, mais l'espace d'itération. Un
noyau annoté peut ainsi contenir des itérations qui dépendent les unes des
autres, ce qui serait invalide en Kokkos standard. Un tel noyau ne fonctionne
donc correctement qu'avec l'option `usePolyOpt`.

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

=== Réécriture du backend et isolation

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

#figure(
  context {
    let current-page = here().page()
    let angle = if calc.even(current-page) { 90deg } else { -90deg }

    rotate(angle, reflow: true, fig.kokkosvisibility-kokkosbackend)
  },
  caption: [Architecture de sélection des backends dans Kokkos.],
) <fig:kokkosvisibility:backendselection>


L'implémentation de ces backends étant masquée pour l'utilisateur, elle offre
l'opportunité d'adapter le code généré de manière transparente. Cette couche
d'abstraction permet de réécrire la structure des noyaux en supprimant la
complexité introduite par les optimisations matérielles natives ou les pragmas,
permettant ainsi de produire un code source intermédiaire plus accessible pour
l'analyse polyédrique par Polly.

Lors de l'utilisation de `MDRangePolicy` pour itérer sur des espaces
multidimensionnels, les backends standards de Kokkos appliquent des mécanismes
statiques de découpage en blocs pour appliquer un tuilage. Bien que ces
transformations statiques soient essentielles pour exposer le parallélisme et
optimiser l'exécution sur les architectures cibles, elles saturent le code
généré de niveaux de boucles supplémentaires et d'une arithmétique d'indexation
complexe dans l'IR. Cela rend opaques les SCoPs que Polly tente de reconstruire.

Or, le modèle polyédrique est conçu pour effectuer lui-même de telles
transformations. Afin de promouvoir la détection de SCoPs en exposant à Polly
des nids de boucles canoniques et réguliers, la politique `MDRangePolicy` a été
réécrite pour désactiver le tuilage de Kokkos lorsqu'elle est utilisée dans
notre pipeline. Concrètement, une variante de la structure responsable du
tuilage, nommée `HostIterate`, a été ajoutée et remplace `HostIterateTile` lors
de l'utilisation du paramètre `usePolyOpt` (voir
@fig:kokkosvisibility:backendselection). Cela garantit un code épuré pour Polly,
tout en préservant le fonctionnement par défaut de Kokkos pour le reste de
l'application, et sans nécessiter la moindre intervention du développeur.


Par ailleurs, un noyau Kokkos n'est pas une simple boucle isolée : il est
accessible à travers une pile de fonctions imbriquées souvent inlinées à la
compilation. Une fois ces fonctions inlinées, le corps de la boucle se retrouve
"noyé" dans une vaste région de l'IR contenant des portions de code qui ne
doivent pas être transformées par des techniques polyédriques. Notre solution
est d'associer un attribut `noinline` à la fonction "feuille" de cette pile
d'appels, où se situe l'appel à la fonction de calcul. Nous marquons aussi la
fonction avec un attribut dédié `findscop`. Ainsi, Polly identifie sans
ambiguïté les noyaux issus du paramètre `usePolyOpt`. De plus, limiter le
spectre d'analyse de Polly uniquement aux fonctions portant cet attribut permet
d'accélérer la compilation et de garantir que le reste de l'application Kokkos
n'est pas impacté par d'éventuelles transformations polyédriques.


=== Annotations <sec:kokkosvisibility:kokkosannotations>

Afin de préserver la sémantique de haut niveau tout au long du processus
d'abaissement vers la représentation intermédiaire, il est nécessaire d'intégrer
des informations directement au sein du code de Kokkos. En effet, à travers ses
multiples couches d'abstraction, certaines informations explicites dans le code
source (telles que les bornes de boucles, les dimensions ou encore les fonctions
d'accès aux tableaux) sont perdues, masquées par des structures complexes ou par
des calculs d'adresses. Cette perte d'information contraint le compilateur à
adopter une approche conservatrice, limitant drastiquement les transformations
applicables.

Afin de pallier ce problème de manière transparente, notre approche exploite la
fonction intrinsèque de Clang :

```cpp
typeof(expr) __builtin_annotation (typeof(expr) e, const char *string);
```

Cette construction associe une chaîne de caractères `string` (faisant office
d'étiquette sémantique) à une expression `e`, générant ainsi un nœud
`llvm.annotate` au sein de l'IR. Elle établit ainsi un pont sémantique robuste
entre les abstractions C++ de haut niveau et la représentation de bas niveau.

L'injection de ces annotations est réalisée directement au sein des différents
backends de Kokkos, mais aussi dans les méthodes d'accès aux données
multidimensionnelles. L'utilisateur n'a donc pas à écrire ces annotations
lui-même.

Ces annotations sont notamment employées pour garantir la détection des SCoPs et
appliquer de manière sécurisée les nouvelles passes de restructuration
(@sec:kokkosvisibility:restructuration) spécifiques à Kokkos au sein de Polly.
Elles jouent également un rôle fondamental pour assurer la délinéarisation des
tableaux multidimensionnels, dont les détails de mise en œuvre et le
fonctionnement sont exposés à la @sec:kokkosvisibility:delinearization.



== Préparation du code et restructuration de l'IR <sec:kokkosvisibility:restructuration>

Notre approche de co-design nécessite également d'adapter Polly afin de lui
permettre non seulement d'interpréter les informations injectées par Kokkos,
mais également d'appliquer des transformations basées sur des heuristiques
spécifiques à Kokkos. En effet, la réécriture des backends de la bibliothèque et
la présence d'annotations et de leur interprétation directe s'avèrent
insuffisantes : l'IR LLVM générée à partir du code Kokkos reste trop opaque à
cause de constructions complexes (telles que des bornes de boucles lues
dynamiquement depuis la mémoire) que le compilateur peine à identifier comme
invariantes. Afin de préparer le code pour l'analyse polyédrique, plusieurs
passes de restructuration dédiées doivent être exécutées en amont. Celles-ci
garantissent l'obtention d'une représentation intermédiaire sémantiquement
équivalente, mais dont la structure épurée expose clairement les informations
nécessaires à Polly pour la construction du SCoP.

Au sein de la chaîne de compilation, l'exécution des transformations de
restructuration nécessite d'établir un point d'ancrage précis dans la séquence
des passes de Polly. Dans son fonctionnement par défaut, le pipeline de Polly
débute par une étape préparatoire `CodePreparation` dont le rôle est d'isoler
les allocations mémoire locales (`alloca`) des opérations arithmétiques et des
accès aux données, afin de simplifier les analyses subséquentes. Nous mettons à
profit cette phase précoce pour ajouter, juste après cette passe initiale, notre
propre suite de passes de prétraitement.

À ce stade du pipeline, l'IR LLVM résultant de l'abaissement des modèles C++ de
Kokkos doit faire l'objet de transformations. Elles relèvent d'un double
objectif :
- D'une part, extraire et exploiter les annotations sémantiques injectées par
  les backends de Kokkos, afin d'exposer clairement à Polly les informations
  permettant de construire la modélisation polyédrique
  (@sec:kokkosvisibility:annotations) ;
- D'autre part, assainir la topologie du graphe de flot de contrôle en éliminant
  les branchements inutiles de la structure de boucle issue de Kokkos
  (@sec:kokkosvisibility:cfg_simplification).

=== Extraction et exploitation des annotations <sec:kokkosvisibility:annotations>

Afin d'établir une passerelle sémantique entre les abstractions C++ de haut
niveau et le modèle polyédrique, notre approche repose sur l'extraction
systématique des annotations injectées au sein des backends de Kokkos via les
fonctions `__builtin_annotation`. Ce mécanisme, totalement transparent pour
l'utilisateur, permet à Polly de récupérer les informations fondamentales pour
la modélisation polyédrique :
- Les bornes de l'espace d'itérations des boucles ;
- Les pointeurs de base des structures de données (`View`) ;
- Les dimensions spatiales des tableaux multidimensionnels.

L'accès à ces informations constitue une condition préalable absolue pour
permettre au compilateur de construire un domaine d'itérations et de
délinéariser fidèlement les accès mémoire.

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
de référencer des valeurs ayant été altérées ou supprimées principalement pour
le marquage des tableaux constitué d'au moins trois annotations distinctes.

Une considération supplémentaire réside dans le fait que le système
d'annotations cible les variables de boucle originelles, mais pas nécessairement
les expressions dérivées qui en découlent. À titre d'illustration, la
@fig:kokkosvisibility:complexebound présente un fragment de code exploitant les
fonctionnalités détaillées à la @sec:complexexecutionpatterns:assumptions. La
boucle interne `j` s'appuie sur la même variable `n` que la boucle externe `i`,
mais au travers de l'expression arithmétique `n - 1`. L'annotation explicite de
`n` porte ainsi exclusivement sur `n`, et non sur le registre temporaire
résultant du calcul de `n - 1`. Par conséquent, afin de préserver la validité du
SCoP et d'en déduire correctement les bornes polyédriques, le mécanisme
d'analyse des annotations doit être capable de remonter la chaîne de dépendances
depuis l'utilisation de la borne dérivée jusqu'à la variable annotée initiale.


#figure(
  ```cpp
  auto policy = Kokkos::RangePolicy(0, n);
  Kokkos::parallel_for<Kokkos::usePolyOpt, "p0.u0 == n">(
    policy,
    KOKKOS_LAMBDA(int i) {
      for(int j = 1; j < KOKKOS_LOOP_BOUND(n) - 1; j++) {
        A(i, j) = B(i, j);
      }
    }
  );
  ```,
  caption: [Exemple d'annotation de borne de boucle impliquant une expression
    arithmétique `n-1`.],
) <fig:kokkosvisibility:complexebound>


*Élévation des bornes de boucles et invariants.*
Le modèle d'exécution de Kokkos s'appuie sur des politiques de parcours
(`RangePolicy`, `MDRangePolicy`) qui, au lieu de manipuler de simples variables
scalaires, encapsulent les bornes de boucles dans des structures de données sous
forme de tableaux. Lors de l'abaissement vers l'IR LLVM, l'évaluation de ces
bornes se matérialise souvent par des chargements mémoire répétés
(`getelementptr` suivi de `load`) qui peuvent se situer à l'intérieur même du
nid de boucles, bien que les valeurs obtenues soient invariantes.

Cette situation est hautement pénalisante à deux égards :
1. *Pénalité de performance :* À chaque itération, le processeur exécute une
  lecture mémoire redondante pour recharger une valeur de borne que le
  programmeur sait invariante sur l'ensemble de la boucle. L'analyse d'alias
  conservatrice de LLVM ne parvenant pas à prouver qu'aucune écriture dans le
  corps de boucle ne modifie la valeur de la borne, la passe standard de
  déplacement de code invariant (*Loop Invariant Code Motion*, LICM) échoue à
  hisser cette instruction hors de la boucle faute de pouvoir exclure un
  aliasing.
2. *Incompatibilité avec le modèle polyédrique :* La théorie polyédrique impose
  que les bornes régissant le domaine d'itérations soient des paramètres
  invariants définis strictement en amont de chaque boucle du nid. La présence
  d'un chargement dynamique au sein du corps de boucle disqualifie immédiatement
  le nid de boucles lors de la phase de détection de SCoP.

L'extraction des annotations relatives aux bornes permet à notre passe de
transformation de l'IR d'identifier sans ambiguïté la nature invariante de ces
accès mémoire, et d'en forcer l'élévation (*hoisting*) hors du nid de boucles
(@fig:kokkosvisibility:loop_hoisting). Une fois les instructions de chargement
de bornes de boucles déplacées juste après le calcul invariant de leur adresse
en amont de la boucle, ces bornes sont reconnues par Polly comme de véritables
paramètres invariants, satisfaisant ainsi pleinement les prérequis de la
modélisation polyédrique.

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
          caption: [Code IR avant la passe de hoisting.],
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
          caption: [Code IR après élévation de la borne invariante.],
        )<fig:kokkosvisibility:loop_hoisting_after>
      ],
    ),
    caption: [Élévation du chargement de la borne de boucle dans le pré-en-tête
      du SCoP.],
    label: <fig:kokkosvisibility:loop_hoisting>,
  )
]

*Autres annotations contextuelles.*
L'étiquette ajoutée grâce à la fonction `__builtin_annotation` permet non
seulement de déterminer la nature de l'annotation, mais elle peut également être
exploitée pour extraire des métadonnées d'une plus fine granularité. Ainsi,
chaque dimension des tableaux utilisés dans le noyau est annotée par une chaîne
de caractères définissant le type d'accès (ex. `"dim"`), tout en précisant le
niveau d'imbrication correspondant (ex. `"dim 1"`). Concernant les bornes de
boucles, un mécanisme analogue est employé afin de relier les bornes (inférieure
et supérieure) de la politique d'exécution utilisée à la profondeur de la boucle
au sein du nid de boucles.

Le @sec:complexexecutionpatterns détaillera l'utilisation de ces annotations
pour étendre les capacités de détection de Polly. Au-delà des métadonnées
relatives aux tableaux et aux bornes de boucles, des annotations additionnelles
s'avèrent indispensables pour garantir une utilisation transparente de Polly
dans Kokkos et pour modéliser des schémas d'exécution plus complexes. Ces
annotations supplémentaires, ainsi que les sections qui leur sont consacrées,
sont détaillées ci-dessous.

- Le *backend d'exécution cible* : transmission de l'architecture matérielle
  assignée au noyau Kokkos (`Serial`, `OpenMP`, `Cuda`), permettant à Polly de
  sélectionner la stratégie de génération de code adéquate à l'échelle de chaque
  SCoP individuel (@sec:kokkosvisibility:backendsync);
- *Le nommage statique des tableaux* : l'assignation d'un identifiant statique
  aux structures `Kokkos::View` permet de rétablir l'identité commune de
  pointeurs distincts. Cette étape est cruciale lorsque ces pointeurs sont
  capturés par des fonctions _lambda_ différentes dans le cadre d'une fusion
  inter-noyaux (@sec:complexexecutionpatterns:globalloopvision);
- Les *contraintes d'assomption* : formulation textuelle de relations
  algébriques (égalités, inégalités) entre paramètres de boucles, injectées sous
  forme d'hypothèses dans le domaine polyédrique
  (@sec:complexexecutionpatterns:assumptions).


=== Simplification et assainissement du CFG <sec:kokkosvisibility:cfg_simplification>

Bien que l'extraction des annotations sémantiques fournisse les informations de
haut niveau indispensables, elles peuvent ne pas suffire à elles seules pour
garantir une analyse polyédrique réussie.

En effet, pour qu'une région de code puisse être formellement reconnue comme un
#gls("scop"), l'IR LLVM doit impérativement satisfaire des critères de
régularité stricts : des bornes de boucles et des conditions de branchement
exprimées sous forme de fonctions affines des itérateurs et paramètres, un flot
de contrôle statique, des accès mémoire déterministes et explicites, ainsi que
l'absence d'aliasing.

Afin de garantir le respect de ces contraintes, nous avons conçu et intégré une
suite de passes de restructuration s'exécutant directement lors de la phase de
`CodePreparation` de Polly. Lors des phases d'optimisation préliminaires de
LLVM, les boucles sont réorganisées (via des passes comme `loop-rotate`) afin
d'adopter une structure de type `do-while` facilitant les optimisations. Cette
transformation canonique impose l'insertion de branchements conditionnels en
amont, visant à vérifier dynamiquement si une boucle possède au minimum une
itération avant d'autoriser l'entrée dans le corps de la boucle. Cette
vérification est redondante avec celle déjà présente dans les _backends_
modifiés pour l'application du modèle polyédrique.

Ainsi, au niveau de la représentation intermédiaire, deux constructions
idiomatiques entravent particulièrement la détection des SCoPs : les
branchements qui encadrent préventivement les boucles, ainsi que les mécanismes
de versionnage de boucles.

Bien que Polly ait été conçu pour gérer certaines de ces structures complexes,
comme par exemple la @fig:kokkosvisibility:versionning, le code intermédiaire
généré par Kokkos empêche la détection systématique des SCoPs. Les analyses
d'évolution scalaire deviennent excessivement conservatrices, rompant ainsi la
validité du #gls("scop"). Il s'avère donc indispensable d'introduire des passes
de restructuration dédiées afin d'assainir et de simplifier le CFG en amont pour
garantir la détection systématique des SCoPs.

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
espace d'itérations non vide lors de l'exécution. Il devient dès lors possible
de supprimer en toute sécurité ces vérifications conditionnelles de bornes, qui
surchargent inutilement le graphe de flot de contrôle.

*Suppression du versionnage de boucles.*
De manière analogue, le versionnage de boucles introduit par LLVM génère des
variantes d'exécution redondantes, protégées par des gardes. Puisque notre
approche délègue le réordonnancement et la parallélisation au moteur
polyédrique, ce versionnage prématuré démultiplie inutilement les arêtes du CFG.
Une passe dédiée est ainsi chargée de les éliminer, ramenant le nid de boucles à
une forme unique, simplifiée et analysable par Polly.

Par ailleurs, Polly insère automatiquement un mécanisme de garde dynamique afin
de vérifier à l'exécution la validité des hypothèses formulées lors de l'analyse
statique. Ce contrôle s'assure notamment de la cohérence entre le domaine
d'itération et les paramètres utilisés. Ces vérifications conditionnent le
lancement du code transformé : si les contraintes du modèle polyédrique ne sont
pas respectées, l'exécution bascule vers la version originelle du code,
garantissant ainsi la préservation de la sémantique du programme.




=== Canonicalisation des registres de tableaux <sec:kokkosvisibility:array_canonicalization>

L'analyse et la transformation de la représentation intermédiaire LLVM soulèvent
des problématiques que l'on ne rencontre pas avec les outils opérant de source à
source. Au niveau de l'IR, les registres employés pour stocker les données
obéissent à la forme #gls("ssa"). Cette propriété impose l'immuabilité et
l'assignation unique de chaque registre, par opposition au code source où une
même variable peut être réassignée de multiples fois. Dans le contexte de l'IR,
cette contrainte engendre non seulement une multiplication des registres
définissant une même donnée, mais introduit également des dépendances entre les
blocs de base par l'intermédiaire de nœuds PHI.

La @fig:kokkosvisibility:polly_scalar_dep illustre ce phénomène. La
@fig:kokkosvisibility:polly_scalar_dep_nodep présente le graphe de flot de
contrôle d'un code source effectuant des accès consécutifs à la même zone
mémoire `array[i]`, sans aucune dépendance scalaire entre les instructions. À
l'inverse, la @fig:kokkosvisibility:polly_scalar_dep_dep expose la
représentation intermédiaire LLVM équivalente. L'accès mémoire `array[i]` au
sein du bloc `block 1` y est remplacé par une instruction de chargement (`load`)
dont le résultat est assigné à la variable SSA `%a`. Cette variable `%a` est
ensuite consommée non seulement dans le `block 1`, mais également dans le
`block 2`.

Lors de son analyse, Polly modélise ces deux blocs sous la forme de deux
_statements_ distincts. De ce fait, Polly introduit artificiellement une
dépendance scalaire : pour que le _statement_ représentant le `block 2` puisse
être évalué, il est impératif que le premier _statement_ (associé au `block 1`)
ait été exécuté au préalable, puisqu'il héberge l'instruction de chargement.

#[
  #show raw: set text(size: 6pt)
  #show figure: set block(breakable: false)
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
              *block 1 :*
              #v(-15pt)
              #line(length: 100%, stroke: 0.5pt + gray)
              #v(-15pt)
              ```
              ...
              b = array[i] * 2
              ...
              ```])),

            node((0, 1), box(width: 11em, align(left)[
              *block 2 :*
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
            _statements_.],
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
entre _statements_ afin d'élargir l'espace de recherche de l'ordonnanceur. Son
mécanisme repose sur la remontée d'arbres d'opérandes : au lieu de calculer une
valeur scalaire dans un _statement_ producteur puis de la transmettre à un
_statement_ consommateur via un registre ou un nœud PHI, la passe identifie
l'arbre d'instructions générant cette valeur et le duplique directement au sein
du _statement_ consommateur. Dans l'exemple précédent
(@fig:kokkosvisibility:polly_scalar_dep_dep), la passe remonte l'arbre
d'opérations de `%a` depuis le `block 2` vers le `block 1`. Si elle parvient à
prouver qu'il n'existe aucun risque d'altérer la sémantique du programme, elle
effectuera une copie de l'instruction `load a from array[i]` dans le `block 2`,
brisant ainsi la dépendance.

Néanmoins, la portée de la passe `ForwardOpTree` demeure limitée. En effet, les
transformations LLVM sont soumises à des contraintes très strictes afin de
préserver absolument la sémantique d'origine du programme. Ces analyses
conservatrices brident l'application de la passe, principalement pour des
raisons de risques d'aliasing mémoire ou de dépendances cycliques
inter-itérations. Cette prudence entrave, dans certains cas complexes, la
capacité de l'ordonnanceur à optimiser les boucles efficacement.

Afin de pallier ces limitations, nous avons conçu et implémenté la passe
`ArrayReg2MemPass`. Son objectif est de rétrograder les registres optimisés sous
la forme #gls("ssa") des tableaux préalablement annotés vers des accès mémoire
explicites. L'idée est de briser les dépendances scalaires directement au niveau
de l'IR afin de rétablir une structure sémantique plus proche de celle du code
source original. Cette passe cible spécifiquement quatre types de dépendance au
sein des boucles :
- la dépendance scalaire sortante d'une boucle;
- la dépendance scalaire inter-itérations;
- la dépendance scalaire intra-bloc qui se décline en deux variantes : la
  lecture réutilisée (une valeur chargée puis utilisée plusieurs fois) et les
  écritures multiples (une valeur écrite à plusieurs adresses distinctes);
- la dépendance scalaire étendue.

Le @ex:array_reg_to_mem présente ces différents types de structures de
dépendances ainsi que l'impact de l'application de notre passe sur l'IR.

#[
  #show figure: set block(breakable: true)
  #show raw.where(block: true): it => block(breakable: false, it)
  #figure(
    fig.kokkosvisibility-arrayreg2mem,
    caption: [Liste de transformations de dépendances scalaires vers des accès
      mémoire explicites, appliquées par la passe `ArrayReg2MemPass`.],
  )<ex:array_reg_to_mem>
]


En définitive, l'application de la passe `ArrayReg2MemPass` s'avère essentielle
pour lever les verrous structurels induits par les abstractions de Kokkos. En
remplaçant ces dépendances scalaires artificielles par des accès mémoire
explicites, cette transformation affranchit l'ordonnanceur polyédrique de
contraintes de séquencement superflues. Elle rend ainsi possible l'optimisation
de codes qui, autrement, auraient été bridés par la présence de fausses
dépendances.

=== Délinéarisation <sec:kokkosvisibility:delinearization>

Afin de construire le domaine d'exécution, le modèle polyédrique doit
impérativement reconstruire une représentation multidimensionnelle exacte des
accès mémoire, exprimée sous forme de fonctions affines des itérateurs sur
chaque dimension, à partir des calculs de pointeurs linéarisés, présents sous
forme polynomiale dans l'IR. Polly se base pour cela sur l'analyse d'évolution
scalaire (*Scalar Evolution*, SCEV) de LLVM, qui modélise l'évolution des
adresses d'accès via une chaîne récursive d'additions (*AddRec*) indexée par les
compteurs de boucle. La délinéarisation repose ensuite sur une division
itérative de l'expression d'accès par les tailles des dimensions successives du
tableau (@sec:scientificbackground:delinearization).

Dans le cas d'un accès complet impliquant l'ensemble des dimensions (par exemple
`A[i][j][k]`, pour des éléments de 8 octets), la SCEV produit une expression
polynomiale imbriquée (voir @fig:kokkosvisibility:scev_failure_full[figure]).
L'algorithme standard de délinéarisation décompose ensuite ce polynôme via des
divisions successives par les tailles respectives des dimensions afin de
recouvrer les indices affines canoniques `[i][j][k]`.

Cependant, cette heuristique algébrique présente une faille structurelle majeure
lorsqu'elle est confrontée à des accès dont certains indices sont statiquement
évalués à zéro (par exemple, `A[0][j][k]`). Dans une telle configuration,
l'indice de la dimension externe étant nul (`i = 0`), le terme polynomial
contenant la taille de la dimension (`%n`) s'annule lors des simplifications
algébriques opérées par LLVM (voir
@fig:kokkosvisibility:scev_failure_partial[figure]). L'expression SCEV
résultante ne contenant plus cette taille intermédiaire, le solveur s'avère
incapable de la déduire par factorisation. Cette perte d'information génère des
accès mémoire ambigus : un même pointeur peut alors être interprété avec un
nombre variable de dimensions selon le motif d'accès étudié.

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
SCoP, les accès mémoire reconstruits correspondent fidèlement à la sémantique
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
        caption: [Sélection fine et individualisée du backend par noyaux
          Kokkos.],
      )<fig:kokkosvisibility:backendchoise_kokkos>
    ],
  ),
  caption: [Comparaison de la sélection du modèle d'exécution entre l'approche
    globale monolithique de Polly et l'approche fine par noyau de Kokkos.],
  label: <fig:kokkosvisibility:backendchoise>,
)

Afin de s'affranchir de cette contrainte globale, l'indicateur `-polly-parallel`
étant désormais ignoré par notre chaîne de compilation, un nouveau mécanisme de
contrôle à grain fin a été introduit. Par l'intermédiaire du système
d'annotations décrit à la @sec:kokkosvisibility:annotations, c'est désormais
chaque noyau Kokkos qui informe explicitement le compilateur de son architecture
matérielle cible et qui définit si le SCoP correspondant doit être exécuté en
parallèle. Notre implémentation permet actuellement de cibler trois
environnements d'exécution distincts : *Serial* (exécution séquentielle),
*OpenMP* et *CUDA*. La génération de code pour l'architecture CUDA, qui n'existe
pas nativement au sein de Polly, a nécessité une intégration spécifique qui est
détaillée à la @sec:schedulingheterogeneous:ppcg.

Grâce à ces informations contextuelles, Polly acquiert la capacité d'isoler et
d'adapter sa stratégie de transformation pour chaque SCoP de manière
indépendante. Contrairement au comportement natif de Polly, cette
synchronisation autorise la cohabitation, au sein d'un même binaire, de noyaux
spécifiquement optimisés pour des architectures distinctes. Ce couplage préserve
ainsi l'un des engagements fondamentaux de Kokkos : l'intégrité et la
portabilité des performances.

Néanmoins, si cette infrastructure permet d'optimiser efficacement des noyaux
réguliers et isolés, le traitement d'algorithmes plus complexes soulève de
nouveaux défis pour l'optimisation polyédrique. D'une part, Polly doit être
capable de traiter les nids de boucles triangulaires. D'autre part, lorsque les
calculs sont fragmentés en de multiples appels consécutifs à la fonction
`parallel_for`, le compilateur ne conserve qu'une vision locale de chaque
portion du noyau, ce qui entrave l'application de transformations inter-noyaux.
Nous détaillons au chapitre suivant (@sec:complexexecutionpatterns) les
extensions conçues pour surmonter ces verrous et étendre notre approche à ces
motifs d'exécution complexes.
