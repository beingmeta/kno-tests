(use-module '{logger optimize})
(load-component "common.scm")
(config! 'optalltest #t)
(config! 'traceload #t)
;(config! 'optimize:checkusage #f)
(config! 'optimize:err #t)
(config! 'mysql:lazyprocs #f)
(define %loglevel %info%)
(define trouble #f)

(define check-modules
  (macro expr
    `(onerror
	 (begin
	   (use-module ,(cadr expr))
	   (do-choices (mod ,(cadr expr))
	     (loginfo |Load All| "Optimizing module " mod)
	     (optimize-module! mod)))
	 (lambda (ex) (set! trouble ex) (reraise ex)))))

;;(optimize-module! 'optimize)

(load-component "libscm.scm")
(load-component "stdlib.scm")
(load-component "brico.scm")

(when (> (optimize/count-warnings) 0)
  (optimize/list-warnings)
  (error |OptimizeWarnings|))

(when trouble (exit 1))
