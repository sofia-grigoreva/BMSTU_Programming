package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

type Matrix [][]float64

const N = 2000

func getNewMatrix(n int) Matrix {
    m := make(Matrix, n)
    for i := range m {
        m[i] = make([]float64, n)
    }
    return m
}

func getRandomMatrix(n int, r *rand.Rand) Matrix {
	m := getNewMatrix(n)
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			m[i][j] = r.Float64()*10 - 5
		}
	}
	return m
}

func isEqual(a, b Matrix, eps float64) bool {
    if len(a) != len(b) {
        return false
    }
    n := len(a)
    for i := 0; i < n; i++ {
        for j := 0; j < n; j++ {
            if diff := a[i][j] - b[i][j]; diff > eps || diff < -eps {
                return false
            }
        }
    }
    return true
}

func rowMul(a, b Matrix) Matrix {
    n := len(a)
    c := getNewMatrix(n)
    for i := 0; i < n; i++ {
        for k := 0; k < n; k++ {
            aik := a[i][k]
            for j := 0; j < n; j++ {
                c[i][j] += aik * b[k][j]
            }
        }
    }
    return c
}

func columnMul(a, b Matrix) Matrix {
    n := len(a)
    c := getNewMatrix(n)
    for j := 0; j < n; j++ {
        for i := 0; i < n; i++ {
            sum := 0.0
            for k := 0; k < n; k++ {
                sum += a[i][k] * b[k][j]
            }
            c[i][j] = sum
        }
    }
    return c
}

func parallelMu(a, b Matrix, blocks int) Matrix {
    n := len(a)
    c := getNewMatrix(n)

    if blocks < 1 {
        blocks = 1
    }
    if blocks > n {
        blocks = n
    }

    var wg sync.WaitGroup
    rowsPerBlock := n / blocks
    extra := n % blocks

    startRow := 0
    for bIdx := 0; bIdx < blocks; bIdx++ {
        blockRows := rowsPerBlock
        if bIdx < extra {
            blockRows++
        }
        endRow := startRow + blockRows
        if startRow >= endRow {
            break
        }

        wg.Add(1)
        go func(r0, r1 int) {
            defer wg.Done()
            for i := r0; i < r1; i++ {
                for k := 0; k < n; k++ {
                    aik := a[i][k]
                    for j := 0; j < n; j++ {
                        c[i][j] += aik * b[k][j]
                    }
                }
            }
        }(startRow, endRow)

        startRow = endRow
    }

    wg.Wait()
    return c
}

func main() {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	A := getRandomMatrix(N, r)
	B := getRandomMatrix(N, r)

	t1 := time.Now()
	CRow := rowMul(A, B)
	durRow := time.Since(t1)

	t2 := time.Now()
	CCol := columnMul(A, B)
	durCol := time.Since(t2)

	blocks := 2
	t3 := time.Now()
	CPar := parallelMu(A, B, blocks)
	durPar := time.Since(t3)

	fmt.Printf("Сравнение результатов (строки/столбцы): %v\n", isEqual(CRow, CCol, 1e-6))
	fmt.Printf("Сравнение результатов (строки/параллельно): %v\n", isEqual(CRow, CPar, 1e-6))

	fmt.Println()
	fmt.Printf("Время по строкам: %v\n", durRow)
	fmt.Printf("Время по столбцам: %v\n", durCol)
	fmt.Printf("Время с использованием параллельных вычислений (%d блоков): %v\n", blocks, durPar)
}

