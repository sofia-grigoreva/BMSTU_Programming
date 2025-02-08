#include <iostream>
#include <vector>

class Trio {

public:
    std::vector<int> nums;
    Trio(const std::vector<int>& values) : nums(values) {}
    
    bool static isprtr(int a, int b, int c) {
    if ((a * a + b * b == c * c || a * a + c * c == b * b || b * b + c * c == a * a) && (a * b * c != 0)) {
        return true;
    } else {
        return false;
    }
    }

    class Iterator {
    private:
        const Trio& t;
        size_t index1, index2, index3;

    public:
        
        Iterator(const Trio& arr, size_t idx1, size_t idx2, size_t idx3) : t(arr), index1(idx1), index2(idx2), index3(idx3) {}

        bool operator!=(const Iterator& other) const {
            return index1 != other.t.nums.size() - 2;
        }

        Iterator& operator++() {
        while (true) {
            if (index3 < t.nums.size() - 1) {
                index3++;
            } else if (index2 < t.nums.size() - 2) {
                index2++;
                index3 = index2 + 1;
            } else {
                index1++;
                index2 = index1 + 1;
                index3 = index2 + 1;
            }
            if (isprtr(t.nums[index1], t.nums[index2], t.nums[index3]) ||  index3 >= t.nums.size()){
                break;
            }
        }
            return *this;
        }

        std::vector<int> operator*() const {
            return {t.nums[index1], t.nums[index2], t.nums[index3]};
        }
        
};
        
    Iterator begin() const {
        int i1 = 0;
        int i2 = 1;
        int i3 = 2;
        while (true) {
            if (i3 < nums.size() - 1) {
                i3++;
            } else if (i2 < nums.size() - 2) {
                i2++;
                i3 = i2 + 1;
            } else {
                ++i1;
                i2 = i1 + 1;
                i3 = i2 + 1;
            }
            if (isprtr(nums[i1], nums[i2], nums[i3]) ||  i3 >= nums.size()){
                break;
            }
        }
        return Iterator(*this, i1,i2,i3);
    }
    

    Iterator end() const {
        return Iterator(*this, nums.size(), nums.size(), nums.size());
    }
    
};

int main() {
    std::vector<int> values = {1, 2, 3, 4, 9, 5, 12, 13};
    //values = {1, 2, 3};

    Trio arr(values);

    for (auto it = arr.begin(); it != arr.end(); ++it) {
        std::vector<int> triplet = *it;
        std::cout << triplet[0] << ", " << triplet[1] << ", " << triplet[2] << std::endl;
    }

    return 0;
}
