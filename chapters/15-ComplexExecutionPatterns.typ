#import "../src/common.typ": *

= Motifs d'exécution complexes <sec:complexexecutionpatterns>

Le @sec:kokkosvisibility précédent a présenté la mise en place du pipeline de
compilation, permettant d'extraire et de modéliser les informations
structurelles nécessaires à l'application de transformations polyédriques sur
des noyaux de calcul simples écrits avec Kokkos.

Toutefois, de nombreux algorithmes réels présentent des schémas d'exécution plus
complexes qui résistent à cette première approche. D'une part, les boucles
triangulaires, courantes dans le calcul scientifique, échouent à être
correctement détectées et modélisées par Polly en raison de l'introduction de
branchements irréguliers lors de leur abaissement dans la représentation
intermédiaire. D'autre part, les algorithmes nécessitant plusieurs étapes de
calcul imposent d'enchaîner de multiples appels consécutifs à la fonction
`parallel_for`. Cette fragmentation structurelle empêche le compilateur
d'acquérir une vision globale du noyau de calcul, restreignant ainsi
l'application de transformations inter-noyaux optimales telles que la fusion de
boucles.

Ce chapitre propose les solutions pour étendre l'applicabilité du modèle
polyédrique à ces motifs complexes. Dans un premier temps, la
@sec:complexexecutionpatterns:triangularloop détaille les défis liés aux nids de
boucles triangulaires et introduit une technique d'épluchage statique de boucle
pour régulariser le flot de contrôle. Dans un second temps, la
@sec:complexexecutionpatterns:globalloopvision aborde la problématique de la
fragmentation des noyaux et décrit les mécanismes développés pour réunifier les
noyaux de calcul en un seul `parallel_for` ainsi que la représentation
intermédiaire associée. Enfin, nous introduisons une méthode permettant de
transmettre des informations sémantiques explicites au modèle polyédrique sous
forme de contraintes, afin de consolider l'analyse inter-noyaux.

== Boucles triangulaires <sec:complexexecutionpatterns:triangularloop>

Les boucles triangulaires constituent un motif d'exécution fondamental et
récurrent dans les applications de calcul scientifique, notamment dans les
algorithmes d'algèbre linéaire. Elles se caractérisent par des boucles
imbriquées dont les bornes d'itération internes dépendent directement des
variables d'induction des boucles englobantes. Par exemple, la
@fig:complexexecutionpatterns:trisolv illustre le noyau de résolution de système
triangulaire (*trisolv*) implémenté en Kokkos. Dans ce noyau, la boucle interne
sur l'indice `j` a pour borne supérieure l'itérateur `i` de la boucle externe.
Ainsi, l'espace d'itération interne évolue dynamiquement à chaque étape de la
boucle externe, décrivant un espace de forme triangulaire.

#figure(
  ```cpp
  void function(Kokkos::View<"L", float **> L,
                Kokkos::View<"x", float *> x,
                Kokkos::View<"b", float *> b,
                size_t n) {
    auto policy = Kokkos::RangePolicy<OpenMP>(0, n);

    Kokkos::parallel_for<usePolyOpt>(
        policy, KOKKOS_LAMBDA(const size_t i) {
          x(i) = b(i);                        // Stmt1
          for (size_t j = 0; j < i; j++)
            x(i) -= L(i, j) * x(j);           // Stmt2
          x(i) = x(i) / L(i, i);              // Stmt3
        });
  }
  ```,
  caption: [Exemple de code Kokkos présentant un motif de boucle triangulaire
    (noyau *trisolv*).],
) <fig:complexexecutionpatterns:trisolv>

Bien que ce motif soit sémantiquement simple, son analyse par les compilateurs
s'avère complexe. En associant ces boucles aux abstractions de Kokkos, la
linéarité apparente des accès mémoire se perd au niveau de la représentation
intermédiaire, empêchant directement la détection de telles régions par le
modèle polyédrique.

=== Problèmes liés à la représentation intermédiaire

L'implémentation de ces boucles triangulaires pose un défi majeur lors de
l'abaissement en représentation intermédiaire LLVM vis-à-vis de l'analyse
polyédrique. La @fig:complexexecutionpatterns:trisolv_ir illustre le graphe de
flot de contrôle et l'IR LLVM simplifié générés par le compilateur pour le noyau
trisolv (@fig:complexexecutionpatterns:trisolv).

#figure(
  fig.complexexecutionpatterns-trisolvissue,
  caption: [Représentation simplifiée en IR LLVM du noyau *trisolv*
    (@fig:complexexecutionpatterns:trisolv).],
) <fig:complexexecutionpatterns:trisolv_ir>

Lors du processus de compilation, un branchement conditionnel est inséré dans le
bloc de base `for.body1` afin d'ignorer la première itération de la boucle
interne (lorsque $i=0$), l'espace d'itération de l'itérateur $j$ étant alors
vide. L'insertion de ce branchement autorise le compilateur à optimiser les
accès au tableau $L$ en extrayant un décalage invariant (`%gap_L`) pour la
boucle $j$. Par conséquent, le bloc de convergence `for.body1.exit` doit traiter
deux cas de figure distincts : si l'itérateur `%i` est égal à 0, l'accès à $L$
s'effectue avec un décalage statique nul et dans le cas contraire, il s'opère
avec le décalage constant `%gap_L`.

