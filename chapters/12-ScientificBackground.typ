#import "../src/common.typ": *

= Scientific Background <chapter:scientificbackground>

This thesis focuses on applying the polyhedral model to statically optimize the loop nests expressed by Kokkos @kokkos kernels. Because this work bridges high-level performance portability frameworks with low-level mathematical loop transformations, a solid understanding of both domains is required.

This chapter provides the necessary theoretical foundations for the remainder of the manuscript. First, @sec:loopnests presents the Loop nest concept. Then, @sec:kokkos introduces the Kokkos programming model, detailing its memory and execution abstractions. @sec:polyhedral explores the polyhedral representation and @sec:polyhedralecosystem describes the Polyhedral ecosystem tools and compilers with a specific focus in @sec:polly on the Polly tool that forms the base of our implementation.


== Loop Nests <sec:loopnests>

A fundamental loop is programmatically and mathematically defined by an iteration variable $i$ (often called the iterator or index), a lower bound, an upper bound, and a stride.

When one or more loops are enclosed within another loop, the resulting structure is called a *loop nest*. The number of nested loops defines the *depth* of the nest (e.g., a depth of $n$). At any given execution step, the state of a loop nest of depth $n$ is uniquely identified by its *iteration vector* $arrow(i) = (i_1, i_2, dots, i_n)^T$, which groups the current values of all enclosing loop indices.

Within these loops, a *statement* represents the actual computational instruction or operation that is executed at a given iteration point.

These structures are widely used in High Performance Computing and scientific codes, as they provide the primary mechanism for traversing and manipulating large multi-dimensional data structures such as vectors, matrices and tensors.

=== Perfectly Nested Loops

A loop nest is considered *perfectly nested* if all the computational statements are located exclusively within the innermost loop. There is no code executed between the `for` statements of the outer and inner loops.

@code:perfectnest illustrates a perfectly nested loop of depth 2 with one statement `S1`.

#figure(
  ```cpp
  for (int i = 0; i < N; i++) {
      for (int j = 0; j < M; j++) {
          C[i][j] = A[i][j] + B[i][j];  // Statement S1 (Depth 2)
      }
  }
  ```,
  caption: [Example of a perfectly nested loop of depth 2.],
) <code:perfectnest>

=== Imperfectly Nested Loops

In practice, many scientific algorithms cannot be written as perfectly nested loops. We generalize the concept to *imperfectly nested loops*, which occur when computational statements exist at different nesting levels. In other words, statements are interleaved between the loops.

@code:imperfectnest demonstrates an imperfect loop nest where an initialization statement `S1` is executed within the outer loop `i`, but outside the inner loop `j` with the second statement `S2`.

#figure(
  ```cpp
  for (int i = 0; i < N; i++) {
      row_sum[i] = 0;                  // Statement S1 (Depth 1)
      for (int j = 0; j < M; j++) {
          row_sum[i] += A[i][j];       // Statement S2 (Depth 2)
      }
  }
  ```,
  caption: [Example of an imperfectly nested loop where statements exist at different depths.],
) <code:imperfectnest>

While imperfect loop nests are natural for developers to write, they pose a significant challenge for parallelization frameworks like Kokkos, which will be detailed in @sec:kokkos. Extracting parallelism and optimizing data locality in these imperfect nests requires complex code transformations. This mathematical complexity is precisely what the polyhedral model, introduced in the following @sec:polyhedral, is designed to resolve.



== The Kokkos Programming Model <sec:kokkos>

Originally developed to abstract hardware parallelism, the Kokkos programming model has established itself as a reference framework in High-Performance Computing (HPC) and scientific simulation. It provides a unified C++ interface for heterogeneous parallel programming, with a primary focus on performance portability. By offering high-level abstractions for both memory management and execution control, Kokkos simplifies the development process while ensuring that applications achieve optimal performance regardless of the target architecture.

=== Spaces: Execution and Memory

To successfully target various hardware architectures, Kokkos introduces the concept of spaces to abstract the complex execution units and memory hierarchies of modern supercomputers. A typical HPC node is heterogeneous, often coupling a host processor (CPU) with one or more device accelerators (GPUs), each possessing its own distinct physical memory. Kokkos manages this heterogeneity by clearly decoupling where the code runs from where the data resides:

- *Execution Spaces* define where the computational kernels are executed. They map the parallel operations to a specific hardware backend and its underlying programming model. For instance, `Kokkos::Serial` or `Kokkos::OpenMP` dictate that the code will run on the host CPU, whereas `Kokkos::Cuda` or `Kokkos::HIP` target GPU accelerators.
- *Memory Spaces* define where the data is physically allocated. They abstract the memory hierarchy of the target machine. Common examples include `Kokkos::HostSpace` for standard CPU RAM, `Kokkos::CudaSpace` for Cuda GPU device memory, or `Kokkos::CudaUVMSpace` for Unified Virtual Memory.

This concept of spaces is tightly coupled with Kokkos's data abstractions and parallel execution patterns, which are discussed in the following sections.

=== Data Abstraction

To simplify data management across heterogeneous architectures, Kokkos provides a core data abstraction: the Kokkos::View. This templated C++ data structure acts as a lightweight, reference-counted multi-dimensional array. A View encapsulates the data pointer, its dimensions, the target memory space, and its memory layout, effectively abstracting the underlying hardware allocations.

