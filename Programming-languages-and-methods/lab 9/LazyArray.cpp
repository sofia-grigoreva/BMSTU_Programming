/*LazyArray<T> – массив с элементами типа T неопределённого размера, растущий по мере надобности. Должен быть реализован через класс vector. 
Требование к типу T: наличие конструктора по умолчанию. Операции, которые должны быть перегружены для LazyArray<T>:
    1. «[ ]» – получение ссылки на i-тый элемент массива (размер массива должен быть автоматически увеличен, если i выходит за пределы массива);
    2. «( )» – формирование подмассива, содержащего элементы с индексами из указанного диапазона (принимает в качестве параметров границы диапазона, возвращает новый LazyArray<T>).
    3. «==», «!=».*/
    
#include <iostream>   
#include <vector>

template <typename T>

class LazyArray {

public:
    
    std::vector<T> list;

    LazyArray<T>(){
    }


    T& operator[](int index) {
        if (index >= list.size()) {
            list.resize(index + 1);
        }
        return list[index];
    }
    
    bool operator== (const LazyArray<T> &other) const{
    	return list == other.list;
    }
    
    
    bool operator!= (const LazyArray<T> &other) const{
    	return list != other.list;
    }
    
    LazyArray<T> operator()(size_t s, size_t e) {
        LazyArray<T> l ;
        int j = 0;
        for (size_t i = s; i < e; i++){
            l[j] = list[i];
            j++;
        }
        return l;
    }
  
};


int main() {
    LazyArray<int> a1;
    a1[0] = 1;
    a1[1] = 3;
    a1[2] = 6;
    a1[3] = 10;
    a1[4] = 7;
    a1[5] = 9;
    a1[6] = 4;
    
    LazyArray<int> a2;
    a2[0] = 1;
    a2[1] = 2;
    a2[2] = 4;
    
    LazyArray<int> a4;
    a4[0] = 1;
    a4[1] = 2;
    a4[2] = 4;
    
    std::cout << std::boolalpha << (a4 == a2) << std::endl;
    std::cout << std::boolalpha << (a1 != a2) << std::endl;
    LazyArray<int> a3 = a1(2, 5);

    for (size_t i : a3.list) {
        std::cout << i << " ";
    }
    
    std::cout << std::endl;
    return 0;
}
