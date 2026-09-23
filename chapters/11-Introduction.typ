#import "../src/common.typ": *

= Introduction <sec:introduction>

La puissance de calcul des supercalculateurs n'a cessé d'augmenter au fil des
années, stimulée par l'évolution rapide des architectures matérielles.
Historiquement, cette progression a été alimentée par la loi de Moore à travers
l'augmentation du nombre de transistors, leur miniaturisation et l'élévation de
la fréquence d'horloge des processeurs. Toutefois, alors que les contraintes
physiques ont mis un frein à la montée en fréquence, l'industrie s'est
massivement tournée vers le parallélisme matériel, conduisant à l'adoption
généralisée d'architectures pipelinées et vectorielles, de systèmes à mémoire
partagée et distribuée, ainsi qu'à l'intégration d'accélérateurs matériels.

L'exploitation de ces architectures hétérogènes a entraîné l'émergence de
multiples paradigmes de programmation, rendant le développement de codes
scientifiques de haute performance de plus en plus complexe. Bien que des
efforts aient été déployés pour déléguer cette complexité aux compilateurs et
autres outils automatisés, l'obtention d'une optimisation et d'une
parallélisation purement automatiques sur les systèmes modernes multi-coeurs et
basés sur des accélérateurs reste un défi majeur.

Bien que les compilateurs modernes intègrent de nombreuses passes
d'optimisation, ils peinent fréquemment à appliquer efficacement des
parallélisations avancées et des transformations de boucles. Cette limitation
provient principalement du fossé sémantique entre l'intention de haut niveau du
programmeur et la représentation intermédiaire de bas niveau comprise par la
machine. Pour réduire les coûts de développement, la communauté HPC a conçu des
frameworks de portabilité des performances. Ces bibliothèques fournissent des
abstractions de haut niveau permettant aux développeurs d'exprimer explicitement
des motifs de calcul optimisés, des stratégies de parallélisation et la gestion
de la mémoire, avec la promesse de hautes performances sur diverses
architectures (CPUs, GPUs) à partir d'un code source unique et unifié.

Alors que ces frameworks facilitent grandement l'expression du parallélisme,
l'optimisation fine des nids de boucles reste un défi majeur. Le modèle
polyédrique offre une solution mathématique éprouvée pour l'optimisation des
boucles. Cette approche algébrique permet l'analyse précise des dépendances de
données et l'application de transformations complexes que les compilateurs
traditionnels peinent à réaliser. Une solution prometteuse au défi de
l'optimisation des boucles réside dans la synergie entre la puissance analytique
du modèle polyédrique et les abstractions de haut niveau des frameworks de
portabilité des performances. En faisant converger ces deux approches, il
devient possible d'optimiser et de paralléliser efficacement les codes
scientifiques sur des architectures complexes et hétérogènes.


== Compilateurs

Le compilateur sert de pont critique entre les abstractions de haut niveau
écrites par le développeur et les instructions de bas niveau exécutées par la
machine. En plus de la conversion en un fichier binaire exécutable, le
compilateur est responsable de l'application d'optimisations spécifiques.
Idéalement, un développeur pourrait s'en remettre entièrement aux heuristiques
internes et aux passes d'optimisation du compilateur pour atteindre des
performances maximales. Cependant, pour maximiser l'utilisation des ressources
matérielles pour les codes HPC intensifs en calcul, cela est rarement suffisant.

Une approche alternative consiste à effectuer des transformations et des
optimisations manuelles du code directement au niveau de la source pour aider le
compilateur. Bien qu'une optimisation manuelle bien exécutée produise souvent
des performances supérieures, elle exige une expertise significative, augmente
le temps de développement et dégrade sévèrement la maintenabilité du code. Elle
nécessite en effet que le développeur soit à la fois un scientifique du domaine
et un expert en optimisation de code de bas niveau. Pour surmonter ce goulot
d'étranglement, les frameworks de portabilité des performances offrent une
alternative permettant d'obtenir des performances sans requérir d'expertise de
développement approfondie. Ils permettent aux développeurs d'exprimer simplement
leurs noyaux de calcul, tandis que le framework gère la parallélisation, le
mapping complexe et le déploiement de ces noyaux pour maximiser les performances
sur les cibles matérielles choisies.


== Frameworks de Portabilité des Performances

