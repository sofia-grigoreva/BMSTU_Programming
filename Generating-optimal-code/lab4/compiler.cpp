#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <stack>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

static bool startsWith(const std::string& s, const std::string& pref) {
    return s.rfind(pref, 0) == 0;
}

static bool isIntegerLiteral(const std::string& s) {
    if (s.empty()) return false;
    size_t i = (s[0] == '-') ? 1 : 0;
    if (i == s.size()) return false;
    for (; i < s.size(); ++i) {
        if (!std::isdigit(static_cast<unsigned char>(s[i]))) return false;
    }
    return true;
}

static bool isUserVariableName(const std::string& name) {
    if (isIntegerLiteral(name)) return false;
    if (startsWith(name, "tmp")) return false;
    if (startsWith(name, "cmp")) return false;
    return true;
}

enum class IROpcode {
    ADD, SUB, MUL, DIV,
    LT, GT, LE, GE, EQ, NE,
    ASSIGN,
    PHI,
    COND_BR,
    BR,
    RET
};

struct IRValue {
    std::string name;
    int version;

    IRValue(const std::string& n = "", int v = -1) : name(n), version(v) {}

    std::string toString() const {
        if (name.empty()) return "<empty>";
        if (version >= 0) return name + "_" + std::to_string(version);
        return name;
    }
};

struct IRInstruction {
    IROpcode opcode;
    IRValue result;
    IRValue arg1;
    IRValue arg2;
    std::vector<std::pair<std::string, IRValue>> phiArgs;
    std::string trueLabel;
    std::string falseLabel;

    IRInstruction(IROpcode op = IROpcode::ASSIGN) : opcode(op) {}

    bool isTerminator() const {
        return opcode == IROpcode::COND_BR || opcode == IROpcode::BR || opcode == IROpcode::RET;
    }

    std::string toString() const {
        std::stringstream ss;

        if (!result.name.empty()) {
            ss << result.toString() << " = ";
        }

        switch (opcode) {
            case IROpcode::ADD:
                ss << "add " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::SUB:
                ss << "sub " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::MUL:
                ss << "mul " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::DIV:
                ss << "div " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::LT:
                ss << "lt " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::GT:
                ss << "gt " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::LE:
                ss << "le " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::GE:
                ss << "ge " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::EQ:
                ss << "eq " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::NE:
                ss << "ne " << arg1.toString() << ", " << arg2.toString();
                break;
            case IROpcode::ASSIGN:
                ss << "assign " << arg1.toString();
                break;
            case IROpcode::PHI:
                ss << "phi ";
                for (size_t i = 0; i < phiArgs.size(); ++i) {
                    if (i > 0) ss << ", ";
                    ss << "[" << phiArgs[i].first << ": " << phiArgs[i].second.toString() << "]";
                }
                break;
            case IROpcode::COND_BR:
                ss << "br " << arg1.toString() << ", " << trueLabel << ", " << falseLabel;
                break;
            case IROpcode::BR:
                ss << "br " << trueLabel;
                break;
            case IROpcode::RET:
                ss << "ret " << arg1.toString();
                break;
        }

        return ss.str();
    }
};

class CFGBlock {
public:
    int id;
    std::string name;
    std::vector<IRInstruction> instructions;
    std::vector<CFGBlock*> successors;
    std::vector<CFGBlock*> predecessors;
    std::set<std::string> phiVariables;

    int preOrder = 0;
    int postOrder = 0;
    int revPostOrder = 0;
    bool visited = false;

    CFGBlock(int blockId, const std::string& blockName) : id(blockId), name(blockName) {}

    bool hasTerminator() const {
        return !instructions.empty() && instructions.back().isTerminator();
    }

    void addInstruction(const IRInstruction& instr) {
        if (hasTerminator()) {
            return;
        }
        instructions.push_back(instr);
    }

    void addPhiVariable(const std::string& var) {
        phiVariables.insert(var);
    }

