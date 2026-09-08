#import "../src/common.typ": *

= Evaluations <chapter:evaluations>

== Experimental Setup
- *Hardware* : Dual AMD EPYC 7502 (2x32 cœurs, 756 GB RAM) et Intel Core Ultra 7 265 (20 cœurs) + NVIDIA RTX 5090 (16 GB).
- *Software* : LLVM/Clang++ 23.0.0, Kokkos 4.6.99 modifiée, compilation CMake en mode Release.
- *Méthodologie* : Baseline Kokkos idiomatique (single-source), 5 itérations par test (variance < 4%), vérification des sorties avec tolérance $10^{-8}$.

== Experimental Data Size
- *Benchmarks utilisés* : Suite Polybench réécrite en Kokkos.
- *Exclusions* : `correlation`, `nussinov`, `floyd-warshall` écartés (control flow non-affine).
- *Tailles de données* : (Référence à la Table 1 de l'article) Tailles de problèmes larges adaptées aux architectures modernes (ex: N=5000 à 35800 selon les noyaux).

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: 4,
      align: (left, center, left, center),
      stroke: none,
      table.vline(x: 2, stroke: 0.5pt + luma(200)),
      table.hline(stroke: 1pt),
      table.header([*Benchmark*], [*Problem Size*], [*Benchmark*], [*Problem Size*]),
      table.hline(stroke: 0.5pt),
      [covariance], [$M = 12000, N = 1400$], [cholesky], [$N = 2048$],
      [gemm], [$N I = 5000, N J = 5500, N K = 6000$], [durbin], [$N = 15048$],
      [gemver], [$N = 20000$], [gramschmidt], [$M = 2000, N = 2600$],
      [gesummv], [$N = 35800$], [lu], [$N = 2048$],
      [symm], [$M = 1000, N = 1200$], [ludcmp], [$N = 2048$],
      [syr2k], [$M = 5000, N = 5200$], [trisolv], [$N = 35048$],
      table.hline(start: 2, stroke: 0.5pt),
      [syrk], [$M = 5000, N = 5200$], [deriche], [$W = 1024, H = 880$],
      table.hline(start: 2, stroke: 0.5pt),
      [trmm], [$M = 2000, N = 2600$], [adi], [$N = 1000, T = 250$],
      [2mm], [$N I = 5024, N J = 5048, N K = 5072,$ \ $N L = 5096$], [fdtd-2d], [$N X = 900, N Y = 1100, T = 250$],
      [3mm], [$N I = 5024, N J = 5048, N K = 5072,$ \ $N L = 5096, N M = 5120$], [heat-3d], [$N = 256, T = 250$],
      [atax], [$M = 10024, N = 10048$], [jacobi-1d], [$N = 50000, T = 10000$],
      [bicg], [$M = 22400, N = 24800$], [jacobi-2d], [$N = 10000, T = 250$],
      [doitgen], [$N Q = 656, N R = 664, N P = 672$], [seidel-2d], [$N = 10000, T = 250$],
      [mvt], [$N = 20028$], [], [],
      table.hline(stroke: 1pt),
    ),
    caption: [Polybench Problem Sizes],
  ) <tab:problemsizes>
]

== CPU Performance Analysis
- *Résultats globaux* : Accélérations massives, jusqu'à 118.26x sur AMD (ex: sur `lu`, `trmm`).
- *Impact des Schedulers* : Comparaison ISL vs Pluto. Pluto est meilleur sur les stencils (ex: `jacobi`, `seidel`) car ISL parallélise parfois la boucle interne à tort.
- *Sensibilité micro-architecturale* : L'impact du tiling (tuilage) varie selon les caches (AMD L2 512 KB vs Intel L2 3 MB).

== GPU Performance Analysis
- *Résultats globaux* : Accélérations jusqu'à 3 ordres de grandeur via PPCG (ex: 5757x sur `cholesky`, 1559x sur `seidel-2d`).
- *Points forts* : Loop skewing (pour le parallélisme externe), utilisation de la mémoire partagée et privatisation des variables.
- *Contre-performances* : Ralentissements sur les kernels simples (`deriche`, `jacobi`) à cause de l'overhead des grid-stride loops et du manque d'heuristique dynamique pour la taille des blocs.

== Discussion and Limitations
- *Temps de compilation* : Globalement acceptable, mais "timeout" sur les noyaux très complexes avec PPCG (ex: `adi`, `fdtd-2d`).
- *Limites actuelles* : La véracité du Static Naming et des Assumptions repose entièrement sur l'utilisateur (pas de vérification auto).
- *Travaux futurs* : Implémenter des vérifications automatiques (compile-time/runtime) et ajouter des heuristiques adaptatives pour choisir la taille des tuiles/blocs.
