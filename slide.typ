#import "@preview/typslides:1.3.3": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/codly:1.3.0": codly, codly-init
#import "@preview/codly-languages:0.1.1": codly-languages
#import "src/colors.typ": *

#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Inter",
  font-size: 16pt,
  link-style: "color",
  show-progress: true,
)

#show: codly-init.with()
#codly(
  languages: codly-languages,
  zebra-fill: none,
  number-format: none,
  stroke: 0.5pt + luma(180),
)
#show raw: set text(
  font: "FiraCode Nerd Font Mono",
  ligatures: false,
  features: (calt: 0),
)
#show raw.where(block: true): set text(size: 9.5pt)
#set par(leading: 0.55em)
#set list(spacing: 0.7em)

#let small(body) = text(size: 0.75em, body)
#let note(body) = text(size: 0.7em, fill: luma(90), body)
#let fig-cpu-amd = "figures/evaluations/polybench_trahrhe_cpu.pdf"
#let fig-cpu-intel = "figures/evaluations/polybench_eugene_cpu.pdf"
#let fig-gpu = "figures/evaluations/polybench_eugene_gpu.pdf"
#let fig-tri-before = "figures/complexexecutionpatterns/trisolvbefore.pdf"
#let fig-tri-after = "figures/complexexecutionpatterns/trisolvafter.pdf"

// ---------------------------------------------------------------- Title
#front-slide(
  title: "Unlocking Polyhedral Optimization for Kokkos Kernels",
  subtitle: "A Library–Compiler Co-Design",
  authors: "Ugo Battiston¹, Philippe Clauss¹, Marc Pérache²",
  info: [¹ Inria CAMUS, ICube, Université de Strasbourg \ ² CEA, DAM, DIF,
    Université Paris-Saclay],
)

// ---------------------------------------------------------------- 1. Context
#title-slide[Context and problem]

#slide(title: "Kokkos: one source, many architectures")[
  #cols(columns: (1.05fr, 1fr), gutter: 1.5em)[
    - Heterogeneous supercomputers: CPUs, GPUs, several vendors.
    - *Kokkos*: C++ performance-portability library.
      - `View`: multidimensional arrays, layout per target.
      - *Execution policies*: the iteration space.
      - `parallel_for` + lambda: the loop body.
    - Templates lower it to OpenMP loops (CPU) or CUDA kernels (GPU).
  ][
    ```cpp
    Kokkos::View<double**> A("A", n, m), B("B", n, m);
    auto policy = Kokkos::MDRangePolicy<
        Kokkos::OpenMP, Kokkos::Rank<2>>({1, 1}, {n-1, m-1});

    Kokkos::parallel_for("stencil", policy,
      KOKKOS_LAMBDA(long i, long j) {
        B(i, j) = A(i, j) + A(i, j-1) + A(i, j+1)
                          + A(i-1, j) + A(i+1, j);
      });
    ```
    #framed[Loops are *regular*: rectangular space, constant bounds, affine
      accesses. Ideal polyhedral candidates.]
  ]
]

#slide(title: "The polyhedral model and Polly")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *Polyhedral model* \
    Mathematical modeling of nested loops:
    - Loop nest = set of integer points
    - Dependences = affine constraints.
    - Affine bounds and subscripts: a *SCoP* (Static Control Part).
    - Aggressive loop transformations: *tiling, fusion, skewing, wavefront
      parallelism*.
  ][
    *Polly* : the polyhedral optimizer of LLVM
    + Canonicalization
    + SCoP detection
    + SCoP construction
    + Dependence analysis and scheduling
    + Code generation with runtime guards

    #framed[Works on LLVM IR: the right level for inlined C++ templates, unlike
      source-to-source tools.]
  ]
]

#slide(title: "Problem: Polly cannot see Kokkos loops")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    After inlining the Kokkos dispatch stack, Polly sees:
    - a loop body scattered across a region without boundaries,
    - *array dimensions lost*: `A(i, j)` is 1D pointer arithmetic,
    - bounds and View sizes reloaded inside the loop (no LICM),
    - safety checks and loop versioning that break the CFG,
    - the default `MDRangePolicy` tiling: extra loop levels,
    - no trace of the execution space (Serial / OpenMP / Cuda).
  ][
    #framed(title: "Our claim")[
      The barrier is one of *visibility*, not of optimizer capability.
    ]
    #v(0.5em)
    #framed(title: "Our approach")[
      A *library–compiler co-design*: Kokkos emits annotated, clean IR; Polly
      learns to read it. The user keeps the portable, single-source style.
    ]
  ]
]

