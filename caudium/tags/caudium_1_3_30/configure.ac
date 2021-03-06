#
# $Id$
#
AC_PREREQ(2.53)
AC_INIT(Caudium, 1.3.23, bugs@caudium.net)

AC_REVISION($Revision$)

#
# Some prerequisites of ours
#
# The oldest version of Pike we run
REQ_MIN_PIKE_MAJOR=7
REQ_MIN_PIKE_MINOR=6
REQ_MIN_PIKE_BUILD=7
# But on the other end we can't run Pike above or equal this one
REQ_MAX_PIKE_MAJOR=7
REQ_MAX_PIKE_MINOR=7
REQ_MAX_PIKE_BUILD=0

# Some DMALLOC and usefull macros
# Copyright 1996, 1998, 1999, 2000, 2001, 2002  Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

# serial 2

AC_DEFUN([AM_WITH_DMALLOC],
[AC_MSG_CHECKING([if malloc debugging is wanted])
AC_ARG_WITH(dmalloc,
[  --with-dmalloc          use dmalloc, as in
                          http://www.dmalloc.com/dmalloc.tar.gz],
[if test "$withval" = yes; then
  AC_MSG_RESULT(yes)
  AC_DEFINE(WITH_DMALLOC,1,
            [Define if using the dmalloc debugging malloc package])
  LIBS="$LIBS -ldmalloc"
  LDFLAGS="$LDFLAGS -g"
else
  AC_MSG_RESULT(no)
fi], [AC_MSG_RESULT(no)])
])

AU_DEFUN([fp_WITH_DMALLOC], [AM_WITH_DMALLOC])

## End of DMALLOC definitions.

AC_SET_MAKE

AC_PROG_INSTALL
BUILDDIR=`pwd`
case "$ac_cv_path_install" in
  *installbsd*)
    AC_MSG_CHECKING(if $ac_cv_path_install works)
    AC_CACHE_VAL(caudium_cv_install_works,
[
    if $ac_cv_path_install "$srcdir/configure.ac" ./conftest >/dev/null 2>&1
    then
      if cmp "$srcdir/configure.ac" ./conftest >/dev/null 2>&1; then
        caudium_cv_install_works=yes;
      else
        caudium_cv_install_works=no;
      fi
    else
      caudium_cv_install_works=no;
    fi
    if test -f ./conftest; then
      rm -f ./conftest
    fi
])
    AC_MSG_RESULT($caudium_cv_install_works)
    if test "$caudium_cv_install_works" = "no"; then
      echo "Warning: Falling back to $ac_install_sh"
      INSTALL="$ac_install_sh"
    fi
  ;;
esac

