#include <iostream>
#include <thread>
#include <mutex>
#include <random>
#include <unordered_set>
#include <vector>

constexpr int NUM_THREADS = 4;
constexpr int NUMBERS_PER_THREAD = 1000;
constexpr int MAX_VALUE = 1000;

struct Node {
    int value;
    Node* next;
    
    Node(int val) : value(val), next(nullptr) {}
};

class SafeList {
private:
    Node* head;
    std::mutex read_mutex;   
    std::mutex write_mutex;         

public:
    SafeList() : head(nullptr) {}
    
    ~SafeList() {
        Node* current = head;
        while (current != nullptr) {
            Node* next = current->next;
            delete current;
            current = next;
        }
    }
    
    bool Contains(int value) {
        Node* current = head;
        while (current != nullptr) {
            if (current->value == value) {
                return true;
            }
            current = current->next;
        }
        return false;
    }
    
    bool ContainsWithMutex(int value) {
        read_mutex.lock();
        bool result = Contains(value);
        read_mutex.unlock();
        return result;
    }
    
    bool Add(int value) {
        write_mutex.lock();
        
        if (Contains(value)) {
            write_mutex.unlock();
            return false;
        }
        
        Node* newNode = new Node(value);
        
        if (head == nullptr) {
            head = newNode;
        } else {
            Node* current = head;
            while (current->next != nullptr) {
                current = current->next;
            }
            current->next = newNode;
        }
        
        write_mutex.unlock();
        return true;
    }
    
    bool CheckNoDuplicates() {
        
        std::unordered_set<int> seen;
        Node* current = head;
        while (current != nullptr) {
            if (seen.find(current->value) != seen.end()) {
                return false;
            }
            seen.insert(current->value);
            current = current->next;
        }
        return true;
    }
};

int main() {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, MAX_VALUE);
    
    SafeList list;
    std::vector<std::thread> threads;
    
    for (int t = 0; t < NUM_THREADS; t++) {
        threads.emplace_back([&list, &gen, &dis, t]() {
            int added = 0;
            for (int i = 0; i < NUMBERS_PER_THREAD; i++) {
                int value = dis(gen);
                
                if (!list.ContainsWithMutex(value)) {
                    if (list.Add(value)) {
                        added++;
                    }
                }
            }
        });
    }
    
    for (auto& thread : threads) {
        thread.join();
    }
    
    if (list.CheckNoDuplicates()) {
        std::cout << "повторяющихся чисел нет" << std::endl;
    } else {
        std::cout << "ошибка" << std::endl;
    }
    
    return 0;
}