A crucial feature for performance portability is the Memory Layout. Because CPUs and GPUs handle memory accesses differently, Kokkos defines specific layout traits:
- `Kokkos::LayoutRight` (row-major): Optimizes spatial locality and cache-line usage for CPUs.
- `Kokkos::LayoutLeft` (column-major): Ensures memory access coalescing, which is critical for GPU performance.

By default, Kokkos automatically selects the optimal layout at compile time based on the execution space, though it can be explicitly specified by the programmer.

@code:viewexample illustrates a basic heterogeneous memory management workflow. In line 2, a 2D View of floats is allocated directly in the device's memory (`Kokkos::CudaSpace`), explicitly using a left layout. Kokkos handles the low-level CUDA allocation. Line 4 demonstrates the creation of a host-accessible mirror view (`Kokkos::create_mirror_view`). This function allocates an equivalent array in the host memory space, allowing the CPU to safely manipulate the data.

The overloaded parenthesis `operator()` provides an intuitive multi-dimensional access syntax, automatically handling the complex index linearization (line 7). Finally, explicit data synchronization between the host and device memory spaces is performed using `Kokkos::deep_copy` (line 9).

#figure(
  ```cpp
  // ...
  Kokkos::View<float **, Kokkos::CudaSpace, Kokkos::LayoutLeft> tab_device("tab_device", N, N);

  auto tab_host = Kokkos::create_mirror_view(tab_device);

  for(int i = 0; i < N; i++)
      tab_host(i, i) = static_cast<float>(i);

  Kokkos::deep_copy(tab_device, tab_host);
  // ...
  ```,
  caption: [Example of standard `Kokkos::View` allocation and heterogeneous memory transfers.],
) <code:viewexample>

Kokkos provides several specialized view types for advanced use cases (e.g., `DualView`, `DynRankView`, `OffsetView`). However, this thesis will focus exclusively on standard views.

=== Parallel Execution

In the Kokkos programming model, launching a computational kernel requires combining an execution pattern, an execution policy, and the kernel body (typically defined via a C++ lambda function or a functor). This separation of concepts allows developers to express the semantics of their algorithm independently of the underlying hardware mapping.

==== Execution Patterns

To abstract hardware specific parallel programming models (e.g., OpenMP, CUDA), Kokkos provides three fundamental parallel execution patterns. An execution pattern dictates the semantics of the operation:

- `Kokkos::parallel_for`: Maps an independent operation over an iteration space. It represents standard data-parallel loops where no dependencies exist between iterations.
- `Kokkos::parallel_reduce`: Computes a reduction (e.g., sum, min, max, or custom reductions) across an iteration space. Kokkos automatically manages architecture specific data races and concurrency.
- `Kokkos::parallel_scan`: Performs a prefix sum across an iteration space providing a parallel building block.

==== Execution Policies

While the pattern defines *what* operation is performed, the execution policy defines *how* and *where* it is executed. It defines the iteration domain, hints the scheduling strategy depending on the structure type and specifies the target execution space.

===== RangePolicy and MDRangePolicy
`Kokkos::RangePolicy` and `Kokkos::MDRangePolicy` describe basic iteration spaces for one-dimensional and $n$ dimensional perfectly nested loops, respectively. Under the hood, MDRangePolicy automatically applies architecture specific tiling and index linearization to maximize cache locality and memory coalescing.

===== TeamPolicy
For more complex algorithms, flat iteration spaces and basic scheduling are often insufficient. `Kokkos::TeamPolicy` addresses this issue by exposing hierarchical parallelism, which is crucial for fully exploiting specific hardware topologies, particularly on GPUs. It logically divides the iteration space into a one dimensional array of _Leagues_ where each league consists of multiple _Teams_ of threads. When mapped to a GPU, a league typically corresponds to a grid of thread blocks, while a team corresponds to an individual block of threads. On a CPU, a league might map to the available physical cores, with teams utilizing hardware threads or vector lanes. With this more advanced approach, developers gain fine grained control over hardware resources such as exploiting user-managed shared memory on GPUs or explicitly managing cache memory on CPUs to the detriment of development simplicity.

To illustrate how Kokkos exposes multi-dimensional iteration spaces, @code:mdrangeexample demonstrates a simple 2D matrix addition implemented with an `Kokkos::MDRangePolicy`. In this example, the policy explicitly defines a two-dimensional iteration domain (indicated by `Kokkos::Rank<2>`) ranging from $(0, 0)$ to $(N, M)$. The third argument of `Kokkos::parallel_for` is the lambda function, which describes the computational kernel itself. As arguments, this lambda function takes the iteration indices $i$ and $j$ to perform the element-wise operations on the multi-dimensional views.

#figure(
  ```cpp
  Kokkos::View<double**> A("A", N, M);
  Kokkos::View<double**> B("B", N, M);
  Kokkos::View<double**> C("C", N, M);

  Kokkos::parallel_for("MatrixAddition",
      Kokkos::MDRangePolicy<Kokkos::Rank<2>>({0, 0}, {N, M}),
      KOKKOS_LAMBDA(const int i, const int j) {
          C(i, j) = A(i, j) + B(i, j);
      }
  );```,
  caption: [Example of a parallel matrix addition using a `MDRangePolicy`],
) <code:mdrangeexample>




== Polyhedral Model <sec:polyhedral>

The polyhedral model is a powerful mathematical framework enabling the precise analysis and transformation of loop nests. Unlike traditional compilers that apply local, syntactic transformations directly on an #gls("ir") or an #gls("ast"), the polyhedral model relies entirely on algebraic abstractions. This mathematical foundation guarantees the semantic correctness of the applied transformations. To represent loop nests, the model utilizes a geometric representation of iteration domains, memory accesses, data dependencies, and instruction schedules, all expressed through mathematical sets and relations.

