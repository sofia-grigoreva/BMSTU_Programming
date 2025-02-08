/*Vector<T, N> – вектор размера N с элементами типа T, имеющий операции сложения и скалярного умножения. 
Вектор должен быть реализован через массив размера N. 
В Vector<bool, N> каждый компонент должен быть представлен одним битом.*/

#include <iostream>
#include <bitset>
#include <initializer_list>

template<typename T, size_t N>
class Vector {
public:
    T v[N];

    Vector() {}

    Vector(std::initializer_list<T> list) {
        size_t i = 0;
        for (T x : list) {
            v[i++] = x;
            if (i >= N) {
                break;
            }
        }
    }
    
    Vector<T, N> sum(Vector<T, N> v2) {
        Vector<T, N> res;
        for (size_t i = 0; i < N; i++) {
            res.v[i] = v[i] + v2.v[i];
        }
        return res;
    }
    
    T pr(Vector<T, N> v2) {
        T res = 0;
        for (size_t i = 0; i < N; i++) {
            res += v[i] * v2.v[i];
        }
        return res;
    }
    
};

template<size_t N>
class Vector<bool, N> {
public:
    std::bitset<N> v;

    Vector() {}

    Vector(std::initializer_list<bool> list) {
        size_t i = 0;
        for (bool x : list) {
            v[i++] = x;
            if (i >= N) {
                break;
            }
        }
    }
    
    Vector<bool, N> sum(Vector<bool, N> v2) {
        Vector<bool, N> res;
        res.v = v & v2.v;
        return res;
    }
    
    bool pr(Vector<bool, N> v2) {
        return (v & v2.v).count() > 0;
    }
};

int main() {
    Vector<int, 5> v1{1, 2, 3, 1, 2};
    Vector<int, 5> v2{1, 1, 1, 1, 10};

    Vector<int, 5> v3 = v1.sum(v2);
    
    std::cout << v1.pr(v2) << std::endl;
    
    for (size_t i = 0; i < 5; i++) {
        std::cout << v3.v[i] << " ";
    }
    std::cout << std::endl;
    
    Vector<bool, 5> v4{1, 1, 1, 1, 1};
    Vector<bool, 5> v5{0, 0, 0, 0, 1};

    Vector<bool, 5> v6 = v4.sum(v5);
    
    std::cout << v4.pr(v5) << std::endl;
    
    for (size_t i = 0; i < 5; i++) {
        std::cout << v6.v[i] << " ";
    }
    std::cout << std::endl;

    return 0;
}
