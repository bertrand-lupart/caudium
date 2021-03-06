# $Id$
# $Revision$
#
# Created by Mike A. Harris <mharris@caudium.org> for
# the Caudium webserver project.  Portions of text were borrowed from
# the debian packaging files written by Marek Habersack <grendel@caudium.org>

%define name	caudium
%define version	cvs20001005
%define release	2
%define packager Mike A. Harris <mharris@caudium.org>

# This line creates a macro _initdir which is where initscripts will
# get placed.  This is done to maintain backwards compatibility now
# that FHS compliance changes have made it into Red Hat 7.0
%define _initdir %([ -d /etc/init.d -a ! -L /etc/init.d ] && echo /etc/init.d || echo /etc/rc.d/init.d)

# Detect the pike version that is installed
%define PIKEVERSION %(rpm -q pike --qf '%{VERSION}\\n')

Summary: An extensible high performance web server written in Pike
Name: %{name}
Version: %{version}
Release: %{release}
Copyright: GPL
Group: System Environment/Daemons
Source: %{name}-%{version}.tgz

BuildRoot: %_tmppath/%{name}-build
Packager: %packager
Vendor: The Caudium Group
URL: http://www.caudium.org

BuildPrereq: pike
Requires: pike
Conflicts: apache

%description
Caudium is a modern, fast and extensible WWW server derived from Roxen.
Caudium is by default compatible with Roxen 1.3 although some incompatible
options, mostly introduced to improve the performance, security etc. of the
server, can be turned on.
Caudium features built-in log parsing engine (UltraLog), XSLT parser, native
PHP4 support (you need Pike7 that has been compiled to support php4 for this
to work), multiple execution threads and many more features - see
http://caudium.net/ and http://caudium.org/ for more information.

%package modules
Summary: Caudium modules written in C
License: GPL
Group: System Environment/Daemons
#Prereq: /sbin/chkconfig, /usr/sbin/useradd, /usr/sbin/userdel
Requires: %name = %version

%description modules
Certain parts of Caudium are coded in C for speed. This package contains
the compiled shared modules that are required by Caudium to run.

%package pixsl
Summary: Caudium PiXSL Pike XSLT module
License: GPL
Group: System Environment/Daemons
Requires: %name = %version

%description pixsl
Certain parts of Caudium are coded in C for speed. This package contains 
the compiled shared extension module that provides Caudium with XSLT support.

%package ultralog
Summary: Caudium Ultralog log parser module
License: GPL
Group: System Environment/Daemons
Requires: %name = %version

%description ultralog
Certain parts of Caudium are coded in C for speed. This package contains 
the compiled shared extension module that provides Caudium with a built-in 
log file parser that is capable of generating extensive statistics on the 
fly for virtual servers configured in your Caudium WebServer.

%prep

%setup
 
###############  PATCH SECTION  ########################################
#%patch0 -p1


###############  BUILD SECTION  ########################################
%build
# Clean out the build dir to prevent common errors
[ $RPM_BUILD_ROOT != "/" ] && rm -rf $RPM_BUILD_ROOT

./autogen.sh
./configure --prefix=/usr --with-pike=$(which pike)
make

###############  INSTALL SECTION  ######################################
%install
make install_alt DESTDIR=$RPM_BUILD_ROOT

# Create documentation directory
mkdir -p $RPM_BUILD_ROOT/%_docdir/%name-%version