#definition(
  title: "Set",
)[
  A _set_ is a collection of coordinates in a single space $E$ of dimension $k$. In the context of the polyhedral model, a set can be formally viewed as a special case of a relation where the input space is zero-dimensional.

  A set can be represented as a parametric polyhedron restricting the valid coordinates:
  $
    S(arrow(p)) = { arrow(x) in E mid(|) A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0)}
  $
  where:
  - $arrow(p)$ is a vector of $N$ parameters,
  - $arrow(x) in E$ is a coordinate vector,
  - $A$ is an $m times (k + N + 1)$ integer matrix that encodes the $m$ affine constraints defining the boundaries of the set.
]

#definition(
  title: "Relation",
)[
  A _relation_ #box($R : E -> F$) is a mapping from a set of input coordinates in an input space $E$ of dimension $k$ to a set of output coordinates in an output space $F$ of dimension $l$.

  #box($x in E$) is said to be related with #box($y in F$) #box([if $(x, y) in E times F$]). It is commonly noted $x space R space y$ or $R space x space y$. A relation can also be represented as a parametric polyhedron:
  $
    R(arrow(p)) = { arrow(x)_"in" -> arrow(x)_"out" in E times F mid(|) A dot.op vec(arrow(x)_"out", arrow(x)_"in", arrow(p), 1) polyrelcst arrow(0)}
  $
  where:
  - $arrow(p)$ is a vector of $N$ parameters,
  - $arrow(x)_"in" in E$ is an input coordinate,
  - $arrow(x)_"out" in F$ is an output coordinate,
  - $A$ is an $m times (k + l + N + 1)$ integer matrix that encodes the $m$ affine constraints of the relation.

  *Note:* In the context of the polyhedral model (and underlying libraries such as ISL), an _integer set_ is fundamentally treated as a special case of a relation where the input space $E$ has a dimension of zero ($k = 0$). It effectively maps from a zero-dimensional space to an output space $F$, reducing to a pure parametric polyhedron that defines a domain of coordinates.
]

By representing loop nests in this manner, the polyhedral model reasons exclusively over mathematical objects, providing significantly greater freedom to safely apply complex transformations. While traditional #gls("ast") or #gls("ir") representations allow for a wide range of standard compiler passes, complex loop optimizations remain highly constrained. However, this mathematical rigor restricts the application domain: the polyhedral model can only optimize loop nests with affine memory accesses and affine loop bounds, formally known as #glspl("scop").

#definition(
  title: "Static Control Part",
)[
  A #gls("scop") is a region of code without function calls or pointer arithmetic, where loop bounds, conditionals, and array subscripts are either constant or affine functions of surrounding loop iterators and global parameters.
]

Within a #gls("scop"), each loop iteration can be represented as an integer point inside a convex polyhedron of dimension $d$, where $d$ corresponds to the maximum loop depth. Data dependencies are modeled as affine relations between the iteration vectors of source and target statements. Consequently, optimizing a code segment equates to applying affine transformations to these iteration spaces to expose parallelism, improve data locality, or reduce synchronization overhead. Such transformations include loop tiling, skewing, and loop fusion or fission.

To illustrate these concepts throughout this section, @fig:scientificbackground:scopexample presents a simple example of a #gls("scop") featuring two statements, $S_1$ and $S_2$, nested within two loops.

#figure(
  ```cpp
  for (int i = 0; i < N; i++)
    for (int j = 0; j < M; j++)
      C[i][j] = A[i][j] + B[i][j];      // Statement S1

  for (int i = 1; i < N; i++)
    for (int j = 0; j < M; j++)
      C[i][j] = C[i][j] + C[i - 1][j];  // Statement S2
  ```,
  caption: [Example of a simple loop nest with two statements.],
) <fig:scientificbackground:scopexample>


=== Polyhedron

#definition(
  title: "Rational Polyhedron/Polytope",
)[
  A rational _$d$-dimensional polyhedron_ $cal(P)$ is a subspace of $bb(Q)^d$ that can be defined by a system of $n in bb(N)^+$ affine inequalities:
  #math.equation(
    block: true,
    alt: "P is a set of x in rationals constrained by n inequalities",
    $
      cal(P) = { arrow(x) in bb(Q)^d | A dot.op arrow(x) + a >= arrow(0) }
    $,
  )
  where $A$ is an $n times d$ integer matrix and $a in bb(Z)^n$. This formulation is known as the _implicit representation_ of a polyhedron.

  Since a polyhedron may extend infinitely in certain directions, a strictly bounded convex polyhedron is specifically called a _polytope_.
]

In the vast majority of real world applications, loop bounds are not explicitly defined by static constants. To address this, symbolic parameters are introduced to represent dynamic bounds and data sizes. Consequently, the polyhedral model extends standard polytopes into parametric ones.

#definition(
  title: "Parametric Polytope",
)[
  A parametric _d-polytope_ $cal(P)(arrow(p))$ is a bounded parametric polyhedron defined by:
  $
    cal(P)(arrow(p)) = { arrow(x) in bb(Q)^d | A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0) }
  $
  where $arrow(p)$ is the symbolic _p-vector_ of the parameters, and $A$ is an $m times (d + p + 1)$ integer matrix encoding the $m$ constraints. \
  Note that these constraints can express both inequalities and equalities. For instance, the pair of inequalities $x_i >= 0$ and $-x_i >= 0$ is naturally used to represent the strict equality $x_i = 0$.
]

