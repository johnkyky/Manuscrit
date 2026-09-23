#import "../src/common.typ": *

= Scheduling and Heterogeneous Generation <sec:schedulingheterogeneous>

== Génération de code (backend) <sec:schedulingheterogeneous:backend>

rappeller ce que c'est, ces limitations actuelle dans Polly et aussi pourquoi
c'est pas optimal dans kokkos, qu'est ce que l'on voudrait faire mieux.

== Pluto intégration

Le schedule polyedrique est une etape crtiale, bien choisir les transformation
de code est primordiale pour obtenir un code optimisé. L'algorihtme de polly de
scheduling utilise isl qui se base sur une réimplementation de l'algorithme de
scheduling de pluto. Malgré cela les deux algorithme n'ont pas le meme
comportement et ne produisent pas le meme schedule. Pluto integre des
transformation plus complexe comme le diamonde tilling et le wave front
parallelisme. Pour etendre les possibilités de scheduling et de transformation
de code, la possibilité du choix du schedule en passant par pluto en outil
externe a ete ajouté. Pour fonctionner la représentation du scop de polly est
tranformé en une representation OpenSCoP standardisé pouvant a l'avenir intégré
d'autre outils de schedule.

== PPCG Integration <sec:schedulingheterogeneous:ppcg>

La génération de code GPU représente un chaînon manquant critique dans le
pipeline de compilation de Polly, en raison des différences architecturales
fondamentales entre les CPUs et les GPUs.

Pour combler cette lacune, nous avons réintégré et mis à jour les concepts de
*Polly-ACC* dans l'infrastructure moderne de Polly. Cette intégration s'appuie
sur *PPCG* (Polyhedral Parallel Code Generation), un compilateur source-à-source
spécialisé dans l'application de contraintes de scheduling adaptées aux
architectures massivement parallèles.

Concrètement, Polly-ACC utilise le SCoP extrait par Polly pour alimenter les
structures de données requises par PPCG. Cela permet à PPCG :
- De calculer un nouveau schedule (ordonnancement) optimisé.
- De cartographier intelligemment ce schedule sur l'architecture GPU, en
  associant les boucles à des hiérarchies de blocs et de threads.

PPCG excelle dans la construction de schedules qui tirent parti de la *mémoire
partagée* et de la *privatisation des variables*, maximisant ainsi le débit de
calcul de l'accélérateur. Une fois le schedule optimisé déterminé, Polly génère
l'IR LLVM spécifique au périphérique (GPU), ainsi que le code côté hôte
nécessaire pour orchestrer le lancement des kernels et gérer les transferts
mémoire.