    std::string toString() const {
        std::stringstream ss;
        ss << name << " (Block " << id << ") [pre=" << preOrder
           << ", post=" << postOrder << ", rpo=" << revPostOrder << "]:\n";
        for (const auto& instr : instructions) {
            ss << "  " << instr.toString() << "\n";
        }
        return ss.str();
    }
};


class CFG {
private:
    std::vector<std::unique_ptr<CFGBlock>> blocks;
    CFGBlock* entry = nullptr;
    CFGBlock* exit = nullptr;
    int nextBlockId = 0;

    void dfs(CFGBlock* v, int& preCounter, int& postCounter) {
        v->visited = true;
        v->preOrder = ++preCounter;

        for (CFGBlock* succ : v->successors) {
            if (!succ->visited) dfs(succ, preCounter, postCounter);
        }

        v->postOrder = ++postCounter;
    }

public:
    CFG() {
        entry = createBlock("entry");
        exit = createBlock("exit");
    }

    CFGBlock* createBlock(const std::string& baseName) {
        std::string uniqueName = baseName + "_" + std::to_string(nextBlockId);
        auto block = std::make_unique<CFGBlock>(nextBlockId, uniqueName);
        CFGBlock* ptr = block.get();
        blocks.push_back(std::move(block));
        ++nextBlockId;
        return ptr;
    }

    void addEdge(CFGBlock* from, CFGBlock* to) {
        if (!from || !to) return;

        if (std::find(from->successors.begin(), from->successors.end(), to) == from->successors.end()) {
            from->successors.push_back(to);
        }
        if (std::find(to->predecessors.begin(), to->predecessors.end(), from) == to->predecessors.end()) {
            to->predecessors.push_back(from);
        }
    }

    CFGBlock* getEntry() const { return entry; }
    CFGBlock* getExit() const { return exit; }
    const std::vector<std::unique_ptr<CFGBlock>>& getAllBlocks() const { return blocks; }

    void computeOrders() {
        for (const auto& block : blocks) {
            block->visited = false;
            block->preOrder = 0;
            block->postOrder = 0;
            block->revPostOrder = 0;
        }

        int preCounter = 0;
        int postCounter = 0;
        dfs(entry, preCounter, postCounter);

        std::vector<CFGBlock*> reachable;
        for (const auto& block : blocks) {
            reachable.push_back(block.get());
        }

        std::sort(reachable.begin(), reachable.end(), [](CFGBlock* a, CFGBlock* b) {
            return a->postOrder > b->postOrder;
        });

        int rpo = 1;
        for (CFGBlock* block : reachable) {
            block->revPostOrder = rpo++;
        }
    }

    void print() const {
        for (const auto& block : blocks) {
            std::cout << block->toString();

            std::cout << "  Predecessors: ";
            for (CFGBlock* pred : block->predecessors) std::cout << pred->name << " ";
            std::cout << "\n";

            std::cout << "  Successors: ";
            for (CFGBlock* succ : block->successors) std::cout << succ->name << " ";
            std::cout << "\n\n";
        }
    }

    void toGraphviz(const std::string& filename) const {
        std::ofstream file(filename);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot write Graphviz file: " + filename);
        }

        file << "digraph CFG {\n";
        file << "  node [shape=box, fontname=\"Courier\"];\n";
        file << "  edge [fontname=\"Courier\"];\n";

        for (const auto& block : blocks) {
            file << "  \"" << block->name << "\" [label=\"" << block->name << "\\n";
            for (const auto& instr : block->instructions) {
                std::string s = instr.toString();
                size_t pos = 0;
                while ((pos = s.find('"', pos)) != std::string::npos) {
                    s.replace(pos, 1, "\\\"");
                    pos += 2;
                }
                file << s << "\\n";
            }
            file << "\"];\n";
        }