Throughout this thesis, we will exclusively use parametric polytopes to geometrically represent loop nests.


=== Statement

#definition(
  title: "Statement Instance",
)[
  A _statement instance_ is a specific execution of a given statement $S$ during a particular iteration of its $k$ surrounding loops. Each statement instance is uniquely identified by the values of its surrounding loop iterators at the time of execution.
]

Returning to @fig:scientificbackground:scopexample, the provided #gls("scop") features two distinct statements nested within two loops. In this context, an instance of statement $S_1$ occurs for every valid combination of the iterators $i$ and $j$.


=== Iteration Domain

A statement is associated with a set of statement instances bounded within a polytope. Each individual instance is uniquely characterized by a vector composed of the iterators from its surrounding loops.

#definition(
  title: "Iteration Vector",
)[
  An _iteration vector_ $arrow(x)$ is a $k$-dimensional column vector that represents the values of the $k$ loop iterators characterizing a specific execution of a statement $S$. It is defined as:
  $
    arrow(x) = vec(x_1, x_2, ..., x_k)
  $
  where $x_i$ is the index of the loop at depth $i$, and $k$ is the total loop depth surrounding the statement.
]

The exhaustive set of all iteration vectors for which a given statement is executed is formally referred to as the iteration domain of that statement.

#definition(
  title: "Iteration Domain",
)[
  The iteration domain of a statement $S$ is the set of all possible iteration vectors $arrow(x)$ for which the statement $S$ is
  executed. It can be represented as a convex polyhedron defined by a system of affine inequalities. This set can be
  represented as the integer points of a parametric polytope:
  $
    cal(D)_(S)(arrow(p)) = { arrow(x) in bb(Z)^k | A dot.op vec(arrow(x), arrow(p), 1) polyrelcst arrow(0) }
  $
  where $arrow(p)$ is a vector of $N$ parameters, $arrow(x)$ is a $k$-iteration vector, and $A$ is a $m times (k times N + 1)$ integer
  matrix that encodes the $m$ constraints of the polytope.
]

@fig:scientificbackground-iterationdomain illustrates the iteration domain of statement $S_1$ derived from the #gls("scop") in @fig:scientificbackground:scopexample. The iteration domain of $S_1$ is geometrically represented as a convex polyhedron in the two-dimensional space defined by the loop indices $i$ and $j$. Each integer point within this polyhedron corresponds to a unique instance of the statement, while the boundaries of the polyhedron are strictly determined by the loop bounds and any conditional statements present in the code.


#figure(
  block(height: 5.5cm, align(bottom, fig.scientificbackground-scopexample)),
  caption: [Geometric representation of the iteration domain for statement $S_1$.],
) <fig:scientificbackground-iterationdomain>


=== Data Dependencies

For the polyhedral model to generate valid transformations that yield the exact same results as the original code, it must strictly respect the program's original data dependencies. Data dependencies act as constraints that restrict the legal execution order of statement instances. They are introduced when multiple statement instances access the same memory location.

#definition(
  title: "Data Dependency",
)[
  Two statement instances $S_1(arrow(x)_1)$ and $S_2(arrow(x)_2)$ are said to be dependent if both instances access the exact same memory location, at least one of the accesses is a write operation, and one instance executes before the other in the original program order.
]

There are three primary types of data dependencies that restrict statement reordering:
- *Read-After-Write (RAW):* A source statement writes to a memory location that is subsequently read by a target statement.
- *Write-After-Read (WAR):* A source statement reads from a memory location before it is overwritten by a target statement.
- *Write-After-Write (WAW):* A source statement writes to a memory location that is later overwritten by a target statement.

The polyhedral model geometrically represents these data dependencies as affine relations between the iteration vectors of the source and target statements.

#definition(
  title: "Dependency relation",
)[
  Dependencies between statement instances of a source statement $S$ and a target statement $T$ can be represented as
  relations between iteration vectors. A couple of integer points in the polyhedron associated with the relation
  represents a dependency between the corresponding source and target iteration vectors. This relation can be represented
  by the following parametric polyhedron:
  $
    delta_(S,T)(arrow(p)) = {arrow(x)_S -> arrow(x)_T | R_(S,T) op(dot) vec(arrow(x)_S, arrow(x)_T, arrow(p), 1) >= arrow(0)}
  $
  where $R_(S,T)$ is a $m times (k + l + N + 1)$ integer matrix, with $m$ the number of constraints, $k = "dim"(arrow(x)_S)$ the
  depth of the source statement, $l = "dim"(arrow(x)_T)$ the depth of the target statement and $N = "dim"(arrow(p))$ the
  number of parameters.
]

Returning to the running example in @fig:scientificbackground:scopexample, we can observe a RAW dependency on statement $S_2$ across the outer loop iterations. Specifically, $S_2$ at iteration $(i', j')$ reads the value `C[i' - 1][j']`, which was previously written by $S_2$ at iteration $(i, j)$ where $i = i' - 1$ and $j = j'$. This loop-carried flow dependency can be formally expressed using our matrix representation:

$
  delta_(S_2,S_2)(arrow(p)) & = { vec(i, j) -> vec(i', j') mid(|) i = i' - 1 "and" j = j' } \
                            & = { vec(i, j) -> vec(i', j') mid(|)
                                mat(
                                  1, 0, -1, 0, 0, 0, 1;
                                  0, 1, 0, -1, 0, 0, 0
                                )
                                dot.op vec(i, j, i', j', N, M, 1) = arrow(0) }
$


=== Scheduling

A schedule dictates the chronological execution order of statement instances within the iteration space. In the polyhedral model, this schedule is represented as an affine relation mapping the iteration vector of a statement to a multidimensional logical date vector.

#definition(
  title: "Schedule Relation",
)[
  Given a statement $S$, a _scheduling relation_ $theta_S$ determines the execution order of its instances. To do so, it maps each instance $arrow(x)$ of a statement $S$ to a _logical execution time_ (or _logical date_) $arrow(t)$:
  $
    theta_S (arrow(p)) = { arrow(x) -> arrow(t) mid(|) T dot.op vec(arrow(x), arrow(t), arrow(p), 1) polyrelcst arrow(0)}
  $
  where $arrow(p)$ is a vector of $N$ parameters, $arrow(x)$ is a $k$-dimensional iteration vector of $S$, $arrow(t)$ is a $d$-dimensional logical scheduling vector, and $T$ is an $m times (k + d + N + 1)$ integer matrix that encodes the $m$ affine constraints of the polyhedron.
]

The schedule abstraction allows compilers to reason about time using multidimensional logical dates rather than explicit, linear execution orders. To compare the execution order of two statement instances based on their logical dates, the model relies on the lexicographic order.

#definition(
  title: "Lexicographic order",
)[
  Given two iteration vectors $arrow(x)$ and $arrow(x)'$ of the same dimension, the lexicographic order $lexordersym$ is
  defined as
  $
    vec(x_1, x_2, ..., x_n) lexordersym vec(x'_1, x'_2, ..., x'_n)
    & <==> exists k, 1 <= k <= n : (forall j : 1 <= j < k | x_j = x'_j) and x_k <= x'_k \
    & <==> cases(
      x_1 <= x'_1,
      "or", x_1 = x'_1 and x_2 <= x'_2,
      "or", ...,
      "or", (forall i in bracket.l.stroked 1"," n bracket.l.stroked "," space x_i = x'_i) and x_n <= x'_n,
    )\
  $
]

Returning to our running example from @fig:scientificbackground:scopexample, the original, unmodified execution schedule maps the 2D iteration domain to a 3D logical time space. The first dimension ($t_0$) encodes the lexical order of the statements, while the remaining dimensions encode the iterators. The corresponding schedule relations are:

$
  theta_(S_1)(arrow(p)) & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|) t_0 = 0 "and" t_1 = i "and" t_2 = j } \
                        & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|)
                            mat(
                              0, 0, -1, 0, 0, 0, 0, 0;
                              1, 0, 0, -1, 0, 0, 0, 0;
                              0, 1, 0, 0, -1, 0, 0, 0
                            )
                            dot.op vec(i, j, t_0, t_1, t_2, N, M, 1) = arrow(0) }
$

$
  theta_(S_2)(arrow(p)) & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|) t_0 = 1 "and" t_1 = i "and" t_2 = j } \
                        & = { vec(i, j) -> vec(t_0, t_1, t_2) mid(|)
                            mat(
                              0, 0, -1, 0, 0, 0, 0, 1;
                              1, 0, 0, -1, 0, 0, 0, 0;
                              0, 1, 0, 0, -1, 0, 0, 0
                            )
                            dot.op vec(i, j, t_0, t_1, t_2, N, M, 1) = arrow(0) }
$

By transforming the 2D spatial domain into a 3D temporal domain, the schedule isolates the execution order. Here, $S_1$ is always executed before $S_2$ at any given iteration because its outer time dimension is statically lower ($t_0 = 0$ for $S_1$, whereas $t_0 = 1$ for $S_2$). Within their respective blocks, both statements are sequentially executed following the original iteration vector $(i, j)$ since $t_1$ and $t_2$ exactly mirror the loop iterators.



== The Polyhedral Ecosystem <sec:polyhedralecosystem>

While the mathematical abstractions of the polyhedral model provide a powerful framework for loop optimization, applying these transformations automatically to real-world programs requires robust software infrastructures. Over the past decades, the compilation community has developed a rich ecosystem to manipulate polyhedral representations, perform dependence analysis, and generate optimized code.

This section explores the core components of this ecosystem, categorizing it into polyhedral tools and compilers.

=== Polyhedral Tools

The application of the polyhedral model relies heavily on underlying mathematical libraries capable of solving complex systems of affine inequalities.

==== Integer Set Library (isl) <sec:isl>

To manipulate polyhedra, the #gls("isl"), developed by Sven Verdoolaege~@ISL, is widely used in the polyhedral community. isl is a C library designed for manipulating sets and relations of integer points bounded by affine constraints.

- *Sets:* Used to represent iteration domains.
- *Maps:* Used to represent access functions, dependencies, and schedules by mapping elements from one set to another.

isl provides highly optimized implementations for essential polyhedral operations, including intersection, union, set difference, emptiness checks, and calculating lexicographic minimums or maximums.

Beyond basic set operations, one of the most critical features of modern isl is its built-in *scheduling engine*. Based on a variant of the Pluto algorithm~@pluto1, isl can automatically compute affine schedules that respect all data dependencies while concurrently maximizing data locality and exposing parallelism.

