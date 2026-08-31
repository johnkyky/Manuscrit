#import "../src/common.typ": *

= Introduction <chapter:introduction>

The computational power of supercomputers has continuously grown over the years, driven by the rapid evolution of hardware architectures. Historically, this progress was fueled by Moore's law through an increase in the number of transistors, their miniaturization, and higher processor clock frequencies. However, as physical constraints brought frequency scaling to a halt, the industry massively shifted toward hardware parallelism, leading to the widespread adoption of pipelined and vector architectures, shared and distributed memory systems, and the integration of hardware accelerators.

Exploiting these heterogeneous architectures has led to the emergence of multiple programming paradigms, making the development of high-performance scientific codes increasingly complex. While substantial efforts have been made to delegate this complexity to compilers and other automated tools, achieving purely automatic optimization and parallelization on modern multi-core and accelerator based systems remains difficult.

Although modern compilers integrate numerous optimization passes, they frequently struggle to apply advanced parallelization and loop transformations efficiently. This limitation primarily comes from the semantic gap between the programmer's high-level intent and the machine-level intermediate representation. To reduce programming cost, the HPC community has designed performance portability frameworks. These libraries provide high-level abstractions that allow developers to explicitly express optimized computational motifs, parallelization strategies, and memory management, with the promise of high performance across diverse architectures (CPUs, GPUs) from a single, unified source code.

While these frameworks greatly facilitate the expression of parallelism, the fine-grained optimization of loop nests remains a significant challenge. The polyhedral model offers a proven mathematical solution for loop optimization. This algebraic approach enables the precise analysis of data dependencies and the application of complex transformations that traditional compilers cannot perform. A highly promising solution to the loop optimization challenge lies in the synergy between the analytical power of the polyhedral model and the high-level abstractions of performance portability frameworks. By converging these two approaches, it becomes possible to effectively optimize and parallelize scientific codes across complex and heterogeneous architectures.


== Compilers

The compiler serves as the critical bridge between the high-level abstractions written by the developer and the low-level instructions executed by the machine. In addition to the conversion to an executable binary file, the compiler is responsible for applying specific optimizations. Ideally, a developer could rely entirely on the compiler's internal heuristics and optimization passes to achieve maximum performance. However, to maximize the utilization of hardware resources for compute-intensive HPC codes, this is rarely sufficient.

An alternative approach is to perform manual code transformations and optimizations directly at the source level to assist the compiler. While a well-executed manual optimization often yields superior performance, it demands significant expertise, increases development time, and severely degrades code maintainability. It effectively requires the developer to be both a domain scientist and a low-level code optimization expert. To overcome this bottleneck, performance portability frameworks offer an alternative to obtain performance without requiring deep development expertise. They allow developers to simply express their computational kernels, while the framework handles the complex mapping and deployment of these kernels to maximize performance across the chosen hardware targets.


== Performance Portability Frameworks

Performance portability frameworks are provided as software libraries that developers can leverage to express parallelism and manage memory across diverse hardware architectures. In the HPC domain, the most prominent examples include Kokkos, RAJA, and the C++ Standard Parallelism (`std::par`). These frameworks enable the development of a single source code that can be compiled for various targets, with the promise of performance portability.

However, these frameworks do not inherently perform automatic source code optimization. They rely on static structural optimizations and explicit parallelism without performing deep static analysis of the computational kernels themselves. The performance they deliver stems primarily from robust parallel dispatching and low-level mapping techniques implemented by the framework developers, rather than from aggressive loop restructuring. By employing the polyhedral model, complex loop transformations can be automatically applied to these critical, computationally expensive code regions to maximize hardware utilization.


== Polyhedral Model

The polyhedral model is a mathematical framework dedicated to the optimization of loop nests. It has proven its effectiveness in program optimization through robust implementations such as Pluto, Polly, and PPCG. By expressing a program's loops in a mathematical form using sets and relations, the model enables complex, linear transformations that are typically out of reach for traditional AST-based optimizers. Among its capabilities, it can automatically reorder, fuse, fission, tile, vectorize, and parallelize loops.

The application of the polyhedral model is limited to computational kernels containing nested loops with affine data accesses. In the HPC universe, these specific kernels often correspond to the most time consuming and critical portions of an application. Crucially, these are the exact same code regions where performance portability frameworks provide their greatest advantage, offering simplified syntax for parallel execution. Targeting these regions with polyhedral techniques enables HPC codes to be significantly optimized.


== Outline and Contributions