        for (const auto& block : blocks) {
            for (CFGBlock* succ : block->successors) {
                file << "  \"" << block->name << "\" -> \"" << succ->name << "\";\n";
            }
        }

        file << "}\n";
    }
};


class DominatorInfo {
private:
    CFG* cfg;
    std::map<CFGBlock*, std::set<CFGBlock*>> doms;
    std::map<CFGBlock*, CFGBlock*> idom;
    std::map<CFGBlock*, std::set<CFGBlock*>> domTree;
    std::map<CFGBlock*, std::set<CFGBlock*>> domFrontier;

public:
    explicit DominatorInfo(CFG* c) : cfg(c) {
        computeDominators();
        buildDomTree();
        computeDominanceFrontier();
    }

    CFGBlock* getIDom(CFGBlock* block) const {
        auto it = idom.find(block);
        return it == idom.end() ? nullptr : it->second;
    }

    const std::set<CFGBlock*>& getChildren(CFGBlock* block) const {
        static std::set<CFGBlock*> empty;
        auto it = domTree.find(block);
        return it == domTree.end() ? empty : it->second;
    }

    const std::set<CFGBlock*>& getDomFrontier(CFGBlock* block) const {
        static std::set<CFGBlock*> empty;
        auto it = domFrontier.find(block);
        return it == domFrontier.end() ? empty : it->second;
    }

private:
    void computeDominators() {
        std::vector<CFGBlock*> reachable;
        for (const auto& block : cfg->getAllBlocks()) {
            reachable.push_back(block.get());
        }
        std::set<CFGBlock*> allReachable(reachable.begin(), reachable.end());
        CFGBlock* entry = cfg->getEntry();

        for (CFGBlock* b : reachable) {
            if (b == entry) doms[b] = {b};
            else doms[b] = allReachable;
        }

        bool changed = true;
        while (changed) {
            changed = false;

            std::sort(reachable.begin(), reachable.end(), [](CFGBlock* a, CFGBlock* b) {
                return a->revPostOrder < b->revPostOrder;
            });

            for (CFGBlock* b : reachable) {
                if (b == entry) continue;

                std::set<CFGBlock*> newDoms;
                bool first = true;

                for (CFGBlock* pred : b->predecessors) {
                    if (first) {
                        newDoms = doms[pred];
                        first = false;
                    } else {
                        std::set<CFGBlock*> inter;
                        std::set_intersection(newDoms.begin(), newDoms.end(),
                                              doms[pred].begin(), doms[pred].end(),
                                              std::inserter(inter, inter.begin()));
                        newDoms = inter;
                    }
                }

                newDoms.insert(b);

                if (newDoms != doms[b]) {
                    doms[b] = newDoms;
                    changed = true;
                }
            }
        }

        for (CFGBlock* b : reachable) {
            if (b == entry) {
                idom[b] = nullptr;
                continue;
            }

            CFGBlock* best = nullptr;
            for (CFGBlock* d : doms[b]) {
                if (d == b) continue;
                if (!best || doms[d].size() > doms[best].size()) {
                    best = d;
                }
            }
            idom[b] = best;
        }
    }

    void buildDomTree() {
        for (const auto& pair : idom) {
            CFGBlock* b = pair.first;
            CFGBlock* parent = pair.second;
            if (parent) domTree[parent].insert(b);
        }
    }

    void computeDominanceFrontier() {
        std::vector<CFGBlock*> postOrder;
        for (const auto& block : cfg->getAllBlocks()) {
            postOrder.push_back(block.get());
        }
        std::sort(postOrder.begin(), postOrder.end(), [](CFGBlock* a, CFGBlock* b) {
            return a->postOrder < b->postOrder;
        });

        for (CFGBlock* x : postOrder) {
            domFrontier[x] = std::set<CFGBlock*>();

            for (CFGBlock* y : x->successors) {
                if (getIDom(y) != x) {
                    domFrontier[x].insert(y);
                }
            }

            for (CFGBlock* z : getChildren(x)) {
                for (CFGBlock* y : domFrontier[z]) {
                    if (getIDom(y) != x) {
                        domFrontier[x].insert(y);
                    }
                }
            }
        }
    }
};


