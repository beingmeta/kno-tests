(use-module '{logger optimize})
(load-component "common.scm")
(config! 'optalltest #t)
(config! 'traceload #t)
(config! 'mysql:lazyprocs #f)
(define %loglevel %info%)
(define trouble #f)

(define check-modules
  (macro expr
    `(onerror
	 (use-module ,(cadr expr))
	 (lambda (ex) (set! trouble ex) (reraise ex)))))

(load-component "libscm.scm")
(load-component "stdlib.scm")
(load-component "brico.scm")

(when trouble (exit 1))

