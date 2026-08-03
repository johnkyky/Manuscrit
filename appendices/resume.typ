#import "../src/common.typ": *

= Résumé en français

La puissance de calcul des supercalculateurs n'a cessé d'augmenter au fil des années grâce à l'évolution des architectures matérielles. Historiquement, cette évolution s'est faite par l'augmentation du nombre de transistors, leur miniaturisation, ainsi que l'augmentation de la fréquence des processeurs. Toutefois, en raison de contraintes physiques, l'augmentation de la fréquence a été freinée. Cela a conduit à l'adoption massive d'approches basées sur le parallélisme matériel : architectures pipelinées, vectorielles, à mémoire partagée, à mémoire distribuée et l'intégration d'accélérateurs.
L'exploitation de ces architectures hétérogènes a entraîné l'émergence de multiples paradigmes de programmation, rendant le développement de codes performants de plus en plus complexe pour les scientifiques. De nombreux travaux ont été réalisés pour déléguer cette complexité aux compilateurs ou autre outils, dans le but d'optimiser et de paralléliser le code automatiquement. Cependant, la parallélisation multi-coeurs et l'utilisation d'accélérateurs rendent l'optimisation purement automatique par le compilateur extrêmement difficile.

Malgré que les compilateurs integrent de nombreuses passes d'optimisation, il est tres difficile pour eux d'appliquer efficacement certaine optimisation ou parallélisation en raison du gap de compréhension entre ce que le programmeur souhaite ecrire et ce que la machine comprend. Pour facilité le developpement la communauté a imaginé des bibliothèques de portabilité des performances. Ces framework offre des abstractions de haut niveau permettant au développeur d'exprimer explicitement les motifs optimisé de noyaux de calcul ainsi que leur parallélisation et la gestion de la mémoire, garantissant ainsi de hautes performances sur diverses architectures (CPU, GPU) à partir d'un code source unique.

Bien que ces frameworks facilitent l'expression du parallélisme, l'optimisation fine des nids de boucles largement présent dans les codes scientifiques reste un défi. Le modèle polyédrique est une technique d'optimisation de code qui modélise l'espace d'itération des boucles imbriquées sous la forme de polyèdres, contrairement aux optimisations classiques se basant purement sur des arbres syntaxiques (AST). Cette approche algébrique permet d'analyser les dépendances de données avec une précision mathématique et d'appliquer des transformations complexes de manière efficace. Une solution à ce défi réside dans l'alliance entre la puissance d'optimisation formelle du modèle polyédrique et les abstractions de haut niveau des frameworks de portabilité des performances. En faisant converger ces approches, il devient possible d'optimiser et de paralléliser efficacement les codes scientifiques, maintenant ainsi des performances optimales sur des architectures matérielles de plus en plus hétérogènes.


== Introduction

Dans ce manuscrit #todo(100)


== Parallelization paradigms


== Compilers


== Performance Portability Frameworks


== Polyhedral model


== Outline and contributions
