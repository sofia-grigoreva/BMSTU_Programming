#include <iostream>
#include <fstream>
#include <string>
#include <sys/types.h>
#include <dirent.h>
#include <vector>

using namespace std;

string getExtension(const string& filename) {
    size_t pos = filename.rfind('.');
    if (pos != string::npos && pos != filename.length() - 1) {
        return filename.substr(pos + 1);
    }
    return "";
}

string cleanFile(const string& filePath, const string& filename) {
    ifstream inputFile(filePath);
    string line;
    string cleanedText;
    string name;
    int t = 1;
    while (getline(inputFile, line)) {
        size_t pos1 = line.find("public");
        size_t pos = line.find("class");
        if (pos != string::npos && pos1 != string::npos) {
        pos += 5;
        while (line[pos] == ' ') {
                pos++;
            }
            name = "";
            while (line[pos] != ' ' && line[pos] != '{') {
                name += line[pos];
                pos++;
            }
            cleanedText += name + " " + to_string(t) + "\n";
        }
        t++;
    }
    inputFile.close();
    return cleanedText;
}
int main(int argc, char* argv[]) {
    std::string PATH(argv[1]);
    DIR* mydir = opendir(PATH.c_str());
    struct dirent* entry;
    vector<string> classNames;
    while ((entry = readdir(mydir)) != NULL) {
        string filename = entry->d_name;
        string extension = getExtension(filename);
        if (extension == "java") {
            string filePath = PATH + "/" + filename;
            string cleanedText = cleanFile(filePath, filename);
            classNames.push_back(cleanedText);
        }
    }
    closedir(mydir);

    ofstream outputFile("classes.txt");
    if (outputFile.is_open()) {
        for (const string& className : classNames) {
            outputFile << className << endl;
        }
        outputFile.close();
    }

    return 0;
}
