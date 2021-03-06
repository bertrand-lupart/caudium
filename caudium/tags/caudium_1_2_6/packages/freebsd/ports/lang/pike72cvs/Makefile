# New ports collection makefile for:	pike
# Date created:		05 Sep 2001
# Whom:			kiwi@oav.net
#
# $FreeBSD$
#

PORTNAME=	pike72cvs
PORTVERSION=	7.2.356
PORTREVISION=	5
CATEGORIES=	lang
MASTER_SITES=	ftp://ftp.oav.net/pkg_freebsd/distfiles/ \
		http://ftp.oav.net/pkg_freebsd/distfiles/ \
		ftp://ftp.oav.net/pike/7.2/unofficial/ \
		http://ftp.oav.net/pike/7.2/unofficial/ \
		http://grendel.firewall.com/caudium-pkg/ \
		ftp://ftp.caudium.net/caudium/snapshots/pike/7.2/unofficial/ \
		http://ftp.caudium.net/caudium/snapshots/pike/7.2/unofficial/
DISTNAME=	pike-${PORTVERSION}

MAINTAINER=	kiwi@oav.net

BUILD_DEPENDS=	bison:${PORTSDIR}/devel/bison/
.if (${MACHINE} == "i386")
BUILD_DEPENDS+=	nasm:${PORTSDIR}/devel/nasm/
.endif

LIB_DEPENDS=	gmp.5:${PORTSDIR}/math/libgmp4 \
		jpeg.9:${PORTSDIR}/graphics/jpeg \
		tiff.4:${PORTSDIR}/graphics/tiff \
		gdbm.2:${PORTSDIR}/databases/gdbm \
		mird.1:${PORTSDIR}/databases/mird

WRKSRC=		${WRKDIR}/${DISTNAME}/src/

WANT_MESA=	yes
WANT_GTK=	yes
WANT_GNOME=	yes
#USE_AUTOCONF_VER=213
#USE_AUTOMAKE=	yes

GNU_CONFIGURE=  yes

CONFIGURE_ARGS+= --without-debug \
		 --with-double-precision \
		 --with-long-double-precision \
		 --disable-rpath \
		 --without-rtldebug \
		 --without-cdebug \
		 --without-copt \
		 --without-shared-nodes \
		 --without-security \
		 --with-oob \
		 --with-poll \
		 --with-max-fd=60000 \
		 --without-relocatable-dumped-modules \
		 --without-libpanda \
		 --without-perl \
		 --with-gmp \
		 --with-zlib \
		 --with-threads \
		 --with-readline \
		 --with-jpeg=${PREFIX} \
		 --with-tiff \
		 --with-gdbm \
		 --without-ssleay
#		 --with-gdbm=${PREFIX} \

.include <bsd.port.pre.mk>

.if exists(${LOCALBASE}/lib/libttf.so.4)
WITH_TTF=	yes
.endif

.if exists(${LOCALBASE}/lib/libfreetype.so.9)
WITH_FREETYPE=	yes
.endif

.if exists(${LOCALBASE}/lib/mysql/libmysqlclient.so.10)
WITH_MYSQL=	yes
.endif

.if exists(${LOCALBASE}/lib/libpq.so.2)
WITH_POSTGRES=	yes
.endif

.if exists(${LOCALBASE}/lib/libodbc.so.1)
WITH_UNIXODBC=	yes
.endif

.if exists(${LOCALBASE}/lib/libiodbc.so.2)
WITH_IODBC=	yes
.endif

.if exists(${LOCALBASE}/lib/libsane.so.1)
WITH_SANE=	yes
.endif

.if exists(${LOCALBASE}/lib/libgtkgl.so.5)
WITH_MESA=	yes
.endif

.if exists(${LOCALBASE}/lib/libpdf.so.4)
WITH_PDF=	yes
.endif

.if defined(WITH_MOST)
WITH_TTF=	yes
WITH_FREETYPE=	yes
.endif

.if defined(WITH_OPTIMIZED_CFLAGS)
CFLAGS+=	-O3 -ffast-math -fomit-frame-pointer
.endif

.if defined(WITH_TTF)
LIB_DEPENDS+=	ttf.4:${PORTSDIR}/print/freetype
CONFIGURE_ARGS+= --with-ttflib
.else
CONFIGURE_ARGS+= --without-ttflib
.endif

.if defined(WITH_FREETYPE)
LIB_DEPENDS+=	freetype.9:${PORTSDIR}/print/freetype2
CONFIGURE_ARGS+= --with-freetype
.else
CONFIGURE_ARGS+= --without-freetype
.endif

.if defined(WITH_MYSQL)
LIB_DEPENDS+=	mysqlclient.10:${PORTSDIR}/databases/mysql323-client
CONFIGURE_ARGS+= --with-mysql=${PREFIX}
.else
CONFIGURE_ARGS+= --without-mysql
.endif

