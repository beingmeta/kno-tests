;;; -*- Mode: Scheme; text-encoding: latin-1 -*-

(load "common.scm")

(applytest #f ffi/probe "kumquat_lime" #f 'int 'int)

(define ipi (ffi/proc "ffitest_ipi" #f 'long 'int 'int))
(define sps (ffi/proc "ffitest_sps" #f 'int 'short 'short))
(define fpf (ffi/proc "ffitest_fpf" #f 'double 'float 'float))
(define strlen (ffi/proc "ffitest_strlen" #f 'long 'string))
(define chr (ffi/proc "ffitest_chr" #f 'char 'string 'int))

(applytest 9 ipi 3 6)
(applytest 170000 ipi 70000 100000)
(applytest (+ 3.14 2.71) fpf 3.14 2.71)
(applytest 30 strlen "012345678901234567890123456789")
(applytest (char->integer #\9) chr "012345678901234567890123456789" 9)

(errtest (sps 3 "three"))
(errtest (sps 3 70000))
(errtest (ipi 3 "three"))
(errtest (ipi 3 3.14))
(errtest (ipi 3 (1+ (* 4 1024 1024 1024))))

(define ffi_getenv (ffi/proc "getenv" #f #[basetype ptr typespec envstring] 'string))
(define ffi_strdup (ffi/proc "_u8_strdup" #f 'string #[basetype ptr typespec envstring]))

(when (getenv "USER")
  (applytest (getenv "USER") ffi_strdup (ffi_getenv "USER")))
