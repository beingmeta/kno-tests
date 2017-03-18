/* -*- Mode: C; Character-encoding: utf-8; -*- */

/* Copyright (C) 2004-2017 beingmeta, inc.
   This file is part of beingmeta's FramerD platform and is copyright
   and a valuable trade secret of beingmeta, inc.
*/

#ifndef _FILEINFO
#define _FILEINFO __FILE__
#endif

#include "framerd/dtype.h"

#include <libu8/libu8.h>

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

static void write_dtype_to_file(fdtype object,FILE *f)
{
  struct FD_OUTBUF out;
  FD_INIT_BYTE_OUTBUF(&out,1024);
  fd_write_dtype(&out,object);
  fwrite(out.buffer,1,out.bufwrite-out.buffer,f);
  u8_free(out.buffer);
}

int main(int argc,char **argv)
{
  fdtype object;
  FILE *f=fopen(argv[1],"wb");
  FD_DO_LIBINIT(fd_init_libfdtype);
  object=fd_parse(argv[2]);
  write_dtype_to_file(object,f);
  u8_fprintf(stderr,"dumped %q\n",object);
  fd_decref(object);
  exit(0);
}
