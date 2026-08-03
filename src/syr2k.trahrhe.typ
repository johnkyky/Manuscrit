

#let i_Ehrhart(N, M) = {
  return int(((1 / 2) * N + (1 / 2) * calc.pow(N, 2)) * M)
}

#let i_Ranking(N, M, i, j, k) = {
  if i < N and 0 < j and j <= i and 0 <= k and k < M {
    return int(((1 + (M / 2) * i + (M / 2) * calc.pow(i, 2)) + M * j) + k)
  }
  if j == 0 and 0 < i and i < N and 0 <= k and k < M {
    return int((1 + (M * i) / 2 + (M * calc.pow(i, 2)) / 2) + k)
  }

  if i == 0 and j == 0 and N > 0 and 0 <= k and k < M {
    return 1 + k
  }

  return -1
}

#let i_trahrhe_i(N, M, pc) = {
  let i = 0
  let j = 0
  let k = 0

  let upper_bound = 0
  let fixed_upper_bound = 0
  let m = 0
  let rank = 0

  i = 0

  upper_bound = N - 1
  fixed_upper_bound = N - 1

  while (i + 1 < upper_bound) {
    m = (i + upper_bound) / 2
    j = 0
    k = 0
    rank = i_Ranking(N, M, m, j, k)
    if (rank <= pc) {
      i = m
    } else {
      upper_bound = m
    }
  }
  if (i + 1 == fixed_upper_bound) {
    m = i + 1

    j = 0
    k = 0
    rank = i_Ranking(N, M, m, j, k)
    if (rank <= pc) {
      i += 1
    }
  }
  return int(i)
}

#let j_Ehrhart(N, M, lbi, ubi) = {
  if (lbi >= 0 and -lbi + ubi >= 0 and -1 + N - ubi >= 0 and M >= 0) {
    return ((((2 + 2 * M) + (-1 - M) * lbi + (-1 - M) * lbi * lbi) + (3 + 3 * M) * ubi + (1 + M) * ubi * ubi) / 2)
  }
}

#let j_Ranking(N, M, lbi, ubi, j, i, k) = {
  if (
    lbi >= 0
      and -1 + N - ubi >= 0
      and -2 - lbi + j >= 0
      and -1 - j + i >= 0
      and ubi - i >= 0
      and k >= 0
      and M - k >= 0
      and -lbi + i >= 0
      and j >= 0
  ) {
    return int(
      (
        (
          ((2 + (-1 - M) * lbi + (-1 - M) * lbi * lbi) + ((1 + M) + (2 + 2 * M) * ubi) * j + (-1 - M) * j * j)
            + (2 + 2 * M) * i
        )
          + 2 * k
      )
        / 2,
    )
  }
  if (
    -j + i == 0
      and lbi >= 0
      and -1 + N - ubi >= 0
      and -2 - lbi + j >= 0
      and ubi - j >= 0
      and k >= 0
      and M - k >= 0
      and j >= 0
  ) {
    return int(
      (((2 + (-1 - M) * lbi + (-1 - M) * lbi * lbi) + ((3 + 3 * M) + (2 + 2 * M) * ubi) * j + (-1 - M) * j * j) + 2 * k)
        / 2,
    )
  }
  if (
    -1 + N - ubi >= 0
      and -1 + j >= 0
      and -1 + lbi - j >= 0
      and -1 - lbi + i >= 0
      and ubi - i >= 0
      and k >= 0
      and M - k >= 0
      and lbi >= 0
      and -j + i >= 0
  ) {
    return int(((((1 + (-1 - M) * lbi) + (((1 + M) + (-1 - M) * lbi) + (1 + M) * ubi) * j) + (1 + M) * i) + k))
  }
  if (
    -1 + N - ubi >= 0
      and -lbi + j >= 0
      and -1 + j >= 0
      and 1 + lbi - j >= 0
      and -1 - j + i >= 0
      and ubi - i >= 0
      and k >= 0
      and M - k >= 0
      and lbi >= 0
      and -lbi + i >= 0
  ) {
    return int((((1 + ((-1 - M) * lbi + (1 + M) * ubi) * j) + (1 + M) * i) + k))
  }
  if (
    (
      -lbi + i == 0
        and -lbi + ubi >= 0
        and -1 + N - ubi >= 0
        and -1 + j >= 0
        and -1 + lbi - j >= 0
        and k >= 0
        and M - k >= 0
        and lbi >= 0
    )
      or (
        -j + i == 0
          and -1 + N - ubi >= 0
          and -lbi + j >= 0
          and -1 + j >= 0
          and ubi - j >= 0
          and 1 + lbi - j >= 0
          and k >= 0
          and M - k >= 0
          and lbi >= 0
      )
  ) {
    return int(((1 + (((1 + M) + (-1 - M) * lbi) + (1 + M) * ubi) * j) + k))
  }
  if (
    j == 0
      and -1 + lbi >= 0
      and -1 + N - ubi >= 0
      and -1 - lbi + i >= 0
      and ubi - i >= 0
      and k >= 0
      and M - k >= 0
      and i >= 0
  ) {
    return int((((1 + (-1 - M) * lbi) + (1 + M) * i) + k))
  }
  if (j == 0 and lbi == 0 and -1 + N - ubi >= 0 and -1 + i >= 0 and ubi - i >= 0 and k >= 0 and M - k >= 0) {
    return int(((1 + (1 + M) * i) + k))
  }
  if (
    (-lbi + i == 0 and j == 0 and -1 + lbi >= 0 and -lbi + ubi >= 0 and -1 + N - ubi >= 0 and k >= 0 and M - k >= 0)
      or (i == 0 and j == 0 and lbi == 0 and -1 + N - ubi >= 0 and M - k >= 0 and ubi >= 0 and k >= 0)
  ) {
    return int((1 + k))
  }
  return -1
}

#let j_trahrhe_j(N, M, lbi, ubi, pc) = {
  let i = 0
  let j = 0
  let k = 0

  let upper_bound = 0
  let fixed_upper_bound = 0
  let m = 0
  let rank = 0

  j = 0

  upper_bound = ubi
  fixed_upper_bound = ubi

  while (j + 1 < upper_bound) {
    m = (j + upper_bound) / 2

    if (lbi >= m) {
      i = lbi
    } else {
      i = m
    }
    k = 0

    rank = j_Ranking(N, M, lbi, ubi, m, i, k)

    if (rank <= pc) {
      j = m
    } else {
      upper_bound = m
    }
  }
  if (j + 1 == fixed_upper_bound) {
    m = j + 1

    if (lbi >= m) {
      i = lbi
    } else {
      i = m
    }
    k = 0
    rank = j_Ranking(N, M, lbi, ubi, m, i, k)
    if (rank <= pc) {
      j += 1
    }
  }
  return int(j)
}