# We want an absolute path to the source-dir.
case "$srcdir" in
    /*)
    ;;
    *)
	oldsrcdir="$srcdir"
	srcdir="`cd \"$srcdir\";pwd`"
	AC_MSG_WARN([ Converted $oldsrcdir to $srcdir,
If this does not work, please use an absolute path to the configure script. ])
    ;;
esac


# Compiler checks
#--------------------------

# Strip smartlink from cached CC if it's there.
if test ! -z "$ac_cv_prog_CC"; then
 ac_cv_prog_CC="`echo $ac_cv_prog_CC|sed -e 's/.*smartlink //'`"
 export ac_cv_prog_CC
fi

if test ! -z "$caudium_cv_prog_CC" -a ! -z "$CC" -a "$CC" != "$caudium_cv_prog_CC"
then
  AC_MSG_WARN([CC is different than last time Caudium was compiled,
It is probably best to delete ./config.cache before proceeding])
fi

#
# NOTE: These tests must be before AC_PROG_CC
# since AC_PROG_CC sets CFLAGS by itself.
#

if test "x${CFLAGS-}" = "x" ; then
  cflags_is_set=no
else
  cflags_is_set=yes
fi

if test "x${CPPFLAGS-}" = "x" ; then
  cppflags_is_set=no
else
  cppflags_is_set=yes
fi

if test "x${LDFLAGS-}" = "x" ; then
  ldflags_is_set=no
else
  ldflags_is_set=yes
fi

caudium_cv_prog_CC="$CC"

AC_PROG_CC
AC_AIX
AC_MINIX

AC_CHECK_LIB(dl, dlopen)
AC_CHECK_LIB(dld, shl_load)
AC_CHECK_LIB(dld, dld_link)

#############################################################
# Set some OS/Compiler Specific flags...
# Compiler flags...

AC_DEFUN(AC_SYS_COMPILER_FLAG,
[
  AC_MSG_CHECKING($1)
  OLD_CFLAGS="[$]CFLAGS"
  AC_CACHE_VAL(caudium_cv_option_$2,
  [
    CFLAGS="[$]OLD_CFLAGS $1"
    AC_TRY_RUN([int main(){exit(0);}],caudium_cv_option_$2=yes,caudium_cv_option_$2=no)
  ])
  
  CFLAGS="[$]OLD_CFLAGS"
  
  if test x"[$]caudium_cv_option_$2" = "xyes" ; then
    $3="[$]$3 $1"
    AC_MSG_RESULT(yes)
  else
    AC_MSG_RESULT(no)
  fi
])

AC_DEFUN(AC_SYS_CPU_COMPILER_FLAG,
[
  if test "`uname -m 2>/dev/null`" = "$1" ; then
    AC_SYS_COMPILER_FLAG($2,$3,$4)
  fi
])

AC_DEFUN(AC_SYS_OS_COMPILER_FLAG,
[
  if test "x$caudium_cv_sys_os" = "x$1" ; then
    AC_SYS_COMPILER_FLAG($2,$3,$4)
  fi
])

# Test the following compiler flag only for OS + CPU that NOT 
# passed in $1 and $2 args
AC_DEFUN(AC_SYS_NOT_OS_CPU_COMPILER_FLAG,
 [
   if test "x$caudium_cv_sys_os" != "x$1"; then
     if test "`uname -m 2>/dev/null`" != "$2" ; then
       AC_SYS_COMPILER_FLAG($3,$4,$5)
     fi
   fi
])


# We need some special hacks when running slowaris
## Build smartlink

AC_CHECK_HEADERS(stdlib.h string.h unistd.h sys/stat.h sys/types.h sys/errno.h)

AC_PATH_PROG(uname_prog,uname,no)
if test "$uname_prog" != "no"; then
  UNAME=`$uname_prog -sr`
elif test -x /usr/bin/uname 2>/dev/null; then
  UNAME=`/usr/bin/uname -sr`
elif test -x /usr/bin/uname 2>/dev/null; then
  UNAME=`/usr/bin/uname -sr`
elif test -x /bin/uname 2>/dev/null; then
  UNAME=`/bin/uname -sr`
else
  UNAME=unknown
fi

AC_MSG_CHECKING(operating system)

AC_CACHE_VAL(caudium_cv_sys_os,
[
if test "$uname_prog" != "no"; then
  caudium_cv_sys_os="`uname`"

  case "$caudium_cv_sys_os" in
    SunOS)
      case "`uname -r`" in
        5.*) caudium_cv_sys_os="Solaris";
      esac
    ;;
    Monterey64)
      # According to the release notes, the string "Monterey64"
      # will be changed to "AIX" in the final release.
      # (Monterey 64 is also known as AIX 5L).
      caudium_cv_sys_os="AIX"
    ;;
  esac
else
  caudium_cv_sys_os="Not Solaris"
fi
])
AC_MSG_RESULT($caudium_cv_sys_os)

if test "$caudium_cv_sys_os" = "Solaris" ; then
  AC_DEFINE(SOLARIS)
else
  :
fi

# FIXME: Add proper tests
case "$UNAME" in
  OSF1\ V4.*)
    AC_DEFINE(USE_RPATH)
    ;;
  HPUX\ 11.*)
    AC_DEFINE(USE_PLUS_b)
    ;;
  IRIX\ 6.*)
    AC_DEFINE(USE_RPATH)
    ;;
  IRIX\ 5.*)
    AC_DEFINE(USE_RPATH)
    ;;
  SunOS\ 5.*)
    if test "$TCC" = "yes"; then
      # tcc doesn't know about -R
      AC_DEFINE(USE_Wl_R)
    else
      AC_DEFINE(USE_R)
    fi
    ;;
  Linux\ 2.*)
    AC_DEFINE(USE_Wl)
    ;;
  UnixWare\ 7.*)
    if test "$ac_cv_prog_gcc" = "yes"; then
      AC_DEFINE(USE_XLINKER_YP_)
    else
      AC_DEFINE(USE_YP_)
    fi
    ;;
  *)
    AC_DEFINE(USE_LD_LIBRARY_PATH)
    ;;
esac

# Fix a smartlink
SMARTLINK="$BUILDDIR/smartlink"

AC_MSG_CHECKING(if $SMARTLINK exists is up to date and works)
if ls -1tr "$SMARTLINK" "$srcdir/tools/smartlink.c" 2>/dev/null | head -1 | grep "smartlink" >/dev/null 2>&5 && "$SMARTLINK" -v >/dev/null 2>&5; then
  AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
  rm -f "$SMARTLINK"
  AC_MSG_CHECKING(whether smartlink compiles)

  link_cmd='${CC} -o smartlink $CFLAGS -I. $CPPFLAGS $LDFLAGS $srcdir/tools/smartlink.c $LIBS 2>&5'
   if { (eval echo Compiling smartlink: \"$link_cmd\") 1>&5; (eval $link_cmd) 2>&5; } && "$BUILDDIR/smartlink" -v >/dev/null 2>&5; then
      AC_MSG_RESULT(yes)
  else
    AC_MSG_RESULT(no - use the sh script)
    SMARTLINK="$srcdir/tools/smartlink" 
 fi
fi
CC="$SMARTLINK $CC"
ac_cv_prog_CC="$CC"
case "$caudium_cv_sys_os" in
  SCO*)
    case "$CFLAGS" in
      *-belf*) 
        AC_SYS_COMPILER_FLAG(-belf,sco_belf_option,CFLAGS,[],[
          case "$LDFLAGS" in
            *-belf*) ;;
            *)
	      echo "Adding -belf option to ldflags."
              LDFLAGS="$LDFLAGS -belf"
            ;;
          esac
        ])
      ;;
      *)
        AC_SYS_COMPILER_FLAG(-belf,sco_belf_option,CFLAGS,[],[
          case "$LDFLAGS" in
            *-belf*) ;;
            *)
	      echo "Adding -belf option to ldflags."
              LDFLAGS="$LDFLAGS -belf"
            ;;
          esac
        ])
      ;;
    esac
  ;;
 
  UnixWare*)
    case "$CFLAGS" in
      *-Kalloca*) ;;
      *)
	if test "$GCC" != "yes"; then
 	# We are using built-in inline function
          CFLAGS="$CFLAGS -Kalloca"
          CXX="CC -DNO_CPLUSPLUS_ALLOCA"
 	fi
      ;;
    esac
  ;;
esac
  
AC_SUBST(CXX)
AC_SUBST(LD)

### Let's set the default,            ###
### which we can change if we'd like. ###
#########################################
# Sometimes prefix is set to NONE (EPITA, why ?)
if test "$prefix" != "NONE"; then
  CAUDIUM_SERVERDIR="$prefix/caudium/server/"
else
  CAUDIUM_SERVERDIR=""
fi

AC_ARG_WITH(serverdir,
AC_HELP_STRING([--with-serverdir=DIR],[Location of the top-level Caudium directory after installation]),
[
  if test ! -z "$withval"; then
    CAUDIUM_SERVERDIR="$withval/"
  else
    CAUDIUM_SERVERDIR="$prefix/caudium/server/"
  fi
])

### Pike Detection ###
######################

AC_ARG_WITH(pike, 
AC_HELP_STRING([--with-pike[=binary]],[Use the specified Pike.]),
[
    if test ! -z "$withval" -a "$withval" != "yes"; then 
		extpike="`type  $withval |sed "s:$withval is ::" 2>/dev/null`"
                if test "$extpike" != ""; then
                   withval="$extpike";
                fi
		if test -f "$withval" -a  ! -x "$withval" ; then
			echo "$withval is not an executable file"
 			exit 1
		elif test -x "$withval" -a -f "$withval"; then
			DEFPIKE="$withval"
		else
			echo "$withval doesn't exist or isn't an executable file."
 			exit 1
		fi
	fi
])
RESULT=no
AC_MSG_CHECKING([for a working Pike (>= $REQ_MIN_PIKE_MAJOR.$REQ_MIN_PIKE_MINOR.$REQ_MIN_PIKE_BUILD <= $REQ_MAX_PIKE_MAJOR.$REQ_MAX_PIKE_MINOR.$REQ_MAX_PIKE_BUILD)])
AC_MSG_RESULT( )
pathpike="`type  pike 2> /dev/null |sed 's/pike is//' 2>/dev/null`"
if test "$prefix" != "NONE"; then
  PREFIXPIKE="$prefix/bin/pike"
fi
FOUND_PIKE=0
PIKE_INCLUDE_DIRS=""
REQ_MIN_PIKE_DECNUM=`expr '(' $REQ_MIN_PIKE_MAJOR '*' 10000 ')' + '(' $REQ_MIN_PIKE_MINOR '*' 1000 ')' + $REQ_MIN_PIKE_BUILD`
REQ_MAX_PIKE_DECNUM=`expr '(' $REQ_MAX_PIKE_MAJOR '*' 10000 ')' + '(' $REQ_MAX_PIKE_MINOR '*' 1000 ')' + $REQ_MAX_PIKE_BUILD`
OLD_DIR=`pwd`
for PIKE in $DEFPIKE $PREFIXPIKE $pathpike /usr/local/bin/pike /opt/pike/bin/pike /sw/bin/pike74 /sw/local/bin/pike /opt/local/bin/pike /usr/gnu/bin/pike /usr/bin/pike /usr/pkg/bin/pike /usr/pkg/bin/pike74 /opt/local/bin/pike /opt/local/bin/pike74 /opt/bin/pike /opt/bin/pike74 /usr/bin/pike7.4 /usr/bin/pike7.5; do
  if test -x $PIKE; then
    echo -n "  ...${PIKE}"
    THIS_PIKE_VER=`$PIKE -e 'int maj,min,bld;sscanf(version(),"Pike v%d.%d release %d",maj,min,bld);write(sprintf("%d.%d.%d",maj,min,bld));exit(0);'`
    if test -z "$THIS_PIKE_VER"; then
      continue
    fi
    echo -n " ${THIS_PIKE_VER}"
    THIS_PIKE_MAJOR=`echo $THIS_PIKE_VER | cut -d '.' -f 1`
    THIS_PIKE_MINOR=`echo $THIS_PIKE_VER | cut -d '.' -f 2`
    THIS_PIKE_BUILD=`echo $THIS_PIKE_VER | cut -d '.' -f 3`
    THIS_PIKE_VERNUM=$THIS_PIKE_MAJOR$THIS_PIKE_MINOR$THIS_PIKE_BUILD
    THIS_PIKE_DECNUM=`expr '(' $THIS_PIKE_MAJOR '*' 10000 ')' + '(' $THIS_PIKE_MINOR '*' 1000 ')' + $THIS_PIKE_BUILD`

    if test $THIS_PIKE_DECNUM -lt $REQ_MIN_PIKE_DECNUM; then
       echo " => too old"
       continue
    fi
    if test $THIS_PIKE_DECNUM -ge $REQ_MAX_PIKE_DECNUM; then
      echo " => too new"
      continue
    fi

    echo " => good version"

    PIKE_DIRNAME="`dirname $PIKE`"
    for PIKE_INCDIR in $PIKE_DIRNAME/.. \
                       $PIKE_DIRNAME/../..\
                       $PIKE_DIRNAME/../../..\
                       $PIKE_DIRNAME/../../../.. ; do
      for INCDIR in $PIKE_INCDIR/pike/$THIS_PIKE_VER/include/pike \
                  $PIKE_INCDIR/include/`basename $PIKE` \
                  $PIKE_INCDIR/include/pike/${THIS_PIKE_VER} \
                  $PIKE_INCDIR/include/pike${THIS_PIKE_VER} \
                  $PIKE_INCDIR/include/pike$THIS_PIKE_VER \
                  $PIKE_INCDIR/include/pike${THIS_PIKE_MAJOR}.${THIS_PIKE_MINOR}\
                  $PIKE_INCDIR/include/pike/${THIS_PIKE_MAJOR}.${THIS_PIKE_MINOR} \
                  $PIKE_INCDIR/include/pike \
                  $PIKE_INCDIR/src ; do

	if test ! -f $INCDIR/version.h; then
          continue
        else
          cd $INCDIR
          INCLUDE_DIR=`pwd`
	fi
	if test -f version.h; then
	  C_PIKE_MAJOR=`cat version.h | grep PIKE_MAJOR_VERSION | tr -s ' ' | cut -d ' ' -f 3`
	  C_PIKE_MINOR=`cat version.h | grep PIKE_MINOR_VERSION | tr -s ' ' | cut -d ' ' -f 3`
	  C_PIKE_BUILD=`cat version.h | grep PIKE_BUILD_VERSION | tr -s ' ' | cut -d ' ' -f 3`

	  if test $C_PIKE_MAJOR -ne $THIS_PIKE_MAJOR -o $C_PIKE_MINOR -ne $THIS_PIKE_MINOR -o $C_PIKE_BUILD -ne $THIS_PIKE_BUILD; then
	    echo -n
	    break
	  fi
	  echo ", $INCLUDE_DIR"
	  FOUND_PIKE=1
	  PIKE_VERSION=$THIS_PIKE_VER
	  PIKE_INCLUDE_DIRS="$PIKE_INCLUDE_DIRS -I$INCLUDE_DIR"
	  break
	else
	  echo -n
	fi
      done
    done
  fi
  if test x"$FOUND_PIKE" = "x1"; then
    break
  fi
done

cd $OLD_DIR
if test x"$FOUND_PIKE" = "x1"; then 
  AC_MSG_RESULT([found Pike $PIKE_VERSION ($PIKE) with C headers in $PIKE_INCLUDE_DIRS])
else
  cat << EOF
*****************************************************************************
*** I couldn't find a suitable Pike for Caudium. 
***
*** PLEASE NOTE: THIS VERSION OF Caudium DOES NOT WORK WITH 
*** PIKE OLDER THAN $REQ_MIN_PIKE_MAJOR.$REQ_MIN_PIKE_MINOR.$REQ_MIN_PIKE_BUILD!
*** 
*** You can download and install one of our Pike $REQ_MIN_PIKE_MAJOR.$REQ_MIN_PIKE_MINOR or 
*** newer snapshots available from our website at:
***
*** http://caudium.net/download/source/caudiumbuild.rxml
***
*** If you have this or newer version of Pike installed in a different 
*** location or under a different name, please use the --with-pike argument
*** to the configure script to specify the location of the Pike binary you
*** want to use with Caudium
***
*****************************************************************************
EOF
  exit 1;
fi

export PIKE PIKE_INCLUDE_DIRS PIKE_VERSION
AC_SUBST(PIKE)
AC_SUBST(PIKE_VERSION)

#############################################################################

# Set some of the compiler flags.

for ac_site_file in $CONFIG_SITE; do
  if test -r "$ac_site_file"; then
    AC_MSG_WARN([You are using a site file to initialize configure, please
note that this can lead to problems if anything in
$ac_site_file is not correct. If Caudium does not compile, or
does not run, please try this to compile Caudium again:
rm ./config.cache ; CONFIG_SITE=x ./configure ; make])
  fi
done

#############################################################################

## Search for some popular places where libraries may be hidden.

#############################################################################

AC_MSG_CHECKING(for extra include directories)
AC_MSG_RESULT( )
if test $cppflags_is_set = no -a x${C_INCLUDE_PATH-} = x ; then
  for d in `echo ${with_include_path} | sed 's/:/ /g'` \
    `echo $prefix | sed "s@^NONE@$ac_default_prefix@g"`/include \
    /usr/local/include /sw/local/include /usr/gnu/include /opt/gnu/include \
    /sw/gnu/include /sw/include /usr/freeware/include /usr/pkg/include \
    /opt/include /opt/local/include \
    `echo /usr/X11*/include | sort -r`
  do
    AC_MSG_CHECKING($d)
    if test -d "$d/." ; then
      AC_MSG_RESULT(added)
      CPPFLAGS="${CPPFLAGS} -I$d"
    else
      AC_MSG_RESULT(no)
    fi
  done
else
  :
fi

AC_MSG_CHECKING(for extra library directories)
AC_MSG_RESULT( )
if test $ldflags_is_set = no ; then
  for d in `echo ${with_lib_path} | sed 's/:/ /g'` \
    `echo $exec_prefix | sed "s@^NONE@$prefix/lib@g" | sed "s@^NONE@$ac_default_prefix/lib@g"` \
    /usr/local/lib /sw/local/lib /sw/lib /usr/pkg/lib \
    /usr/gnu/lib /opt/gnu/lib /sw/gnu/lib /usr/freeware/lib \
    /opt/lib /opt/local/lib \
    `echo /usr/X11*/lib | sort -r`
  do
    AC_MSG_CHECKING($d)
    if test -d "$d/." ; then
      AC_MSG_RESULT(added)
      LDFLAGS="${LDFLAGS} -R$d -L$d"
    else
      AC_MSG_RESULT(no)
    fi
  done
else
  :
fi

WARN=""
OPTIMIZE=""

if test "$GCC" = "yes"; then
# Disabled since -pipe causes gcc to hang on some systems
# (gcc-2.7.2 on Slackware Linux 3.2 when compiling assembler files).
# Thanks to Michael Finken <finken@nentec.de> for pointing it out.
#	/grubba 1997-10-07
#   if test $cflags_is_set = no; then
#     AC_SYS_COMPILER_FLAG(-pipe, pipe, CFLAGS)
#   fi
    :
else
#
# Special hack for HP-UX stupid cc
#
  if test "$caudium_cv_sys_os" = "HP-UX"; then
    AC_TRY_COMPILE([int foo(int bar);],[],[],
    [
      OLD_CC="${CC-cc}"
      OLD_CFLAGS="$CFLAGS"
      if test "$CC" = "$SMARTLINK cc" -a -x /usr/bin/cc ; then
        CC="$SMARTLINK /usr/bin/cc"
      fi
      CFLAGS="-Ae +Olibcalls $CFLAGS"
      AC_TRY_COMPILE([int foo(int bar);],[],[],[
        CC="$OLD_CC"
	CFLAGS="$OLD_CFLAGS"
      ])
    ])
  fi
fi

if test $ac_cv_prog_gcc = yes; then
  AC_MSG_CHECKING(for libgcc file name)
  AC_CACHE_VAL(caudium_cv_libgcc_filename,
  [
    caudium_cv_libgcc_filename="`${CC-cc} -print-libgcc-file-name`"
    if test -z "$caudium_cv_libgcc_filename"; then
      caudium_cv_libgcc_filename=no
    else
       if test -f "$caudium_cv_libgcc_filename"; then
         :
       else
         caudium_cv_libgcc_filename=no
       fi
    fi
  ])
  AC_MSG_RESULT($caudium_cv_libgcc_filename)
  if test x"$caudium_cv_libgcc_filename" = xno; then
    LIBGCC=""
  else
    LIBGCC="$caudium_cv_libgcc_filename"
  fi
else
  LIBGCC=""
fi

export LIBGCC

# SO is the extension of shared libraries
# -- usually so, sl on HP-UX
AC_MSG_CHECKING(SO)
if test -z "$SO"
then
	case "$caudium_cv_sys_os" in
	hp*|HP*)   SO=sl;;
	*)	   SO=so;;
	esac
fi
AC_MSG_RESULT($SO)

# LDSHARED is the ld *command* used to create shared library
# -- "ld" on SunOS 4.x.x, "ld -G" on SunOS 5.x, "ld -shared" on IRIX 5
AC_MSG_CHECKING(LDSHARED)
if test -z "$LDSHARED" ; then
  case "$caudium_cv_sys_os" in
    AIX*)
      if test "$GCC" = yes ; then
        if test "`uname -r`" -ge 2 -a "`uname -v`" -ge 4 ; then
          LDSHARED="ld -G -bexpall"
	else if test "`uname -v`" -gt 4 ; then
	    # Extra forward compatibility...
	    # AIX 5+
	    LDSHARED="ld -G -bexpall"
	  else
	    # AIX 4.1 and earlier don't have/have unreliable
	    # handling of dlopen et al.
	    #
	    # Even AIX 4.2.1 has buggy dlopen -- NEVER attempt
	    # to dlopen a file that hasn't been linked with -G.
	    caudium_cv_sys_dynamic_loading=no
	    LDSHARED="ld"
	  fi
        fi
      else
        # Dynamic linking turned off for AIX-cc
	#
	# In addition, the dynamic loading test seems to
	# cause our RS/6000 to hang, which causes the
	# watchdog-timer to PANIC.
	caudium_cv_sys_dynamic_loading=no
        LDSHARED="ld"
      fi
    ;;
    IRIX*)
      if test "$GCC" = yes ; then
        # egcs defaults to building -n32 objects
        LDSHARED="ld -shared -n32"
      else
        LDSHARED="ld -shared"
      fi
      # -woff isn't understood by ld on Irix 5.
      if test "`uname -r`" -ge 6 ; then
        LDSHARED="$LDSHARED -woff 84,85,134"
      else :; fi
    ;;
    SunOS*) LDSHARED="ld";;
    Solaris) LDSHARED="/usr/ccs/bin/ld -G";;
    hp*|HP*) LDSHARED="ld -b";;
    OSF*) LDSHARED="ld -expect_unresolved '*' -shared -msym -O3";;
    DYNIX/ptx*) LDSHARED="ld -G";;
    next*) LDSHARED="$CC $CFLAGS -nostdlib -r";;
    Linux*) LDSHARED="$CC -shared";;
    GNU*) LDSHARED="ld -Bshareable";;
    FreeBSD*) LDSHARED="$CC -Wl,-Bshareable";;
    NetBSD*) LDSHARED="ld -Bshareable";;
    OpenBSD*) LDSHARED="ld -Bshareable";;
    BSD/OS*) LDSHARED="shlicc -r";;
    Darwin*) LDSHARED="$CC -bundle -undefined error -bundle_loader $PIKE";;
    UNIX_SV*) LDSHARED="ld -G";;
    SCO_SV*) LDSHARED="cc -G -KPIC -Wl,-Bexport";;
    UnixWare*)
      if test "$GCC" = yes ; then
        LDSHARED="ld -G"
      else
        LDSHARED="cc -G -KPIC -Wl,-Bexport"
      fi
    ;;
    Windows_NT*) LDSHARED="$CC -shared";;
    *) LDSHARED="ld";;
  esac
fi

# Strip smartlink from $CC
LDSHARED="$SMARTLINK `echo $LDSHARED|sed -e 's/.*smartlink //'`"

AC_MSG_RESULT($LDSHARED)

# CCSHARED are the C *flags* used to create objects to go into a shared
# library -- this is only needed for a few systems
AC_MSG_CHECKING(CCSHARED)
AC_CACHE_VAL(caudium_cv_sys_ccshared,[
if test -z "$CCSHARED" ; then
  if test "$GCC" = yes ; then
    case $caudium_cv_sys_os in
	BSD/OS*) CCSHARED="";;
	Darwin*) CCSHARED="-fPIC";;
	*) CCSHARED="-fpic";;
    esac
  else
    case $caudium_cv_sys_os in
	hp*|HP*) CCSHARED="+z"; ;;
	FreeBSD*) CCSHARED="-fpic";;
	Darwin*) CCSHARED="-fPIC";;
	SCO_SV*) CCSHARED="-KPIC -dy -Bdynamic";;
	UnixWare*) CCSHARED="-KPIC -dy -Bdynamic";;
	Solaris*) CCSHARED="-KPIC -Bdynamic";;
        Windows_NT*) CCSHARED="-shared" ;;
    esac
  fi
fi
  OLD_CFLAGS="$CFLAGS"
  CFLAGS="$CFLAGS $CCSHARED"
  AC_TRY_COMPILE([], [int main() { exit(0); }],
    caudium_cv_sys_ccshared="$CCSHARED", caudium_cv_sys_ccshared='')
  CFLAGS="$OLD_CFLAGS"
])

if test "$GCC" != "yes"; then
  case $caudium_cv_sys_os in
    UnixWare*)
	CCSHARED="-KPIC -dy -Bdynamic"
	caudium_cv_sys_ccshared="$CCSHARED"
    ;;
  esac
fi


CLIBRARY_LINK="-lc"
# In special cases we don't want -lc...
case $caudium_cv_sys_os in
  UnixWare*|SCO_SV*)
    CLIBRARY_LINK=""      
  ;;
esac

CCSHARED="$caudium_cv_sys_ccshared"
AC_MSG_RESULT($CCSHARED)

CPPFLAGS="$CPPFLAGS -I$srcdir/src/cmods/"
#
# CPPFLAGS is a precious variable in Autoconf, it is saved with its
# initial value. We must resort to a different way of substituting that
# in the makefile. Ugh.
#
CPPFLAGS="$CPPFLAGS -I$srcdir/src/cmods/"
CAUDIUM_CPPFLAGS="$CPPFLAGS"
AC_SUBST(CAUDIUM_CPPFLAGS)
AC_SUBST(CAUDIUM_SERVERDIR)

#
# Some variables we want to export to the other configure scripts.
#
CFLAGS="$CFLAGS $CCSHARED $WARN $OPTIMIZE"
export CC CFLAGS CPPFLAGS LDFLAGS LDSHARED SO CLIBRARY_LINK

AC_CONFIG_SUBDIRS(src tools)
AC_CONFIG_COMMANDS([hail_epita],[sh tools/fixperms])
AC_OUTPUT(Makefile server/start-caudium server/bin/install.pike)

echo "

Caudium is now configured.  This is some information about
the build environment. If the wrong pike was selected, try
re-running configure with '--with-pike=/path/to/correct/pike'.

	CC:         $CC
        LDSHARED:   $LDSHARED

        CFLAGS:     $CFLAGS

        CPPFLAGS:   $CPPFLAGS

        LDFLAGS:    $LDFLAGS

        Pike binary used:      $PIKE
        Pike version:          $PIKE_VERSION
        Pike include dir:      $PIKE_INCLUDE_DIRS

	"

# Verify the pike ... 
$PIKE $srcdir/tools/verify_pike.pike

