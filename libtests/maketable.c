/* -*- Mode: C; Character-encoding: utf-8; -*- */

/* Copyright (C) 2004-2020 beingmeta, inc.
   Copyright (C) 2020-2021 Kenneth Haase (ken.haase@alum.mit.edu)
*/

#include "kno/lisp.h"
#include "kno/streams.h"

#include <libu8/libu8.h>
#include <libu8/u8stdio.h>

#include <strings.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>

static struct timeval start;
static int started = 0;

double get_elapsed()
{
  struct timeval now;
  if (started == 0) {
    gettimeofday(&start,NULL);
    started = 1;
    return 0;}
  else {
    gettimeofday(&now,NULL);
    return (now.tv_sec-start.tv_sec)+
      (now.tv_usec-start.tv_usec)*0.000001;}
}

#define SLOTMAP(x) (KNO_GET_CONS(struct KNO_SLOTMAP *,x,kno_slotmap_type))
#define HASHTABLE(x) (KNO_GET_CONS(struct KNO_HASHTABLE *,x,kno_slotmap_type))

static void report_on_hashtable(lispval ht)
{
  int n_slots, n_keys, n_buckets, n_collisions, max_bucket, n_vals, max_vals;
  kno_hashtable_stats(kno_consptr(struct KNO_HASHTABLE *,ht,kno_hashtable_type),
		     &n_slots,&n_keys,&n_buckets,&n_collisions,&max_bucket,
		     &n_vals,&max_vals);
  u8_fprintf
    (stderr,"Table distributes %d keys over %d slots in %d buckets\n",
     n_keys,n_slots,n_buckets);
  u8_fprintf
    (stderr,"%d collisions, averaging %f keys per bucket (max=%d)\n",
     n_collisions,((1.0*n_keys)/n_buckets),max_bucket);
  u8_fprintf
    (stderr,
     "The keys refer to %d values all together (mean=%f,max=%d)\n",
     n_vals,((1.0*n_vals)/n_keys),max_vals);

}

int main(int argc,char **argv)
{
  lispval ht, item, key = KNO_VOID; int i = 0;
  struct KNO_STREAM *in, *out;
  struct KNO_INBUF *inbuf;
  double span;
  KNO_DO_LIBINIT(kno_init_lisp_types);
  span = get_elapsed(); /* Start the timer */
  ht = kno_make_hashtable(NULL,64);
  in = kno_open_file(argv[1],KNO_FILE_READ);
  if (in == NULL) {
    u8_log(LOG_ERR,"No such file","Couldn't open file %s",argv[1]);
    exit(1);}
  else inbuf = kno_readbuf(in);
  kno_setbufsize(in,65536*2);
  item = kno_read_dtype(inbuf); i = 1;
  while (!(KNO_EODP(item))) {
    if (i%100000 == 0) {
      double tmp = get_elapsed();
      u8_fprintf(stderr,"%d: %f %f %ld\n",i,tmp,(tmp-span),kno_getpos(in));
      span = tmp;}
    if (KNO_PAIRP(item)) {
      kno_decref(key); key = kno_incref(item);}
    else kno_hashtable_add
	   (kno_consptr(struct KNO_HASHTABLE *,ht,kno_hashtable_type),
	    key,item);
    kno_decref(item); item = kno_read_dtype(inbuf);
    i = i+1;}
  report_on_hashtable(ht);
  kno_close_stream(in,KNO_STREAM_CLOSE_FULL);
  out = kno_open_file(argv[2],KNO_FILE_CREATE);
  if (out) {
    struct KNO_OUTBUF *outbuf = kno_writebuf(out);
    kno_write_dtype(outbuf,ht);
    kno_close_stream(out,KNO_STREAM_CLOSE_FULL);}
  kno_decref(ht); ht = KNO_VOID;
  exit(0);
}

