#include <iostream>

class Rat {
private:
    int a;
    int b;
    
public:
    Rat(int a, int b){
        this->a = a;
        this->b = b;
    }
    
    Rat(){
        this->a = 0;
        this->b = 0;
    }

    Rat plus (Rat other) {
        int newa = a * other.b + other.a * b;
        int newb = b * other.b;
        return Rat(newa, newb);
    }

    Rat minus (Rat other){
        int newa = a * other.b - other.a * b;
        int newb = b * other.b;
        return Rat(newa, newb);
    }

    Rat umn (Rat other) {
        int newa = a * other.a;
        int newb = b * other.b;
        return Rat(newa, newb);
    }
    
    ~Rat() {
    }

    friend std::ostream& operator<<(std::ostream& os, const Rat& Rat) {
        os << Rat.a << "/" << Rat.b;
        return os;
    }
};


class Matr {
private:
    int n;
    Rat** matr;
    
public:
    Matr(int n){
        this->n = n;
        this->matr = new Rat*[n];
        for (int i = 0; i < n; i++) {
            matr[i] = new Rat[n];
        }
    }

    int getn() {
        return this->n;
    }

    Rat& getelem(int i, int j) {
        return matr[i][j];
    }

    Matr getpodmatr(int i, int j) {
        Matr podmatr(this->n - 1);
        
        int ind1 = 0;
        int ind2 = 0;
        
        for (int k = 0; k < this->n; k++){
            if (k == i) continue;
            for (int l = 0; l < this->n; l++ ){
                if (l == j) continue;
                podmatr.getelem(ind1,ind2) = this->matr[k][l];
                ind2++;
            }
            ind2 = 0;
            ind1++;
        }
    
    
        return podmatr;
    }

    Rat getdet() {
    if (this->n == 1) return this->matr[0][0];
        
    Rat det = Rat(0,1);
        
    for (int i = 0; i < this->n; i++) {
        Matr podmatr = this->getpodmatr(i,0);
        if (i%2 != 0){
            det = det.minus(this->matr[i][0].umn(podmatr.getdet()));
        } else{
            det = det.plus(this->matr[i][0].umn(podmatr.getdet()));
        }
    }
    return det;
}

    ~Matr() {
    }
};

int main() {
    Matr m(3);
    
    m.getelem(0, 0) = Rat(1, 1);
    m.getelem(0, 1) = Rat(2, 3);
    m.getelem(0, 2) = Rat(3, 5);
    m.getelem(1, 0) = Rat(4, 1);
    m.getelem(1, 1) = Rat(5, 2);
    m.getelem(1, 2) = Rat(6, 1);
    m.getelem(2, 0) = Rat(7, 1);
    m.getelem(2, 1) = Rat(8, 1);
    m.getelem(2, 2) = Rat(9, 1);
    
    std::cout << m.getn() << "\n";
    std::cout << m.getelem(1, 1) << "\n";
    
    Matr p = m.getpodmatr(0, 0);
    
    for (int i = 0; i < p.getn(); i++) {
        for (int j = 0; j < p.getn(); j++) {
            std::cout << p.getelem(i, j) << " ";
        }
        std::cout << std::endl;
    }
    
    Rat d = m.getdet();
    std::cout << d << "\n";
    
    return 0;
}