Lorsque la phase de détection de Polly examine ces accès mémoire, elle s'appuie
sur l'analyse de l'évolution scalaire (SCEV) de LLVM. Pour l'accès `L(i, i)`
situé dans le bloc `for.body1.exit`, l'analyse produit l'évolution scalaire de
LLVM suivante :
$
  ((8 * "%gap_L") + {0,+,8}"<%for.body1>")
$
où `%gap_L` représente la distance en mémoire entre deux lignes consécutives du
tableau $L$.

L'apparition de la variable `%gap_L` dans l'expression de l'accès mémoire est
perçue comme un scalaire opaque par la passe d'analyse SCEV. À ce stade de la
compilation, Polly est dans l'incapacité de déduire que `%gap_L` constitue en
réalité une combinaison linéaire de la taille de la dimension interne du tableau
$L$ (une propriété qui ne sera démontrée que lors de l'étape ultérieure
`ScopInfo`) et de l'itérateur `%i`. Afin de garantir la validité et la sûreté de
ses transformations, Polly adopte une approche conservative et rejette cet accès
qu'il classifie comme non affine. Cette décision entraîne inéluctablement le
rejet de la région entière, empêchant de fait l'application de toute
optimisation polyédrique.

Afin de pallier cette limitation inhérente sans nécessiter de modification
profonde de l'architecture de détection de Polly, et pour neutraliser d'autres
structures d'IR susceptibles de corrompre l'analyse, nous avons introduit une
passe d'épluchage statique de boucle en amont du processus de détection des
SCoP.


=== Épluchage statique de boucles

L'épluchage de boucle (ou *loop peeling*) est une technique d'optimisation
consistant à extraire une ou plusieurs itérations spécifiques en début ou en fin
d'exécution, hors de la boucle principale. L'objectif est d'isoler un
comportement marginal pour régulariser l'espace d'itération restant.

Afin de pallier les irrégularités induites par les boucles triangulaires, cette
technique est mise à profit au travers d'une passe de transformation dédiée. Son
rôle est d'analyser la représentation intermédiaire (IR) pour cibler et éliminer
systématiquement les branchements parasites du flot de contrôle. Le processus
s'articule autour de trois étapes majeures :
- la détection des boucles triangulaires,
- le calcul du nombre d'itérations à éplucher pour chaque boucle,
- la simplification des conditions résiduelles.

==== Détection des nids de boucles triangulaires
L'identification d'une boucle triangulaire s'appuie sur l'analyse de l'évolution
scalaire de LLVM (SCEV). Le compilateur évalue le nombre d'itérations garanties
pour la boucle interne, appelé Backedge Taken Count (BETC). Dans le cas d'une
boucle rectangulaire classique, cette valeur est invariante par rapport à la
boucle externe. À l'inverse, si le compilateur détecte que l'expression SCEV du
BETC dépend de la variable d'induction de la boucle englobante (exprimée par
exemple sous la forme d'une récurrence `AddRec`), la boucle est formellement
identifiée comme triangulaire.

