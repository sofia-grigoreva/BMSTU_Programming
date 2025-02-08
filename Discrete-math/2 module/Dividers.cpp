#include <iostream>
#include <math.h>

bool previous(long x, long y) {
    for (long i = 2 * y; i < x; i = i + y){
        if (x%i == 0){
            return false;
        }
    }
    if (x == y){
        return false;
    }
    return true;
}

void vertices(long x) {
    long q = ceil(sqrt(x));
    long del[q];
    long count = 0;
    for (long i = 1; i < q; i++){
        if (x%i == 0){
            del[count] = i;
            count++;
        }
    }
    if (x/q == q){
        del[count]=q;
        count++;
    }
    
    for (long i = 0; i < count; i++){
        std::cout << x/del[i] << std::endl;
    }
    for (long i = count - 1; i >= 0; i--){
        std::cout << del[i] << std::endl;
    }
}

void edges(long x) {
    long q = ceil(sqrt(x));
    long del[q];
    long count = 0;
    for (long i = 1; i < q; i++){
        if (x%i == 0){
            del[count] = i;
            count++;
        }
    }
    if (x/q == q){
        del[count]=q;
        count++;
    }
    
    for (long i = 0; i < count; i++){
        if (previous(x, round(x/del[i]))){
                std::cout << x << "--" << x/del[i] <<  std::endl;
                edges(round(x/del[i]));
            }
    }
    
    if (x/q == q){
        del[count]=q;
        count--;
    }
    
    for (long i = count - 1; i >= 0; i--){
        if (previous(x,del[i])){
                std::cout << x << "--" << del[i] <<  std::endl;
                edges(del[i]);
            }
    }
}


int main() {
    long x;
    std::cin >> x;
    std::cout << "graph {" << std::endl;
    vertices(x);
    edges(x);
    std::cout << "}";
    return 0;
}