#slide(title: "Contributions at a glance")[
  #cols(columns: (1fr, 1.1fr), gutter: 1em)[
    #align(center, diagram(
      spacing: 40pt,
      node-shape: rect,
      node-stroke: 0.7pt,
      edge-stroke: 0.7pt,
      node-corner-radius: 4pt,
      node-inset: 7pt,
      node(
        (0, 0),
        [*Kokkos code* + `usePolyOpt`],
        fill: color-blue,
        stroke: color-blue-stroke,
      ),
      edge((0, 0), (0, 1), small[annotations], "-|>"),
      node((0, 1), [Clang front-end]),
      edge((0, 1), (0, 2), small[LLVM IR + annotations], "-|>"),
      node(
        (0, 2),
        [*Polly* + Kokkos-specific passes],
        fill: color-red,
        stroke: color-red-stroke,
      ),
      edge((0, 2), (0, 3), small[optimized IR], "-|>"),
      node((0, 3), [LLVM back-end]),
      node(
        (-0.5, 4),
        [CPU (ISL / Pluto)],
        fill: color-green,
        stroke: color-green-stroke,
      ),
      edge((0, 3), (-0.5, 4), "-|>"),
      node(
        (0.5, 4),
        [GPU (PPCG)],
        fill: color-green,
        stroke: color-green-stroke,
      ),
      edge((0, 3), (0.5, 4), "-|>"),
    ))
  ][
    + *Kokkos side* : kernels isolations, backend annotations (bounds, View
      dimensions, backend used), backend simplification, template option to
      activate the polyhedral path.
    + *Polly side* : annotations extraction, upgraded delinearization, IR
      cleaning, global view across kernels, triangular loops.
    + *Back-ends* : Pluto ordonnancement, PPCG GPU code generation.
  ]
]

// ---------------------------------------------------------------- 2. Bridging
#title-slide[Bridging Kokkos and Polly]

#slide(title: "A template option for the polyhedral path: usePolyOpt")[
  #cols(columns: (1.1fr, 1fr), gutter: 1.5em)[
    ```cpp
    Kokkos::parallel_for<Kokkos::usePolyOpt>(policy,
      KOKKOS_LAMBDA(long i, long j) {
        B(i, j) = A(i, j) + A(i, j-1) + A(i, j+1)
                          + A(i-1, j) + A(i+1, j);
      });
    ```
    - Static dispatch between two paths that *coexist* in the library.
    - Without the option, Kokkos stays strictly standard.
  ][
    *The polyhedral path*
    - Leaf functions `noinline` + attribute: Polly scans only them.
    - `MDRangePolicy` re-implemented *without its default tiling*: a clean,
      perfect nest. Polly tiles itself.

    #v(1em)

    *Scope*
    - Policies: `RangePolicy`, `MDRangePolicy`.
    - Backends: `Serial`, `OpenMP`, `Cuda`.
  ]
]

#slide(title: "Annotations and delinearization")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *Annotations* : \
    `__builtin_annotation` -> `llvm.annotate` in the IR, emitted by the Kokkos
    backends.
    - policy loop bounds,
    - array base pointers bound to their *dimension sizes*,
    - the kernel's *execution space*.

    They survive reordering or elimination of loads.
  ][
    *Delinearization* : `A(i,j,k)` becomes one SCEV polynomial \
    #small[`{{{%A,+,8·m·o}<i>,+,8·o}<j>,+,8}<k>`] \
    Polly guesses dimension sizes from its *terms*.

    #framed[`A(0, j, k)` : the term in `i` vanishes, the first dimension cannot
      be deduced, delinearization *fails*.]

    With annotated sizes, `A[i][j][k]` is recovered for any access.
  ]
]

