; Задание 1

(define call/cc call-with-current-continuation)

(define-syntax assert
  (syntax-rules ()
    ((assert yslovie) (if (equal? #f yslovie)
                          (begin (display "Failed: ")
                                 (write 'yslovie)
                                 (razruv))))))

(define razruv #f)

(define (use-assertions)
  (call/cc (lambda (a)
             (set! razruv a))))

(use-assertions) 

(define (1/x x)
  (assert (not (zero? x))) 
  (/ 1 x))

; Задание 2 ---------------------------------------------------------
      
(define (load-data pyt)
  (call-with-input-file pyt (lambda (port) (read port))))

(define (save-data data pyt)
  (call-with-output-file pyt (lambda (port) (write data port))))

(define (kolvostr pyt)
  (call-with-input-file pyt
    (lambda (port) (begin
                     (define (loop x p not-empty?)
                       (if (eof-object? (peek-char p))
                           x
                           (if (equal? (peek-char p) #\return)
                               (begin (read-char p) (loop x p n))
                               (if (equal? (read-char p) #\newline)
                                   (loop x p #t)
                                   (if not-empty?
                                       (loop (+ x 1) p #f)
                                       (loop x p #f))))))
                     (loop 1 port #f)))))

; Задание 3 ----------------------------------------------------------

(define (tribonachi n)
  (if (<= n 1)
      0
      (if (= n 2)
          1
          (+ (tribonachi (- n 2)) (tribonachi (- n 1)) (tribonachi (- n 3))))))

(define tribonachi-memo
  (let ((known-results '()))
    (lambda (n)
      (let* ((res (assoc n known-results)))
        (if res
            (cadr res)
            (let ((res (if (<= n 1)
                           0
                           (if (= n 2)
                               1
                               (+ (tribonachi-memo (- n 2)) (tribonachi-memo (- n 1))
                                  (tribonachi-memo (- n 3)))))))
              (set! known-results (cons (list n res) known-results))
              res))))))

; Задание 4----------------------------------------------------------

(define-syntax my-if
  (syntax-rules ()
    ((my-if yslovie tr) (and yslovie tr))
    ((my-if yslovie tr fl) 
    (let ((result 
             (delay (or (and yslovie (or (equal? #f tr) tr)) fl))))
                             (force result)))))

; Задание 5 ---------------------------------------------------------

(define-syntax my-let*
  (syntax-rules ()
    ((my-let* ((perem znach)) . action)
     (begin  (define perem znach) (begin . action)))
    ((my-let* ((perem znach) . branches) . action)
     (begin (define perem znach) (my-let* branches . action)))))

(define-syntax my-let
  (syntax-rules ()
    ((my-let ((perem znach) ...) . actions)
     ((lambda (perem ...) (begin . actions)) znach ...))))

; Задание 6 ---------------------------------------------------------

(define-syntax when
  (syntax-rules ()
    ((when yslovie action ... ) (if yslovie (begin action ... )))))

(define-syntax unless
  (syntax-rules ()
    ((unless yslovie action ... ) (if (not yslovie) (begin action ... )))))

(define-syntax for
  (syntax-rules (in as)
    ((for x in xs actions ...)
     (letrec ((loop (lambda (lst)
                      (if (not (null? lst))
                          (begin
                            (let ((x (car lst)))
                              actions ...)
                            (loop (cdr lst))))))) (loop xs)))
    ((for xs as x actions ...)
     (letrec ((loop (lambda (lst)
                      (if (not (null? lst))
                          (begin
                            (let ((x (car lst)))
                              actions ...)
                            (loop (cdr lst))))))) (loop xs)))))

(define-syntax while
  (syntax-rules ()
    ((while cond? actions ...) (letrec ((loop (lambda ()
                                                (if cond?
                                                    (begin
                                                      actions ...
                                                      (loop))))))
                                 (loop)))))

(define-syntax repeat
  (syntax-rules (until)
    ((repeat (actions ...) until cond?) (letrec ((loop
                                                  (lambda ()
                                                    (begin
                                                      actions ...
                                                      (if (not cond?)
                                                          (loop))))))
                                          (loop)))))

(define-syntax cout
  (syntax-rules (<< endl)
    ((cout << endl) (newline))
    ((cout << line) (display line))
    ((cout << endl << line2 ...) 
                   (begin (newline) (cout << line2 ...)))
    ((cout << line << line2 ...) 
                   (begin (display line) (cout << line2 ...)))))