Finally, once the optimal schedule has been computed, isl features an advanced AST (Abstract Syntax Tree) generator. This component translates the transformed polyhedral representation back into a standard loop nest structure. Because it encapsulates the entire mathematical pipeline, isl serves as the fundamental engine behind almost all modern polyhedral compilers. @fig:isl_syntax_example illustrates how a standard C loop nest is mathematically modeled using isl's sets and maps syntax.


#subpar.super(
  grid(
    columns: 1,
    rows: 2,
    inset: 0.5cm,
    [
      #figure(
        ```C
        for (int i = 0; i < N; i++)
          for (int j = 0; j < M; j++)
            A[i][j] = B[i] + C[j]; // S1
        ```,
        caption: [Source input code],
      )
    ],
    [
      #figure(
        ```text
        // Iteration Set Domain
        [N, M] -> { S1[i, j] : 0 <= i < N and 0 <= j < M }

        // Execution Map Schedule
        [N, M] -> { S1[i, j] -> [i, j] }

        // Memory Maps Accesses
        [N, M] -> { S1[i, j] -> A[i, j] } // Write
        [N, M] -> { S1[i, j] -> B[i] }    // Read
        [N, M] -> { S1[i, j] -> C[j] }    // Read
        ```,
        caption: [isl representation of the iteration domain, schedule, and access functions for the example code.],
      )
    ],
  ),
  caption: [Example of a simple loop nest and its corresponding isl representation.],
  label: <fig:isl_syntax_example>,
)


==== Standardized OpenScop Representation

OpenScop~@openscop is an open specification designed to ensure interoperability by allowing different polyhedral tools to seamlessly exchange data. It models the mathematical systems of affine inequalities (domains, access functions, and schedules) using a structured matrix format, where columns correspond to loop iterators, global parameters, and constant terms, and rows represent affine constraints. @code:openscopexample:source shows a simple loop nest, while its corresponding OpenScop representation is detailed in @code:openscopexample:representation.


#subpar.super(
  grid(
    columns: 1,
    rows: 2,
    inset: 0.5cm,
    [
      #figure(
        ```C
        for (int i = 0; i < N; i++)
          for (int j = 0; j < M; j++)
            A[i][j] = 0;               // Statement S1
        ```,
        caption: [Source input code],
      ) <code:openscopexample:source>
    ],
    [
      #figure(
        ```openscop
        <OpenScop>
        ...
        DOMAIN
        6 6 2 0 0 2
        # e/i|  i    j |  N    M |  1
           1    1    0    0    0    0    ## i >= 0
           1   -1    0    1    0   -1    ## -i+N-1 >= 0
           1    0    0    1    0   -1    ## N-1 >= 0
           1    0    1    0    0    0    ## j >= 0
           1    0   -1    0    1   -1    ## -j+M-1 >= 0
           1    0    0    0    1   -1    ## M-1 >= 0
        # ----------------------------------------------  1.2 Scattering
        SCATTERING
        5 11 5 2 0 2
        # e/i| c1   c2   c3   c4   c5 |  i    j |  N    M |  1
           0   -1    0    0    0    0    0    0    0    0    0    ## c1 == 0
           0    0   -1    0    0    0    1    0    0    0    0    ## c2 == i
           0    0    0   -1    0    0    0    0    0    0    0    ## c3 == 0
           0    0    0    0   -1    0    0    1    0    0    0    ## c4 == j
           0    0    0    0    0   -1    0    0    0    0    0    ## c5 == 0
        # ----------------------------------------------  1.3 Access
        WRITE
        3 9 3 2 0 2
        # e/i| Arr  [1]  [2]|  i    j |  N    M |  1
           0   -1    0    0    0    0    0    0    5    ## Arr == A
           0    0   -1    0    1    0    0    0    0    ## [1] == i
           0    0    0   -1    0    1    0    0    0    ## [2] == j
        ...
        </OpenScop>
        ```,
        caption: [OpenScop representation of the iteration domain, scattering, and access functions for the example code.],
      ) <code:openscopexample:representation>
    ],
  ),
  caption: [Example of a simple loop nest and its corresponding OpenScop representation.],
  label: <fig:openscop>,
)

To ease integration, it is accompanied by the #gls("osl"), a lightweight C API used to easily generate, read, and manipulate these representations. Furthermore, OpenScop's extensible architecture supports various tool-specific extensions, allowing compilers to embed custom metadata without breaking compatibility.


=== Polyhedral Compilers

The research community has developed various compilers to automate loop optimizations. While they all share the same theoretical foundation, they target different levels of the compilation stack and diverse hardware architectures. Some of the most notable polyhedral frameworks include:

- *Pluto~@pluto1*: A source-to-source C compiler renowned for its scheduling algorithm, which automatically computes affine transformations to simultaneously maximize data locality and expose parallelism on multicore CPUs.
- *PPCG (Polyhedral Parallel Code Generator)~@ppcg:* A source-to-source compiler designed specifically for heterogeneous architectures, transforming sequential C loop nests into highly optimized CUDA or OpenCL code for GPU execution.
- *Apollo (Automatic speculative POLyhedral Loop Optimizer)~@apollo:* A framework that extends the traditional static model by applying transformations dynamically at runtime, enabling the optimization of loop nests with unresolved memory accesses or data-dependent control flow.
- *Polygeist~@Polygeist:* A modern C/C++ frontend and optimization framework built on top of MLIR (Multi-Level Intermediate Representation), which leverages the Affine dialect to perform polyhedral transformations within a progressive lowering pipeline.
- *LLVM Polly~@polly1:* An integrated loop optimizer within the LLVM compiler infrastructure that operates directly on the #gls("ir"), abstracting away the source language to perform advanced memory access optimizations and auto-parallelization.

