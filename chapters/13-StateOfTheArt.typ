#import "../src/common.typ": *

= State of the art <chapter:stateoftheart>

The evolution of hardware complexity in modern supercomputers has led to a massive increase in both the number of available cores and their computational power. These multi-core architectures are frequently coupled with specialized hardware accelerators, making the development of scientific codes a real challenge. To address this issue, developers have invented distinct programming approaches, relying primarily on two of them: high-level performance portabilité frameworks designed to abstract the hardware and maintain a single source code for multiple architectures, and specialized compilers dedicated to code optimization.

On one hand, high-level performance portability frameworks aim to provide developers with a unified interface to manage parallelism and memory. On the other hand, specialized compilers, such as polyhedral compilers, focus on the mathematical rigor of loop optimization and the exposition of fine-grained parallelism through advanced transformations based on the source code.

Although these two domains coexist, making them interoperate seamlessly remains a major challenge for the compilation community. Extracting a mathematical model from code heavily abstracted by the high-level C++ structures of these frameworks is exceedingly difficult, as the compiler loses critical semantic information during the lowering process. Conversely, the frameworks themselves lack the internal infrastructure required to perform complex static analyses and automatic structural loop transformations.

This chapter reviews the existing literature surrounding these two ecosystems. It first explores how high-level performance portability frameworks achieve performance independently of the target architecture. It then analyzes the evolution of polyhedral compilers, from source-to-source tools to modern IR frameworks, highlighting their inherent limitations when confronted with heavy abstractions. Finally, it explores hybrid approaches and domain-specific languages that attempt to bridge this gap, ultimately demonstrating the need for the novel approach proposed in this thesis.

== Performance Portability Frameworks

The high-performance computing landscape in C++ relies on performance portability frameworks like Kokkos (@sec:kokkos), RAJA~@raja, developed by the Lawrence Livermore National Laboratory (LLNL), or on emerging standards like SYCL~@sycl and C++ Standard Parallelism (`std::par`)~@isostdpar. All these tools share a common philosophy: the strict separation between the algorithm's expression and its execution model. To achieve this, they rely heavily on modern C++ features, particularly lambda expressions and functors, to encapsulate compute kernels. They also use Execution Spaces and Memory Spaces to manage the distribution of computations and data locality across heterogeneous architectures. To illustrate this, @fig:frameworks_syntax compares the different ways to write the same underlying code (a matrix-vector addition) using these various frameworks.

#[
  #show figure: set block(breakable: true)
  #show raw.where(block: true): it => block(breakable: false, it)
  #figure(
    table(
      columns: (auto, 1fr),
      align: (center + horizon, left + horizon),
      stroke: 0.5pt + luma(200),
      [*Framework*], [*Syntax Example (Matrix-Vector Multiplication)*],
      [*`Kokkos`*],
      ```cpp
      void matVecMult_kokkos(int N, int M, View<float**> A,
                             View<float*> x, View<float*> y) {
        auto policy = Kokkos::RangePolicy<>(0, N);

        Kokkos::parallel_for(policy, KOKKOS_LAMBDA(const int i) {
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A(i, j) * x(j);
          y(i) = sum;
        });
      }
      ```,

      [*`RAJA`*],
      ```cpp
      void matVecMult_raja(int N, int M, const float* A,
                           const float* x, float* y) {
        using ExecPolicy = RAJA::omp_parallel_for_exec;

        RAJA::forall<ExecPolicy>(RAJA::RangeSegment(0, N), [=](int i) {
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A[i * M + j] * x[j];
          y[i] = sum;
        });
      }
      ```,

      [*`SYCL`*],
      ```cpp
      void matVecMult_sycl(sycl::queue& q, int N, int M,
                           const float* A, const float* x, float* y) {
        auto policy = sycl::range<1>(N);

        q.parallel_for(policy, [=](sycl::id<1> idx) {
          int i = idx[0];
          float sum = 0.0f;
          for (int j = 0; j < M; ++j)
            sum += A[i * M + j] * x[j];
          y[i] = sum;
        }).wait();
      }
      ```,

      [*`std::par`*],
      ```cpp
      void matVecMult_std(int N, int M, const float* A,
                          const float* x, float* y) {
        std::vector<int> rows(N);
        std::iota(rows.begin(), rows.end(), 0);

        std::for_each(std::execution::par_unseq, rows.begin(), rows.end(),
          [=](int i) {
            float sum = 0.0f;
            for (int j = 0; j < M; ++j)
              sum += A[i * M + j] * x[j];
            y[i] = sum;
        });
      }
      ```,
    ),
    caption: [Syntax comparison of parallel loops across different C++ performance portability frameworks.],
  ) <fig:frameworks_syntax>
]

