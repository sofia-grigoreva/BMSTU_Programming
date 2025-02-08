(define-syntax trace
  (syntax-rules ()
    ((_ expr)
     (begin
       (write 'expr)
       (display " => ")
       (let ((val expr))
         (write val)
         (newline)
         val)))))
   
(define (zip . xss)
  (if (or (null? xss)
          (null? (trace (car xss))))
      '()
      (cons (map car xss) (apply zip (map cdr (trace xss))))))

(define-syntax test
  (syntax-rules ()
    ((test otvet pred)
     (list 'otvet pred))))

(define (signum x)
  (cond
    ((< x 0) -1)
    ((= x 0) 1)
    (else 1)))

(define the-tests
  (list  (test (signum -2) -1)
         (test (signum 0) 0)
         (test (signum 2) 1)))

(define (run-test l)
  (write (car l))
  (define orez (cadr l))
  (define rez (eval (car l) (interaction-environment))) 
  (if ( = rez orez)
      (begin
        (display "  ok") (newline) #t)
      (begin
        (display "  Fail")
        (newline)
        (display "expected:")
        (write orez)
        (newline)
        (display "returned:")
        (write rez)
        (newline)
        #f)))
 
(define (run-tests xs)
  (define (loop xs z)
    (if (null? xs)
        z
        (if (run-test (car xs))
            (loop (cdr xs) z)
            (begin (set! z #f) (loop (cdr xs) z))))) (loop xs #t))

(define (i xs n p)
  (if (> n (length xs))
      #f
      (if (> n 0)
          (cons (car xs) (i (cdr xs) (- n 1) p))
          (cons p xs))))

(define (ref xs . o)
  (define n (car o))
  (if (= (length o) 1)
      (if (string? xs)
          (ref (string->list xs) n)
          (if (list? xs)
              (ref (list->vector xs) n)
              (and (< n (- (vector-length xs) 1)) (vector-ref xs n))))
      (if (and (string? xs) (char? (cadr o)) (<= n (string-length xs)))
          (list->string (i (string->list xs) n (cadr o)))
          (if (and (vector? xs)(<= n (vector-length xs)))
              (list->vector (i (vector->list xs) n (cadr o)))
              (and (list? xs) (i xs n (cadr o)))
              ))))    

(define (factorize xs) 
  (if (= (caddr (cadr xs)) 2)
      `(* (- ,(cadr (cadr xs)) ,(cadr (car (cddr xs)))) 
       (+ ,(cadr (cadr xs)) ,(cadr (car (cddr xs)))))
      (if (equal? (car xs) '-)
          `(* (- ,(cadr (cadr xs)) ,(cadr (car (cddr xs))))
              (+ (expt ,(cadr (cadr xs)) 2) (* ,(cadr (cadr xs)) 
               ,(cadr (car (cddr xs)))) 
                        (expt  ,(cadr (car (cddr xs))) 2)))
          `(* (- ,(cadr (cadr xs)) ,(cadr (car (cddr xs))))
              (+ (expt ,(cadr (cadr xs)) 2) (* ,(cadr (cadr xs)) 
               ,(cadr (car (cddr xs)))) 
                        (expt  ,(cadr (car (cddr xs))) 2))))))