While each of these tools successfully optimizes the performance of the transformed codes, the work presented in this thesis relies primarily on the LLVM infrastructure, utilizing Polly to intercept and optimize Kokkos codes. Consequently, the following section provides a comprehensive deep dive into the architecture and the compilation pipeline of LLVM Polly.



== Deep Dive into LLVM Polly <sec:polly>

Polly~@polly2 is a low level polyhedral loop analysis and optimization framework seamlessly integrated into the LLVM middle-end optimizer. It can be natively invoked through the Clang compiler frontend (e.g., using command-line flags like `-O3 -mllvm -polly`). A key strategic advantage of Polly is its reliance on the LLVM #gls("ir"). By operating strictly at the #gls("ir") level, Polly is completely decoupled from the frontend source language, allowing it to optimize loops regardless of whether the original source code was written in C, C++, Fortran, or any other language supported by the LLVM ecosystem.

This #gls("ir") driven architecture is particularly advantageous when targeting modern high-level parallel frameworks such as Kokkos. Kokkos relies heavily on advanced C++ features, including template metaprogramming, lambda functions, and complex object abstractions, which are notoriously difficult for traditional source-to-source polyhedral compilers to parse and analyze accurately. By positioning Polly in the middle-end, it intercepts the code only after the Clang frontend has fully instantiated the templates, resolved the high-level abstractions, and performed aggressive function inlining. Consequently, Polly operates on a "cleaned up" and canonicalized representation where the underlying multi-dimensional loop nests and memory accesses are explicitly exposed, entirely bypassing the syntactic complexity of the original C++ source code.

=== Architecture and Pipeline Integration

Within the LLVM compiler infrastructure, optimizations are applied as a sequence of passes orchestrated by the Pass Manager. Polly integrates natively into this middle-end pipeline, and its exact point of execution can be controlled via the `-polly-position` command-line flag.

By default—and used during all the experimental work presented in this thesis—Polly is scheduled at the `before-vectorizer` position. This specific placement is highly strategic. Before Polly even inspects the code, the #gls("ir") has already been heavily optimized and canonicalized by standard LLVM passes. Passes such as `mem2reg` (which promotes memory allocations to SSA registers), `simplifycfg` (which cleans up the control-flow graph), and aggressive function inlining have already stripped away the high-level C++ abstraction overhead. Consequently, Polly operates on clean, normalized loop structures and feeds its highly optimized, parallelizable output directly into LLVM's native auto-vectorizer.