De manière générale, on distingue deux grands types de boucles triangulaires en
fonction de l'évolution de l'espace d'itération interne. L'analyse SCEV du BETC
permet d'identifier formellement ces deux profils et d'en déduire à la fois la
stratégie d'épluchage adéquate et le nombre exact d'itérations à extraire :
- *Triangulaire croissante* (épluchage par l'avant ou *front peeling*) : La
  taille de la boucle interne augmente avec l'itérateur externe. L'expression
  SCEV du BETC prend la forme d'une récurrence à pas positif
  `{Start, +, Step}<%for.i>`. Si l'évaluation de cette expression pour la
  première itération (la valeur `Start`) est strictement négative, le corps de
  la boucle interne ne s'exécute pas initialement. Un épluchage par l'avant est
  alors requis pour extraire l'ensemble des premières itérations. Le nombre
  exact d'itérations à éplucher correspond au nombre de pas nécessaires pour
  atteindre un décompte positif ou nul.
- *Triangulaire décroissante* (épluchage par l'arrière ou *back peeling*) : À
  l'inverse, la taille de la boucle interne diminue à mesure que l'itérateur
  externe avance. Le BETC se traduit par une expression avec un pas négatif
  `{Start, +, -Step}<%for.i>`. Le nombre d'itérations internes décroît jusqu'à
  s'annuler puis devenir négatif vers la fin de l'espace d'itération englobant,
  ce qui nécessite un épluchage par l'arrière. Le nombre d'itérations à éplucher
  est déterminé en calculant d'abord le nombre d'itérations où la boucle interne
  s'exécute effectivement. Ce nombre d'itérations pleines est ensuite soustrait
  au nombre total d'itérations de la boucle englobante pour obtenir exactement
  le nombre d'itérations à éplucher.

Cette méthode analytique permet de caractériser complètement les boucles à
traiter et d'éliminer de façon ciblée les itérations non exécutées du corps
principal.


==== Epluchage de boucles
L'étape d'analyse précédente permet de recenser toutes les boucles triangulaires
et de déterminer le nombre d'itérations à éplucher requis pour chacune d'entre
elles. Néanmoins, un noyau de calcul peut encapsuler plusieurs boucles internes
triangulaires distinctes. Il est alors fréquent que plusieurs d'entre elles
requièrent l'épluchage de la même boucle englobante, avec des nombres
d'itérations potentiellement différents en amont ou en aval de la boucle.

Pour consolider ces requêtes, la passe génère un plan d'épluchage. Pour chaque
boucle externe ciblée et chaque direction (en amont ou en aval), le compilateur
calcule la borne supérieure des requêtes en retenant le nombre maximum
d'itérations à éplucher. Cette approche garantit que la boucle englobante
restante sera totalement purgée de ses itérations mortes, satisfaisant ainsi les
contraintes de toutes les boucles internes qu'elle contient.

Une fois ce plan d'épluchage fusionné, la modification de l'IR est appliquée via
la passe `peelLoop` native de LLVM. Une étape supplémentaire est toutefois
nécessaire pour l'épluchage en fin de boucle. En effet, lors de l'extraction par
LLVM, les instructions du bloc épluché conservent leurs liens avec la variable
d'induction d'origine (par exemple via un noeud `%i.peeled = phi [%i, %for.end]`
ou l'on utilise `%i` de la boucle originale comme valeur de départ de la
nouvelle boucle épluchée). Pour isoler totalement ce bloc, notre passe remplace
manuellement toutes les utilisations de l'ancien itérateur de la boucle
originale par une constante dépendante de la borne de la boucle (par exemple
`N-2`), puisque l'on connaît statiquement la valeur exacte de l'initialisation
du nouvel itérateur pour briser toute fausse dépendance entre les deux boucles.

==== Régularisation du flot de contrôle
La simple extraction matérielle des itérations rend théoriquement certaines
conditions de garde obsolètes. Bien que les passes de simplification standards
de LLVM, exécutées en aval, puissent en résoudre une partie, elles ne
parviennent pas systématiquement à détruire toutes les comparaisons générées par
l'abaissement en IR. Afin de garantir formellement que la boucle résultante sera
parfaitement analysable par le modèle polyédrique, une étape de nettoyage manuel
est appliquée.

Cette intervention anticipée élimine définitivement les gardes conditionnelles
parasites inhérentes aux boucles triangulaires. Le graphe de flot de contrôle
redevient ainsi parfaitement régulier, résolvant de fait les problèmes
précédents liés aux accès mémoire non linéaires. Cette régularisation autorise
enfin la modélisation complète du noyau Kokkos par Polly.

L'impact de cette transformation est directement visible sur l'évolution du
graphe de flot de contrôle : la structure initiale, illustrée par
@fig:complexexecutionpatterns:trisolvbefore, est ainsi convertie en une forme
parfaitement régulière sans optimisation local cassant la détection, comme le
montre @fig:complexexecutionpatterns:trisolvafter, la rendant compatible avec
les analyses et transformations polyédriques de Polly.

#subpar.super(
  grid(
    columns: 2,
    rows: 1,
    inset: 0.5cm,
    align: bottom,
    [
      #figure(
        image(fig.complexexecutionpatterns-trisolvbefore, width: 80%),
        caption: [Avant l'épluchage de boucle],
      ) <fig:complexexecutionpatterns:trisolvbefore>
    ],
    [
      #figure(
        image(fig.complexexecutionpatterns-trisolvafter, width: 80%),
        caption: [Après l'épluchage de boucle],
      ) <fig:complexexecutionpatterns:trisolvafter>
    ],
  ),
  caption: [Évolution du graphe de flot de contrôle du noyau *trisolv* suite à
    la passe d'épluchage statique.],
  label: <fig:complexexecutionpatterns:triangularlooppeeling>,
)


== Vision Globale des Boucles <sec:complexexecutionpatterns:globalloopvision>

Pour optimiser les performances de certains noyaux, le modele polyédrique peut
avoir besoin d'appliquer des tranformation inter-noyaux. L'un d'elle est la
fusion de boucle, généralement appliqué lorsque des noyaux successifs accède aux
même données avec des dépendances de données inter-noyaux. Pour y parvenir,
l'optimiseur doit être en mesure de capturer l'intégralité du contexte de calcul
au sein d'un SCoP.

Cependant, l'application du modèle polyédrique sur des codes Kokkos se heurte à
une incompatibilité fondamentale de conception. Alors que le modèle polyédrique
nécessite une vue globale et unifiée du flux d'instructions pour appliquer des
transformations efficaces, l'approche standard de Kokkos favorise l'isolation.
En effet, la représentation de noyaux complexes contraint chaque nid de boucles
à être encapsulé dans un appel distinct à un `parallel_for`. Cette fragmentation
structurelle limite Polly à une vision locale de chaque noyau, empêchant de fait
toute optimisation inter-noyaux.

La @code:complexexecutionpatterns:kokkosgemver illustre ce problème de
conception à travers l'implémentation du noyau `gemver` réécrit avec Kokkos. On
constate que la logique algorithmique globale est nécessairement fragmentée en
quatre sous-noyaux distincts.


#figure(
  ```cpp
  const auto policy_1D = Kokkos::RangePolicy<Kokkos::OpenMP>(0, n);
  const auto policy_2D = Kokkos::MDRangePolicy<Kokkos::OpenMP,
                                               Kokkos::Rank<2>>({0, 0}, {n, n});

  Kokkos::parallel_for(
      policy_2D, KOKKOS_LAMBDA(const INT_TYPE i, const INT_TYPE j) {
        A(i, j) += u1(i) * v1(j) + u2(i) * v2(j);
      });

  Kokkos::parallel_for(
      policy_1D, KOKKOS_LAMBDA(const INT_TYPE i) {
        for (INT_TYPE j = 0; j < n; j++)
          x(i) += beta * A(j, i) * y(j);
      });

  Kokkos::parallel_for(
      policy_1D, KOKKOS_LAMBDA(const INT_TYPE i) {
        x(i) += z(i);
      });

  Kokkos::parallel_for(
      policy_1D, KOKKOS_LAMBDA(const INT_TYPE i) {
        for (INT_TYPE j = 0; j < n; j++)
          w(i) += alpha * A(i, j) * x(j);
      });
  ```,
  caption: [Implémentation du noyau `gemver` en Kokkos, illustrant la
    fragmentation en de multiples appels à `parallel_for`.],
) <code:complexexecutionpatterns:kokkosgemver>

Pour pallier cette limitation et fournir à Polly une vision globale d'un noyau
de calcul fragmenté, nous avons conçu un nouveau `parallel_for` permettant de
donner plusieurs noyaux ainsi qu'un pipeline spécifique de traitement de l'IR
pour reconstruire un seul et unique SCoP.


=== Nouveau `parallel_for` variadique

Dans l'intégration de Polly avec Kokkos, la granularité de détection des SCoPs
se limite au périmètre d'un appel unique à la fonction `parallel_for`. Pour
étendre cette analyse à une séquence de noyaux, il est nécessaire que
l'optimiseur puisse englober plusieurs de ces appels sans rencontrer
d'instructions susceptibles d'interrompre la détection de la région affine. Afin
de garantir cette détection et de générer un code intermédiaire structuré et
prévisible, nous avons conçu une version variadique de la fonction
`parallel_for`.

En exploitant les capacités de métaprogrammation du C++, cette implémentation
variadique (illustrée par @code:complexexecutionpatterns:variadicparallelfor)
permet d'accepter une séquence de paires `(Policy, Functor)`. Lors de la
compilation, une fonction lambda est instanciée pour chaque paire, et ces
lambdas sont ensuite invoquées séquentiellement.

#figure(
  ```cpp
  template <class... FunctorTypes>
  __attribute__((noinline, annotate("multi_parallel_for")))
  void call_for_parallel_for(FunctorTypes... funcs) {
    (funcs(), ...);
  }

  template <bool Polly,
            class... Args,
            std::size_t... Is>
  inline void parallel_for_impl(const std::string& str,
                                const std::tuple<Args...>& args_tuple,
                                std::index_sequence<Is...>) {
    call_for_parallel_for(
        (Kokkos::Impl::construct_with_shared_allocation_tracking_disabled<
             Impl::ParallelFor<
                 std::tuple_element_t<2 * Is + 1, std::tuple<Args...>>,
                 std::tuple_element_t<2 * Is, std::tuple<Args...>>>>(
             std::get<2 * Is + 1>(args_tuple), std::get<2 * Is>(args_tuple))
             .template getExecute<Polly>())...);
  }

  template <bool Polly = false,
            class... Args,
            class Enable = std::enable_if_t<(sizeof...(Args) > 0 &&
                                             sizeof...(Args) % 2 == 0)>
                                           >
  inline void parallel_for(const std::string& str, const Args&... args) {
    static_assert(sizeof...(Args) > 0,
                  "parallel_for requires at least one policy/functor pair.");
    static_assert(sizeof...(Args) % 2 == 0,
                  "parallel_for requires an even number of arguments "
                  "(policy/functor pairs).");

    Impl::parallel_for_impl<Polly, StrAssumption>(
        str, std::make_tuple(args...),
        std::make_index_sequence<sizeof...(Args) / 2>{});
  }

  ```,
  caption: [Nouvelle signature de `parallel_for` avec le paramètre
    `usePolyOpt`.],
) <code:complexexecutionpatterns:variadicparallelfor>


