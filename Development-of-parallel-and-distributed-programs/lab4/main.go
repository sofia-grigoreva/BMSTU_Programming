package main

import (
	"flag"
	"fmt"
	"math/rand"
	"sync"
	"time"
)

const (
	stateThinking  = "is thinking"
	stateTakeLeft  = "takes left fork"
	stateTakeRight = "takes right fork"
	stateEating    = "is eating"
	statePutForks  = "puts down forks"
)

type Philosopher struct {
	id        int
	leftFork  *sync.Mutex
	rightFork *sync.Mutex
}

type Logger struct {
	mu sync.Mutex
}

func (l *Logger) Log(id int, state string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	fmt.Printf("%v: philosopher %d %s\n", time.Since(startTime).Truncate(time.Millisecond), id, state)
}

var startTime time.Time

func (p *Philosopher) Run(stop <-chan struct{}, logger *Logger, minThink, maxThink, minEat, maxEat time.Duration, leftFirst bool) {
	r := rand.New(rand.NewSource(time.Now().UnixNano() + int64(p.id)))

	for {
		select {
		case <-stop:
			return
		default:
		}

		logger.Log(p.id, stateThinking)
		thinkTime := minThink + time.Duration(r.Int63n(int64(maxThink-minThink)))
		time.Sleep(thinkTime)

		if leftFirst {
			p.leftFork.Lock()
			logger.Log(p.id, stateTakeLeft)
			p.rightFork.Lock()
			logger.Log(p.id, stateTakeRight)
		} else {
			p.rightFork.Lock()
			logger.Log(p.id, stateTakeRight)
			p.leftFork.Lock()
			logger.Log(p.id, stateTakeLeft)
		}

		logger.Log(p.id, stateEating)
		eatTime := minEat + time.Duration(r.Int63n(int64(maxEat-minEat)))
		time.Sleep(eatTime)

		logger.Log(p.id, statePutForks)
		p.leftFork.Unlock()
		p.rightFork.Unlock()
	}
}

func main() {
	var (
		nPhilosophers = flag.Int("n", 5, "number of philosophers")
		totalSeconds  = flag.Int("t", 10, "simulation duration in seconds")
	)
	flag.Parse()

	fmt.Printf("Dining Philosophers Problem: N=%d, simulation time=%d seconds\n", *nPhilosophers, *totalSeconds)

	startTime = time.Now()

	forks := make([]*sync.Mutex, *nPhilosophers)
	for i := 0; i < *nPhilosophers; i++ {
		forks[i] = &sync.Mutex{}
	}

	logger := &Logger{}
	stop := make(chan struct{})
	var wg sync.WaitGroup

	minThink := 200 * time.Millisecond
	maxThink := 800 * time.Millisecond
	minEat := 200 * time.Millisecond
	maxEat := 800 * time.Millisecond

	for i := 0; i < *nPhilosophers; i++ {
		left := forks[i]
		right := forks[(i+1)%*nPhilosophers]
		p := &Philosopher{id: i, leftFork: left, rightFork: right}

		wg.Add(1)
		leftFirst := (i%2 == 0)

		go func(ph *Philosopher, lf bool) {
			defer wg.Done()
			ph.Run(stop, logger, minThink, maxThink, minEat, maxEat, lf)
		}(p, leftFirst)
	}

	time.Sleep(time.Duration(*totalSeconds) * time.Second)
	close(stop)
	wg.Wait()

	fmt.Println("Simulation completed.")
}