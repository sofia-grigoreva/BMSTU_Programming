(define (day-of-week d m g)
  (if (< m 3)
      (remainder (+ d (quotient (* 31 (+ m 10)) 12) (- g 1)
                    (- (quotient (- g 1) 4) (quotient (- g 1) 100))
                    (quotient (- g 1) 400)) 7)
      (remainder (+ d (quotient (* 31 (- m 2)) 12) g
                    (- (quotient g 4) (quotient g 100))
                    (quotient g 400)) 7)))

(define (urav a b c)
  (if (< (- (expt b 2) (* 4 a c)) 0)
      (list)
      (if (= (- (expt b 2) (* 4 a c)) 0)
          (list (/ (* -1 b) (* 2 a)))
          (cons (/ (+ (* -1 b) (expt (- (expt b 2) (* 4 a c)) -0.5)) (* 2 a))
                (list (/ (- (* -1 b) (expt (- (expt b 2) (* 4 a c)) -0.5)) (* 2 a)))))))

(define (my-gcd a b)
  (begin
    (define (loop a b c)
      (if (and (= 0 (remainder a c)) (= 0 (remainder b c)))
          c
          (loop a b (- c 1))))
    (if (> (* a a) (* b b))
        (loop (abs a) (abs b) (abs b))
        (loop (abs a) (abs b) (abs a)))))


(define (my-lcm a b)
  (/ (* a b) (my-gcd a b)))


(define (prime? n)
  (begin (define (loop n k)
           (or (= k 1)
               (and (= 1 (my-gcd n k)) (loop n (- k 1)))))
         (loop n (- n 1))))