Statiquement, le compilateur génère pour chaque noyau de calcul une lambda
annotée (grâce à `getExecute` implémenté dans chaque backend) avec les
annotations nécessaires au modèle polyédrique
(@sec:kokkosvisibility:kokkosannotations), selon sa politique d'exécution.
L'ensemble de ces lambdas, qui représente la globalité du calcul, est appelé
séquentiellement grâce à `call_for_parallel_for` en s'affranchissant de
structures de contrôle complexes susceptibles de perturber l'analyse de Polly
grâce aux *fold expressions* du C++. Cette conception offre un point d'entrée
unique et transparent pour l'utilisateur. Elle permet en outre de délimiter
l'intégralité du calcul au sein d'une seule portion d'IR, bornée par un appel de
fonction LLVM spécifique annoté par un attribut de fonction.

Grâce à cette nouvelle implémentation, un noyau complexe tel que `gemver`
(@code:complexexecutionpatterns:kokkosgemver) peut être réécrit de manière
unifiée, comme le montre @code:complexexecutionpatterns:kokkosgemveravariadic.
Un unique appel au `parallel_for` variadique suffit désormais pour écrire
l'ensemble du noyau.

#figure(
  ```cpp
  const auto policy_1D = Kokkos::RangePolicy<Kokkos::OpenMP>(0, n);
  const auto policy_2D = Kokkos::MDRangePolicy<Kokkos::OpenMP,
                                               Kokkos::Rank<2>>({0, 0}, {n, n});

  Kokkos::parallel_for<Kokkos::usePolyOpt>("gemver",
    policy_2D, KOKKOS_LAMBDA(const INT_TYPE i, const INT_TYPE j) {
      A(i, j) += u1(i) * v1(j) + u2(i) * v2(j);
    },
    policy_2D, KOKKOS_LAMBDA(const INT_TYPE i, const INT_TYPE j) {
      x(i) += beta * A(j, i) * y(j);
    },
    policy_1D, KOKKOS_LAMBDA(const INT_TYPE i) {
      x(i) += z(i);
    },
    policy_2D, KOKKOS_LAMBDA(const INT_TYPE i, const INT_TYPE j) {
      w(i) += alpha * A(i, j) * x(j);
    });
  ```,
  caption: [Implémentation du noyau `gemver` en Kokkos, illustrant le
    regroupement en un unique appel au `parallel_for` variadique.],
) <code:complexexecutionpatterns:kokkosgemveravariadic>