class IRGenerator {
private:
    CFG* cfg;
    CFGBlock* currentBlock;
    int nextTempId = 0;

public:
    explicit IRGenerator(CFG* c) : cfg(c), currentBlock(c->getEntry()) {}

    CFGBlock* getCurrentBlock() const { return currentBlock; }
    void setCurrentBlock(CFGBlock* block) { currentBlock = block; }

    IRValue emitBinary(IROpcode opcode, const IRValue& left, const IRValue& right) {
        std::string tempName = "tmp" + std::to_string(nextTempId++);
        IRInstruction instr(opcode);
        instr.result = IRValue(tempName);
        instr.arg1 = left;
        instr.arg2 = right;
        if (currentBlock) currentBlock->addInstruction(instr);
        return IRValue(tempName);
    }

    IRValue emitCompare(IROpcode opcode, const IRValue& left, const IRValue& right) {
        std::string tempName = "cmp" + std::to_string(nextTempId++);
        IRInstruction instr(opcode);
        instr.result = IRValue(tempName);
        instr.arg1 = left;
        instr.arg2 = right;
        if (currentBlock) currentBlock->addInstruction(instr);
        return IRValue(tempName);
    }

    void emitAssignment(const std::string& var, const IRValue& value) {
        IRInstruction instr(IROpcode::ASSIGN);
        instr.result = IRValue(var);
        instr.arg1 = value;
        if (currentBlock) currentBlock->addInstruction(instr);
    }

    void emitReturn(const IRValue& value) {
        if (!currentBlock || currentBlock->hasTerminator()) return;
        IRInstruction instr(IROpcode::RET);
        instr.arg1 = value;
        currentBlock->addInstruction(instr);
        cfg->addEdge(currentBlock, cfg->getExit());
    }

    void emitConditionalBranch(const IRValue& cond, CFGBlock* trueBlock, CFGBlock* falseBlock) {
        if (!currentBlock || currentBlock->hasTerminator()) return;
        IRInstruction instr(IROpcode::COND_BR);
        instr.arg1 = cond;
        instr.trueLabel = trueBlock->name;
        instr.falseLabel = falseBlock->name;
        currentBlock->addInstruction(instr);
        cfg->addEdge(currentBlock, trueBlock);
        cfg->addEdge(currentBlock, falseBlock);
    }

    void emitBranch(CFGBlock* target) {
        if (!currentBlock || currentBlock->hasTerminator()) return;
        IRInstruction instr(IROpcode::BR);
        instr.trueLabel = target->name;
        currentBlock->addInstruction(instr);
        cfg->addEdge(currentBlock, target);
    }
};


enum Token {
    TOK_EOF = -1,
    TOK_IDENT = -2,
    TOK_NUMBER = -3,
    TOK_IF = -4,
    TOK_ELSE = -5,
    TOK_WHILE = -6,
    TOK_RETURN = -7,
    TOK_FUNCTION = -13,
    TOK_LE = -9,
    TOK_GE = -10,
    TOK_EQ = -11,
    TOK_NE = -12
};

class Lexer {
private:
    std::string input;
    size_t pos = 0;

public:
    std::string ident;
    int number = 0;

    explicit Lexer(const std::string& s) : input(s) {}