Les frameworks de portabilité des performances sont fournis sous forme de
bibliothèques logicielles que les développeurs peuvent exploiter pour exprimer
le parallélisme et gérer la mémoire sur diverses architectures matérielles. Dans
le domaine du HPC, les frameworks les plus utilisés sont Kokkos, RAJA, SYCL et
le standard de parallélisme C++ (`std::par`). Ces frameworks permettent le
développement d'un code source unique pouvant être compilé pour différentes
cibles, avec la promesse de la portabilité des performances.

Cependant, ces frameworks n'effectuent pas intrinsèquement d'optimisation
automatique du code source. Ils s'appuient sur des optimisations structurelles
statiques et un parallélisme explicite sans réaliser d'analyse statique profonde
des noyaux de calcul eux-mêmes. Les performances qu'ils délivrent proviennent
principalement d'un dispatching parallèle robuste et de techniques de mapping de
bas niveau implémentées par les développeurs du framework, plutôt que d'une
restructuration agressive des boucles. En employant le modèle polyédrique, des
transformations de boucles complexes peuvent être automatiquement appliquées à
ces régions de code critiques et coûteuses en calcul pour maximiser
l'utilisation du matériel.


== Modèle Polyédrique

Le modèle polyédrique est un framework mathématique dédié à l'optimisation des
nids de boucles. Il a prouvé son efficacité dans l'optimisation de programmes
grâce à des implémentations robustes telles que Pluto, Polly et PPCG. En
exprimant les boucles d'un programme sous une forme mathématique à l'aide
d'ensembles et de relations, le modèle permet des transformations linéaires
complexes qui sont typiquement hors de portée des optimiseurs traditionnels
basés sur les arbres syntaxiques abstraits (AST). Parmi ses capacités, il peut
automatiquement réordonner, fusionner, diviser, tuiler, vectoriser et
paralléliser les boucles.

L'application du modèle polyédrique est limitée aux noyaux de calcul contenant
des boucles imbriquées avec des accès aux données affines. Dans l'univers du
HPC, ces noyaux spécifiques correspondent souvent aux portions les plus
chronophages et critiques d'une application. De manière cruciale, ce sont
exactement les mêmes régions de code où les frameworks de portabilité des
performances offrent leur plus grand avantage, en fournissant une syntaxe
simplifiée pour l'exécution parallèle. Cibler ces régions avec des techniques
polyédriques permet aux codes HPC d'être significativement améliorés.


== Plan et Contributions

Cette thèse introduit et implémente une approche hybride combinant le modèle
polyédrique avec le framework de portabilité des performances Kokkos. L'objectif
principal est de permettre dans Kokkos, d'appliquer les capacités avancées
d'optimisation de boucles fournies par le framework polyédrique.

#chref(<sec:scientificbackground>) détaille le contexte scientifique et
technique nécessaire pour comprendre les fondations de cette thèse. Il introduit
les concepts fondamentaux des nids de boucles, les principes de base de Kokkos,
et les fondements mathématiques du modèle polyédrique.

#chref(<sec:stateoftheart>) présente l'état de l'art, en passant en revue les
recherches existantes sur les optimisations de Kokkos, les outils polyédriques
spécifiques, les développements de l'écosystème autour de Kokkos, et la
recherche sur l'optimisation des bibliothèques logicielles Python à l'aide du
modèle polyédrique.

Dans #chref(<sec:kokkosvisibility>), la première partie de l'implémentation de
l'approche hybride proposée est détaillée. Ce chapitre introduit les
modifications apportées à Kokkos pour exposer ses noyaux de calcul à
l'optimisation polyédrique via Polly de LLVM, qui a lui-même été étendu pour
traiter les constructions Kokkos.

#chref(<sec:complexexecutionpatterns>) se penche sur les schémas d'exécution
complexes, détaillant comment la vision polyédrique peut aller au-delà d'un
noyau Kokkos unique et gérer le cas complexe des boucles triangulaires.

#chref(<sec:schedulingheterogeneous>) couvre les phases d'ordonnancement et de
génération de code hétérogène, incluant l'intégration d'ordonnanceurs externes
comme Pluto et la génération de code GPU via PPCG.

#chref(<sec:evaluations>) présente l'évaluation expérimentale de cette chaîne
d'outils. Le framework est testé face à divers codes scientifiques, et ses
performances sont comparées à la fois aux versions Kokkos standards optimisées
et aux versions Kokkos optimisées polyédriquement. Ces résultats expérimentaux
valident l'efficacité et la viabilité de l'approche hybride proposée.

Enfin, #chref(<sec:conclusion>) conclut ce manuscrit et discute des potentielles
directions de recherche futures.