Cependant, le simple regroupement des noyaux au niveau du code source ne suffit
pas. L'IR LLVM générée initialement demeure fragmentée en raison des multiples
lambdas. Il est donc indispensable d'appliquer une série de transformations
spécifiques sur cette IR afin que Polly puisse l'interpréter comme un unique
SCoP.

==== Linéarisation du flot de contrôle

La nouvelle implémentation présentée dans la section précédente permet à
l'utilisateur de regrouper plusieurs noyaux en un seul appel à la fonction
Kokkos `parallel_for`. Cette approche permet de regrouper physiquement les
noyaux dans l'IR, mais ne suffit pas à elle seule pour garantir la
reconnaissance de l'ensemble de ces noyaux comme un unique SCoP. En effet, lors
de la compilation, LLVM traite chaque noyau individuellement et construit l'IR
associée. Chaque noyau s'accompagne alors de ses propres chargements mémoire
(bornes de boucles, pointeurs de tableaux, paramètres, etc.), des instructions
qui s'intercalent entre les régions de calcul et brisent l'analyse polyédrique
de Polly. La @code:complexexecutionpatterns:cfglinearizationbefore illustre le
graphe de flot de contrôle de l'IR pour deux noyaux de calcul exécutées via le
`parallel_for` variadique. On y observe que les boucles sont séparées par le
block `Preheader B`.

Dans un flot de compilation standard, le regroupement des noyaux n'apporte pas
de gain de performance direct, par conséquent, le compilateur ne réalise aucune
transformation spécifique visant à les fusionner. Cependant, notre
implémentation du `parallel_for` variadique offre de fortes garanties
structurelles. Grâce aux annotations, à la régularité imposée par l'appel
variadique, et à l'impossibilité pour l'utilisateur d'insérer des instructions
entre les noyaux, nous sommes en mesure d'opérer une véritable fusion des noyaux
Kokkos directement au niveau de la représentation intermédiaire en remontant les
blocs d'instructions problématiques au dessus du SCoP global.

@code:complexexecutionpatterns:cfglinearizationafter présente l'IR après
l'application de cette passe de transformation. Le bloc `Preheader B` a été
déplacé pour être exécuté juste après le `Preheader A` et avant la boucle
`Loop A`. L'indépendance initiale des noyaux et la propriété SSA de l'IR
garantissent que les variables manipulées sont indépendantes. Ces blocs peuvent
ainsi être déplacés sans risquer de corrompre la sémantique du programme.