#slide(title: "IR restructuring and backend synchronization")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *Two cleaning passes in Polly*
    - *Forced hoisting* of base pointers and dimension reads out of the nest
      (LICM refuses: possible aliasing).
    - *CFG de-noising*: bound checks and loop versioning replaced by
      `llvm.assume`; Polly constrains the domain and emits one *runtime guard*.
  ][
    *Backend synchronization*
    - Standard Polly: one target per compilation unit (flag).
    - Kokkos: execution space chosen *per kernel*.
    - The backend annotation lets Polly choose *per SCoP*:
      - `Serial` kernel -> not parallelized,
      - `OpenMP` kernel -> OpenMP code generation,
      - `Cuda` kernel -> PPCG path.
  ]
]

// ---------------------------------------------------------------- 3. Complex patterns
#title-slide[Complex execution patterns]

#slide(title: "A global view across kernels: variadic parallel_for")[
  #cols(columns: (1fr, 1fr), gutter: 1em)[
    #align(top)[
      *Idiomatic Kokkos* (gemver): one `parallel_for` per nest, four separate
      SCoPs, no fusion.
      ```cpp
      parallel_for(policy2D, KOKKOS_LAMBDA(long i, long j) {
          A(i,j) += u1(i)*v1(j) + u2(i)*v2(j);
        });
      parallel_for(policy1D, KOKKOS_LAMBDA(long i) {
          for (long j = 0; j < n; j++)
            x(i) += beta * A(j,i) * y(j); 
        });
      parallel_for(policy1D, KOKKOS_LAMBDA(long i) {
          x(i) += z(i);
        });
      parallel_for(policy1D, KOKKOS_LAMBDA(long i) {
          w(i) += alpha * x(i) * y(i);
        });
      ```]
  ][
    *Variadic form*: a sequence of (policy, functor) pairs, executed in order.
    ```cpp
    Kokkos::View<"A", double**> A(...); // static name
    parallel_for<Kokkos::usePolyOpt>("gemver",
      policy2D, KOKKOS_LAMBDA(long i, long j) {
        A(i,j) += u1(i)*v1(j) + u2(i)*v2(j); },
      policy1D, KOKKOS_LAMBDA(long i) {
        for (long j = 0; j < n; j++)
          x(i) += beta * A(j,i) * y(j); 
      },
      policy1D, KOKKOS_LAMBDA(long i) { x(i) += z(i); },
      policy1D, KOKKOS_LAMBDA(long i) {
        w(i) += alpha * A(i,j) * x(j); 
    });
    ```
    - *CFG linearization*: preheaders hoisted above the sequence, one contiguous
      region.
    - *Static naming*: each lambda captures its own pointer copy; same name ->
      RAUW to the first one.
  ]
]

#slide(title: "Relating loop bounds: constraint injection")[
  #cols(columns: (1.2fr, 1fr), gutter: 1.5em)[
    Each policy keeps its own copy of the bounds; Polly must be told how they
    relate.

    *Constraint grammar* : `Operand op Operand`
    - `pN.lM` / `pN.uM` : bound of dimension `M` of policy `N`,
    - `KOKKOS_LOOP_BOUND(n)` : a variable of the body,
    - literals; `==, <, >, <=, >=`.
  ][
    ```cpp
    auto policy = Kokkos::RangePolicy(0, n);
    parallel_for<Kokkos::usePolyOpt, "p0.u0 == n">(policy,
      KOKKOS_LAMBDA(int i) {
        for (int j = 1; j < KOKKOS_LOOP_BOUND(n) - 1; j++)
          A(i, j) = B(i, j);
      });
    ```
    #framed[Fewer SCoP parameters -> *lower compile time* (scheduling is
      exponential in the parameters).]
  ]
]