#figure(
  image(fig.scientificbackground-pollypipeline),
  caption: [Integration of Polly passes within the LLVM middle-end optimization pipeline at the `before-vectorizer` position. (Source: #link("https://polly.llvm.org/docs/Architecture.html")[LLVM Polly Documentation])],
) <fig:pollypipeline>

Once invoked, Polly executes its own specialized internal pipeline. This subsystem closely mirrors the theoretical polyhedral workflow and consists of a strict sequence of sequential LLVM passes, as illustrated in @fig:pollypipeline:

- *`CodePreparation`:* Performs final transformations to canonicalize the #gls("ir"), ensuring that loop structures and memory accesses are in a form suitable for polyhedral analysis.
- *`ScopDetect`:* Analyzes the control-flow graph to identify valid Single-Entry Single-Exit (SESE) regions that are valid for polyhedral representation.
- *`ScopInfo`:* Extracts the #gls("ir") instructions from valid regions and translates them into exact mathematical isl representations (domains, accesses, exact data dependencies, and original scheduling).
- *`ScheduleOptimizer`:* Invokes the built-in isl scheduling engine to compute optimal affine transformations that maximize data locality and expose parallelism.
- *`IslAst`:* Generates a new #gls("ast") representing the structure of the optimally scheduled loop nest.
- *`CodeGeneration`:* Traverses the #gls("isl") #gls("ast") to emit the final, optimized LLVM #gls("ir"), integrating runtime aliasing and bounds checks when necessary.

The detailed mechanisms of each of these internal passes are explored in the following subsections.

==== Code Preparation

Before identifying polyhedral regions, Polly must ensure the LLVM #gls("ir") is in a highly canonical and simplified state. The `CodePreparation` pass acts as a specialized bridge between the standard LLVM middle-end optimizations and Polly's strict mathematical requirements. It performs transformations, such as simplifying loop exit blocks, normalizing induction variables, rotating loops to obtain the correct structural form, and ensuring that basic blocks are structured in a way that facilitates polyhedral extraction. This preparatory step maximizes the number of loop nests that can be subsequently recognized as valid SCoPs.

==== SCoP Detection

Following the preparatory transformations, the `ScopDetect` pass is responsible for identifying segments of the LLVM #gls("ir") that can be legally optimized using the polyhedral model. Polly operates on the Control-Flow Graph (CFG) to isolate maximal Single-Entry Single-Exit (SESE) regions.

For a SESE region to be validated as a Static Control Part (SCoP), Polly enforces strict acceptance criteria. It relies heavily on LLVM's Scalar Evolution (SCEV) analysis to inspect loop induction variables, bounds, and conditional branches. The region is accepted only if `ScopDetect` can definitively prove that all loop bounds and control-flow conditions are purely affine expressions.

Furthermore, this pass performs a rigorous legality and safety check. The SESE region is immediately rejected if it contains instructions with unknown side effects (such as external or uninlined function calls), non-affine array subscripts, or complex pointer aliasing that cannot be resolved statically.

==== SCoP Building

Once a valid SESE region is successfully detected, the `ScopInfo` pass is executed to translate the underlying LLVM #gls("ir") into the mathematical abstractions of the polyhedral model. This process involves mapping the code structures into #gls("isl") objects.

For each basic block within the region, `ScopInfo` defines a mathematical statement. It then constructs the exact *iteration domain* by translating the affine constraints of the surrounding loops (captured via SCEV) into isl sets. Similarly, memory instructions (such as `load` and `store`) are converted into isl access relations, mapping the logical execution of a statement to specific memory addresses.

Crucially, this phase also extracts the original schedule of the unmodified program and performs a data dependence analysis (identifying Read-After-Write, Write-After-Write, and Write-After-Read dependencies). By the end of this pass, Polly has built a complete and mathematically robust representation of the loop nest, entirely detached from the LLVM #gls("ir"), ready to be optimized by the polyhedral engine.

==== SCoP Optimization

With the mathematical representation fully constructed, the `ScheduleOptimizer` pass delegates the core optimization workload to ISL's built-in scheduling engine. The primary objective of the solver is to compute a new affine schedule that reshapes the execution order of the statement instances. The scheduler searches for transformations that minimize the reuse distance of memory accesses and expose parallelism. Crucially, the engine mathematically guarantees the semantic equivalence of the program: any computed schedule must strictly respect the exact instance-wise data dependencies (RAW, WAR, WAW) extracted during the previous phase.

The output of this pass is an optimized mathematical schedule tree. By isolating loop dimensions that are completely free of cyclic loop-carried dependencies, the solver mathematically proves the absence of data races. This exposed parallelism directly guides the subsequent #gls("ast") generation and code emission phases to safely apply vectorization or multithreading.

=== AST Generation

Taking the newly optimized schedule tree as input, the `IslAst` pass generates an #gls("ast") that logically represents the structure of the transformed loop nest. At this stage, the pass deeply analyzes the mathematical properties of the new schedule to embed crucial execution hints directly into the #gls("ast") nodes.

Specifically, if the #gls("isl") solver has mathematically proven that certain loop dimensions are completely free of loop-carried dependencies, the corresponding #gls("ast") nodes are explicitly annotated as parallel. Similarly, inner loops are annotated as vectorizable. These semantic annotations are fundamental, as they serve as direct directives to guide the code generation phase, safely enabling multithreading and SIMD instructions.

==== Code Generation

The `CodeGeneration` pass is responsible for reconstructing the final, optimized LLVM #gls("ir") from the newly generated #gls("isl") #gls("ast"). By traversing the #gls("ast") nodes, this pass utilizes the LLVM `IRBuilder` to emit the corresponding loop structures and #gls("cfg"). If the traversed #gls("ast") nodes carry the parallel or vector annotations embedded during the previous phase, the code generator translates them into appropriate OpenMP runtime library calls or SIMD directives.

Rather than generating computational instructions from scratch, the generator intelligently reuses the original code. It copies the old LLVM #gls("ir") instructions, as the mathematical operations and data processing logic saved during the `ScopInfo` phase, and injects them into the newly constructed loop bodies. During this copying process, memory instructions (`load` and `store`) are dynamically updated. Their array subscripts and pointer arithmetic are rewritten with the new affine access functions and the newly created loop induction variables.

Finally, to guarantee absolute semantic correctness, Polly employs a loop versioning mechanism. Because static analysis cannot always definitively prove the absence of pointer aliasing or out-of-bounds accesses at compile time, the code generator often emits a block of runtime safety checks. The original, unmodified loop nest is preserved in the #gls("ir") as a fallback path. At runtime, if these safety checks fail, the execution dynamically branches to the original code, ensuring that the polyhedral transformations never compromise the program's validity.

=== Polly's Limitations

While LLVM Polly provides a mechanism for loop optimization, its architectural choice to operate exclusively at the #gls("ir") level introduces several inherent limitations. These challenges are particularly pronounced when analyzing heavily abstracted C++ code like Kokkos.

- *The Semantic Gap and Information Reconstruction:* Operating on LLVM #gls("ir") means that all high-level language constructs have been lowered and flattened. To apply the polyhedral model, Polly must artificially reverse-engineer the original program structure from low-level instructions. This involves recovering multi-dimensional array structures (delinearization), reconstructing loop hierarchies, and logically grouping instructions into mathematical statements. If the original C++ code relies on complex template abstractions, this reconstruction process becomes highly fragile, frequently causing Polly to fail in recognizing valid SCoPs.
- *Lack of GPU Support:* Polly is primarily engineered to optimize data locality and parallelism for multi-core CPUs (via OpenMP and SIMD vectorization). While experimental extensions like Polly-ACC~@pollyacc were historically developed to generate GPU code, they are not actively maintained in the upstream LLVM compiler. Consequently, Polly natively lacks the robust capability to generate optimized CUDA or HIP code for modern heterogeneous architectures.

These inherent structural and hardware-targeting limitations underscore the difficulty of applying standard polyhedral compilers directly to performance-portable frameworks. Overcoming these barriers to unlock polyhedral optimizations for tools like Kokkos, which provide high-level abstractions for both CPU and GPU architectures, forms the core motivation for the methodologies developed in the subsequent chapters of this thesis.
