dnl     $Id$
dnl
dnl     This file is an input file used by the GNU "autoconf" program to
dnl     generate the file "configure", which is run during the build
dnl     to configure the system for the local environment.
dnl
dnl Mark R. Brown
dnl mbrown@openmarket.com
dnl
dnl Lots of patches by Henrik Grubbström <grubba@idonex.se>
dnl

CCDEFS="$DEFS"

AC_INIT(libfcgi/fcgiapp.c)
AC_CONFIG_HEADER(include/fcgi_config.h)

AC_SET_MAKE

AC_PROG_CC
AC_PROG_RANLIB
AC_MSG_CHECKING(for sun_len in sys/un.h)
AC_EGREP_HEADER(sun_len,
   sys/un.h,
   AC_MSG_RESULT(yes)
   AC_DEFINE(HAVE_SOCKADDR_UN_SUN_LEN),
   AC_MSG_RESULT(no))

if test "x$INSTALL" = "x"; then :; else
  # $INSTALL overrides ac_cv_path_install anyway...
  ac_cv_path_install="$INSTALL"
fi

AC_PROG_INSTALL

AC_CHECK_HEADERS(sys/types.h arpa/inet.h strings.h)

#--------------------------------------------------------------------
#  What extra libraries do we need for this platform?
#--------------------------------------------------------------------
AC_CHECK_LIB(m, floor, [LIBS="$LIBS -lm"])
AC_CHECK_LIB(bind, __inet_ntoa, [LIBS="$LIBS -lbind"])
AC_CHECK_LIB(socket, main, [LIBS="$LIBS -lsocket"])
AC_CHECK_LIB(nsl, main, [LIBS="$LIBS -lnsl"])
AC_CHECK_LIB(Xbsd, main, [LIBS="$LIBS -lXbsd"])
AC_SUBST(LIBS)

AC_REPLACE_FUNCS(strerror strtol)

#--------------------------------------------------------------------
#       Include sys/select.h if it exists and if it supplies things
#       that appear to be useful and aren't already in sys/types.h.
#       This appears to be true only on the RS/6000 under AIX.  Some
#       systems like OSF/1 have a sys/select.h that's of no use, and
#       other systems like SCO UNIX have a sys/select.h that's
#       pernicious.  If "fd_set" isn't defined anywhere then set a
#       special flag.
#--------------------------------------------------------------------

AC_MSG_CHECKING(for fd_set in in sys/types.h)
AC_TRY_LINK([#include <sys/types.h>],
   [fd_set readMask, writeMask;],
   AC_MSG_RESULT(yes),
   AC_MSG_RESULT(no)
   AC_MSG_CHECKING(for fd_mask in in sys/select.h)
   AC_HEADER_EGREP(fd_mask,
      sys/select.h,
      AC_MSG_RESULT(yes)
      AC_DEFINE(HAVE_SYS_SELECT_H),
      AC_MSG_RESULT(no)
      AC_DEFINE(NO_FD_SET)))

AC_MSG_CHECKING(for fpos in stdio.h)
AC_EGREP_HEADER(fpos_t,
   stdio.h,
   AC_MSG_RESULT(yes)
   AC_DEFINE(HAVE_FPOS),
   AC_MSG_RESULT(no))

dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS(fcntl.h unistd.h sys/socket.h netdb.h netinet/in.h \
		 arpa/inet.h strings.h sys/time.h)

if test "x$ac_cv_header_sys_socket_h" = "xyes"; then
    AC_MSG_CHECKING(for socklen_t in sys/socket.h)
    AC_EGREP_HEADER(socklen_t,
       sys/socket.h,
       AC_MSG_RESULT(yes)
       AC_DEFINE(HAVE_SOCKLEN),
       AC_MSG_RESULT(no))
fi

dnl Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_TIME

dnl Checks for library functions.

AC_HAVE_FUNCS(memmove memcpy realloc)

#--------------------------------------------------------------------
#  Build with profiling?
#--------------------------------------------------------------------
AC_ARG_WITH(profile,
    AC_HELP_STRING([--with-profile],[Build a version with profiling]),
    [with_profile=$withval],
    [with_profile=no]
)
if test "$with_profile" = "yes" ; then
    [PROFILE="-pg"]
else
    [PROFILE=""]
fi
AC_SUBST(PROFILE)

#--------------------------------------------------------------------
#  Build optimized, production version with no debugging code?  No
#  asserts?  No testing code?
#--------------------------------------------------------------------
AC_ARG_WITH(nodebug, 
    AC_HELP_STRING([--with-nodebug],[ Build a production version with no debugging code]),
    [with_nodebug=$withval],
    [with_nodebug=no]
)
if test "$with_nodebug" = "yes" ; then
    CCDEFS="$CCDEFS -O"
else
    AC_DEFINE(WITH_DEBUG)
    if test -f /bin/uname && test `/bin/uname` != "IRIX"; then
       CCDEFS="$CCDEFS -g"
    fi
fi
AC_ARG_WITH(noassert,
    AC_HELP_STRING([--with-noassert],[Build a production version with no ASSERTs]),
    [with_noassert=$withval],
    [with_noassert=no]
)
if test "$with_noassert" = "no" ; then
    AC_DEFINE(WITH_ASSERT)
fi
AC_ARG_WITH(notest,
    AC_HELP_STRING([--with-notest],[Build a production version with no testing code]),
    [with_notest=$withval],
    [with_notest=no]
)
if test "$with_notest" = "no" ; then
    AC_DEFINE(WITH_TEST)
fi
#--------------------------------------------------------------------
#  Do we need cross-process locking on this platform?
#--------------------------------------------------------------------
AC_MSG_CHECKING("if this machine needs cross-process locking")
case "`uname -sr`" in
    IRIX\ 5.*)	
	AC_DEFINE(USE_LOCKING)
	AC_MSG_RESULT(yes)
    ;;
    SunOS\ 5.*)	
	AC_DEFINE(USE_LOCKING)
	AC_MSG_RESULT(yes)
    ;;
    UNIX_System_V\ 4.0)
	AC_DEFINE(USE_LOCKING)
	AC_MSG_RESULT(yes)
    ;;
    *)
	AC_MSG_RESULT(no)
    ;;