#subpar.super(
  grid(
    columns: (1fr, 1fr),
    align: bottom + center,
    [
      #figure(
        fig.complexexecutionpatterns-moveblocksbefore,
        caption: [Flot de contrôle initial fragmenté en multiples SCoPs.],
      ) <code:complexexecutionpatterns:cfglinearizationbefore>
    ],
    [
      #figure(
        fig.complexexecutionpatterns-moveblocksafter,
        caption: [Flot de contrôle linéarisé formant un unique SCoP.],
      ) <code:complexexecutionpatterns:cfglinearizationafter>
    ],
  ),
  caption: [Transformation de l'IR illustrant la linéarisation du flot de
    contrôle et la fusion des noyaux.],
  label: <code:complexexecutionpatterns:cfglinearization>,
)

Grâce à cette transformation, Polly est en mesure de reconnaître l'ensemble des
noyaux fusionnés comme un seul et unique SCoP. Toutefois, le modèle
d'abstraction de Kokkos pose une dernière difficulté : il empêche Polly
d'identifier correctement les paramètres du modèle (bornes de boucles, tableaux,
etc.). En effet, chaque valeur du code source fait l'objet d'un chargement
mémoire distinct pour chaque noyau du à la capture par lambda des noyaux,
conduisant à la création de multiples variables SSA différentes pour une même
variable logique. Les sections suivantes exposent les méthodes déployées pour
résoudre ce problème.

=== Nommage statique des tableaux <sec:complexexecutionpatterns:staticarraysnaming>

L'encapsulation d'un noyau de calcul au sein de plusieurs lambdas C++ engendre
un problème majeur pour l'analyse globale de la mémoire : la duplication des
pointeurs capturés. Lorsqu'un même tableau logique (représenté par une `View`
Kokkos) est accédé par plusieurs noyaux successifs, chaque lambda capture ses
propres variables. Au niveau de la représentation intermédiaire, le compilateur
traduit ces captures par la création de variables SSA distinctes pour chaque
noyau. Par conséquent, bien que deux noyaux manipulent la même zone mémoire,
l'IR présente des variables de pointeurs différentes. Cette divergence empêche
Polly de construire un modèle cohérent des dépendances de données, compromet
l'ordonnancement efficace des noyaux et introduit de faux problèmes d'aliasing à
l'exécution, invalidant ainsi les vérifications dynamiques d'exécution.

Pour pallier ce problème, nous avons étendu l'API `View` de Kokkos en
introduisant un mécanisme de nommage statique. Contrairement aux chaînes de
caractères utilisées dynamiquement pour le débogage (les `label` standards de
Kokkos), ce nommage statique est intégré directement dans la signature du type
de la vue par l'intermédiaire d'un paramètre template. L'implémentation de cette
fonctionnalité s'appuie sur la structure `ConstExprLabel`, présentée par la
@code:complexexecutionpatterns:constexprlabel.

#figure(
  ```cpp
  template <std::size_t N>
  struct ConstExprLabel {
    char value[N];

    constexpr ConstExprLabel(const char (&str)[N]) {
      for (std::size_t i = 0; i < N; ++i)
        value[i] = str[i];
    }

    constexpr std::string_view view() const {
      return std::string_view(value, N - 1);
    }

    constexpr auto operator<=>(const ConstExprLabel&) const = default;
  };

  template <ConstExprLabel Label, class DataType, class... Properties>
  class View;
  ```,
  caption: [Définition de la structure `ConstExprLabel` permettant l'intégration
    de chaînes de caractères statiques dans les paramètres de _template_ d'une
    `View`.],
) <code:complexexecutionpatterns:constexprlabel>

La structure `ConstExprLabel` exploite les fonctionnalités introduites par la
norme C++20, autorisant l'instanciation de chaînes de caractères littérales dès
la phase de compilation. Ainsi, chaque vue instanciée acquiert un type unique,
défini non seulement par le type de ses éléments (`DataType`), mais également
par l'identifiant statique qui lui est associé. Par exemple, la déclaration
suivante illustre la création d'une vue bidimensionnelle nommée statiquement
`"A"` :

```cpp
Kokkos::View<"A", float **> A(n, n);
```

Grâce à cette intégration au sein même de la signature du type de la donnée, le
nom d'un tableau peut être déterminé statiquement en inspectant son type. Ainsi,
lors de chaque accès mémoire effectué via Kokkos, une annotation est générée
pour exposer non seulement le pointeur et les dimensions du tableau, mais
également ce nom statique. L'analyse de ces annotations permet dès lors
d'identifier les tableaux partageant un identifiant commun au sein de l'IR.
L'égalité de ces noms statiques est une garantie de l'utilisateur que les vues
partagent à la fois le même pointeur de données et les mêmes dimensions.

Une fois ces équivalences établies, nous appliquons une transformation globale
sur l'IR en tirant parti de la méthode de remplacement de LLVM : Replace All
Uses With (RAUW). Les références aux pointeurs dupliqués dans les noyaux
ultérieurs sont systématiquement remplacées par le pointeur originel capturé
lors de la première occurrence du tableau. Cette unification des variables SSA
permet non seulement d'éliminer les redondances dans l'IR, mais aussi
d'éradiquer les faux positifs liés à l'aliasing. Polly dispose ainsi d'une
vision globale et parfaitement cohérente des différents accès mémoires, pour
analyse correcte du SCoP fusionné.



