#import "../src/common.typ": *

= Conclusion et perspectives <sec:conclusion>

L'optimisation des programmes constitue un enjeu majeur pour le calcul
scientifique à haute performance. Le développement de codes de calcul est en
effet confronté à la complexité et à l'hétérogénéité des architectures
matérielles modernes. Si les bibliothèques de portabilité des performances,
telles que Kokkos, permettent de s'abstraire de l'architecture cible pour le
déploiement des noyaux de calcul, elles confient largement la charge de
l'optimisation fine aux compilateurs. Or, ces derniers peinent souvent à
appliquer des transformations agressives face à la complexité des nids de
boucles rencontrés dans les applications réelles.

À l'inverse, le modèle polyédrique offre un cadre d'optimisation mathématique
puissant, mais son application directe sur des abstractions de haut niveau reste
difficile. L'objectif principal de cette thèse a été de combler ce fossé
sémantique en proposant une approche hybride, unissant la flexibilité et la
portabilité de Kokkos à la puissance d'analyse et d'optimisation du modèle
polyédrique.

== Contributions

=== Visibilité des noyaux Kokkos

L'optimisation polyédrique nécessite une représentation mathématique précise du
code source, une information qui est souvent masquée par l'utilisation
d'abstractions de haut niveau et de constructions logicielles complexes. Les
noyaux Kokkos, bien que portables et expressifs, demeurent opaques pour les
outils d'analyse statique polyédrique classiques.

Pour lever ce verrou technologique, nous avons modifié la chaîne de compilation
et étendu l'outil Polly au sein de LLVM. Cette intégration permet d'extraire la
sémantique et la structure des noyaux Kokkos pour les rendre pleinement visibles
et compréhensibles par les outils polyédriques.

Cela constitue la fondation de notre approche hybride, en permettant
l'extraction transparente de modèles mathématiques rigoureux à partir de codes
sources portables.

=== Motifs d'exécution complexes

Si l'extraction et l'optimisation de noyaux isolés et réguliers constituent une
première étape cruciale, les applications scientifiques reposent fréquemment sur
des schémas d'exécution plus complexes. L'application du modèle polyédrique à
ces structures non triviales nécessite des mécanismes d'analyse pour garantir la
validité des transformations.

Nous avons ainsi étendu notre approche hybride à la gestion et à la modélisation
des nids de boucles triangulaires, ainsi qu'à la modélisation fidèle des nids de
boucles fragmentés en différents appels à `parallel_for`.

Nous avons démontré que notre approche pouvait s'appliquer efficacement à ces
structures algorithmiques, augmentant significativement la portée des codes
pouvant être optimisés par le modèle polyédrique.

=== Ordonnancement et génération de code hétérogène

La dernière étape de notre démarche consiste à introduire de nouveaux
ordonnanceurs, à la fois pour profiter des capacités d'optimisation de ces
derniers, mais aussi pour permettre d'exploiter des architectures hétérogènes.

Pour répondre à ce défi, nous avons traduit la représentation polyédrique en un
format standard, permettant ainsi à d'autres ordonnanceurs, tels que Pluto,
d'optimiser le code. L'intégration de l'outil PPCG a également été réalisée plus
en profondeur dans le pipeline de compilation afin de permettre l'application de
transformations polyédriques ciblant des noyaux GPU.

Nos évaluations expérimentales ont validé l'efficacité de cette chaîne d'outils.
Nos résultats démontrent des accélérations significatives par rapport aux
implémentations Kokkos standards, tant sur CPU que sur GPU. Ces résultats
prouvent que l'approche hybride Kokkos, couplée aux optimisations polyédriques,
permet non seulement de surpasser les performances de l'approche Kokkos
standard, mais aussi d'exploiter pleinement le potentiel des architectures
hétérogènes, tout en conservant la portabilité du code. Comparée à Polly
appliqué aux versions C d'origine des noyaux, notre chaîne de compilation ne
dégrade pas les performances, et les améliore même en moyenne, ce qui montre que
l'abstraction Kokkos ne fait pas obstacle à l'optimisation polyédrique.

== Discussion et limites

Bien que notre approche hybride démontre des gains de performance prometteurs
pour les codes Kokkos, elle reste soumise à certaines limites conceptuelles et
techniques.

Premièrement, notre outil ne prend pas en charge la politique d'exécution
hiérarchique `TeamPolicy`. Cette limitation découle d'une incompatibilité
inhérente avec le modèle polyédrique classique. La sémantique de `TeamPolicy`
repose sur une hiérarchie d'exécution parallèle incompatible avec le modèle
polyédrique, limitant ainsi notre périmètre d'action actuel aux politiques
`RangePolicy` et `MDRangePolicy`.

Deuxièmement, la complexité des algorithmes polyédriques peut entraîner des
problèmes de scalabilité lors de la phase de compilation. Si le surcoût reste
modéré pour la grande majorité des noyaux, le calcul de l'ordonnancement par
PPCG ne termine pas en un temps raisonnable sur les stencils `adi`, `fdtd-2d` et
`heat-3d`, en raison du nombre de contraintes générées pour ces nids de boucles.

Enfin, l'outil accorde actuellement une confiance totale aux informations
sémantiques fournies par le développeur (noms statiques, suppositions
mathématiques), ce qui constitue un point de fragilité pouvant mener à des
erreurs silencieuses en cas de spécification erronée.

== Perspectives <sec:conclusion:perspectives>

Les travaux présentés dans ce manuscrit ouvrent plusieurs pistes, allant de
l'amélioration de l'implémentation actuelle à des extensions plus fondamentales
de notre approche hybride.

Premièrement, l'implémentation logicielle pourrait être améliorée. À l'heure
actuelle, notre prototype prend en charge les espaces d'exécution fondamentaux
de Kokkos, à savoir `Serial`, `OpenMP` et `Cuda`. Une évolution naturelle
consisterait à intégrer d'autres backends d'exécution, tels que HIP pour cibler
les accélérateurs matériels d'AMD, ou SYCL pour les architectures Intel. Cette
extension garantirait une portabilité des performances sur un spectre matériel
encore plus vaste.

Deuxièmement, la robustesse de l'outil face aux spécifications de l'utilisateur
pourrait être considérablement renforcée. Actuellement, notre approche permet
aux développeurs d'injecter des informations sémantiques cruciales pour
l'analyse polyédrique, notamment via le nommage statique des vues et l'ajout de
suppositions mathématiques. Une perspective de développement majeure
consisterait à implémenter des mécanismes de vérification statique capables de
valider la cohérence de ces informations. Cela permettrait de fournir une
gestion des erreurs robuste, avec des retours pertinents lors de la compilation.

Dans cette même dynamique d'intégration à l'écosystème Kokkos, une autre
évolution viserait à contrôler les paramètres d'optimisation, comme la taille
des tuiles, directement au travers des abstractions de la bibliothèque. Cela
offrirait au développeur la possibilité de piloter finement l'application du
modèle polyédrique depuis son code source, en respectant la philosophie de
conception de Kokkos.

Enfin, notre chaîne d'outils s'appuie encore sur des heuristiques de tuilage et
de partitionnement de blocs qui manquent d'adaptabilité. En l'absence de modèles
de coût dynamiques guidés par la structure des noyaux, les tailles de tuiles
générées ne garantissent pas toujours l'atteinte des performances maximales
théoriques. Le développement d'heuristiques adaptatives, capables d'ajuster
automatiquement ces paramètres en fonction de la structure des noyaux et de
l'architecture ciblée, constitue ainsi une piste de recherche.