This thesis introduces and implements a hybrid approach combining the polyhedral model with the performance portability framework Kokkos. The primary objective is to enable in Kokkos the advanced loop optimization capabilities provided by the polyhedral framework.

#chref(<chapter:scientificbackground>) details the scientific and technical background necessary to understand the foundations of this thesis. It introduces the core concepts of loop nests, the fundamental principles of Kokkos, and the mathematical basis of the polyhedral model.

#chref(<chapter:stateoftheart>) presents the state of the art, reviewing existing research on Kokkos optimizations, specific polyhedral tools, ecosystem developments around Kokkos, and research to optimize software python libraries using the polyhedral model.

In #chref(<chapter:loopkerneloptimizations>), the implementation of the proposed hybrid approach is detailed. This chapter introduces the modifications made to Kokkos to expose its computational kernels to polyhedral optimization via LLVM Polly, which was itself extended to process Kokkos constructs. It details the implementation phases, the Kokkos API adaptations, the internal modifications to Polly, and the compilation for GPU architectures within the polyhedral pipeline.

#chref(<chapter:evaluations>) presents the experimental evaluation of this hybrid toolchain. The framework is tested against various scientific codes, and its performance is compared against both standard Kokkos optimized versions and Kokkos with polyhedral optimizion versions. These experimental results validate the efficiency and viability of the proposed hybrid approach.

Finally, #chref(<chapter:conclusion>) concludes this manuscript and discusses potential future research directions.




