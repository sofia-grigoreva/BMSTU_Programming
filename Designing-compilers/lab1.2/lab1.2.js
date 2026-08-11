class Lexer {

    constructor(text) {
        this.text = text;
        this.pos = 0;
        this.line = 1;
        this.column = 1;
        this.domains = [
            {name: 'NUMBER', reg : /^\d+/},
            {name: 'FLOAT', reg : /^\d+\/\d+/},
            {name: 'OPERATOR', reg : /^[+\-*/\(\)]/},  
            {name: 'COMMENT', reg : /^\(\*(?:(?!\(\*|\*\))[\s\S])*\*\)/},
            {name: 'STRING', reg: /^\{(?:\#\{|\#\}|\#\#|[^#{}\n]|\#[0-9a-fA-F]{2})*\}/},
        ] 
    }

    peekText() {
        return this.text.slice(this.pos);
    }

    skipWhitespace() {
        const match = this.peekText().match(/^[\s]+/);
        if (match) {
            this.clip(match[0]);
        }
    }

    clip (lexeme) {
        for (let s of lexeme) {
            if (s === '\n') {
                this.line++;
                this.column = 1;
            } else {
                this.column++;
            }
        }
        this.pos += lexeme.length;
    }

    nextToken = () => {

        this.skipWhitespace();

        if (this.pos >= this.text.length) {
            return null;
        }

        const startLine = this.line;
        const startColumn = this.column;
        const text = this.peekText();

        let bestMatch = null;
        let bestDomain = null;

        for (let domain of this.domains) {
            const match = text.match(domain.reg)
            if (match) {
                const lexeme = match[0];
                if (!bestMatch || lexeme.length > bestMatch.length) {
                    bestMatch = lexeme;
                    bestDomain = domain;
                }
            }
        }

        if (!bestMatch) {
            console.log(`syntax error (${startLine}, ${startColumn})`);
            this.clip(text[0]);
            return this.nextToken();
        }

        this.clip(bestMatch);

        return {
            type: bestDomain.name,
            line: startLine,
            column: startColumn,
            value: bestMatch,
        }
    }
}

const fs = require('fs');

const filename = process.argv[2];
const content = fs.readFileSync(filename, 'utf8');

const lexer = new Lexer(content);

let token;

while ((token = lexer.nextToken()) !== null) {
    console.log(`${token.type} (${token.line}, ${token.column}): ${token.value}`);
}