(define call/cc call-with-current-continuation)

(char->integer #\a)
(define (make-stream items . eos)
  (if (null? eos)
      (make-stream items #f)
      (list items (car eos))))

(define (peek stream)
  (if (null? (car stream))
      (cadr stream)
      (caar stream)))

(define (peek2 stream)
  (if (null? (car stream))
      (cadr stream)
      (if (null? (cdar stream))
          (list (caar stream))
          (list (caar stream) (cadar stream)))))

(define (next stream)
  (let ((n (peek stream)))
    (if (not (null? (car stream)))
        (set-car! stream (cdr (car stream))))
    n))


(define (list->number a b)
  (if (null? a)
      0
      (+ (* (- (char->integer (car a)) 48) b)
         (list->number (cdr a) (* b 10)))))

;<Expression> ::= <whitespace> <value> <expression> | <whitespace> .
;<whitespace> ::= WHITE-SPACE <whitespace> | .
; <value> ::= <sign> | <number> | <variable> + - * / ^ )(.
;<number> ::= NUMBER <numbers>.
;<numbers> ::= NUMBER <numbers> | . <numbers> | e + <numbers> | e - <numbers> | .
;<variable> ::= LETTER <variables>.
;<variables> ::= LETTER <variables> | .

(define (tokenize str)

  ;<Expression> ::= <whitespace> <value> <expression> | <whitespace> .
  (define (expression stream error)
    (whitespace stream error)
    (if (and (char? (peek stream))
             (or (equal? #\+ (peek stream))
                 (equal? #\- (peek stream))
                 (equal? #\* (peek stream))
                 (equal? #\/ (peek stream))
                 (equal? #\^ (peek stream))
                 (equal? #\) (peek stream))
                 (equal? #\( (peek stream))
                 (equal? #\. (peek stream))
                 (char-numeric? (peek stream))
                 (char-alphabetic? (peek stream))))
        (begin (whitespace stream error)
               (cons (value stream error) (expression stream error)))
        (list)))
    
  (define (find-Term Term stream error)
    (if (equal? (peek stream) Term)
        (next stream)
        (error #f)))

  ;<number> ::= NUMBER <numbers>.
  (define (number stream error)
    (if (and (char? (peek stream))(char-numeric? (peek stream)))
        (string->number
         (list->string (cons (next stream) (numbers stream error)))) 
        (error #f)))

  ;<numbers> ::= NUMBER <numbers> | .
  (define (numbers stream error)
    (if (and (char? (peek stream))
             (or (equal? (peek stream) #\.)
                 (char-numeric? (peek stream))
                 (equal? (peek stream) #\e)))
        (if (equal? (peek stream) #\e)
            (begin
              (next stream)
              (if (or (equal? (peek stream) #\-) (equal? (peek stream) #\+))
                  (cons #\e (cons (next stream) (numbers stream error)))
                  (cons #\e (numbers stream error))))
            (cons (next stream) (numbers stream error)))
        (if (and (char? (peek stream)) (char-alphabetic? (peek stream))
                 (char-numeric? (cadr (peek2 stream))))
            (error #f)
            (list))))
            

  (define (alf a)
    (if (< (char->integer a) 97)
        (integer->char (+ 32 (char->integer a)))
        a))

  ;<variable> ::= LETTER <variables>.
  (define (variable stream error)
    (if (and (char? (peek stream)) (char-alphabetic? (peek stream)))
        (string->symbol (list->string
                         (cons (alf (next stream)) (variables stream error))))
        (error #f)))

  ;<variables> ::= LETTER <variables> | .
  (define (variables stream error)
    (if (and (char? (peek stream))(char-alphabetic? (peek stream)))
        (cons (alf (next stream)) (variables stream error))
        (list)))

  (define (loop ret stream)
    (next stream)
    (car ret))

  ; <value> ::= <sign> | <number> | <variable> + - * / ^ )(.
  (define (value stream error)
    (cond ((equal? #\+ (peek stream)) (loop '(+) stream))
          ((equal? #\- (peek stream)) (loop '(-) stream))
          ((equal? #\* (peek stream))(loop '(*) stream))
          ((equal? #\/ (peek stream)) (loop '(/) stream))
          ((equal? #\^ (peek stream)) (loop '(^) stream))
          ((equal? #\) (peek stream)) (loop '(")") stream))
          ((equal? #\( (peek stream)) (loop '("(") stream))
          ((char-numeric? (peek stream)) (number stream error))
          ((char-alphabetic? (peek stream)) (variable stream error))
          (else (list))))

  ;<whitespace> ::= WHITE-SPACE <whitespace> | .
  (define (whitespace stream error)
    (if (and (char? (peek stream)) (char-whitespace? (peek stream)))
        (begin (next stream) (whitespace stream error))))
       
  (define stream (make-stream (string->list str) "eof"))
  (call/cc
   (lambda (error)
     (define result (expression stream error))
     (and (equal? (peek stream) "eof")
          result)))) 

(define (parse str)
  
  (define (Expr stream error)
    (define result (Term stream error))
    (define (loop xs) 
      (if (or (equal? '+ (peek stream)) (equal? '- (peek stream)))
          (loop (list xs (next stream) (Term stream error)))
          xs))
    (loop result))

  (define (Term stream error)
    (define result (Factor stream error))
    (define (loop xs) 
      (if (or (equal? '* (peek stream)) (equal? '/ (peek stream)))
          (loop (list xs (next stream) (Factor stream error)))
          xs))
    (loop result))

  (define (Factor stream error)
    (define p (power stream error))
    (if (not (equal? '^ (peek stream)))
        p
        (cons p (Factor-2 stream error))))

  (define (Factor-2 stream error)
    (next stream)
    (define p (power stream error))
    (if (not (equal? '^ (peek stream)))
        (cons '^ (list p))
        (list '^ (cons p (Factor-2 stream error)))))

  (define (power stream error)
    (cond ((number? (peek stream)) (next stream))
          ((equal? "(" (peek stream))
           (next stream)
           (let ((e (Expr stream error)))
             (if (not (equal? ")" (next stream)))
                 (error #f)) e))
          ((equal? '- (peek stream))
           (next stream)
           (list '- (power stream error)))
          ((symbol? (peek stream)) (next stream))
          (else (error #f))))
  
  (define stream (make-stream str "eof"))
  (call/cc
   (lambda (error)
     (define result (Expr stream error))
     (and (equal? (peek stream) "eof")
          result))))

(define (tree->scheme xs)
  (if (list? xs)
      (if (= (length xs) 3)
          (list (tree->scheme (cadr xs))
                (tree->scheme (car xs))
                (tree->scheme  (caddr xs)))
          (list (tree->scheme (car xs)) (tree->scheme (cadr xs))))
      (if (equal? xs '^)
          'expt
          xs)))
