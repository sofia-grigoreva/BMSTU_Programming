#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

class Canonic {
public:
    std::vector<int> mark;
    int num;
    int m;
    std::vector<std::vector<int>> p;
    
    Canonic(int n, int m, const std::vector<std::vector<int>>& p) : num(0), m(m), p(p) {
        mark.resize(n, -1);
    }

    void DFS(int start) {
        mark[start] = num;
        num++;
        for (int i = 0; i < m; i++) {
            if (mark[p[start][i]] == -1) {
                DFS(p[start][i]);
            }
        }
    }
};

int main() {
    int n, m, q0;
    std::cin >> n >> m >> q0;
    std::vector<std::vector<int>> p(n, std::vector<int>(m));
    std::vector<std::vector<std::string>> v(n, std::vector<std::string>(m));

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            std::cin >> p[i][j];
        }
    }

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            std::cin >> v[i][j];
        }
    }

    Canonic c(n, m, p);
    c.DFS(q0);

    std::cout << n << std::endl;
    std::cout << m << std::endl;
    std::cout << c.mark[q0] << std::endl;

    std::vector<std::vector<int>> p2(n, std::vector<int>(m, 1));
    int j = 0;
    for (int i : c.mark) {
        p2[i] = p[j];
        j++;
    }

    for (int i = 0; i < n; i++) {
        for (j = 0; j < m; j++) {
            p2[i][j] = c.mark[p2[i][j]];
        }
    }
    
    for (int i = 0; i < p2.size(); i++) {
            for (int j = 0; j < m; j++) {
                std::cout << p2[i][j] << " ";
            }
            std::cout << std::endl;
    }
    
    std::vector<std::vector<std::string>> v2(n, std::vector<std::string>(m, ""));
    j = 0;
    for (int i : c.mark) {
        v2[i] = v[j];
        j++;
    }
    
    for (int i = 0; i < v2.size(); i++) {
            for (int j = 0; j < m; j++) {
                std::cout << v2[i][j] << " ";
            }
            std::cout << std::endl;
    }
        

    return 0;
}