=== Injection de contraintes <sec:complexexecutionpatterns:assumptions>

Bien que la représentation intermédiaire soit dorénavant unifiée au sein d'un
seul SCoP, les politiques d'exécution indépendantes conservent leurs propres
copies locales des variables définissant les bornes de boucle. Statiquement, il
est donc impossible de déduire depuis l'IR que ces différentes variables sont
identiques dans le code source, ce qui empêche leur fusion dans l'IR. Afin que
l'optimiseur puisse identifier que les bornes de différentes boucles sont
identiques ou strictement liées (pour permettre la fusion, par exemple), il est
nécessaire que l'utilisateur fournisse des contraintes explicites à Polly pour
permettre d'interpréter correctement les relations entre les bornes des
différentes boucles. Ce mécanisme, que nous appelons système de contraintes
(assumptions), permet de compenser la perte d'informations sémantiques induite
par la structure interne de Kokkos.

Pour injecter ces informations au niveau du modèle, le système de contraintes
repose sur un argument template optionnel de la fonction `parallel_for`,
positionné à la suite du paramètre `usePolyOpt`. La
@fig:complexexecutionpatterns:parallel_for illustre l'implémentation permettant
de construire et de transmettre statiquement la chaîne de caractères contenant
ces contraintes, en se basant sur la structure `StringAssumption`.

#figure(
  ```cpp
  template <std::size_t N>
  struct StringAssumption {
    constexpr StringAssumption(const char (&str)[N]) {
      std::copy_n(str, N, value);
    }
    char value[N];
  };

  template <bool usePolyOpt = false,
            StringAssumption StrAssumption = "",
            class ExecPolicy,
            class FunctorType,
            class Enable = std::enable_if_t<is_execution_policy<ExecPolicy>::value>
           >
  inline void parallel_for(const std::string& str, const ExecPolicy& policy,
                           const FunctorType& functor);

  template <bool Polly = false,
            StringAssumption StrAssumption = "",
            class... Args,
            class Enable = std::enable_if_t<(sizeof...(Args) > 0 &&
                                             sizeof...(Args) % 2 == 0)>
                                           >
  inline void parallel_for(const std::string& str, const Args&... args);
  ```,
  caption: [Implémentation de l'injection statique des chaînes de contraintes
    (*assumptions*) dans les fonctions de Kokkos.],
) <fig:complexexecutionpatterns:parallel_for>

Cette structure, à l'instar de la méthode employée pour le nommage des tableaux
(@sec:complexexecutionpatterns:staticarraysnaming), permet de construire une
chaîne de caractères, exploitable dès la phase de compilation. Par exemple,
l'utilisation de ce paramètre s'illustre de la façon suivante :

```cpp
Kokkos::parallel_for<Kokkos::usePolyOpt, "p0.l0 == 0">(...);
```

Afin de transmettre l'information contenue dans cette chaîne de caractères à
l'optimiseur Polly, nous nous appuyons sur le système d'annotation présenté dans
la @sec:kokkosvisibility:annotations. Grâce à ce mécanisme, le noyau est annoté
dans l'IR. Cette annotation textuelle est ensuite directement extraite et
traduite en contraintes réelles par notre passe de transformation.

Cette manipulation de contraintes est largement utilisée dans le domaine
polyédrique car elle permet de définir simplement des polyèdres. La section
suivante présente la grammaire de contraintes que nous utilisons pour
contraindre les SCoPs à interpréter différentes variables comme une variable
unique, et ainsi améliorer l'analyse et l'optimisation polyédrique par Polly.

==== Grammaire des contraintes

Afin de formaliser ces relations, nous définissons une grammaire de contrainte
sous la forme suivante :
$ "Opérande"_G quad "Opérateur" quad "Opérande"_D $

Un opérande peut appartenir à l'une des trois catégories distinctes : une borne
de boucle issue d'une politique (*Policy Loop Bound*), une variable de boucle
interne (*Inner Loop Variable*), ou une valeur littérale (un entier constant).

La @fig:complexexecutionpatterns:constraintinjection illustre de manière
concrète l'application de cette syntaxe au sein d'un code source. Dans cet
exemple, la contrainte `"p0.u0 == n"` est injectée directement en argument du
noyau `parallel_for` afin d'indiquer que la borne supérieure de la politique du
premier et unique noyau est égale à la variable `n`. De plus, la macro
`KOKKOS_LOOP_BOUND(n)` est utilisée pour exposer explicitement la borne de la
boucle interne à l'analyse.