#slide(title: "Triangular loops written by hand")[
  #cols(columns: (1.2fr, 0.8fr), gutter: 2em)[
    Policies are rectangular, but developers nest C++ loops in the body
    (trisolv):
    ```cpp
    Kokkos::parallel_for<usePolyOpt>(policy,
      KOKKOS_LAMBDA(size_t i) {
        x(i) = b(i);                      // Stmt1
        for (size_t j = 0; j < i; j++)
          x(i) -= L(i, j) * x(j);         // Stmt2
        x(i) = x(i) / L(i, i);            // Stmt3
      });
    ```
    - `i = 0`: empty inner loop, Stmt1 -> Stmt3 that breaks SCoP detection.
    - SCEV: backedge-taken count is `{-1,+,1}<i>`, not invariant.
    - *Peeling* iteration `i = 0` removes the guard -> valid SCoP.
  ][
    #grid(
      columns: (1fr, 1fr),
      gutter: 0.5em,
      align: center,
      image(fig-tri-before, height: 9.5cm), image(fig-tri-after, height: 9.5cm),
      small[Before: irregular branch], small[After peeling],
    )
  ]
]

// ---------------------------------------------------------------- 4. Schedulers
#title-slide[Scheduling for CPU and GPU]

#slide(title: "Pluto on CPU, PPCG on GPU")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *Pluto scheduler integration*
    - ISL (Polly default) minimizes dependence distances incrementally.
    - Pluto targets *tiling and wavefront parallelism* (diamond tiling on
      stencils).
    - Pluto is source-to-source: *OpenScop export/import bridge* around Polly's
      SCoP.
    - Pluto's tile dimensions re-encoded as *schedule-tree band nodes* (domain
      kept invariant).
  ][
    *GPU code generation (PPCG)*
    - *Polly-ACC revived* on the modern Polly.
    - Polly's SCoP feeds PPCG: GPU schedule, mapping to *blocks and threads*.
    - Polly emits device IR + host code (launches, transfers).
    - PPCG exploits *shared memory* and *privatization*.
  ]
]

// ---------------------------------------------------------------- 5. Evaluation
#title-slide[Evaluation]

#slide(title: "Experimental setup")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *Benchmarks* : PolyBench rewritten in Kokkos, large sizes.
    - *Baseline* : idiomatic Kokkos, original algorithm, outer loops
      parallelized. Not expert-tuned: we measure what *automatic* scheduling
      adds.
    - 27 of 30 kernels (3 have data-dependent control flow).
  ][
    *Machines*
    - Dual AMD EPYC 7502 (2 $times$ 32 cores, 512 KB L2/core).
    - Intel Core Ultra 7 265 (20 cores, 3 MB L2/core) + RTX 5090.

    *Toolchain* : Clang/LLVM 23 dev + modified Polly and Kokkos.

    *Coverage*
    - CPU: 53 / 54 variants correct (`atax` + Pluto: bug in Pluto).
    - GPU: 24 / 27 (PPCG does not terminate on 3 stencils).
  ]
]

#slide(title: "CPU results: AMD EPYC 7502 and Intel Core Ultra 7 265")[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    align: center,
    image(fig-cpu-amd, height: 11.2cm),
    image(fig-cpu-intel, height: 11.2cm),
    small[Dual AMD EPYC 7502 (64 threads)],
    small[Intel Core Ultra 7 265 (20 threads)],
    grid.cell(colspan: 2, note[Speedup over the Kokkos OpenMP baseline, ISL and
      Pluto schedulers, tile size 32.]),
  )
]

#slide(title: "CPU results: summary")[
  #cols(columns: (1.3fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (1.8fr, 1fr, 1fr, 1fr, 1fr),
      align: (left, center, center, center, center),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header(
        [],
        table.cell(colspan: 2)[*AMD EPYC*],
        table.cell(colspan: 2)[*Intel Ultra 7*],
        [*Category*], [Pluto], [ISL], [Pluto], [ISL],
      ),
      table.hline(stroke: 0.5pt),
      [Datamining (1)],
      [11.15$times$], [11.15$times$], [19.19$times$], [21.97$times$],
      [BLAS (7)],
      [4.69$times$], [4.27$times$], [4.74$times$], [3.57$times$],
      [Kernels (6)],
      [3.99$times$], [3.89$times$], [4.37$times$], [4.62$times$],
      [Solvers (6)],
      [5.80$times$], [3.48$times$], [4.77$times$], [1.57$times$],
      [Medley (1)],
      [0.49$times$], [0.35$times$], [0.50$times$], [0.35$times$],
      [Stencils (6)],
      [4.31$times$], [0.38$times$], [2.08$times$], [0.38$times$],
      table.hline(stroke: 0.5pt),
      [*All (27)*],
      [*4.44$times$*], [*2.21$times$*], [*3.74$times$*], [*1.88$times$*],
      table.hline(stroke: 1pt),
    )
    #note[Geometric means of speedups per category.]
  ][
    - *24 of 27 kernels* accelerated on each machine by at least one scheduler.
      - AMD: *5.32$times$*
      - Intel: *4.36$times$*
    - Two sources of gain:
      - *locality* (baseline parallel but poor reuse)
      - *parallelism* (baseline partly sequential)
    - *Pluto wins on stencils and solvers*: Pluto exposes wavefront parallelism
      and ISL parallelizes the innermost loop
  ]
]

