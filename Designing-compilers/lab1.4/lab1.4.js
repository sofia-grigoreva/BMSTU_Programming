const fs = require("fs");

const DomainTag = {
    0: "NOT FINAL",
    1: "WHITESPACE",
    2: "IDENT",
    3: "NUMBER",
    4: "NOT FINAL",
    5: "OPERATION",
    6: "NOT FINAL",
    7: "OPERATION",
    8: "IDENT",
    9: "IDENT",
    10: "IDENT",
    11: "IDENT",
    12: "IDENT",
    13: "KEYWORD",
    14: "IDENT",
    15: "IDENT",
    16: "IDENT",
    17: "IDENT",
    18: "KEYWORD",
    19: "COMMENT",
    20: "COMMENT",
    21: "EOF"
};

class Position {
    constructor(text, index = 0, line = 1, pos = 1) {
        this.text = text;
        this.index = index;
        this.line = line;
        this.pos = pos;
    }

    copy() {
        return new Position(this.text, this.index, this.line, this.pos);
    }

    get cp() {
        if (this.index >= this.text.length) {
            return "";
        }
        return this.text[this.index].toLowerCase();
    }

    next() {
        if (
            this.cp === "\r" &&
            this.index + 1 < this.text.length &&
            this.text[this.index + 1] === "\n"
        ) {
            this.line += 1;
            this.pos = 1;
            this.index += 2;
            return;
        }

        if (this.cp === "\n" || this.cp === "\r") {
            this.line += 1;
            this.pos = 1;
        } else {
            this.pos += 1;
        }

        this.index += 1;
    }

    toString() {
        return `(${this.line},${this.pos})`;
    }
}

class Fragment {
    constructor(start, end) {
        this.starting = start;
        this.ending = end;
    }

    toString() {
        return `${this.starting}-${this.ending}`;
    }
}

class Message {
    constructor(isError, coord, text) {
        this.isError = isError;
        this.coord = coord;
        this.text = text;
    }
}

class MessageList {
    constructor() {
        this.messages = [];
    }

    addError(coord, text) {
        this.messages.push(new Message(true, coord.copy(), text));
    }

    addWarning(coord, text) {
        this.messages.push(new Message(false, coord.copy(), text));
    }

    getSorted() {
        return [...this.messages].sort((a, b) => a.coord.index - b.coord.index);
    }
}

class NameDictionary {
    constructor() {
        this.nameCodes = {};
        this.names = [];
    }

    contains(name) {
        return Object.prototype.hasOwnProperty.call(this.nameCodes, name.toLowerCase());
    }

    getName(code) {
        if (code < 0 || code >= this.names.length) {
            return null;
        }
        return this.names[code];
    }

    addName(name) {
        name = name.toLowerCase();

        if (Object.prototype.hasOwnProperty.call(this.nameCodes, name)) {
            return this.nameCodes[name];
        }

        const code = this.names.length;
        this.names.push(name);
        this.nameCodes[name] = code;
        return code;
    }
}

class Token {
    constructor(tag, attr, start, end) {
        this.tag = tag;
        this.coords = new Fragment(start, end);
        this.attr = attr;
    }

    toString() {
        const s = this.coords.starting;
        const e = this.coords.ending;

        const image = this.attr
            .replace(/\\/g, "\\\\")
            .replace(/\r/g, "\\r")
            .replace(/\n/g, "\\n")
            .replace(/\t/g, "\\t");

        return `${this.tag} (${s.line}, ${s.pos})-(${e.line}, ${e.pos}): ${image}`;
    }
}

class Compiler {
    constructor() {
        this.messages = new MessageList();
        this.names = new NameDictionary();
    }

    addError(pos, text) {
        this.messages.addError(pos, text);
    }

    addWarning(pos, text) {
        this.messages.addWarning(pos, text);
    }

    getScanner(program) {
        return new Scanner(program, this);
    }
}