Although the primary goal of these frameworks is portability, they still offer some structural optimization capabilities. For example, loop tiling is provided in Kokkos, RAJA, and SYCL. This allows developers to apply static tiling on loop nests, which improves data locality in the caches of the target architecture. Kokkos has an algorithm for automatically choosing efficient tile sizes based on the architecture, but it is very limited due to the lack of static information gathered within Kokkos.
Work in Kokkos has been done to add `kokkos-tools`~@kokkostools, an extension that allows monitoring/tracing the code, but also autotuning kernels using external tools like Apex~@apex or Apollo~@apollotuning to specialize the code in search of even higher performance.

However, the fundamental limitation of these frameworks lies in their declarative nature. They act primarily as mapping engines: they blindly map loop iterations to CPU threads or GPU blocks, trusting the code written by the developer. These libraries do not possess an internal static analysis engine capable of analyzing the data dependencies of the compute kernel.

Consequently, it is technically and mathematically impossible for them to restructure the code automatically. Complex transformations that modify the execution order of loop iterations (e.g., fission, skewing) are beyond the reach of these tools. In other words, if the developer writes a structurally sub-optimal loop nest, the framework will faithfully parallelize it, but in a sub-optimal way. Deep code optimization thus remains the sole responsibility of the developer, which limits the maximum potential performance that can be achieved automatically.

== Polyhedral Model and Implementations

Today, there are numerous implementations of compilers and tools based on the polyhedral model. Historically, these tools relied on source-to-source approaches and were limited to analyzing a subset of the C language. One of the most renowned compilers for the quality of its scheduler is Pluto~@plutoscheduler. It enables source-to-source compilation of C code by exploring a vast space of transformations (such as diamond tiling). Another reference tool is PPCG (Polyhedral Parallel Code Generation)~@ppcg, a source-to-source compiler designed to generate optimized GPU code from sequential C code. These purely textual approaches facilitate the extraction of the model: memory accesses, such as multidimensional arrays (for example, A[i][j]), are directly visible as indices, which greatly simplifies the mathematical analysis (@fig:polyhedral_s2s).

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node((0, 0), [Source Code \ (C/C++)], corner-radius: 3pt),
      fletcher.edge((0, 0), (1, 0), "-|>"),
      fletcher.node((1, 0), [Source-to-Source \ (Pluto, PPCG)], fill: rgb("eef5ff"), corner-radius: 3pt),
      fletcher.edge((1, 0), (2, 0), "-|>"),
      fletcher.node((2, 0), [Optimized \ C/C++], corner-radius: 3pt),
      fletcher.edge((2, 0), (3, 0), "-|>"),
      fletcher.node((3, 0), [Compiler], corner-radius: 3pt),
    ),
    caption: [Source-to-Source polyhedral compilation pipeline.],
  ) <fig:polyhedral_s2s>
]


Although these tools achieve excellent performance, their scope of application remains very limited. Relying on rudimentary parsers, they were absolutely not designed to analyze complex codes originating from performance portability frameworks, which make intensive use of metaprogramming and modern C++ structures.

To overcome the complexity associated with parsing high-level languages, the polyhedral compilation community adopted a new approach: lowering the level of analysis. By relying on Intermediate Representations (IR) such as LLVM's, polyhedral tools manage to abstract away the source language (C, C++, Fortran) and the complexities of the compiler front-end.

Graphite~@graphite was one of the first widely adopted polyhedral compilers to use this method, integrating directly into the GCC IR @gccir. Within the LLVM ecosystem, the Polly~@polly1 tool uses the LLVM IR to reconstruct and apply the polyhedral model. More recently, tools like Polygeist~@Polygeist rely on MLIR @mlir, a higher-level LLVM IR representation that allows retaining certain structural information (such as the semantics of `for` loops) without having to reconstruct them from a control flow graph that is closer to the machine. This modern IR-level pipeline is illustrated in @fig:polyhedral_ir.

#[
  #figure(
    fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node-inset: 8pt,
      fletcher.node((0, 1), [Source Code \ (C/C++)], corner-radius: 3pt),
      fletcher.edge((0, 1), (1, 1), "-|>"),
      fletcher.node((1, 1), [Front-End \ (Clang/GCC)], corner-radius: 3pt),
      fletcher.edge((1, 1), (2, 1), "-|>"),
      fletcher.node((2, 1), [IR-Level \ (Polly, Polygeist)], fill: rgb("eef5ff"), corner-radius: 3pt),
      fletcher.edge((2, 1), (3, 1), "-|>"),
      fletcher.node((3, 1), [Back-End], corner-radius: 3pt),
    ),
    caption: [IR-level polyhedral compilation pipeline.],
  ) <fig:polyhedral_ir>
]

Yet, despite the use of IR, modern tools like Polly or Polygeist fail to optimize codes generated by libraries such as Kokkos. This limitation stems from the semantic gap. The architecture of these frameworks, designed to offer the best possible portability and generalization to the user, internally relies on a complex network of lambda expressions, functors, and pointer arithmetic. During compilation, these abstractions hide the linearity of memory accesses, generate aliasing uncertainties, and flatly break the heuristics necessary for constructing the polyhedral model.