#figure(
  ```cpp
  void function(Kokkos::View<"x", float *> &x,
                Kokkos::View<"b", float *> &b,
                Kokkos::View<"L", float **> &L, size_t n) {
    auto policy = Kokkos::RangePolicy<OpenMP>(0, n);

    Kokkos::parallel_for<usePolyOpt, "p0.u0 == n">(
      policy, KOKKOS_LAMBDA(const size_t i) {
        tmp(i) = SCALAR_VAL(0.0);
        y(i) = SCALAR_VAL(0.0);
        for (size_t j = 0; j < KOKKOS_LOOP_BOUND(n); j++) {
          tmp(i) = A(i, j) * x(j) + tmp(i);
          y(i) = B(i, j) * x(j) + y(i);
        }
        y(i) = alpha * tmp(i) + beta * y(i);
      });
  }
  ```,
  caption: [Exemple de code avec des contraintes injectées],
) <fig:complexexecutionpatterns:constraintinjection>

*Référence aux bornes de politique.* Pour faire référence à une borne de boucle
spécifique définie par une politique d'exécution, nous utilisons la syntaxe
`pN.TM`. Dans cette notation, `N` représente l'indice de la politique dans la
séquence d'exécution ($0, 1, dots$), `T` définit le type de la borne (`l` pour
la borne inférieure ou *lower*, `u` pour la borne supérieure ou *upper*), et `M`
correspond à la dimension de la boucle ($0, 1, dots$). En pratique, cette
approche s'appuie sur le système d'annotation des bornes de boucle
(@sec:kokkosvisibility:annotations), ce qui permet de repérer de manière fiable
quelle borne correspond à quelle dimension directement dans l'IR.

*Référence aux variables de boucles internes.* Afin de cibler des variables
utilisées au sein même du corps du noyau d'exécution (`parallel_for`), nous
introduisons la macro `KOKKOS_LOOP_BOUND`. En arrière-plan, cette macro annote
les instructions avec le nom de la variable tel qu'il apparaît dans le code
source. Cette approche permet de manipuler un nom de variable depuis le code
source et de le repérer de façon fiable dans l'IR, alors que cette information
est habituellement perdue lors de la compilation. L'utilisation de cette macro
apporte un avantage supplémentaire : si deux variables partagent l'annotation
avec un nom identique dans deux noyaux du même `parallel_for`, le fonctionnement
intrinsèque de Kokkos garantit qu'elles représentent la même valeur. Elles sont
alors considérées comme identiques par l'analyse, et ce, même si l'utilisateur
n'a pas défini de contrainte explicite.

*Opérateurs et utilisation.* Les contraintes peuvent être définies à l'aide des
opérateurs de comparaison standards (`==`, `<`, `>`, `<=`, `>=`). Afin
d'appliquer ces contraintes, nous utilisons la fonction intrinsèque
`llvm.assume` de LLVM. Celle-ci permet de transmettre des informations
sémantiques directement aux passes d'optimisation de LLVM dans le but de
simplifier le code généré. Ces indications sont par ailleurs interprétées
nativement au sein du flux d'analyse de Polly.

*Réduction du temps de compilation.* Un avantage de cette approche réside dans
la réduction du temps de compilation. Les algorithmes polyédriques présentent
une complexité exponentielle vis-à-vis du nombre de paramètres présents dans le
SCoP. En fusionnant les paramètres représentant les bornes de boucle, la
dimensionnalité du système de contraintes transmis au solveur est
mathématiquement réduite, ce qui diminue considérablement le coût et la durée de
l'analyse lors de la compilation.

=== Limitations de la vision globale des noyaux

Bien que ces transformations permettent d'obtenir une vision globale et unifiée
des noyaux de calcul, elles présentent actuellement certaines limites inhérentes
à leur dépendance envers les informations fournies par l'utilisateur. En effet,
que ce soit pour le nommage statique des tableaux ou l'injection de contraintes,
le processus de compilation accorde une confiance absolue aux annotations sans
pouvoir les vérifier formellement de manière statique.

*Risques liés au nommage des tableaux.* Le mécanisme de nommage statique des
tableaux repose entièrement sur la justesse des déclarations du développeur. Il
n'existe actuellement aucune vérification lors de l'analyse polyédrique pour
s'assurer que deux vues partageant le même identifiant possèdent le même
pointeur de base et partagent les mêmes dimensions. L'utilisation d'un nom
erroné entraîne alors une fusion silencieuse de tableaux distincts au sein de
l'IR, ce qui corrompt inévitablement l'analyse des dépendances et fausse
l'exécution du programme.

*Risques liés à l'injection de contraintes.* De manière similaire, l'injection
de contraintes s'appuie inconditionnellement sur les affirmations de
l'utilisateur. Si ce dernier fournit une hypothèse erronée concernant les
relations entre les bornes de boucle, le domaine d'itération s'en trouvera
restreint de façon incorrecte lors de la modélisation mathématique, conduisant à
des transformations invalides.

*Vérification dynamique.* Pour pallier ces vulnérabilités, une perspective
d'évolution consisterait à introduire des vérifications à l'exécution. Des
assertions dynamiques valideraient que les pointeurs des tableaux fusionnés sont
bien identiques et que les bornes de boucles respectent les contraintes
définies.
