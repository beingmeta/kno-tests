;;; -*- Mode: Scheme; text-encoding: latin-1 -*-

(load-component "common.scm")

(use-module 'ezrecords)

(defrecord type1
  x y (z 3) (q 4))

(defrecord (type2 mutable)
  x y (a 8) (b 9))

(defrecord (type3 opaque)
  x y (m 8) (n 9))

(define type1.1 (cons-type1 11 12))
(define type2.1 (cons-type2 33 99))
(define type3.1 (cons-type3 2000 42))

(applytest "#<<type3 2000 42 8 9>>" lisp->string type3.1)
(applytest "#%(type1 11 12 3 4)" lisp->string type1.1)

(applytest {type1.1 type3.1} pick-compounds {type1.1 9 type3.1 "nine" #"nine" '(9)})
(applytest type1.1 pick-compounds {type1.1 9 type3.1 "nine" #"nine" '(9)} 'type1)

(applytest 'type1 car (unpack-compound type1.1))
(applytest vector? cdr (unpack-compound type1.1))
(applytest 'err unpack-compound type1.1 'type2)

(applytest #t compound? type1.1)
(applytest #t compound? type1.1 'type1)
(applytest #f compound? type1.1 'type2)

(applytest #t tagged? type1.1 'type1)
(applytest #f tagged? type1.1 'type2)

(applytest #t compound? type2.1)
(applytest #t compound? type2.1 'type2)
(applytest #f compound? type2.1 'type1)

(applytest #t compound? type3.1)
(applytest #t exists compound? type1.1 '{type1 type2})
(applytest #t exists compound? type2.1 '{type1 type2})
(applytest #f exists compound? type3.1 '{type1 type2})

(applytest #t type1? type1.1)
(applytest #f compound-mutable? type1.1)
(applytest #f compound-opaque? type1.1)
(applytest 'type1 compound-tag type1.1)
(applytest 4 compound-length type1.1)
(applytest 3 type1-z type1.1)
(applytest 11 type1-x type1.1)

(applytest #t compound-mutable? type2.1)
(applytest #f compound-opaque? type2.1)
(applytest 'type2 compound-tag type2.1)
(applytest 4 compound-length type2.1)
(applytest 8 type2-a type2.1)
(applytest 33 type2-x type2.1)
(applytest 'err type1-x type2.1)

(applytest 33 compound-ref type2.1 0)
(applytest 33 compound-ref type2.1 0 'type2)
(applytest 'err compound-ref type2.1 0 'type1)
(applytest 'err compound-ref type2.1 22 'type2)

(applytest 33 compound-ref type2.1 0)
(evaltest 77 (begin (compound-set! type2.1 0 77)
	       (compound-ref type2.1 0)))
(errtest (compound-set! type1.1 0 77))
(errtest (compound-set! type2.1 0 77 'type1))
(evaltest (* 2 77) (begin (compound-modify! type2.1 0 * 2 'type2)
		     (compound-ref type2.1 0)))
(errtest (compound-modify! type2.1 0 * 2 'type1))


(applytest #f compound-mutable? type3.1)
(applytest #t compound-opaque? type3.1)
(applytest 'type3 compound-tag type3.1)
(applytest 4 compound-length type3.1)

(define (iscompound? x) (compound? x))

(applytest iscompound? make-compound 'type11 3 4 "foo" '(bar))
(applytest iscompound? make-opaque-compound 'type11 3 4 "foo" '(bar))
(applytest iscompound? make-mutable-compound 'type11 3 4 "foo" '(bar))
(applytest iscompound? make-opaque-mutable-compound 'type11 3 4 "foo" '(bar))

(applytest compound-opaque? make-opaque-compound 'type11 3 4 "foo" '(bar))
(applytest compound-mutable? make-mutable-compound 'type11 3 4 "foo" '(bar))
(applytest compound-mutable? make-opaque-mutable-compound 'type11 3 4 "foo" '(bar))
(applytest compound-opaque? make-opaque-mutable-compound 'type11 3 4 "foo" '(bar))


(errtest (sequence->compound 'foo 'type4))
(applytest #%(TYPE4 A B C) sequence->compound #(A B C) 'type4)
(applytest #%(TYPE4 A B C) sequence->compound '(A B C) 'type4)
(applytest "#%(type4 a b c)" lisp->string (sequence->compound '(A B C) 'type4))
(define (type4-opaquefn c)
  (stringout "#<TYPE4" (doseq (elt c) (printout " " elt))
    ">"))
;; (compound-set-stringfn! 'type4 type4-opaquefn)
;; (applytest "#<TYPE4 a b c>" lisp->string (sequence->compound '(A B C) 'type4))
