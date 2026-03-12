package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

const (
	NUM_THREADS        = 4
	NUMBERS_PER_THREAD = 1000
	MAX_VALUE          = 1000
)

type Node struct {
	value int
	next  *Node
}

type SafeList struct {
	head *Node
	rwmu sync.RWMutex
}

func NewSafeList() *SafeList {
	return &SafeList{head: nil}
}

func (sl *SafeList) Contains(value int) bool {
	current := sl.head
	for current != nil {
		if current.value == value {
			return true
		}
		current = current.next
	}
	return false
}

func (sl *SafeList) ContainsWithMutex(value int) bool {
	sl.rwmu.RLock()
	defer sl.rwmu.RUnlock()
	return sl.Contains(value)
}

func (sl *SafeList) Add(value int) bool {
	sl.rwmu.Lock()
	defer sl.rwmu.Unlock()

	if sl.Contains(value) {
		return false
	}

	newNode := &Node{value: value, next: nil}

	if sl.head == nil {
		sl.head = newNode
	} else {
		current := sl.head
		for current.next != nil {
			current = current.next
		}
		current.next = newNode
	}
	return true
}

func (sl *SafeList) CheckNoDuplicates() bool {

	seen := make(map[int]bool)
	current := sl.head
	for current != nil {
		if seen[current.value] {
			return false
		}
		seen[current.value] = true
		current = current.next
	}
	return true
}

func main() {
	rand.Seed(time.Now().UnixNano())
	list := NewSafeList()
	var wg sync.WaitGroup

	for t := 0; t < NUM_THREADS; t++ {
		wg.Add(1)
		go func(threadID int) {
			defer wg.Done()

			added := 0
			for i := 0; i < NUMBERS_PER_THREAD; i++ {
				value := rand.Intn(MAX_VALUE + 1)

				if !list.ContainsWithMutex(value) {
					if list.Add(value) {
						added++
					}
				}
			}
		}(t)
	}

	wg.Wait()

	if list.CheckNoDuplicates() {
		fmt.Println("повторяющихся чисел нет")
	} else {
		fmt.Println("ошибка")
	}
}