.if defined(WITH_POSTGRES)
LIB_DEPENDS+=	pq.2:${PORTSDIR}/databases/postgresql7
CONFIGURE_ARGS+= --with-pgsql=${PREFIX}
.else
CONFIGURE_ARGS+= --without-pgsql
.endif

.if defined(WITH_MSQL)
BUILD_DEPENDS+=	msql:${PORTSDIR}/databases/msql
CONFIGURE_ARGS+= --with-msql=${PREFIX}
.else
CONFIGURE_ARGS+= --without-msql
.endif

.if defined(WITH_UNIXODBC)
LIB_DEPENDS+=	odbc.1:${PORTSDIR}/databases/unixODBC
CONFIGURE_ARGS+= --with-odbc
.endif

.if defined(WITH_IODBC)
LIB_DEPENDS+=	iodbc.3:${PORTSDIR}/databases/libiodbc
CONFIGURE_ARGS+= --with-odbc
.endif

.if !defined(WITH_UNIXODBC) && !defined(WITH_IODBC)
CONFIGURE_ARGS+= --without-odbc
.endif

.if defined(WITH_SANE)
LIB_DEPENDS+=	sane.1:${PORTSDIR}/graphics/sane-backends
CONFIGURE_ARGS+= --with-sane
.else
CONFIGURE_ARGS+= --without-sane
.endif

.if defined(WITH_PDF)
LIB_DEPENDS+=	pdf.4:${PORTSDIR}/print/pdflib
CONFIGURE_ARGS+= --with-libpdf
.else
CONFIGURE_ARGS+= --without-libpdf
.endif

.if defined(HAVE_MESA) || defined(WITH_MESA)
USE_MESA=	yes
LIB_DEPENDS+=	gtkgl.5:${PORTSDIR}/x11-toolkits/gtkglarea
CONFIGURE_ARGS+= --with-GL --with-GLUT
.else
CONFIGURE_ARGS+= --without-GL --without-GLUT
.endif

.if defined(HAVE_GNOME)
USE_GNOME=	yes
USE_GTK=	yes
USE_GLI=	yes
CONFIGURE_ARGS+= --with-GTK --with-gnome --with-glade
.else
CONFIGURE_ARGS+= --without-GTK --without-gnome --without-glade
.endif

.if (${MACHINE} == "i386")
CONFIGURE_ARGS+= --with-poll
.else
# Alpha seems to have problems with poll() with pike... :/
CONFIGURE_ARGS+= --without-poll
.endif

USE_GMAKE=	yes

pre-everything::
.if !defined(WITH_OPTIMIZED_CFLAGS)
	@${ECHO_MSG} "You can enable additional compilation optimizations"
	@${ECHO_MSG} "by defining WITH_OPTIMIZED_CFLAGS"
.endif
.if !defined(WITH_TTF) && !defined(WITH_MOST)
	@${ECHO_MSG} "You can enable _Image_TTF support by defining WITH_TTF."
.endif
.if !defined(WITH_FREETYPE) && !defined(WITH_MOST)
	@${ECHO_MSG} "You can enable _Image_FreeType support by defining WITH_FREETYPE."
.endif
.if !defined(WITH_MYSQL)
	@${ECHO_MSG} "You can enable MySQL support by defining WITH_MYSQL."
.endif
.if !defined(WITH_POSTGRES)
	@${ECHO_MSG} "You can enable PostGres support by defining WITH_POSTGRES."
.endif
.if !defined(WITH_UNIXODBC) && !defined(WITH_IODBC)
	@${ECHO_MSG} "You can enable unixODBC support by defining WITH_UNIXODBC."
	@${ECHO_MSG} "You can enable iodbc support by defining WITH_IODBC."
	@${ECHO_MSG} "Note that you can support only ONE of these two ODBC libs."
.endif
.if !defined(WITH_SANE)
	@${ECHO_MSG} "You can enable Sane support by defining WITH_SANE."
.endif
.if !defined(WITH_SANE) || !defined(HAVE_MESA)
	@${ECHO_MSG} "You can enable MesaGL support by defining WITH_MESA."
.endif
.if !defined(WITH_PDF)
	@${ECHO_MSG} "You can enable PDF support by defining WITH_PDF."
.endif
.if !defined(WITH_MOST)
	@${ECHO_MSG} "You can enable most of the features here except Sane,"
	@${ECHO_MSG} "MesaGLi, GNOME and SQL support by defining WITH_MOST."
.endif


pre-configure:
#	@cd ${WRKSRC}; \
#	./run_autoconfig
	@${ECHO} ${CONFIGURE_ARGS}

post-install:
	${INSTALL_PROGRAM} ${WRKSRC}pike ${PREFIX}/bin
	${INSTALL_SCRIPT} ${WRKSRC}hilfe ${PREFIX}/bin

.include <bsd.port.post.mk>
