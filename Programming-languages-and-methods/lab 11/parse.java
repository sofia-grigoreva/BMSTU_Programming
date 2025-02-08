import java.util.ArrayList;
import java.util.List;

public class parse {

//    <Stmt>::= <Expr> = <Expr>
//    <Expr>::= <Atom> <Expr> |
//    <Atom>::= IDENT | STRING | ( <Expr> )

    public static void main(String[] args) {
        String e = "(a) = (a2 \n (\"aaa\"))";
        List<Lex> Lexs = lexanaliz(e);
        Stream Stream = new Stream(Lexs);
        System.out.println(Stmt(Stream));
        e = "(a) = (a2 \n (\"aaa\")";
        Lexs = lexanaliz(e);
        Stream = new Stream(Lexs);
        System.out.println(Stmt(Stream));
    }
    public enum LexType {
        LEFT_BRACKET, RIGHT_BRACKET,
        R, IDENT, STRING, EOF;
    }

    public static class Lex {
        LexType type;
        String value;
        Integer line, column;

        public Lex (LexType type, Character value, Integer line, Integer column) {
            this.type  = type;
            this.value = value.toString();
            this.line = line;
            this.column = column;
        }

        public Lex(LexType type, String value, Integer line, Integer column) {
            this.type = type;
            this.value = value;
            this.line = line;
            this.column = column;
        }

    }

    public static class Stream{
        private int pos;
        public List<Lex> Lexs;
        public Stream(List<Lex> Lexs) {
            this.Lexs = Lexs;
        }
        public Lex next() {
            return Lexs.get(pos++);
        }
        public void back() {
            pos--;
        }
        public Lex current() {
            return Lexs.get(pos);
        }
    }
    public static List<Lex> lexanaliz(String e) {

        int row = 1;
        int column = 1;
        ArrayList<Lex> Lexs = new ArrayList<>();
        int pos = 0;
        while (pos < e.length()) {
            char c = e.charAt(pos);
            if (c == '(') {
                Lexs.add(new Lex(LexType.LEFT_BRACKET, c, row, column));
                pos++;
                column++;
                continue;
            }

            if (c ==  ')') {
                Lexs.add(new Lex(LexType.RIGHT_BRACKET, c, row, column));
                pos++;
                column++;
                continue;
            }
            if (c ==  '=') {
                Lexs.add(new Lex(LexType.R, c, row, column));
                pos++;
                column++;
                continue;
            }

            if (Character.isLetter(c) ){
                StringBuilder sb = new StringBuilder();
                do {
                    sb.append(c);
                    pos++;
                    column++;
                    if (pos >= e.length()) {
                        break;
                    }
                    c = e.charAt(pos);
                } while (Character.isLetter(c) || Character.isDigit(c));
                Lexs.add(new Lex(LexType.IDENT, sb.toString(), row, column));
            } else if (c == '\"') {
                pos++;
                c = e.charAt(pos);
                if (Character.isLetter(c)) {
                    StringBuilder sb = new StringBuilder();
                    do {
                        sb.append(c);
                        pos++;
                        column++;
                        if (pos >= e.length()) {
                            break;
                        }
                        c = e.charAt(pos);
                    } while (Character.isLetter(c));
                    Lexs.add(new Lex(LexType.STRING, sb.toString(), row, column));
                }
            }
            else if (c == '\n') {
                row++;
                pos++;
                column = 1;
            }
            else if (c == ' '){
                pos++;
                column++;
                continue;
            }
            else{
                throw new RuntimeException("error: " + c + "\nline: "
                        + row + " column: " + column);
            }
        }
        Lexs.add(new Lex(LexType.EOF, "", row, column));
        return Lexs;
    }

    public static String Stmt(Stream Lexs) {
        return Expr(Lexs) + Expr(Lexs);
    }

    public static String Expr(Stream Lexs) {
        if (Lexs.current().type != LexType.EOF) {
            Lex Lex = Lexs.current();
            if (Lex.type == LexType.R){
                Lexs.next();
                return "= ";

            }
            if (Lex.type == LexType.IDENT || Lex.type == LexType.LEFT_BRACKET || Lex.type == LexType.STRING) {
                return Atom(Lexs) + Expr(Lexs);

            } else {
                return "";
            }
        }
        return "";
    }

    public static String Atom(Stream Lexs) {
        Lex Lex = Lexs.next();

        if (Lex.type == LexType.IDENT  || Lex.type == LexType.STRING){
            return "<Atom> ";
        }
        else if (Lex.type == LexType.LEFT_BRACKET){
            String expr = Expr(Lexs);
            Lex = Lexs.next();
            if (Lex.type != LexType.RIGHT_BRACKET){
                Lexs.back();

                throw new RuntimeException("error at (" + Lexs.current().line
                        + ", " + Lexs.current().column + ")");
            }
            return "( " + expr + ") ";
        }
        else {
            throw new RuntimeException("error at (" + Lex.line
                    + ", " + Lex.column + ")");
        }
    }

}
