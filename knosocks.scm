(use-module '{knosocks samplefns})

(define (test-with-socket socket)
  (let* ((server (knosockd/listener socket
				    [xrefs #(square fib fact)
				     initclients 3
				     maxclients 8
				     nthreads 2
				     id "testing"]
				    [square square fib fibi fact facti]))
	 (thread (thread/call knosockd/run server))
	 (client (open-service socket))
	 (waitcount 200))
    (applytest 120 service/call client 'fact 5)
    (applytest 6765 service/call client 'fib 20)
    (lineout "Done with tests")
    (knosockd/shutdown! server)
    (while (and (not (thread/exited? thread)) (>= waitcount 0))
      (sleep 0.01)
      (set! waitcount (-1+ waitcount)))
    (unless (thread/exited? thread)
      (logwarn |ZombieAlert| 
	"The thread " thread " didn't exit when its server was shut down"))
    thread))

;; (define testop '+)
;; (define test-args '(11 99))

;; (define (evaln server n)
;;   (let ((s (open-service server)))
;;     (dotimes (i n) (apply sevice/call s testop test-args))))

;; (define (calln np n)
;;   (dotimes (i n) (apply np test-args)))

;; (define (evalmn server m n)
;;   (let* ((s (open-service server))
;; 	 (nplus (netproc s testop)))
;;     (let ((start (elapsed-time))
;; 	  (threads {}))
;;       (dotimes (i m) (set+! threads (spawn (evaln server n))))
;;       (thread/join threads)
;;       (/ (* m n) (- (elapsed-time) start)))))
