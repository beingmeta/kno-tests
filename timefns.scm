(load-component "common.scm")

(define est-time1 #T2011-12-03T03:23:00EST)
(define gmt-time1 #T2011-12-03T08:23:00Z)

(define est-time1-string #T2011-12-03T03:23:00EST)
(define gmt-time1-string "2011-12-03T08:23:00Z")

(define (get-sign n)
  (if (< n 0) -1 (if (> n 0) 1 0)))

(applytest gmt-time1 gmtimestamp "2011-12-03T08:23:00Z")

(define time1-tick 1322900580)
(applytest #t equal? est-time1 gmt-time1)
(applytest #t equal? (get est-time1 'tick) (get gmt-time1 'tick))
(applytest time1-tick get est-time1 'tick)
(applytest 0 get est-time1 'dstoff)
(applytest -18000 get est-time1 'gmtoff)
(applytest -18000 get est-time1 'tzoff)

(applytest #f time<? time1-tick)
(applytest #t time>? time1-tick)
(evaltest 1 (get-sign (time-since time1-tick)))
(evaltest -1 (get-sign (time-until time1-tick)))

(applytest time1-tick get gmt-time1 'tick)
(applytest 0 get gmt-time1 'gmtoff)
(applytest 0 get gmt-time1 'tzoff)
(applytest 0 get gmt-time1 'dstoff)

(define est-time2 #T2011-06-08T15:00:00EDT)
(define gmt-time2 #T2011-06-08T19:00:00Z)
(define cet-time2 #T2011-06-08T15:00:00EDT)
(store! cet-time2 'tzoff 3600)
;; To check, try date --date='@1307559600'
(define time2-tick 1307559600)

(applytest #t equal? est-time2 gmt-time2)
(applytest #t equal? (get est-time2 'tick) (get gmt-time2 'tick))
(applytest #t equal? (get est-time2 'tick) (get cet-time2 'tick))
(applytest time2-tick get est-time2 'tick)
(applytest time2-tick get cet-time2 'tick)
(applytest 3600 get est-time2 'dstoff)
(applytest -14400 get est-time2 'gmtoff)
(applytest -18000 get est-time2 'tzoff)

(applytest 3600 get cet-time2 'dstoff)
(applytest 7200 get cet-time2 'gmtoff)
(applytest 3600 get cet-time2 'tzoff)

(applytest time2-tick get gmt-time2 'tick)
(applytest 0 get gmt-time2 'gmtoff)
(applytest 0 get gmt-time2 'tzoff)
(applytest 0 get gmt-time2 'dstoff)

(define a-uuid (getuuid))
(applytest #t uuid? a-uuid)
(define a-uuid-packet (uuid->packet a-uuid))
(define a-uuid-string (uuid->string a-uuid))
(define a-uuid-time (uuid-time a-uuid))
(define a-uuid-node (uuid-node a-uuid))
(applytest a-uuid (getuuid a-uuid-string))
(applytest a-uuid (getuuid a-uuid-packet))

(applytest "02:05:00" secs->short (+ (* 3600 2) (* 60 5)))
(applytest "2 hours, 5 minutes" secs->string (+ (* 3600 2) (* 60 5)))

(applytest #t > (microtime) (millitime) (time))

(define (secsdiff t1 t2) (->exact (round (difftime t1 t2))))
(define (tsince t) (->exact (round (time-since t))))
(define (tuntil t) (->exact (round (time-until t))))

(let* ((now (timestamp))
       (tomorrow (timestamp+ (* 24 3600)))
       (yesterday (timestamp+ (* -24 3600)))
       (bday (timestamp "1979-12-03T03:15:00-5:00"))
       (moment (elapsed-time)))
  (applytest 86400 tsince yesterday)
  (applytest 86400 tuntil tomorrow)
  (applytest -86400 tsince tomorrow)
  (applytest -86400 tuntil yesterday)
  (applytest 172800 secsdiff tomorrow yesterday)
  (applytest -172800 secsdiff yesterday tomorrow)
  (applytest #t time<? yesterday tomorrow)
  (applytest #t time<? yesterday now)
  (applytest #f time<? tomorrow yesterday)
  (applytest #f time<? now yesterday)
  (applytest #f time>? yesterday tomorrow)
  (applytest #f time>? yesterday now)
  (applytest #t time>? tomorrow yesterday)
  (applytest #t time>? now yesterday)
  (applytest #t past? yesterday)
  (applytest #f past? tomorrow)
  (applytest #f future? yesterday)
  (applytest #t future? tomorrow)
  (applytest #t < (elapsed-time moment) 2)
  ;; OS dependent?
  ;; (applytest "Mon 03 Dec 1979 03:15:00 AM EST" get bday 'string)
  (applytest "3Dec1979 03:15AM" get bday 'short)
  (applytest 1979 get bday 'year)
  (applytest 11 get bday 'month)
  (applytest 3 get bday 'date)
  (applytest 3 get bday 'hours)
  (applytest 15 get bday 'minutes)
  (applytest 0 get bday 'seconds)
  (applytest 'seconds get bday 'precision)
  (applytest -18000 get bday 'tzoff)
  (applytest 0 get bday 'dstoff)
  (applytest -18000 get bday 'gmtoff)
  (applytest 0 get bday 'milliseconds)
  (applytest 0 get bday 'microseconds)
  (applytest 0 get bday 'nanoseconds)
  (applytest 313056900 get bday 'tick)
  (applytest 313056900 get bday '%tick)
  (applytest 3.130569e+08 get bday 'xtick)
  (applytest "1979-12-03T03:15:00-5:00" get bday 'iso)
  (applytest "1979-12-03" get bday 'isodate)
  (applytest "19791203T031500-5:00" get bday 'isobasic)
  (applytest "19791203" get bday 'isobasicdate)
  (applytest "1979-12-03T03:15:00-5:00" get bday 'isostring)
  (applytest "1979-12-03T03:15:00-5:00" get bday 'iso8601)
  ;; OS dependent?
  ;;(applytest "Mon, 3 Dec 1979 03:15:00 EST" get bday 'rfc822)
  (applytest "Mon, 3 Dec 1979 03:15:00 -0500" get bday 'rfc822x)
  (applytest "Mon, 3 Dec 1979 08:15:00" get bday 'utcstring)
  (applytest 'nighttime get bday 'time-of-day)
  (applytest 'winter get bday 'season)
  (applytest "Dec" get bday 'month-short)
  (applytest "December" get bday 'month-long)
  (applytest "Mon" get bday 'weekday-short)
  (applytest "Monday" get bday 'weekday-long)
  (applytest "03:15:00" get bday 'hms)
  (applytest "3Dec1979" get bday 'dmy)
  (applytest "3Dec" get bday 'dm)
  (applytest "Dec1979" get bday 'my)
  (applytest "3Dec1979 03:15:00AM" get bday 'shortstring)
  (applytest "03:15:00 AM" get bday 'timestring)
  (applytest "12/03/1979" get bday 'datestring)
  (applytest "Monday 03 December 1979 03:15:00 AM -0500" get bday 'fullstring)
  (applytest 'mon get bday 'dowid)
  (applytest 'dec get bday 'monthid))
  
(message "TIMEFNS tests successfuly completed")
