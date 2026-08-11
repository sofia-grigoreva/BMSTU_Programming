#include <iostream>
#include <sstream>
#include <map>
#include <vector>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <cctype>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

class Compiler
{
    LLVMContext Context;
    IRBuilder<> Builder;
    std::unique_ptr<Module> module;
    std::map<std::string, AllocaInst *> NamedValues;
    std::istringstream Input;
    std::string CurTok;

public:
    Compiler() : Builder(Context)
    {
        module = std::make_unique<Module>("lab3_module", Context);
    }

    void compile(const std::string &filename)
    {
        std::string code = readFile(filename);
        initLexer(code);
        parseMain();
        module->print(llvm::outs(), nullptr);
    }

private:
    std::string readFile(const std::string &filename)
    {
        std::ifstream file(filename);
        if (!file)
        {
            std::cerr << "Error opening file: " << filename << "\n";
            exit(1);
        }

        std::ostringstream ss;
        ss << file.rdbuf();
        return ss.str();
    }

    std::string nextToken()
    {
        char c;
        CurTok = "";

        while (Input.get(c) && isspace(c))
            ;

        if (!Input)
            return "";

        CurTok += c;

        if (isalpha(c))
        {
            while (isalnum(Input.peek()))
                CurTok += Input.get();
        }
        else if (isdigit(c) || (c == '-' && isdigit(Input.peek())))
        {
            while (isdigit(Input.peek()))
                CurTok += Input.get();
        }
        else if (c == '=' && Input.peek() == '=')
        {
            CurTok += Input.get();
        }

        return CurTok;
    }

    bool match(const std::string &expected)
    {
        if (CurTok == expected)
        {
            nextToken();
            return true;
        }
        return false;
    }

    Value *parsePrimary()
    {
        if (isdigit(CurTok[0]))
        {
            int num = std::stoi(CurTok);
            nextToken();
            return Builder.getInt32(num);
        }

        if (CurTok[0] == '-')
        {
            int num = std::stoi(CurTok);
            nextToken();
            return Builder.getInt32(num);
        }

        if (isalpha(CurTok[0]))
        {
            std::string var = CurTok;
            nextToken();

            if (NamedValues.find(var) == NamedValues.end())
            {
                std::cerr << "Undeclared variable: " << var << "\n";
                exit(1);
            }

            return Builder.CreateLoad(
                Builder.getInt32Ty(),
                NamedValues[var],
                var
            );
        }

        std::cerr << "Unexpected token: " << CurTok << "\n";
        exit(1);
    }

    Value *parseExpression()
    {
        Value *LHS = parsePrimary();

        if (CurTok == "+" || CurTok == "-" || CurTok == "*" ||
            CurTok == ">" || CurTok == "<" || CurTok == "==")
        {
            std::string op = CurTok;
            nextToken();

            Value *RHS = parsePrimary();

            if (op == "+")
                return Builder.CreateAdd(LHS, RHS, "addtmp");

            if (op == "-")
                return Builder.CreateSub(LHS, RHS, "subtmp");

            if (op == "*")
                return Builder.CreateMul(LHS, RHS, "multmp");

            if (op == ">")
                return Builder.CreateICmpSGT(LHS, RHS, "cmptmp");

            if (op == "<")
                return Builder.CreateICmpSLT(LHS, RHS, "cmptmp");

            if (op == "==")
                return Builder.CreateICmpEQ(LHS, RHS, "cmptmp");
        }

        return LHS;
    }

    void parseAssignment()
    {
        std::string var = CurTok;
        nextToken();

        match("=");

        Value *val = parseExpression();

        match(";");

        if (NamedValues.find(var) == NamedValues.end())
        {
            NamedValues[var] = Builder.CreateAlloca(
                Builder.getInt32Ty(),
                nullptr,
                var
            );
        }

        Builder.CreateStore(val, NamedValues[var]);
    }

    void parseIfStatement(Function *F)
    {
        match("(");

        Value *cond = parseExpression();

        match(")");
        match("{");

        BasicBlock *ThenBB = BasicBlock::Create(Context, "then", F);
        BasicBlock *AfterBB = BasicBlock::Create(Context, "ifcont", F);

        Builder.CreateCondBr(cond, ThenBB, AfterBB);

        Builder.SetInsertPoint(ThenBB);

        parseBlock(F, "}");

        Builder.CreateBr(AfterBB);

        Builder.SetInsertPoint(AfterBB);
    }

    void parseWhileLoop(Function *F)
    {
        match("(");

        std::ostringstream condBuf;

        while (!CurTok.empty() && CurTok != ")")
        {
            condBuf << CurTok << " ";
            nextToken();
        }

        match(")");
        match("{");

        BasicBlock *CondBB = BasicBlock::Create(Context, "loopcond", F);
        BasicBlock *LoopBB = BasicBlock::Create(Context, "loopbody", F);
        BasicBlock *AfterBB = BasicBlock::Create(Context, "loopend", F);

        Builder.CreateBr(CondBB);

        Builder.SetInsertPoint(CondBB);

        std::istringstream oldInput = std::move(Input);
        std::string oldTok = CurTok;

        std::istringstream condInput(condBuf.str());
        Input = std::move(condInput);
        nextToken();

        Value *cond = parseExpression();

        Input = std::move(oldInput);
        CurTok = oldTok;

        Builder.CreateCondBr(cond, LoopBB, AfterBB);

        Builder.SetInsertPoint(LoopBB);

        parseBlock(F, "}");

        Builder.CreateBr(CondBB);

        Builder.SetInsertPoint(AfterBB);
    }

    void parseReturnStatement(Function *F)
    {
        match("return");

        Value *retVal = parseExpression();

        match(";");

        Builder.CreateRet(retVal);
    }

    void parseBlock(Function *F, const std::string &endToken)
    {
        while (!CurTok.empty() && CurTok != endToken)
        {
            if (CurTok == "if")
            {
                nextToken();
                parseIfStatement(F);
            }
            else if (CurTok == "while")
            {
                nextToken();
                parseWhileLoop(F);
            }
            else if (CurTok == "return")
            {
                parseReturnStatement(F);
                break;
            }
            else
            {
                parseAssignment();
            }
        }

        match(endToken);
    }

    void parseMain()
    {
        match("function");
        match("main");
        match("(");
        match(")");
        match("{");

        FunctionType *FT = FunctionType::get(
            Type::getInt32Ty(Context),
            false
        );

        Function *F = Function::Create(
            FT,
            Function::ExternalLinkage,
            "main",
            module.get()
        );

        BasicBlock *BB = BasicBlock::Create(Context, "entry", F);
        Builder.SetInsertPoint(BB);

        parseBlock(F, "}");

        BasicBlock *CurBB = Builder.GetInsertBlock();

        if (!CurBB->getTerminator())
        {
            Builder.CreateRet(Builder.getInt32(0));
        }

        if (verifyFunction(*F, &llvm::errs()))
        {
            std::cerr << "Function verification failed!\n";
            exit(1);
        }
    }

    void initLexer(const std::string &src)
    {
        Input.clear();
        Input.str(src);
        nextToken();
    }
};

int main()
{
    Compiler compiler;
    compiler.compile("test.txt");
    return 0;
}