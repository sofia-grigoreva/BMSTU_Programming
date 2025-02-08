(define (my-even x)
  (= x (* (quotient x 2) 2)))

(define (my-odd x)
  (not (= x (* (quotient x 2) 2))))

(define (my-expt x y)
  (if (= 0 y)
      1
      (* (my-expt x (- y 1)) x)))
