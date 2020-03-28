(load-component "common.scm")

(optimization-leaks)

(define (balance-iter i up down)
  (if (= i 1) (- up down)
      (balance-iter (-1+ i) (1+ up) (1+ down))))
(define (balancer n)
  (if (= n 0) 0 (balance-iter n 0 0)))

(define (fib-iter i cur prev)
  (if (= i 1) cur (fib-iter (-1+ i) (+ cur prev) cur)))
(define (fibi n)
  (if (= n 0) 0 (fib-iter n 1 0)))

(define (test-tail-calls)
  (applytest 0 balancer 100)
  ;; This should blow out the stack if tail recursion is broken
  (applytest 0 balancer 10000)
  (applytest 6765 fibi 20)
  (applytest 280571172992510140037611932413038677189525 fibi 200)
  (applytest 43466557686937456435688527675040625802564660517371780402481729089536555417949051890403879840079255169295922593080322634775209689623239873322471161642996440906533187938298969649928516003704476137795166849228875
	     fibi 1000))

;; This tests that tail calls in WHEN are evaluated

(define test-flag #f)

(define (set-test-flag! val)
  (set! test-flag val))

(define (bug-test (val #f))
  (when (= 3 3)
    (if (= 2 2)
	(set-test-flag! val))))

(define (optimized-tail-testfn)
  (set! test-flag #f)
  (bug-test #t)
  test-flag)

(test-tail-calls)

(applytest #t optimized-tail-testfn)

(test-finished "R4RS test")

