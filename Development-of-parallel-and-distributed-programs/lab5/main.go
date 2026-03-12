package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

const (
	ROWS        = 1000
	COLS        = 1000
	STEPS       = 100
	NUM_THREADS = 4
)

type Grid struct {
	data [][]int
	rows int
	cols int
}

func NewGrid(rows, cols int) *Grid {
	data := make([][]int, rows)
	for i := range data {
		data[i] = make([]int, cols)
	}
	return &Grid{data: data, rows: rows, cols: cols}
}

func (g *Grid) Copy() *Grid {
	newGrid := NewGrid(g.rows, g.cols)
	for i := 0; i < g.rows; i++ {
		copy(newGrid.data[i], g.data[i])
	}
	return newGrid
}

func (g *Grid) CountNeighbors(row, col int) int {
	count := 0
	for dr := -1; dr <= 1; dr++ {
		for dc := -1; dc <= 1; dc++ {
			if dr == 0 && dc == 0 {
				continue
			}
			r := (row + dr + g.rows) % g.rows
			c := (col + dc + g.cols) % g.cols
			count += g.data[r][c]
		}
	}
	return count
}

func EvolutionSequential(grid *Grid, steps int) time.Duration {
	start := time.Now()
	current := grid.Copy()
	next := NewGrid(grid.rows, grid.cols)

	for step := 0; step < steps; step++ {
		for i := 0; i < current.rows; i++ {
			for j := 0; j < current.cols; j++ {
				neighbors := current.CountNeighbors(i, j)
				if current.data[i][j] == 1 {
					if neighbors < 2 || neighbors > 3 {
						next.data[i][j] = 0
					} else {
						next.data[i][j] = 1
					}
				} else {
					if neighbors == 3 {
						next.data[i][j] = 1
					} else {
						next.data[i][j] = 0
					}
				}
			}
		}
		current, next = next, current
	}

	return time.Since(start)
}

type Barrier struct {
	count    int
	waiting  int
	mutex    sync.Mutex
	cond     *sync.Cond
}

func NewBarrier(count int) *Barrier {
	b := &Barrier{count: count}
	b.cond = sync.NewCond(&b.mutex)
	return b
}

func (b *Barrier) Wait() {
	b.mutex.Lock()
	b.waiting++
	if b.waiting == b.count {
		b.waiting = 0
		b.cond.Broadcast()
	} else {
		b.cond.Wait()
	}
	b.mutex.Unlock()
}

type ThreadData struct {
	localRows    [][]int
	startRow     int
	endRow       int
	threadID     int
	mu           sync.RWMutex
}

type BorderRequest struct {
	requestType int
	result      chan []int
}

const (
	REQUEST_TOP    = 0
	REQUEST_BOTTOM = 1
)

func EvolutionParallel(grid *Grid, steps int, numThreads int) time.Duration {
	start := time.Now()
	rowsPerThread := grid.rows / numThreads

	var wg sync.WaitGroup
	barrier := NewBarrier(numThreads)

	threadData := make([]*ThreadData, numThreads)
	borderRequests := make([]chan BorderRequest, numThreads)

	for t := 0; t < numThreads; t++ {
		borderRequests[t] = make(chan BorderRequest, 10)
		startRow := t * rowsPerThread
		endRow := startRow + rowsPerThread
		if t == numThreads-1 {
			endRow = grid.rows
		}

		localRows := make([][]int, endRow-startRow)
		for i := 0; i < endRow-startRow; i++ {
			localRows[i] = make([]int, grid.cols)
			copy(localRows[i], grid.data[startRow+i])
		}

		threadData[t] = &ThreadData{
			localRows: localRows,
			startRow:  startRow,
			endRow:    endRow,
			threadID:  t,
		}
	}

	for t := 0; t < numThreads; t++ {
		wg.Add(1)
		go func(threadID int) {
			defer wg.Done()

			td := threadData[threadID]
			localRows := td.localRows
			localRowsNext := make([][]int, len(localRows))
			for i := range localRowsNext {
				localRowsNext[i] = make([]int, grid.cols)
			}

			topNeighbor := make([]int, grid.cols)
			bottomNeighbor := make([]int, grid.cols)

			done := make(chan bool)
			go func() {
				for {
					select {
					case req := <-borderRequests[threadID]:
						td.mu.RLock()
						result := make([]int, grid.cols)
						if req.requestType == REQUEST_TOP {
							copy(result, localRows[0])
						} else {
							copy(result, localRows[len(localRows)-1])
						}
						td.mu.RUnlock()
						req.result <- result
					case <-done:
						return
					}
				}
			}()

			for step := 0; step < steps; step++ {
				prevThread := threadID - 1
				if prevThread < 0 {
					prevThread = numThreads - 1
				}
				nextThread := threadID + 1
				if nextThread >= numThreads {
					nextThread = 0
				}

				reqTop := BorderRequest{requestType: REQUEST_BOTTOM, result: make(chan []int, 1)}
				reqBottom := BorderRequest{requestType: REQUEST_TOP, result: make(chan []int, 1)}
				borderRequests[prevThread] <- reqTop
				borderRequests[nextThread] <- reqBottom
				topNeighbor = <-reqTop.result
				bottomNeighbor = <-reqBottom.result

				for i := 0; i < len(localRows); i++ {
					for j := 0; j < grid.cols; j++ {
						count := 0
						for dr := -1; dr <= 1; dr++ {
							for dc := -1; dc <= 1; dc++ {
								if dr == 0 && dc == 0 {
									continue
								}
								r := i + dr
								c := (j + dc + grid.cols) % grid.cols

								var value int
								if r >= 0 && r < len(localRows) {
									value = localRows[r][c]
								} else if r == -1 {
									if topNeighbor != nil {
										value = topNeighbor[c]
									}
								} else if r == len(localRows) {
									if bottomNeighbor != nil {
										value = bottomNeighbor[c]
									}
								}
								count += value
							}
						}

						if localRows[i][j] == 1 {
							if count < 2 || count > 3 {
								localRowsNext[i][j] = 0
							} else {
								localRowsNext[i][j] = 1
							}
						} else {
							if count == 3 {
								localRowsNext[i][j] = 1
							} else {
								localRowsNext[i][j] = 0
							}
						}
					}
				}

				for i := range localRows {
					copy(localRows[i], localRowsNext[i])
				}

				barrier.Wait()
			}
			close(done)
		}(t)
	}

	wg.Wait()
	return time.Since(start)
}

func main() {
	rand.Seed(time.Now().UnixNano())
	grid := NewGrid(ROWS, COLS)
	for i := 0; i < ROWS; i++ {
		for j := 0; j < COLS; j++ {
			grid.data[i][j] = rand.Intn(2)
		}
	}

	seqTime := EvolutionSequential(grid.Copy(), STEPS)
	seqTimePerStep := seqTime.Seconds() * 1000 / float64(STEPS)

	parTime := EvolutionParallel(grid.Copy(), STEPS, NUM_THREADS)
	parTimePerStep := parTime.Seconds() * 1000 / float64(STEPS)

	fmt.Printf("Среднее время выполнения одного шага без потоков: %.4f мс\n", seqTimePerStep)
	fmt.Printf("Среднее время выполнения одного шага с потоками: %.4f мс\n", parTimePerStep)
}