esac

#--------------------------------------------------------------------
#  Does va_arg(arg, long double) crash the compiler?
#  hpux 9.04 compiler does and so does Stratus FTX (uses HP's compiler)
#--------------------------------------------------------------------
AC_MSG_CHECKING(if va_arg(arg, long double) crashes the compiler)
AC_TRY_COMPILE([#include <stdarg.h>],
   [long double lDblArg; va_list arg; lDblArg = va_arg(arg, long double);],
   AC_MSG_RESULT(no),
   AC_DEFINE(HAVE_VA_ARG_LONG_DOUBLE_BUG)
   AC_MSG_RESULT(yes))

#--------------------------------------------------------------------
#  Determine the best warning options for this platform
#--------------------------------------------------------------------
if test "$CC" = "gcc"; then
    WARNDEFS="-ansi -pedantic -Wall"
else
    if test -f /bin/uname && test `/bin/uname` = OSF1; then
	WARNDEFS="-std1 -warnprotos"
    fi
fi
CCDEFS="$CCDEFS $WARNDEFS"

#--------------------------------------------------------------------
#  Run with Purify?  PureCoverage?  Quantify?
#--------------------------------------------------------------------
CC_PURE="$CC"
AC_ARG_WITH(purify,
    AC_HELP_STRING([--with-purify],[Build a WebServer executable with Purify (Pure Software's tool for finding memory errors)]),
    [CC_PURE="purify $CC_PURE"],)

AC_ARG_WITH(purecov,
    AC_HELP_STRING([--with-purecov],[Build a WebServer executable with PureCoverage (Pure Software's tool for doing test coverage analysis)]),
    [CC_PURE="purecov $CC_PURE"],)

AC_ARG_WITH(quantify,
    AC_HELP_STRING([--with-quantify],[Build a WebServer executable with Quantify (Pure Software's tool for doing performance analysis)]),
    [CC_PURE="quantify $CC_PURE"],)

AC_SUBST(CC_PURE)
AC_SUBST(CCDEFS)

AH_TOP([
#ifndef FCGI_CONFIG_H
#define FCGI_CONFIG_H
])

AH_BOTTOM([
#undef HAVE_FPOS 
#undef HAVE_SOCKADDR_UN_SUN_LEN 
#undef HAVE_SYS_SELECT_H 
#undef NO_FD_SET 
#undef USE_LOCKING 
#undef WITH_ASSERT 
#undef WITH_DEBUG 
#undef WITH_TEST
#undef HAVE_VA_ARG_LONG_DOUBLE_BUG
#undef HAVE_SOCKLEN
#endif

])

AC_OUTPUT(Makefile libfcgi/Makefile cgi-fcgi/Makefile )
