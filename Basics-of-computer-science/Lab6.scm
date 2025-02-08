(define call/cc call-with-current-continuation)
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

;<numbers> ::= ЦИФРА <numbers> | .
;<number> ::= ЦИФРА <numbers>.
;<number-with-sign> ::= + <number> | - <number> | <number>.
; <drob> ::= <number-with-sign> / <number>.

(define (list->number a b)
  (if (null? a)
      0
      (+ (* (- (char->integer (car a)) 48) b) (list->number (cdr a) (* b 10)))))

(define (check-frac str)
  
  (define (find-term term stream error)
    (if (equal? (peek stream) term)
        (next stream)
        (error #f)))
  
  ;<number-with-sign> ::= + <number> | - <number> | <number>.
  (define (number-with-sign stream error)
    (cond ((equal? #\+ (peek stream)) (begin (next stream) (number stream error)))
          ((equal? #\- (peek stream)) (begin (next stream) (number stream error)))
          (else (number stream error))))
  
  ;<number> ::= ЦИФРА <numbers>.
  (define (number stream error)
    (if (char-numeric? (peek stream))
        (begin (next stream) (numbers stream error))
        (error #f)))

  ;<numbers> ::= ЦИФРА <numbers> | .
  (define (numbers stream error)
    (if (char-numeric? (peek stream))
        (begin (next stream) (numbers stream error))
        #t))
  
  ; <drob> ::= <number-with-sign> / <number>.
  (define (drob stream error)
    (number-with-sign stream error)
    (find-term #\/ stream error)
    (number stream error))
  
  (define stream (make-stream (string->list str) #\е))
  (call/cc
   (lambda (error)
     (define result (drob stream error))
     (and (equal? (peek stream) #\е)
          result))))

(define (scan-frac str)
  
  (define (find-term term stream error)
    (if (equal? (peek stream) term)
        (next stream)
        (error #f)))

  ;<number-with-sign> ::= + <number> | - <number> | <number>.
  (define (number-with-sign stream error)
    (cond ((equal? #\+ (peek stream)) (begin (next stream) (+ (number stream error))))
          ((equal? #\- (peek stream)) (begin (next stream) (- (number stream error))))
          (else (number stream error))))

  ;<number> ::= ЦИФРА <numbers>.
  (define (number stream error)
    (if (char-numeric? (peek stream))
        (list->number (reverse (cons (next stream) (numbers stream error))) 1)
        (error #f)))
  
  ;<numbers> ::= ЦИФРА <numbers> | .
  (define (numbers stream error)
    (if (char-numeric? (peek stream))
        (cons (next stream) (numbers stream error))
        (list)))
  
  ; <drob> ::= <number-with-sign> / <number>.
  (define (drob stream error)
    (define n (number-with-sign stream error))
    (find-term #\/ stream error)
    (/ n (number stream error)))
  
  (define stream (make-stream (string->list str) #\е))
  (call/cc
   (lambda (error)
     (define result (drob stream error))
     (and (equal? (peek stream) #\е)
          result))))

;<numbers> ::= ЦИФРА <numbers> | .
;<number> ::= ЦИФРА <numbers>.
;<number-with-sign> ::= + <number> | - <number> | <number>.
; <drob> ::= <number-with-sign> / <number>.
;<whitespace> ::= ПРОБЕЛЬНЫЙ СИМВОЛ <whitespace> | .
;<droby> ::= <whitespace> <drob> <droby> | <whitespace>.

(define (scan-many-fracs str)
  (define (find-term term stream error)
    (if (equal? (peek stream) term)
        (next stream)
        (error #f)))

  ;<number-with-sign> ::= + <number> | - <number> | <number>.
  (define (number-with-sign stream error)
    (cond ((equal? #\+ (peek stream)) (begin (next stream) (+ (number stream error))))
          ((equal? #\- (peek stream)) (begin (next stream) (- (number stream error))))
          (else (number stream error))))
  
  ;<number> ::= ЦИФРА <numbers>.
  (define (number stream error)
    (if (char-numeric? (peek stream))
        (list->number (reverse (cons (next stream) (numbers stream error))) 1)
        (error #f)))

  ;<numbers> ::= ЦИФРА <numbers> | .
  (define (numbers stream error)
    (if (char-numeric? (peek stream))
        (cons (next stream) (numbers stream error))
        (list)))
  
  ; <drob> ::= <number-with-sign> / <number>.
  (define (drob stream error)
    (define n (number-with-sign stream error))
    (find-term #\/ stream error)
    (/ n (number stream error)))

  ;<whitespace> ::= ПРОБЕЛЬНЫЙ СИМВОЛ <whitespace> | .
  (define (whitespace stream error)
    (if (char-whitespace? (peek stream))
        (begin (next stream) (whitespace stream error))))

  ;<droby> ::= <whitespace> <drob> <droby> | <whitespace>.
  (define (droby stream error)
    (whitespace stream error)
    (if (or (equal? #\+ (peek stream)) (equal? #\- (peek stream)) 
                                       (char-numeric? (peek stream)))
        (cons (drob stream error) (droby stream error))
        (list)))
       
  (define stream (make-stream (string->list str) #\е))
  (call/cc
   (lambda (error)
     (define result (droby stream error))
     (and (equal? (peek stream) #\е)
          result))))

;<Program>  ::= <Articles> <Body> .
;<Articles> ::= <Article> <Articles> | .
;<Article>  ::= define word <Body> end .
;<Body>     ::= if <Body> endif <Body> | numbers <Body> | word <Body> |.

(define (parse tokens)
  ;<Program>  ::= <Articles> <Body> .
  (define (PROGRAM stream error)
    (let* ((articles (ARTICLES stream error))
           (body (BODY stream error)))
      (list articles body)))

  (define (find-term term stream error)
    (if (equal? (peek stream) term)
        (next stream)
        (error #f)))
  
  ;<Articles> ::= <Article> <Articles> | .
  (define (ARTICLES stream error)
    (if (equal? (peek stream) 'define)
        (let* ((article (ARTICLE stream error))
               (articles (ARTICLES stream error)))
          (cons article articles))
        (list)))
  
  ;<Article> ::= define word <Body> end .
  (define (ARTICLE stream error)
    (find-term 'define stream error)
    (let* ((word (next stream))
           (body (BODY stream error)))
      (begin (find-term 'end stream error)
             (list word body))))

  ;<Body> ::= if <Body> endif <Body> | numbers <Body> | word <Body> |.
  (define (BODY stream error)
    (cond
      ((equal? (peek stream) 'if)
       (begin (next stream)
              (let* ((body1 (BODY stream error)))
                (begin (find-term 'endif stream error)
                       (let* ((body2 (BODY stream error)))
                         (cons (list 'if body1) body2))))))

        
      ((integer? (peek stream)) (let* ((numbers (next stream))
                                       (body (BODY stream error)))
                                  (cons numbers body)))
        
      ((and (symbol? (peek stream))
            (not (equal? (peek stream) 'endif))
            (not (equal? (peek stream) 'end)))

       (let* ((word (next stream))
              (body (BODY stream error)))
         (cons word body)))
      (else (list))))
  
  (define stream (make-stream (vector->list tokens) "end-of-file"))
  (call/cc
   (lambda (error)
     (define result (PROGRAM stream error))
     (and (equal? (peek stream) "end-of-file")
          result))))