#slide(title: "GPU results: NVIDIA RTX 5090 with PPCG")[
  #cols(columns: (0.8fr, 1.2fr), gutter: 1em)[
    #align(center, image(fig-gpu, height: 11.2cm))
  ][
    - *16 of 24 kernels* accelerated -> geometric mean 7.25$times$.
    - *Solvers*: skewing exposes wavefront parallelism where the baseline keeps
      a sequential outer loop (`lu`, `cholesky`, `seidel-2d`)
    - *Linear algebra*: shared memory and privatization (`syrk` 43$times$,
      `symm` 34$times$)
    - *Slowdowns* on light kernels (`doitgen`, `deriche`, `jacobi`): same
      parallelism as Kokkos, but with polyhedral boundary-check overhead and
      without Kokkos' launch-parameter heuristics.
  ]
  #note[Speedup over the Kokkos OpenMP baseline, ISL and Pluto schedulers, tile
    size 32.]
]

#slide(title: "Compilation time")[
  #v(0.5em)
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (1fr, 1fr, 1fr, 1fr),
      align: (left, center, center, center),
      stroke: none,
      table.hline(stroke: 1pt),
      table.header([*Kernel*], [ISL], [Pluto], [PPCG]),
      table.hline(stroke: 0.5pt),
      [most kernels], [1.0–1.1], [1.0–1.3], [0.8–1.2],
      [`gemm`], [2.55], [1.06], [0.97],
      [`3mm`], [28.82], [1.38], [17.36],
      [`gesummv`, `syrk`], [1.02], [10.4], [0.99],
      [`heat-3d`], [1.14], [24.04], [∞],
      [`jacobi-2d`], [1.05], [2.60], [88.28],
      [`adi`, `fdtd-2d`], [≤ 1.14], [≤ 1.51], [∞],
      table.hline(stroke: 1pt),
    )
  ][
    - Scheduling is NP-complete: cost follows kernel complexity and dependences.
    - *Comparable to the baseline for most kernels.*
    - Outliers where constraints explode; PPCG never terminates on three
      stencils.
    - Parameter fusion via constraints keeps systems small.
  ]
  #note[Relative compile time of Kokkos vs Kokkos + Polly (Intel)]
]

// ---------------------------------------------------------------- 6. Conclusion
#title-slide[Conclusion]

#slide(title: "Take-aways")[
  #cols(columns: (1fr, 1fr), gutter: 1.5em)[
    *What we showed*
    - The obstacle is *visibility*; a library–compiler co-design removes it.
    - One template option, no application rewrite.
    - Delinearization, inter-kernel fusion, triangular loops, Pluto and PPCG now
      work on Kokkos code.
    - Up to *118$times$* on CPU, *three orders of magnitude* on GPU over
      idiomatic Kokkos.
  ][
    *Limits and future work*
    - Runtime checks for user constraints and static names (today trusted
      as-is).
    - Compilation timeouts on complex stencils.
    - *Adaptive tile and block sizes* from kernel structure and cache hierarchy.
    - More backends: HIP, SYCL; `TeamPolicy`.

    #v(0.4em)
    #framed(title: "Artifact")[
      Docker image (toolchain, benchmarks, scripts):
      #small[`registry.gitlab.inria.fr/eauer-utils/eauer-docker-images/polly-kokkos/debian12:latest`]
    ]
  ]
]

#focus-slide[
  Thank you! \
  #text(size: 0.6em)[Questions?]
]
