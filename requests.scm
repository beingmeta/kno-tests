;;; -*- Mode: Scheme; text-encoding: latin-1 -*-

(load-component "common.scm")

(define (glom-ab (alpha "foo") (beta "bar"))
  (glom alpha beta))
(applytest "foobar" glom-ab)
(applytest "foobar" req/call glom-ab)
(define (cons-ab (alpha "foo") (beta "bar"))
  (cons alpha beta))

(define (plus-ts (tt 1) (ttt 2.1)) (+ tt ttt))
(applytest 3.1 req/call plus-ts)

(define (testargs symbol string bad1 bad2)
  (and (symbol? symbol) (string? string)
       (string? bad1) (string? bad2)))

(applytest #f req/live?)

(with/request
 (req/log |Startup| "Starting test of request functions")
 (req/set! 'alpha "alpha")
 (req/set! 'beta "beta")
 (req/set! 'words "alpha")
 (req/add! 'words "beta")
 (req/add! 'words "gamma")
 (req/set! 'tt "33")
 (req/set! 'ttt "33.3")
 (req/push! 'lst 'first)
 (req/push! 'lst 'second)
 (applytest slotmap? (req/data))
 (applytest "33" req/get 'tt)
 (applytest "33.3" req/get 'ttt)
 (applytest 33 req/val 'tt)
 (applytest 33.3 req/val 'ttt)
 (applytest {} req/val 'tttt)
 (applytest "ttttt" req/val 'tttt "ttttt")
 (applytest #t req/test 'alpha)
 (applytest #f req/test 'gamma)
 (applytest #t req/test 'alpha "alpha")
 (applytest #t req/test 'words "gamma")
 (req/drop! 'words "gamma")
 (req/set! 'notanum "35x")
 (applytest #f req/test 'words "gamma")
 (req/log |ReqCall| "Starting req/call tests")
 (applytest "alphabeta" req/call glom-ab)
 (applytest 66.3 req/call plus-ts)
 (req/set! 'symbol ":symbol")
 (req/set! 'colon ":")
 (req/set! 'string "\\:string")
 (req/set! 'bad1 ":(+ 3")
 (req/set! 'bad2 "(+ 3")
 (req/set! 'eval5 "(+ 3 2)")
 (req/set! 'eval5a ":(+ 3 2)")
 (applytest #t req/call testargs)
 (applytest "(+ 3" req/call (lambda (bad2) bad2))
 (applytest ":(+ 3" req/call (lambda (bad1) bad1))
 (applytest '(+ 3 2) req/call (lambda (eval5) eval5))
 (applytest '(+ 3 2) req/call (lambda (eval5a) eval5a))
 (applytest "33" req/call (lambda (%tt) %tt))
 (req/set! 'eval5b ":(+ 3 2)")
 (applytest '(+ 3 2) req/call (lambda (eval5b) eval5b))
 (req/add! 'eval5b 9)
 (req/add! 'eval5b "9")
 (req/add! 'eval5b ":(+ 4 3)")
 (req/add! 'eval5b "11")
 (req/add! 'eval5b "\\11")
 (req/add! 'eval5b ":")
 (applytest '{(+ 3 2) (+ 4 3) 9 11 ":" "11"} req/val 'eval5b)
 (req/add! 'eval5b ":(+ 3 2")
 (applytest '{(+ 3 2) (+ 4 3) 9 11 ":(+ 3 2" "11" ":"} req/call (lambda (eval5b) eval5b))
 (applytest string? req/call (lambda (notanum) notanum))
 (applytest '(second first) req/get 'lst)
 (applytest #t req/live?)
 (req/log "ReqLogString" "Test with string")
 (let ((len (req/loglen))
       (string (req/getlog)))
   (when (and (applytest len length string)
	      (applytest > 0 req/loglen))
     (req/log |ReqLogOK| "REQ/LOG appears to be written okay")
     (applytest #f equal? string (req/getlog))))
 )

(with/request 
  (req/set! 'alpha 9)
  (req/log (append "foo" 3) "Error"))

(with/request 
 (req/set! 'alpha 9)
 (req/log (glom "foo" 3) "No error"))

(with/request 
 (req/set! 'alpha 9)
 (req/log 'beta "No error"))

(with/request
 (req/set! 'alpha 9)
 (req/log 'inerr "There was " (1+ "zero") " error"))

(errtest
 (with/request
  (req/set! 'alpha 9)
  (req/set! 'beta (1+ "zero"))
  (req/get! 'gamma 8)))


