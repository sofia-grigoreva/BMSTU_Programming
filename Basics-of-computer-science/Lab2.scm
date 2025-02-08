(define (count x xs)
  (define (l x i xs) 
    (if (null? xs)
        i
        (if (equal? (car xs) x)
            (l x (+ i 1)(cdr xs)) (l x i (cdr xs)))))
  (l x 0 xs))

(define (delete pred? xs)
  (if (null? xs)
      (list)
      (if (pred? (car xs))
          (delete pred? (cdr xs))
          (cons (car xs) (delete pred? (cdr xs))))))

(define (iterate f x n)
  (if (= n 0)
      (list)
      (cons x (iterate f (f x) (- n 1)))))

(define (intersperse e xs)
  (if (null? xs)
      (list)
      (if (null? (cdr xs))
          (cons (car xs) (intersperse e (cdr xs)))
          (cons (car xs) (cons e (intersperse e (cdr xs)))))))

(define (any? f xs) 
  (and (not (null? xs))
      (or (f (car xs)) (and ( not (equal? (cdr xs)(list))) (any? f (cdr xs))))))

(define (all? f xs) 
  (or (null? xs) 
      (and (f (car xs)) (or (equal? (cdr xs)(list)) (all? f (cdr xs))))))

(define (o . xs)
  (define (loop x xs)
    ( if (null? xs)
         x
         ((car xs)(loop x (cdr xs))))) (lambda (x) (loop x xs)))