    int getTok() {
        skipSpacesAndComments();
        if (pos >= input.size()) return TOK_EOF;

        char c = input[pos];

        if (std::isalpha(static_cast<unsigned char>(c)) || c == '_') {
            ident.clear();
            while (pos < input.size()) {
                char x = input[pos];
                if (!std::isalnum(static_cast<unsigned char>(x)) && x != '_') break;
                ident += x;
                ++pos;
            }

            if (ident == "if") return TOK_IF;
            if (ident == "else") return TOK_ELSE;
            if (ident == "while") return TOK_WHILE;
            if (ident == "function") return TOK_FUNCTION;
            if (ident == "return") return TOK_RETURN;
            return TOK_IDENT;
        }

        if (std::isdigit(static_cast<unsigned char>(c))) {
            number = 0;
            while (pos < input.size() && std::isdigit(static_cast<unsigned char>(input[pos]))) {
                number = number * 10 + (input[pos] - '0');
                ++pos;
            }
            return TOK_NUMBER;
        }

        ++pos;

        if (c == '<' && pos < input.size() && input[pos] == '=') {
            ++pos;
            return TOK_LE;
        }
        if (c == '>' && pos < input.size() && input[pos] == '=') {
            ++pos;
            return TOK_GE;
        }
        if (c == '=' && pos < input.size() && input[pos] == '=') {
            ++pos;
            return TOK_EQ;
        }
        if (c == '!' && pos < input.size() && input[pos] == '=') {
            ++pos;
            return TOK_NE;
        }

        return c;
    }

private:
    void skipSpacesAndComments() {
        while (pos < input.size()) {
            while (pos < input.size() && std::isspace(static_cast<unsigned char>(input[pos]))) ++pos;

            if (pos + 1 < input.size() && input[pos] == '/' && input[pos + 1] == '/') {
                pos += 2;
                while (pos < input.size() && input[pos] != '\n') ++pos;
                continue;
            }

            if (pos + 1 < input.size() && input[pos] == '/' && input[pos + 1] == '*') {
                pos += 2;
                while (pos + 1 < input.size() && !(input[pos] == '*' && input[pos + 1] == '/')) ++pos;
                if (pos + 1 < input.size()) pos += 2;
                continue;
            }

            break;
        }
    }
};


class Parser {
private:
    Lexer lexer;
    int currentTok = TOK_EOF;
    IRGenerator* irGen;
    CFG* cfg;
    std::set<std::string> declaredVariables;

public:
    Parser(const std::string& input, IRGenerator* gen, CFG* c)
        : lexer(input), irGen(gen), cfg(c) {
        nextToken();
    }

    void parse() {
        parseFunctionMain();
        if (currentTok != TOK_EOF) {
            error("unexpected tokens after function main");
        }
    }

private:
    void nextToken() {
        currentTok = lexer.getTok();
    }

    void error(const std::string& msg) {
        throw std::runtime_error("Parser error: " + msg);
    }

    bool activeBlockCanReceiveCode() const {
        CFGBlock* b = irGen->getCurrentBlock();
        return b != nullptr && !b->hasTerminator();
    }

    void parseFunctionMain() {
        expect(TOK_FUNCTION, "'function'");
        if (currentTok != TOK_IDENT || lexer.ident != "main") {
            error("expected main after function");
        }
        nextToken();
        expect('(', "'('");
        expect(')', "')'");
        parseBlock();
    }

    void parseStatement() {
        if (!activeBlockCanReceiveCode()) {
            skipStatement();
            return;
        }

        switch (currentTok) {
            case TOK_IDENT:
                parseAssignment(true);
                break;
            case TOK_IF:
                parseIfStatement();
                break;
            case TOK_WHILE:
                parseWhileStatement();
                break;
            case TOK_RETURN:
                parseReturnStatement();
                break;
            case '{':
                parseBlock();
                break;
            case ';':
                nextToken();
                break;
            default:
                nextToken();
                break;
        }
    }

    void expect(int tok, const std::string& what) {
        if (currentTok != tok) error("expected " + what);
        nextToken();
    }

    void parseAssignment(bool needSemicolon) {
        if (currentTok != TOK_IDENT) error("assignment identifier");
        std::string varName = lexer.ident;

        declaredVariables.insert(varName);

        nextToken();
        expect('=', "'='");

        IRValue value = parseExpression();
        irGen->emitAssignment(varName, value);

        if (needSemicolon) expect(';', "';'");
    }

