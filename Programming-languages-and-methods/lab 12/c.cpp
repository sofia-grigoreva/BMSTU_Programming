#include <iostream>
#include <fstream>
#include <string>
#include <sys/types.h>
#include <dirent.h>
#include <vector>

using namespace std;

string get(const string& st) {
    size_t pos = st.rfind('.');
    if (pos <= 0) return "";
    return st.substr(pos + 1, string::npos);
}

void cleanFile(const string& filePath, const string& filename) {
    ifstream inputFile(filePath);
    string line;
    string cleanedText;
    bool t = false;
    while (getline(inputFile, line)) {
        size_t pos = line.find("//");
        if (pos != string::npos) {
            line.erase(pos);
        }
        pos = line.find("/*");
        if (pos != string::npos) {
            t = true;
            line.erase(pos);
        }
        if (t) {
            pos = line.find("*/");
            if (pos != string::npos) {
                t = false;
                line.erase(0, pos + 2);
            } else {
                line = "";
            }
        }
        cleanedText += line + "\n";
    }

    inputFile.close();

    ofstream outputFile(filename);
    if (outputFile.is_open()) {
        outputFile << cleanedText;
        outputFile.close();
    }
}


int main(int argc, char* argv[]) {
    std::string PATH(argv[1]);
    DIR* mydir = opendir(PATH.c_str());
    struct dirent* entry;
    entry = readdir(mydir);
    vector<string> hyperlinks;
    while (entry) {
        string expansion = get(entry->d_name);
        if (expansion == "c") {
            string filePath = PATH + "//" + entry->d_name;
            cleanFile(filePath, entry->d_name);
        }

        entry = readdir(mydir);
    }
    closedir(mydir);
    cout << endl;
}
