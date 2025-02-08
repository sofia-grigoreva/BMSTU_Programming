#include <iostream>
#include <sstream>
#include <list>
#include <string>

class Line {
public:
    class Iterator;
    Line(const std::string& input) {
        std::istringstream iss(input);
        std::string word;
        int t = 0;
        while (iss >> word) {
            wordList.push_back(word);
            t++;
        }
        n = t;
    }

    ~Line() = default;

    std::string operator[](int i) const {
        auto it = wordList.begin();
        std::advance(it, i);
        return *it;
    }

    int len() const {
        return n;
    }

    Iterator begin() {
        return Iterator(wordList.begin(), wordList);
    }

    Iterator end() {
        return Iterator(wordList.end(), wordList);
    }

    class Iterator {
        friend class Line;
    private:
        std::list<std::string>::iterator p;
        std::list<std::string>& wordList;
    public:
        Iterator(std::list<std::string>::iterator t, std::list<std::string>& list)
            : p(t), wordList(list) {}

        std::string operator*() {
            if (p != wordList.begin()) {
                return *(std::prev(p)) + *p;
            }
            return *p;
        }

        Iterator& operator++() {
            ++p;
            return *this;
        }

        Iterator operator++(int) {
            Iterator tmp(*this);
            ++p;
            return tmp;
        }

        Iterator& operator--() {
            --p;
            return *this;
        }

        Iterator operator--(int) {
            Iterator tmp(*this);
            --p;
            return tmp;
        }

        bool operator!=(const Iterator& iter) {
            return p != iter.p;
        }

        bool operator==(const Iterator& iter) {
            return p == iter.p;
        }
    };

private:
    int n;
    std::list<std::string> wordList;
};

int main() {
    std::string s = "apple pen coconut kiwi";
    Line a(s);
    auto it = a.begin();
    it++;
    while (it != a.end()) {
        std::cout << *it << ' ';
        it++;
    }
    std::cout << std::endl;
    return 0;
}