    void parseReturnStatement() {
        expect(TOK_RETURN, "'return'");
        IRValue value = parseExpression();
        irGen->emitReturn(value);
        expect(';', "';'");
    }

    void parseBlock() {
        expect('{', "'{'");
        while (currentTok != TOK_EOF && currentTok != '}') {
            parseStatement();
        }
        expect('}', "'}'");
    }

    void parseIfStatement() {
        expect(TOK_IF, "'if'");
        expect('(', "'('");
        IRValue cond = parseExpression();
        expect(')', "')'");

        CFGBlock* thenBlock = cfg->createBlock("then");
        CFGBlock* elseBlock = cfg->createBlock("else");
        CFGBlock* mergeBlock = cfg->createBlock("ifcont");

        irGen->emitConditionalBranch(cond, thenBlock, elseBlock);

        irGen->setCurrentBlock(thenBlock);
        parseBlock();
        bool thenReachesMerge = !thenBlock->hasTerminator();
        if (thenReachesMerge) irGen->emitBranch(mergeBlock);

        irGen->setCurrentBlock(elseBlock);
        if (currentTok == TOK_ELSE) {
            nextToken();
            parseBlock();
        }
        bool elseReachesMerge = !elseBlock->hasTerminator();
        if (elseReachesMerge) irGen->emitBranch(mergeBlock);

        if (thenReachesMerge || elseReachesMerge) {
            irGen->setCurrentBlock(mergeBlock);
        } else {
            irGen->setCurrentBlock(nullptr);
        }
    }

    void parseWhileStatement() {
        expect(TOK_WHILE, "'while'");
        expect('(', "'('");

        CFGBlock* condBlock = cfg->createBlock("while_cond");
        CFGBlock* bodyBlock = cfg->createBlock("while_body");
        CFGBlock* exitBlock = cfg->createBlock("while_exit");

        irGen->emitBranch(condBlock);

        irGen->setCurrentBlock(condBlock);
        IRValue cond = parseExpression();
        expect(')', "')'");
        irGen->emitConditionalBranch(cond, bodyBlock, exitBlock);

        irGen->setCurrentBlock(bodyBlock);
        if (currentTok == '{') {
            parseBlock();
        } else {
            parseStatement();
        }

        CFGBlock* bodyExitBlock = irGen->getCurrentBlock();
        if (bodyExitBlock && !bodyExitBlock->hasTerminator()) {
            irGen->emitBranch(condBlock);
        }

        irGen->setCurrentBlock(exitBlock);
    }

    IRValue parseExpression() {
        return parseComparison();
    }

    IRValue parseComparison() {
        IRValue left = parseAdditive();

        while (currentTok == '<' || currentTok == '>' || currentTok == TOK_LE ||
               currentTok == TOK_GE || currentTok == TOK_EQ || currentTok == TOK_NE) {
            int op = currentTok;
            nextToken();
            IRValue right = parseAdditive();

            switch (op) {
                case '<':
                    left = irGen->emitCompare(IROpcode::LT, left, right);
                    break;
                case '>':
                    left = irGen->emitCompare(IROpcode::GT, left, right);
                    break;
                case TOK_LE:
                    left = irGen->emitCompare(IROpcode::LE, left, right);
                    break;
                case TOK_GE:
                    left = irGen->emitCompare(IROpcode::GE, left, right);
                    break;
                case TOK_EQ:
                    left = irGen->emitCompare(IROpcode::EQ, left, right);
                    break;
                case TOK_NE:
                    left = irGen->emitCompare(IROpcode::NE, left, right);
                    break;
            }
        }

        return left;
    }

