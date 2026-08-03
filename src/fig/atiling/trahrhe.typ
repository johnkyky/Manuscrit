/*
  Isl domain:
  [N] -> { [i, j] : 0 <= i <= N and 0 <= j <= i }
*/

/*
  Ehrhart = 1 + 3/2 N + 1/2 N^2
*/
#let i_Ehrhart(N) = {
  return int(((1 / 2) * calc.pow(N, 2)) + ((3 / 2) * N) + 1)
}


#let i_Ranking(N, i, j) = {
  if 0 < i and i <= N and 0 <= j and j <= i {
    return int((1 + (1 / 2) * i + (1 / 2) * calc.pow(i, 2)) + j)
  }
  if i <= 0 and i <= N and 0 <= j <= i {
    return int(1 + j)
  }
  return -1
}

#let i_trahrhe(N, pc) = {
  let i = 0
  let upper_bound = N
  let fixed_upper_bound = N
  let m
  let rank
  let j

  while i + 1 < upper_bound {
    m = calc.div-euclid((i + upper_bound), 2)
    j = 0
    rank = i_Ranking(N, m, j)
    if rank <= pc {
      i = m
    } else {
      upper_bound = m
    }
  }
  if i + 1 == fixed_upper_bound {
    m = i + 1
    j = 0
    rank = i_Ranking(N, m, j)
    if (rank <= pc) {
      i += 1
    }
  }
  return i
}

#let j_Ehrhart(N, lbi, ubi) = {
  return int((1 - (1 / 2) * lbi - (1 / 2) * calc.pow(lbi, 2)) + (3 / 2) * ubi + (1 / 2) * calc.pow(ubi, 2))
}

#let j_Ranking(N, lbi, ubi, i, j) = {
  if lbi >= 0 and N - ubi >= 0 and -2 - lbi + j >= 0 and -j + i >= 0 and ubi - i >= 0 {
    return calc.div-euclid((((2 - lbi - lbi * lbi) + (1 + 2 * ubi) * j - j * j) + 2 * i), 2)
  }
  if N - ubi >= 0 and -1 + j >= 0 and -1 + lbi - j >= 0 and -lbi + i >= 0 and -j + i >= 0 and ubi - i >= 0 {
    return int(((1 - lbi) + ((1 - lbi) + ubi) * j) + i)
  }
  if (
    N - ubi >= 0
      and -1 + j >= 0
      and 1 + lbi - j >= 0
      and -lbi + i >= 0
      and -j + i >= 0
      and ubi - i >= 0
      and lbi >= 0
      and -lbi + j >= 0
  ) {
    return int((1 + (-lbi + ubi) * j) + i)
  }
  if j == 0 and N - ubi >= 0 and ubi - i >= 0 and -1 + lbi >= 0 and -lbi + i >= 0 {
    return int((1 - lbi) + i)
  }
  if lbi >= 0 and N - ubi >= 0 and -lbi + j >= 0 and 1 + lbi - j >= 0 and -j + i >= 0 and ubi - i >= 0 and -j >= 0 {
    return int((1 - j) + i)
  }
  return -1
}

#let j_trahrhe(N, lbi, ubi, pc) = {
  let i = 0
  let j = 0
  let m = 0
  let rank = 0


  let upper_bound = ubi
  let fixed_upper_bound = ubi

  while j + 1 < upper_bound {
    m = calc.div-euclid(j + upper_bound, 2)

    if lbi >= m {
      i = lbi
    } else {
      i = m
    }

    rank = j_Ranking(N, lbi, ubi, i, m)

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
    rank = j_Ranking(N, lbi, ubi, i, m)
    if rank <= pc {
      j += 1
    }
  }
  return j
}