# Caudium's "make install_alt" target is FHS compliant, so on systems that
# are not fully FHS compliant we need to move the documentation to where 
# users will expect to find it.
mv $RPM_BUILD_ROOT/usr/share/doc/caudium/* \
		$RPM_BUILD_ROOT/%_docdir/%name-%version
rmdir $RPM_BUILD_ROOT/usr/share/doc/caudium
rmdir $RPM_BUILD_ROOT/usr/share/doc

# Install config files and initscript
mkdir -p $RPM_BUILD_ROOT/etc/caudium/servers
cp debian/localhost $RPM_BUILD_ROOT/etc/caudium/servers/localhost
mkdir -p $RPM_BUILD_ROOT/%_initdir
cp packages/redhat/caudium.init $RPM_BUILD_ROOT/%_initdir/caudium

# Install logrotate file
mkdir -p $RPM_BUILD_ROOT/etc/logrotate.d/
cp packages/redhat/caudium.logrotate $RPM_BUILD_ROOT/etc/logrotate.d/caudium

# Create various dirs required for proper operation
mkdir -p $RPM_BUILD_ROOT/var/{cache,log,run}/caudium
mkdir -p $RPM_BUILD_ROOT/var/log/caudium/ultralog

# Snag the ultralog documentation
mkdir -p $RPM_BUILD_ROOT/%_docdir/%name-%version/ultralog
cp src/cmods/UltraLog/README $RPM_BUILD_ROOT/%_docdir/%name-%version/ultralog
cp src/cmods/UltraLog/docs/CONFIG.spec $RPM_BUILD_ROOT/%_docdir/%name-%version/ultralog
cp src/cmods/UltraLog/docs/CUSTOM_LOG.spec $RPM_BUILD_ROOT/%_docdir/%name-%version/ultralog

# Remove unwanted files from the packaging.
find $RPM_BUILD_ROOT -name '.cvsignore' -type f -exec rm -- '{}' \;
find $RPM_BUILD_ROOT -name 'CVS' -type f -exec rm -- '{}' \;
rm -rf $RPM_BUILD_ROOT/usr/share/caudium/unfinishedmodules


###############  CLEAN SECTION  ########################################
%clean
[ $RPM_BUILD_ROOT != "/" ] && rm -rf $RPM_BUILD_ROOT


###############  FILES SECTION  ########################################
%files
%defattr(-,root,root)
%_bindir/htpasswd
%_libdir/caudium/bin/garbagecollector.pike
%_libdir/caudium/bin/install.pike
%_libdir/caudium/bin/pdbi.pike
%_libdir/caudium/bin/sqladduser.pike
%_libdir/caudium/bin/caudium
%_libdir/caudium/base_server
%_libdir/caudium/caudium-images
%_libdir/caudium/config_actions
%_libdir/caudium/etc
%_libdir/caudium/fonts
%_libdir/caudium/nfonts
%_libdir/caudium/protocols
%_libdir/caudium/languages
%_libdir/caudium/server_templates
%_libdir/caudium/configvar
%_libdir/caudium/demo_certificate.pem
%_libdir/caudium/install
%_libdir/caudium/mkdir
%_libdir/caudium/start
%_libdir/caudium/testca.pem
%_datadir/caudium/modules/directories
%_datadir/caudium/modules/filesystems
%_datadir/caudium/modules/graphics
%_datadir/caudium/modules/logging
%_datadir/caudium/modules/proxies
%_datadir/caudium/modules/tags
%_datadir/caudium/modules/examples
%_datadir/caudium/modules/filters
%_datadir/caudium/modules/ldap
%_datadir/caudium/modules/misc
%_datadir/caudium/modules/scripting
%dir %_datadir/caudium/modules
%dir /usr/local/share/caudium/modules
%dir /var/cache/caudium
%dir /var/log/caudium
%dir /var/run/caudium

%config %attr(0755, root, root) %_initdir/caudium
%config(noreplace) %attr(0755, root, root) /etc/caudium/*
%config(noreplace) %attr(0755, root, root) /etc/logrotate.d/caudium

%doc %_docdir/%{name}-%{version}/*


###############  FILES SECTION (caudium-modules)  ######################
%files modules
%defattr(-,root,root)
%_libdir/caudium/lib/%{PIKEVERSION}/Caudium.so

###############  FILES SECTION (caudium-pixsl)  ######################
%files pixsl
%defattr(-,root,root)
%_bindir/pixsl
%_libdir/caudium/bin/pixsl.pike
%_libdir/caudium/lib/%{PIKEVERSION}/PiXSL.so

###############  FILES SECTION (caudium-ultralog)  ######################
%files ultralog
%defattr(-,root,root)
%_bindir/ultrasum
%_libdir/caudium/lib/%{PIKEVERSION}/UltraLog.so
%_libdir/caudium/etc/modules/UltraSupport.pmod
%_libdir/caudium/bin/ultrasum.pike
%_datadir/caudium/modules/ultralog/*
%dir %_datadir/caudium/modules/ultralog
%dir /var/log/caudium/ultralog

# No easy way to pull the docs out of the main package without jumping
# through hoops, so the ultralog docs are not here yet.
#%doc %_docdir/%{name}-%{version}/ultralog

%preun
if [ $1 -eq 0 ]; then   # We're running "rpm -e"
  if [ -x %_initdir/caudium ];then
    %_initdir/caudium stop
    chkconfig --del caudium;
  fi
fi

%changelog
* Thu Oct 5 2000 Mike A. Harris <mharris@caudium.org>
  Binary stripping now done in Makefile, removed from specfile.  Added
  %defattr to all subpackages.

* Thu Oct 5 2000 Mike A. Harris <mharris@caudium.org>
  Added logrotate config file to installation, and made tweaks to make
  everything work with the new moved dir (packages/redhat).

* Tue Oct 3 2000 Mike A. Harris <mharris@caudium.org>
  Added '%preun' section.  Strip compiled binaries in install section.
  Changed my email address to caudium.org everywhere.

* Tue Oct 3 2000 Mike A. Harris <mharris@caudium.org>
  Modified the build to be pike version independant (hopefully).
  Got pike version detection with RPM working correctly.
  Big cleanup of spec file debugging cruft that is no longer needed.

* Tue Oct 3 2000 Mike A. Harris <mharris@caudium.org>
  Corrected documentation packaging, stripped out unfinished modules
  from being packaged in final install rpms.

* Mon Oct 2 2000 Mike A. Harris <mharris@caudium.org>
  Added pike version detection to spec file, then took it back away
  until the RPM guys get back to me with a fix.  ;o)

* Sat Sep 30 2000 Mike A. Harris <mharris@caudium.org>
  Now that the redhat stuff is built into the CVS sources, I changed
  the spec to use the files in the main tarball instead of being
  external.  I also updated the lame package descriptions I had, by
  stealing Marek's debian package descriptions.  ;o)

* Thu Sep 28 2000 Mike A. Harris <mharris@caudium.org>
  Prepared first public release of RPM spec file, and submitted
  it to caudium-devel mailing list for inclusion.

* Wed Sep 27 2000 Mike A. Harris <mharris@caudium.org>
  Updated my local tree again, and made more tweaks to the Red Hat
  build.  Made a few changes similar to Marek's debian build.

* Mon Sep 25 2000 Mike A. Harris <mharris@caudium.org>
  Updated working caudium cvs tree, made few modifications to
  spec to allow building in Red Hat 6.x and 7.0 environments.

* Sat Sep 23 2000 Mike A. Harris <mharris@caudium.org>
  Changed documentation install from hardcoded /usr/share/doc to
  softcoded %_docdir so that FHS compliant systems get docs where
  they should be, however FHS non-compliant systems have docs where
  users expect them.  The spec file shouldn't dictate FHS compliance,
  but should follow compliance if the given system is compliant.

* Fri Aug 18 2000 Mike A. Harris <mharris@caudium.org>
  Fixed install section to put the initscript in proper place.
  Fixed files section to more properly include the files it should.

* Thu Aug 17 2000 Mike A. Harris <mharris@caudium.org>
  Refined spec file, and proper file lists.  Corrected many
  numerous errors from the original broken first build.

* Thu Aug 17 2000 Mike A. Harris <mharris@caudium.org>
  Initial .spec file creation