    IRValue parseAdditive() {
        IRValue left = parseMultiplicative();

        while (currentTok == '+' || currentTok == '-') {
            int op = currentTok;
            nextToken();
            IRValue right = parseMultiplicative();
            left = irGen->emitBinary(op == '+' ? IROpcode::ADD : IROpcode::SUB, left, right);
        }

        return left;
    }

    IRValue parseMultiplicative() {
        IRValue left = parsePrimary();

        while (currentTok == '*' || currentTok == '/') {
            int op = currentTok;
            nextToken();
            IRValue right = parsePrimary();
            left = irGen->emitBinary(op == '*' ? IROpcode::MUL : IROpcode::DIV, left, right);
        }

        return left;
    }

    IRValue parsePrimary() {
        if (currentTok == TOK_NUMBER) {
            int value = lexer.number;
            nextToken();
            return IRValue(std::to_string(value));
        }

        if (currentTok == TOK_IDENT) {
            std::string varName = lexer.ident;
            if (!declaredVariables.count(varName)) {
                error("variable '" + varName + "' is not declared");
            }
            nextToken();
            return IRValue(varName);
        }

        if (currentTok == '(') {
            nextToken();
            IRValue value = parseExpression();
            expect(')', "')'");
            return value;
        }

        error("primary expression");
        return IRValue();
    }

    void skipStatement() {
        if (currentTok == TOK_EOF) return;

        if (currentTok == '{') {
            skipBalancedBlock();
            return;
        }

        if (currentTok == TOK_IF) {
            nextToken();
            if (currentTok == '(') skipBalancedParen();
            skipStatement();
            if (currentTok == TOK_ELSE) {
                nextToken();
                skipStatement();
            }
            return;
        }

        if (currentTok == TOK_WHILE) {
            nextToken();
            if (currentTok == '(') skipBalancedParen();
            skipStatement();
            return;
        }

        while (currentTok != TOK_EOF && currentTok != ';' && currentTok != '}') {
            nextToken();
        }
        if (currentTok == ';') nextToken();
    }

    void skipBalancedParen() {
        if (currentTok != '(') return;
        int depth = 0;
        do {
            if (currentTok == '(') ++depth;
            else if (currentTok == ')') --depth;
            nextToken();
        } while (currentTok != TOK_EOF && depth > 0);
    }

    void skipBalancedBlock() {
        if (currentTok != '{') return;
        int depth = 0;
        do {
            if (currentTok == '{') ++depth;
            else if (currentTok == '}') --depth;
            nextToken();
        } while (currentTok != TOK_EOF && depth > 0);
    }
};


class SSABuilder {
private:
    CFG* cfg;
    DominatorInfo* domInfo;

    std::map<std::string, std::set<CFGBlock*>> varDefBlocks;
public:
    SSABuilder(CFG* c, DominatorInfo* d) : cfg(c), domInfo(d) {}

    void buildSSA() {
        collectVariableDefinitions();
        placePhiFunctions();
        insertPhiInstructions();
        renameVariables();
    }

private:
    void collectVariableDefinitions() {
        for (const auto& blockPtr : cfg->getAllBlocks()) {
            CFGBlock* block = blockPtr.get();

            for (const IRInstruction& instr : block->instructions) {
                if (!instr.result.name.empty() && isUserVariableName(instr.result.name)) {
                    varDefBlocks[instr.result.name].insert(block);
                }
            }
        }
    }

    std::set<CFGBlock*> dfSet(const std::set<CFGBlock*>& s) const {
        std::set<CFGBlock*> res;
        for (CFGBlock* v : s) {
            for (CFGBlock* y : domInfo->getDomFrontier(v)) {
                res.insert(y);
            }
        }
        return res;
    }

    std::set<CFGBlock*> dfpSet(const std::set<CFGBlock*>& s) const {
        std::set<CFGBlock*> res;
        std::set<CFGBlock*> dfp = dfSet(s);
        bool change = true;

        while (change) {
            change = false;

            std::set<CFGBlock*> combined = s;
            combined.insert(dfp.begin(), dfp.end());
            dfp = dfSet(combined);

            if (dfp != res) {
                res = dfp;
                change = true;
            }
        }

        return res;
    }

