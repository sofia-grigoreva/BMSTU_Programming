(define feature-while-loop #t)
(define feature-repeat-loop #t)
(define feature-break-continue #t)


(define (interpret program stack)
  (letrec ((index_down (lambda (program n closeword)
                    (if (equal? (vector-ref program n) closeword)
                        n
                        (index_down program (+ 1 n) closeword))))
           (index_up (lambda (program n closeword)
                    (if (equal? (vector-ref program n) closeword)
                         (- n 1)
                        (index_up program (- n 1) closeword)))))
    
    (define (readword program nslova stack slovar stackvf stackvc)
      (begin                              
        (if (or (<= (vector-length program) nslova))
            stack
            (begin 
              (cond
                ((integer? (vector-ref program nslova))
                 (set! stack (cons (vector-ref program nslova) stack)))
                ((equal? (vector-ref program nslova) '+)
                 (set! stack (cons (+ (cadr stack) (car stack)) (cddr stack))))
                ((equal? (vector-ref program nslova) '-)
                 (set! stack (cons (- (cadr stack) (car stack)) (cddr stack))))
                ((equal? (vector-ref program nslova) '*)
                 (set! stack (cons (* (cadr stack) (car stack)) (cddr stack))))
                ((equal? (vector-ref program nslova) '/)
                 (set! stack (cons (quotient (cadr stack) (car stack)) (cddr stack))))
                
                ((equal? (vector-ref program nslova) 'mod)
                 (set! stack (cons (remainder (cadr stack) (car stack)) (cddr stack))))
                
                ((equal? (vector-ref program nslova) 'neg)
                 (set-car! stack (* (car stack) -1)))
                ((equal? (vector-ref program nslova) '=)
                 (set! stack (cons (if (= (cadr stack) (car stack)) -1 0)
                                   (cddr stack))))
                ((equal? (vector-ref program nslova) '>)
                 (set! stack (cons (or (and (> (cadr stack) (car stack)) -1) 0)
                                   (cddr stack))))
                ((equal? (vector-ref program nslova) '<)
                 (set! stack (cons (or (and (< (cadr stack) (car stack)) -1) 0)
                                   (cddr stack))))
                ((equal? (vector-ref program nslova) 'and)
                 (set! stack (cons (if (or (= (car stack) 0) (= (cadr stack) 0)) 0 -1)
                                   (cddr stack))))
                ((equal? (vector-ref program nslova) 'or)
                 (set! stack (cons (if (and (= (car stack) 0) (= (cadr stack) 0)) 0 -1)
                                   (cddr stack))))
                ((equal? (vector-ref program nslova) 'not)
                 (set! stack (cons (if (= 0 (car stack)) -1 0) (cdr stack))))
                ((equal? (vector-ref program nslova) 'drop)
                 (set! stack (cdr stack)))
                ((equal? (vector-ref program nslova) 'swap)
                 (set! stack (cons (cadr stack) (cons (car stack) (cddr stack)))))                  
                ((equal? (vector-ref program nslova) 'dup)
                 (set! stack (cons (car stack) stack)))                  
                ((equal? (vector-ref program nslova) 'over)
                 (set! stack (cons (cadr stack) stack)))                  
                ((equal? (vector-ref program nslova) 'rot)
                 (set! stack (cons (caddr stack)
                                   (cons (cadr stack)
                                         (cons (car stack) (cdddr stack))))))                  
                ((equal? (vector-ref program nslova) 'depth)
                 (set! stack (cons (length stack) stack)))
                
                ((equal? (vector-ref program nslova) 'if)
                 (begin  (if (equal? (car stack) 0)
                             (set! nslova (index_down program nslova 'endif)))
                         (set! stack (cdr stack))))           
                
                ((equal? (vector-ref program nslova) 'wend)
                 (set! nslova (index_up program nslova 'while)))             

                ((equal? (vector-ref program nslova) 'while)
                 (begin  (if (equal? (car stack) 0)
                             (set! nslova (index_down program nslova 'wend)))
                             (set! stack (cdr stack))
                             (set! stackvc (cons (index_down program nslova 'wend) stackvc))))

                 ((equal? (vector-ref program nslova) 'repeat)
                 (set! stackvc (cons (index_down program nslova 'until) stackvc)))

                 ((equal? (vector-ref program nslova) 'until)
                 (begin  (if (equal? (car stack) 0)
                             (set! nslova 
                             (+ (index_up program nslova 'repeat) 1)))                            
                             (set! stack (cdr stack))))
                                                                    
                ((equal? (vector-ref program nslova) 'define)
                 (begin (set! slovar (cons (cons (vector-ref program (+ 1 nslova))
                                                 (list (+ 1 nslova))) slovar))
                        (set! nslova (index_down program nslova 'end))))
                
                ((assoc (vector-ref program nslova) slovar)
                 (begin (set! stackvf (cons (+ 1 nslova) stackvf))
                        (set! nslova (cadr (assoc (vector-ref program nslova) slovar)))))
                
                ((equal? (vector-ref program nslova) 'exit)
                 (begin (set! nslova (- (car stackvf) 1))
                        (set! stackvf (cdr stackvf))))
                
                ((equal? (vector-ref program nslova) 'end)
                 (begin (set! nslova (- (car stackvf) 1))
                        (set! stackvf (cdr stackvf))))
                
                ((equal? (vector-ref program nslova) 'continue)
                 (begin (set! nslova (- (car stackvc) 1))))
                
                ((equal? (vector-ref program nslova) 'break)
                 (begin (set! nslova (car stackvc))
                        (set! stackvc (cdr stackvc))))
                )
              
              (readword program (+ nslova 1) stack slovar stackvf stackvc)))))     
    (readword program 0 stack '() '() '())))