class Scanner {
    constructor(program, compiler) {
        this.program = program;
        this.compiler = compiler;
        this.cur = new Position(program);

        this.comments = [];

        // "0"     - цифра
        // "s"     - пробел или табуляция
        // "n"     - конец строки
        // "="     - символ '='
        // "!"     - символ '!'
        // "u","p","d","a","t","e","w","h","r" - соответствующие буквы
        // "i"     - остальные латинские буквы
        // "other" - прочие символы
        this.table = [
            { "0": 3,  "s": 1,  "n": 1,  "=": 4,  "!": 6,  "u": 8,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 14, "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 0
            { "0": -1, "s": 1,  "n": 1,  "=": -1, "!": -1, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 1
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 2
            { "0": 3,  "s": -1, "n": -1, "=": -1, "!": -1, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 3
            { "0": -1, "s": -1, "n": -1, "=": 5,  "!": -1, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 4
            { "0": -1, "s": -1, "n": -1, "=": -1, "!": -1, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 5
            { "0": -1, "s": -1, "n": -1, "=": 7,  "!": 19, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 6
            { "0": -1, "s": -1, "n": -1, "=": -1, "!": -1, "u": -1, "p": -1, "d": -1, "a": -1, "t": -1, "e": -1, "w": -1, "h": -1, "r": -1, "i": -1, "other": -1 },  // 7
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 9,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 8
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 10, "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 9
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 11, "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 10
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 12, "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 11
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 13, "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 12
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 13
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 15, "r": 2,  "i": 2,  "other": -1 },  // 14
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 16, "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 15
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 17, "i": 2,  "other": -1 },  // 16
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 18, "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 17
            { "0": 2,  "s": -1, "n": -1, "=": -1, "!": -1, "u": 2,  "p": 2,  "d": 2,  "a": 2,  "t": 2,  "e": 2,  "w": 2,  "h": 2,  "r": 2,  "i": 2,  "other": -1 },  // 18
            { "0": 19, "s": 19, "n": -1, "=": 19, "!": 20, "u": 19, "p": 19, "d": 19, "a": 19, "t": 19, "e": 19, "w": 19, "h": 19, "r": 19, "i": 19, "other": 19 },  // 19
            { "0": 19, "s": 19, "n": 19, "=": 19, "!": 20, "u": 19, "p": 19, "d": 19, "a": 19, "t": 19, "e": 19, "w": 19, "h": 19, "r": 19, "i": 19, "other": 19 }   // 20
        ];
        this.state = 0;
    }

    trans(ch) {
        if (/^[0-9]$/.test(ch)) {
            ch = "0";
        } else if (ch === " " || ch === "\t") {
            ch = "s";
        } else if (ch === "\n" || ch === "\r") {
            ch = "n";
        } else if (/^[a-z]$/.test(ch) && !"updatwher".includes(ch)) {
            ch = "i";
        } else if (!"0supdatwhern=!".includes(ch) && !/^[a-z]$/.test(ch)) {
            ch = "other";
        }
        return ch;
    }

    isFinal(state) {
        return DomainTag[state] !== "NOT FINAL";
    }

    nextToken() {
        while (true) {
            const start = this.cur.copy();
            this.state = 0;

            if (this.cur.cp === "") {
                return new Token(DomainTag[21], "", start, this.cur.copy());
            }

            let pos = this.cur.copy();
            let lastFinalState = -1;
            let lastFinalPos = null;

            while (pos.cp) {
                try {
                    const ch = pos.cp;
                    const nextState = this.table[this.state][this.trans(ch)];

                    if (nextState === -1 || nextState === undefined) {
                        break;
                    }

                    this.state = nextState;
                    pos.next();

                    if (this.isFinal(this.state)) {
                        lastFinalState = this.state;
                        lastFinalPos = pos.copy();
                    }
                } catch (e) {
                    this.compiler.addError(pos, "unexpected character");
                    pos.next();
                    break;
                }
            }

            if (lastFinalState !== -1) {
                const tokenText = this.program.slice(start.index, lastFinalPos.index);
                this.cur = lastFinalPos.copy();
                return new Token(DomainTag[lastFinalState], tokenText, start, lastFinalPos);
            }

            this.compiler.addError(this.cur, "unexpected character");
            this.cur.next();
        }
    }
}

const program = fs.readFileSync("input.txt", { encoding: "ascii" });

const compiler = new Compiler();
const scanner = compiler.getScanner(program);

while (true) {
    const token = scanner.nextToken();

    if (token.tag !== "WHITESPACE") {
        console.log(token.toString());
    }

    if (token.tag === "EOF") {
        break;
    }
}

if (compiler.messages.messages.length > 0) {
    for (const msg of compiler.messages.getSorted()) {
        const prefix = msg.isError ? "ОШИБКА" : "ПРЕДУПРЕЖДЕНИЕ";
        console.log(`${prefix} в ${msg.coord}: ${msg.text}`);
    }
}