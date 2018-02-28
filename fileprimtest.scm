;;; -*- Mode: scheme; text-encoding: utf-8; -*-

(load-component "common.scm")

(define data-dir (get-component "data"))
(define text-file (mkpath data-dir "testobj.text"))
(define dtype-file (mkpath data-dir "testobj.dtype"))
(define private-text-file
  (and (file-exists? (mkpath data-dir "private.text"))
       (mkpath data-dir "private.text")))
(define private-dtype-file
  (and (file-exists? (mkpath data-dir "private.dtype"))
       (mkpath data-dir "private.dtype")))

(applytest #f file-readable? private-text-file)
(applytest #f file-readable? private-dtype-file)

(applytest "(#[foo 3 bar 8] " getline
	   (open-input-file (mkpath data-dir "testobj.text")))
(define inport (open-input-file (mkpath data-dir "testobj.text")))
(applytest #\( getchar inport)
(evaltest #[foo 3 bar 8] (read inport))
(define inport (open-input-file (mkpath data-dir "testobj.text")))
(evaltest #[foo 3 bar 8] (car (read inport)))

(define intext (filestring text-file))
(applytest intext (filestring text-file))
(define indata (filedata dtype-file))
(applytest indata (filedata dtype-file))

(define from-text (read (open-input-file text-file)))
(define from-dtype (file->dtype (open-dtype-input dtype-file)))
(evaltest #t (equal? from-text from-dtype))
(applytest from-text (file->dtype dtype-file))
(applytest from-text (file->dtype (open-dtype-input dtype-file)))

(set! inport #f)
(when private-text-file
  (evaltest #f (onerror (getchar (open-input-file private-text-file)) #f )))
(when private-dtype-file
  (evaltest #f (onerror
		   (read-dtype (open-dtype-input private-dtype-file))
		   #f)))
