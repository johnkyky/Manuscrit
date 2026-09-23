#import "../src/common.typ": *

= Complex Execution Patterns <sec:complexexecutionpatterns>

```cpp
      PA = VarFusionPass().run(F, FAM);
      PA = UserAssumptions().run(F, FAM);
      PA = LoopFusionPass().run(F, FAM);
      PA = TriangularLoopFixPass().run(F, FAM);
      PA = MergeRedundantInvariantLoadsPass().run(F, FAM);
      PA = ArrayFusion().run(F, FAM);
```

#figure(
  ```cpp
  template <bool usePolyOpt = false,
            StringAssumption StrAssumption = "",
            class ExecPolicy,
            class FunctorType,
            class Enable = std::enable_if_t<is_execution_policy<ExecPolicy>::value>
            >
  inline void parallel_for(const std::string& str, const ExecPolicy& policy,
                           const FunctorType& functor);
  ```,
  caption: [Nouvelle signature de `parallel_for` avec le paramètre
    `usePolyOpt`.],
)

Grâce aux différents mécanismes présentés dans le @sec:kokkosvisibility pour
pallier la complexité inhérente à Kokkos, il est désormais possible d'appliquer
des transformations polyédriques sur des noyaux de calcul simples. Toutefois,
certains algorithmes nécessitent d'être décomposés en plusieurs étapes,
engendrant ainsi de multiples appels consécutifs à la fonction `parallel_for`.
Il en résulte une vision fragmentée du noyau global, ce qui empêche le
compilateur d'appliquer efficacement des transformations polyédriques complexes.
Un autre défi majeur concerne l'optimisation des boucles triangulaires, qui
requièrent des transformations spécifiques au niveau de la représentation
intermédiaire (IR) pour être correctement modélisées.

Dans ce chapitre, la @sec:complexexecutionpatterns:globalloopvision aborde la
problématique liée à la fragmentation des noyaux de calcul. Ensuite, la
@sec:complexexecutionpatterns:assumptions introduit une nouvelle méthode
permettant de transmettre des informations sémantiques au modèle polyédrique
sous forme de contraintes (*assumptions*). Enfin, la
@sec:complexexecutionpatterns:triangularloop traite des défis et des solutions
liés à l'optimisation des nids de boucles triangulaires.

== Global Loop Vision <sec:complexexecutionpatterns:globalloopvision>
Une difficulté majeure réside dans la différence de possibilité du modèle
polyédrique et du modèle de programmation de Kokkos. En standard, l'approche
Kokkos favorise l'isolation : chaque `parallel_for` est un appel de fonction
distinct et Polly ne possède qu'une vision locale de chaque noyau. Or, le modèle
polyédrique peut (et doit) avoir une vision globale pour générer des
transformations optimales, telles que la fusion de boucles inter-kernels.

Pour surmonter cela, nous avons implémenté une version variadique de
`parallel_for` capable d'accepter une séquence illimitée de paires
`(Policy, Functor)`.

#figure(
  rect(width: 100%, height: 150pt, stroke: 1pt + black, align(center + horizon)[
    Exemple de kernel TRMM
  ]),
  caption: [Utilisation du parallel_for variadique sur un exemple type (TRMM)],
) <code:complexexecutionpatterns:trmm>

Initialement, le noyau TRMM (ou tout noyau complexe) est écrit comme en
@code:complexexecutionpatterns:trmm. Bien que cette implémentation groupe les
boucles dans le code source, l'IR générée reste fragmentée. Nous appliquons donc
des transformations spécifiques pour unifier l'IR et reconstruire un SCoP unique
:

- *Linéarisation du flot de contrôle :* Lors de la compilation, chaque nid de
  boucles possède ses propres blocs de *preheader* (chargement des arguments,
  bornes, etc.). Nous identifions ces blocs et les remontons (*hoisting*) pour
  qu'ils dominent l'ensemble de la séquence de nids de boucles, permettant à
  Polly de détecter une région contiguë.
- *Fusion de tableaux par nommage statique (*Static Naming*) :* Les lambdas C++
  dupliquent les pointeurs, masquant le fait que deux boucles accèdent au même
  tableau logique. Nous avons étendu l'API View pour supporter un nom statique
  via les paramètres de template. Lors de l'analyse, l'IR est réécrite (*Replace
  All Uses With* - RAUW) pour fusionner ces pointeurs dupliqués entre les
  lambdas successifs, offrant ainsi une vision globale cohérente de la mémoire.
- Les variables de bornes de boucles ne laissent pas la possibilité de fusionner
  naturellement, car on ne sait pas si les copies sont identiques statiquement.
  Nous devons alors passer par un système de contraintes (*assumptions*),
  présenté dans la partie @sec:complexexecutionpatterns:assumptions.

le nom des tableaux est une prouesse de c++ donc montrer comment je me suis fait
chier a le faire

== Assumptions <sec:complexexecutionpatterns:assumptions>

expliquer comment on creer l'assumption dans Kokkos

Le systeme d'annotation permet de passer des informations semantiques
suplémentaire neccessaire pour le modele que l'on perd a cause de la structure
des Kokkos.

Le systeme d'assymption fonctionne grace a un argument suplémentaire optionnel a
la suite de l'option usePolyOpt.

```cpp
  exemple de la définition du parametre d'assumption
```

=== Grammar

definir la grammar
- borne de boucle / literal / operateur / variable

Parler de KOKKOS_LOOP_BOUND pour pouvoir utiliser les variable interne du kernel
qui definissent les bornes de boucles.


== Triangular Loop <sec:complexexecutionpatterns:triangularloop>

Certains cas de code contiennent des portions triangulaires. Avec les
contraintes de kokkos, les acces mémoire des tableaux utilisé perdre la
linéarité des acces et rende la détection plus complexe
(@fig:complexexecutionpatterns:triangularloop).

#figure(
  rect(width: 100%, height: 150pt, stroke: 1pt + black, align(center + horizon)[
    Polly's pipeline
  ]),
  caption: [Schema de comment ca casse la linéarité avec les triangulaires],
) <fig:complexexecutionpatterns:triangularloop>

Les simples annalyse de LLVM ne foncitonne pas dans ce cas, et avec une
connaissance d'information suplémentaire (code kokkos, indices de boucles,
tableau, dimensions des tableaux) on peut deduir pour chaque boucle un peeling
static efficace pour casser les brachement indésirable qui casse le modele
polyhedrique. Ca permet de faire foncitonner des codes non polyédrique d'apres
la détection et etendre les possiblilté de polly sur les code kokkos.
