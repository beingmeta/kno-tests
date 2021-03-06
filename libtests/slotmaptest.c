/* -*- Mode: C; Character-encoding: utf-8; -*- */

/* Copyright (C) 2004-2020 beingmeta, inc.
   Copyright (C) 2020-2021 Kenneth Haase (ken.haase@alum.mit.edu)
*/

#include "kno/lisp.h"

#include <libu8/libu8.h>
#include <libu8/u8stdio.h>

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

static lispval read_dtype_from_file(FILE *f)
{
  lispval object;
  struct KNO_OUTBUF out = { 0 };
  struct KNO_INBUF in = { 0 };
  char buf[1024]; int delta = 0;
  KNO_INIT_BYTE_OUTPUT(&out,1024);
  while ((delta = fread(buf,1,1024,f))) {
    if (delta<0)
      if (errno == EAGAIN) {}
      else u8_raise("Read error","u8recode",NULL);
    else kno_write_bytes(&out,buf,delta);}
  KNO_INIT_BYTE_INPUT(&in,out.buffer,(out.bufwrite-out.buffer));
  object = kno_read_dtype(&in);
  kno_close_outbuf(&out);
  return object;
}

static int write_dtype_to_file(lispval object,FILE *f)
{
  struct KNO_OUTBUF out = { 0 };
  int retval;
  KNO_INIT_BYTE_OUTPUT(&out,1024);
  kno_write_dtype(&out,object);
  retval = fwrite(out.buffer,1,out.bufwrite-out.buffer,f);
  kno_close_outbuf(&out);
  return retval;
}

#define free_val(x) kno_decref(x); x = KNO_VOID

#define SLOTMAP(x) (kno_consptr(struct KNO_SLOTMAP *,x,kno_slotmap_type))

int main(int argc,char **argv)
{
  FILE *f = fopen(argv[1],"rb");
  lispval smap;
  KNO_DO_LIBINIT(kno_init_lisp_types);
  if (f) {
    smap = read_dtype_from_file(f); fclose(f);}
  else smap = kno_empty_slotmap();
  if (argc == 2) {
    lispval keys = kno_slotmap_keys(SLOTMAP(smap));
    KNO_DO_CHOICES(key,keys) {
      lispval v = kno_slotmap_get(SLOTMAP(smap),key,KNO_EMPTY_CHOICE);
      u8_fprintf(stdout,"%s=%s\n",key,v);
      kno_decref(v);}
    free_val(keys); free_val(smap);
    exit(0);}
  else if (argc == 3) {
    lispval slotid = kno_parse(argv[2]);
    lispval value = kno_slotmap_get(SLOTMAP(smap),slotid,KNO_VOID);
    u8_fprintf(stdout,"%q=%q\n",slotid,value);
    free_val(value);}
  else if (argv[3][0] == '+') {
    lispval slotid = kno_parse(argv[2]);
    lispval value = kno_parse(argv[3]+1);
    kno_slotmap_add(SLOTMAP(smap),slotid,value);
    f = fopen(argv[1],"wb");
    write_dtype_to_file(smap,f);
    free_val(slotid); free_val(value);
    fclose(f);}
  else if (argv[3][0] == '-') {
    lispval slotid = kno_parse(argv[2]);
    lispval value = kno_parse(argv[3]+1);
    kno_slotmap_drop(SLOTMAP(smap),slotid,value);
    f = fopen(argv[1],"wb");
    write_dtype_to_file(smap,f);
    free_val(slotid); free_val(value);
    fclose(f);}
  else {
    lispval slotid = kno_parse(argv[2]);
    lispval value = kno_parse(argv[3]);
    kno_slotmap_store(SLOTMAP(smap),slotid,value);
    f = fopen(argv[1],"wb");
    write_dtype_to_file(smap,f);
    free_val(slotid); free_val(value);
    fclose(f);}
  u8_fprintf(stdout,"%q\n",smap);
  free_val(smap);
  exit(0);
}