    void placePhiFunctions() {
        for (const auto& entry : varDefBlocks) {
            const std::string& varName = entry.first;
            const std::set<CFGBlock*>& defBlocks = entry.second;

            for (CFGBlock* y : dfpSet(defBlocks)) {
                if (y == cfg->getExit()) {
                    continue;
                }
                y->addPhiVariable(varName);
            }
        }
    }

    void insertPhiInstructions() {
        for (const auto& blockPtr : cfg->getAllBlocks()) {
            CFGBlock* block = blockPtr.get();
            if (block->phiVariables.empty()) continue;

            std::vector<IRInstruction> phis;
            for (const std::string& var : block->phiVariables) {
                IRInstruction phi(IROpcode::PHI);
                phi.result = IRValue(var);
                phis.push_back(phi);
            }

            block->instructions.insert(block->instructions.begin(), phis.begin(), phis.end());
        }
    }

    void renameVariables() {
        for (const auto& entry : varDefBlocks) {
            renameVar(entry.first);
        }
    }

    void renameVar(const std::string& p) {
        int counter = 0;
        std::stack<int> stack;
        traverse(cfg->getEntry(), p, counter, stack);
    }

    void traverse(CFGBlock* v, const std::string& p, int& counter, std::stack<int>& stack) {
        for (IRInstruction& instr : v->instructions) {
            if (instr.opcode != IROpcode::PHI) {
                continue;
            }
            if (instr.result.name != p) {
                continue;
            }
            int i = counter;
            instr.result.version = i;
            stack.push(i);
            counter = i + 1;
        }

        for (IRInstruction& instr : v->instructions) {
            if (instr.opcode == IROpcode::PHI) {
                continue;
            }

            renameUse(p, stack, instr.arg1);
            renameUse(p, stack, instr.arg2);

            if (instr.result.name == p) {
                int i = counter;
                instr.result.version = i;
                stack.push(i);
                counter = i + 1;
            }
        }

        for (CFGBlock* v1 : v->successors) {
            for (IRInstruction& phi : v1->instructions) {
                if (phi.opcode != IROpcode::PHI) {
                    continue;
                }
                if (phi.result.name != p) {
                    continue;
                }
                if (!stack.empty()) {
                    phi.phiArgs.push_back({v->name, IRValue(p, stack.top())});
                } else {
                    phi.phiArgs.push_back({v->name, IRValue(p)});
                }
            }
        }

        for (CFGBlock* v1 : domInfo->getChildren(v)) {
            traverse(v1, p, counter, stack);
        }

        for (IRInstruction& instr : v->instructions) {
            if (instr.result.name == p) {
                if (!stack.empty()) {
                    stack.pop();
                }
            }
        }
    }

    void renameUse(const std::string& p, const std::stack<int>& stack, IRValue& value) {
        if (value.name != p) {
            return;
        }
        if (!stack.empty()) {
            value.version = stack.top();
        }
    }
};


std::string readProgramFromFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Cannot open file: " + filename);
    }

    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}


int main() {
    const std::string filename = "input.txt";

    try {
        std::string program = readProgramFromFile(filename);

        CFG cfg;
        IRGenerator irGen(&cfg);
        Parser parser(program, &irGen, &cfg);
        parser.parse();

        if (irGen.getCurrentBlock() && !irGen.getCurrentBlock()->hasTerminator()) {
            irGen.emitBranch(cfg.getExit());
        }

        cfg.computeOrders();

        DominatorInfo domInfo(&cfg);

        SSABuilder ssaBuilder(&cfg, &domInfo);
        ssaBuilder.buildSSA();

        cfg.print();
        cfg.toGraphviz("cfg.dot");

    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }

    return 0;
}