== Combining High-Level Abstractions and Polyhedral Optimization

Another approach to mitigate the previously exposed problems consists of raising the level of semantic abstraction by using higher-level languages such as Python or Domain-Specific Languages (DSL), or libraries offering greater expressiveness. Thus, the mathematical semantics of the operations become much more obvious for compilation tools to interpret, drastically reducing the semantic gap between the source code and the application of the polyhedral model.

Tiramisu~@tiramisu perfectly illustrates this dynamic. It is a C++ framework functioning, in its design, as a Domain-Specific Language for high-performance computing. The user formally declares the computations, data sizes, iteration domain, as well as the mathematical transformations to apply (tiling, unrolling, parallelization). By imposing this explicit declaration, the tool can apply polyhedral transformations and generate highly optimized C++ code without the compiler having to guess the underlying structure of the program, as shown in @fig:tiramisu_syntax.

#[
  #show figure: set block(breakable: true)
  #figure(
    ```cpp
    void matVecMul_tiramisu(int N, int M) {
        tiramisu::init("matVecMult");

        tiramisu::var i("i", 0, N);
        tiramisu::var j("j", 0, M);

        tiramisu::input A("A", {i, j}, tiramisu::p_float32);
        tiramisu::input x("x", {j}, tiramisu::p_float32);

        tiramisu::computation y_init("y_init", {i}, tiramisu::expr(0.0f));

        tiramisu::computation y_update("y_update", {i, j}, y_init(i) + A(i, j) * x(j));

        y_init.then(y_update, i);

        y_init.parallelize(i);
        y_update.parallelize(i);

        tiramisu::buffer b_A("b_A", {tiramisu::expr(N), tiramisu::expr(M)}, tiramisu::p_float32, tiramisu::a_input);
        tiramisu::buffer b_x("b_x", {tiramisu::expr(M)}, tiramisu::p_float32, tiramisu::a_input);
        tiramisu::buffer b_y("b_y", {tiramisu::expr(N)}, tiramisu::p_float32, tiramisu::a_output);

        A.store_in(&b_A);
        x.store_in(&b_x);

        y_init.store_in(&b_y, {i});
        y_update.store_in(&b_y, {i});

        tiramisu::codegen({&b_A, &b_x, &b_y}, "matvec_mult.o");
    }
    ```,
    caption: [Example of declarative syntax in Tiramisu, cleanly separating the algorithm and the execution schedule.],
  ) <fig:tiramisu_syntax>
]

Following this same logic of abstraction, other works have turned to the Python ecosystem to overcome the complex memory management of C++. For example, @ramon2018autoparallel demonstrated the effectiveness of applying the polyhedral model directly to NumPy~@numpy operations.
Similarly, initiatives such as PyKokkos~@pykokkos offer high-level Python interfaces. These abstraction layers make it possible to capture mathematical operations in a highly abstract manner. Having access to this preserved semantic information would be highly beneficial for extracting the polyhedral model, all while continuing to hide hardware complexity. An example of this high-level syntax is provided in @fig:pykokkos_syntax.

#[
  #show figure: set block(breakable: true)
  #figure(
    ```python
    import pykokkos as pk

    @pk.workunit
    def matVecMult_kernel(i: int, M: int,
                            A: pk.View2D[pk.float],
                            x: pk.View1D[pk.float],
                            y: pk.View1D[pk.float]):
        sum_val: pk.float = 0.0
        for j in range(M):
            sum_val += A[i, j] * x[j]
        y[i] = sum_val

    def matvec_mult_pykokkos(N: int, M: int, A: pk.View2D, x: pk.View1D, y: pk.View1D):
        pk.parallel_for(N, matvec_kernel, M=M, A=A, x=x, y=y)
    ```,
    caption: [Example of matrix-vector multiplication using the PyKokkos high-level Python interface.],
  ) <fig:pykokkos_syntax>
]

Although these approaches provide highly effective solutions to performance problems, they impose a prohibitive entry cost for the HPC industry. Indeed, they require scientists to completely rewrite their historical and massive simulation codes into new languages or highly specific APIs.

To bypass this rewriting barrier, some works have explored the reverse approach: using portability frameworks as compilation targets. For example, researchers @polykokkosbackend used polyhedral tools to analyze classic sequential C code in order to automatically generate Kokkos code. This strategy combines the mathematical optimization performed upstream with the hardware portability guaranteed by Kokkos downstream.

However, while this method is relevant for modernizing legacy codes, it absolutely does not solve the central problem of the current ecosystem: optimizing codes already written natively in Kokkos. To date, there is no tool capable of ingesting Kokkos source code, analyzing it mathematically, and restructuring its loops from the inside transparently. It is to fill this scientific void that this thesis proposes an integration of the polyhedral model, capable of operating directly beneath Kokkos' abstractions.