// = Introduction
//
// La puissance de calcul des supercalculateurs n'a cessé d'augmenter au fil des années grâce à l'évolution des architectures matérielles. Historiquement, cette évolution s'est faite par l'augmentation du nombre de transistors, leur miniaturisation, ainsi que l'augmentation de la fréquence des processeurs. Toutefois, en raison de contraintes physiques, l'augmentation de la fréquence a été freinée. Cela a conduit à l'adoption massive d'approches basées sur le parallélisme matériel : architectures pipelinées, vectorielles, à mémoire partagée, à mémoire distribuée et l'intégration d'accélérateurs.
// L'exploitation de ces architectures hétérogènes a entraîné l'émergence de multiples paradigmes de programmation, rendant le développement de codes performants de plus en plus complexe pour les scientifiques. De nombreux travaux ont été réalisés pour déléguer cette complexité aux compilateurs ou autre outils, dans le but d'optimiser et de paralléliser le code automatiquement. Cependant, la parallélisation multi-coeurs et l'utilisation d'accélérateurs rendent l'optimisation purement automatique par le compilateur extrêmement difficile.
//
// Malgré que les compilateurs integrent de nombreuses passes d'optimisation, il est tres difficile pour eux d'appliquer efficacement certaine optimisation ou parallélisation en raison du gap de compréhension entre ce que le programmeur souhaite ecrire et ce que la machine comprend. Pour facilité le developpement la communauté a imaginé des bibliothèques de portabilité des performances. Ces framework offre des abstractions de haut niveau permettant au développeur d'exprimer explicitement les motifs optimisé de noyaux de calcul ainsi que leur parallélisation et la gestion de la mémoire, garantissant ainsi de hautes performances sur diverses architectures (CPU, GPU) à partir d'un code source unique.
//
// Bien que ces frameworks facilitent l'expression du parallélisme, l'optimisation fine des nids de boucles largement présent dans les codes scientifiques reste un défi. Le modèle polyédrique est une technique d'optimisation de code qui modélise les boucles mathématiquement. Cette approche algébrique permet d'analyser les dépendances de données avec une précision mathématique et d'appliquer des transformations complexes. Une solution à ce défi réside dans l'alliance entre la puissance d'optimisation du modèle polyédrique et les abstractions de haut niveau des frameworks de portabilité des performances. En faisant converger ces approches, il devient possible d'optimiser et de paralléliser efficacement les codes scientifiques sur des architectures complexe et heterogène.
//
//
// == Compilers
//
// Le compilateur represente le pont entre le haut niveau ecrit par le developpeur et le bas niveau execute par la machine. Il permet non seulement la traduction du code en executable mais aussi l'optimisation des codes specifique aux différentes architectures et accelerateurs. Pour obtenir des performances optimales, le developpeur peut laisser le compilateur optimiser grace aux différentes passes d'optimisation et différentes heuristiques internes, ce qui est rarement le cas pour des codes de calcul intensif.
// Une autre approche consiste a faire des transformations et optimisations de code sur le code source pour faciliter le travail du compilateur. Cette approche, bien executé, est souvent plus performantes mais demande une expertise importante du developpeur ainsi qu'un surcout du temps de developpement et une maintenabilité du code plus difficile. Le developpeur doit à la fois etre un expert du domaine scientifique et un expert en optimisation de code pour obtenir des performances optimales. Pour pallier a ce probleme, une autre approche consiste a utiliser des frameworks de portabilité des performances.
// Ils permettent au developpeur d'exprimer simplement le noyaux de calcul et le frameworks devoloppper par des expert en optimisation se charge de la repartition des noyaux de calculs pour maximiser les performances sur les différentes architectures choisi (CPU, GPU).
//
// == Performance Portability Frameworks
//
// Les frameworks de portablilité de performances se presentes sous la forme de bibliotheques que le developpeur peut utiliser pour exprimer le parallelisme et la gestion de la mémoire sur des différentes architectures. Les principaux utilisé dans le monde du HPU sont Kokkos, RAJA et la librairie standard C++ Parallel STL. Ces frameworks permettent de developper un code source unique et de la compiler pour differentes architectures avec une promesse de portabilité des performances.
// Cependant ces frameworks ne permettent pas d'optimiser le code source de manière automatique. Ce sont des optimisations de structure statiques sans aucune annalyse du noyaux de calcul dans la librairie qui permettent d'obtenir des corrects independament de l'architecture et accelerateurs avec des performances du au parallelisme et au faible levier d'optimisation possible par les developper du frameworks.
// Pourtant statiquement il est possible, grace au modele polyedrique, d'optimiser les noyaux de calculs pour appliquer des transformations de boucles complexes permettant de maximiser les performances sur les portions couteuse du code.
//
//
// == Polyhedral model
//
// Le modele polyedrique est un modele mathématique d'optimisation de loopnest. Il a largement fait ses preuves dans l'optimisation de programmes, grace a ses multiples implémentations Pluto, Polly, PPCG, etc. Il permet d'exprimer les boucles d'un programme sous une forme mathématique grace a des set et relation permettant d'appliquer des transformations linéaires complexe pour les optimiseurs classiques. Il permet entre autre de réordonner les boucles, de fusionner ou de diviser les boucles, de tiller les boucles, de vectoriser et paralléliser les boucles de maniere automatique.
// Le modele polyedrique se limite au noyaux de calculs contenant des boucles impriquées avec des acces linéaires aux données. Dans l'univers du HPC, ces noyaux de calculs sont souvent des portions de code critiques et couteuses en temps de calcul, c'est d'ailleurs sur ces portions de code que les frameworks de portabilité de performances donnent un avantage grace a leur simplicité d'écriture et leur optimisations et parallélisations.
//
//
// == Outline and contributions
//
// Cette these introduit et implémente une approche hybride combinant le modele polyédrique au framework de portabilité de performance Kokkos. L'objectif est de pouvoir ajouter un nouveau champs d'optimisation que propose le modele polyédrique à Kokkos.
//
// #chref(<chapter:scientificbackground>) detail le background scientifique et technique nessaire a la bonne compréhension de cette these. Il introduit les concets de loopnest, ainsi que les concpets de base de Kokkos et du modele polyedrique.
//
// #chref(<chapter:stateoftheart>) introduit l'état de l'art des différents travaux réalisés sur l'optimisation de kokkos, des différents outils polyedrique spécifiques, des outils autour de kokkos ou des optimsation de librairies avec le modele polyedrique.
//
// In #chref(<chapter:loopkerneloptimizations>), l'implémentation de l'approche hybride est detaillé. Elle introduira les modifications apportées à Kokkos pour permettre l'optimisation des noyaux de calculs par le modèle polyédrique grâce a Polly, lui meme transformé pour accueillir les code Kokkos. Elle détaillera également les différentes étapes de l'implémentation, les changements de l'API Kokkos, les modifications de Polly et les différentes étapes de l'implémentation ainsi que la gestion des architectures CPU et GPU dans Polly.
//
// #chref(<chapter:evaluations>) présente les résultats expérimentaux de cette aproche hybride. L'outils sera confronté à différents codes scientifiques et les performances seront comparées avec les versions optimisées par Kokkos et les versions optimisées par le modèle polyédrique. Les résultats expérimentaux permettront de valider l'efficacité de l'approche hybride proposée.
//
//
// Finally, #chref(<chapter:conclusion>) concludes this manuscript and discusses potential future research directions.
