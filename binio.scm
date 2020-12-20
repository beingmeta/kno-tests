;;; -*- Mode: scheme; text-encoding: utf-8; -*-

(load-component "common.scm")

(use-module '{binio})

(define sample-file (get-component "data/sample.dtype"))

(define sample-object
  #(a 33 "bcdef" @99/88 '(x . y) (x y z) {"four" "five" six seven}))

(define (parse-dtype in)
  (let ((byte (read-byte in)))
    (cond ((= byte 0x01) '())
	  ((= byte 0x02)
	   (if (read-byte in) #t #f))
	  ((= byte 0x03) (read-4bytes in))
	  ((= byte 0x04) (read-8bytes in))
	  ((or (= byte 0x05) (= byte 0x06) (= byte 0x07)
	       (= byte 0x10) (= byte 0x11))
	   (let* ((len (if (< byte 0x10) (read-4bytes in) (read-byte in)))
		  (bytes (make-vector len))
		  (i 0))
	     (while (< i len)
	       (vector-set! bytes i (read-byte in))
	       (set! i (1+ i)))
	     (if (= byte 0x05)
		 (->packet bytes)
		 (let* ((packet (->packet bytes))
			(string (packet->string packet)))
		   (if (or (= byte 0x06) (= byte 0x11))
		       string
		       (string->symbol string))))))
	  ((= byte 0x08)
	   (cons (qc (parse-dtype in)) (qc (parse-dtype in))))
	  ((= byte 0x09)
	   (let* ((len (read-4bytes in))
		  (vector (make-vector len))
		  (i 0))
	     (while (< i len)
	       (vector-set! vector i (qc (parse-dtype in)))
	       (set! i (1+ i)))
	     vector))
	  ((= byte 0x0e) (make-oid (read-8bytes in)))
	  ((= byte 0x12)
	   (let ((len (read-byte in))
		 (items {}))
	     (dotimes (i len)
	       (set+! items (parse-dtype in)))
	     items))
	  ((= byte 0x13) {})
	  ((= byte 0x42)
	   (let ((next (read-byte in)))
	     (cond ((or (= next 0xc0)  (= next 0x80))
		    (let ((len (if (= next 0xc0) (read-4bytes in) (read-byte in)))
			  (items {}))
		      (dotimes (i len)
			(set+! items (parse-dtype in)))
		      items)))))
	  (else (irritant byte |NotHandled|)))))

(applytest sample-object parse-dtype (open-dtype-input sample-file))

(test-finished "BINIO")

