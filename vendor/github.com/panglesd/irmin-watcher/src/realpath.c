/*
 * Copyright (c) 2009 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2016 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifdef _MSC_VER
/* https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation */
#define PATH_MAX MAX_PATH
#else
#include <sys/param.h>
#endif
#include <stdlib.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

#ifdef _WIN32
CAMLprim value irmin_watcher_unix_realpath(value path)
{
  TCHAR buffer[PATH_MAX]=TEXT("");
  DWORD error = 0;
  DWORD retval = 0;
  retval = GetFullPathName(String_val(path), PATH_MAX, buffer, NULL);
  if (retval == 0) {
    error = GetLastError();
    uerror("realpath", path);
  };
  return caml_copy_string(buffer);
}
#else
CAMLprim value irmin_watcher_unix_realpath(value path)
{
  char buffer[PATH_MAX];
  char *r;
  r = realpath(String_val(path), buffer);
  if (r == NULL) uerror("realpath", path);
  return caml_copy_string(buffer);
}
#endif
