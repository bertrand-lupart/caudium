/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2002 The Caudium Group
 * Copyright � 1994-2001 Roxen Internet Software
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

//
//! module: Content types
//!  This module handles all normal extension to
//!  content type mapping. Given the file 'foo.html', it will
//!  normally set the content type to 'text/html'
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_TYPES
//! cvs_version: $Id$
//

/*
 * This module handles all normal extension to content type
 * mapping. Given the file 'foo.html', it will per default
 * set the contenttype to 'text/html'
 */

constant cvs_version = "$Id$";
constant thread_safe=1;

#include <module.h>
inherit "module";

constant module_type = MODULE_TYPES;
constant module_name = "Content types";
constant module_doc  = "This module handles all normal extension to "+
	     "content type mapping. Given the file 'foo.html', it will "+
	     "normally set the content type to 'text/html'.";
constant module_unique = 1;

mapping (string:string) extensions=([]), encodings=([]);
mapping  (string:int) accessed=([]);

void create()
{
  defvar("exts", "\n"
	 "# This will include the defaults from a file.\n"
	 "# Feel free to add to this, but do it after the #include line if\n"
	 "# you want to override any defaults\n"
	 "\n"
	 "#include <etc/extensions>\n\n", "Extensions", 
	 TYPE_TEXT_FIELD, 
	 "This is file extension "
	 "to content type mapping. The format is as follows:\n"
	 "<pre>extension type encoding<br />gif image/gif<br />"
	 "gz STRIP application/gnuzip</pre>"
	 "For a list of types, see <a href=\"ftp://ftp.isi.edu/in-"
	 "notes/iana/assignments/media-types/media-types\">ftp://ftp"
	 ".isi.edu/in-notes/iana/assignments/media-types/media-types</a>");
  defvar("default", "application/octet-stream", "Default content type",
	 TYPE_STRING, 
	 "This is the default content type which is used if a file lacks "
	 "extension or if the extension is unknown.\n");
}

string status()
{
  string a,b;
  b="<h2>Accesses per extension</h2>\n\n";
  foreach(indices(accessed), a)
    b += a+": "+accessed[ a ]+"<br>\n";
  return b;
}

string comment()
{
  return sizeof(extensions) + " extensions, " + sizeof(accessed)+" used.";
}

void parse_ext_string(string exts)
{
  string line;
  string *f;

  foreach((exts-"\r")/"\n", line)
  {
    if(!strlen(line))  continue;
    if(line[0]=='#')
    {
      string file;
      if(sscanf(line, "#include <%s>", file))
      {
	string s;
	if(s=Stdio.read_bytes(file)) parse_ext_string(s);
      }
    } else {
      f = (replace(line, "\t", " ")/" "-({""}));
      if(sizeof(f) >= 2)
      {
	if(sizeof(f) > 2) encodings[lower_case(f[0])] = lower_case(f[2]);
	extensions[lower_case(f[0])] = lower_case(f[1]);
      }
    }
  }
}

void start()
{
  parse_ext_string(QUERY(exts));
}

array type_from_extension(string ext)
{
  ext = lower_case(ext);
  if(ext == "default") {
    accessed[ ext ] ++;
    return ({ QUERY(default), 0 });
  } else if(extensions[ ext ]) {
    accessed[ ext ]++;
    return ({ extensions[ ext ], encodings[ ext ] });
  }
}

int may_disable() 
{ 
  return 0; 
}


/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: exts
//! This is file extension to content type mapping. The format is as follows:
//!<pre>extension type encoding<br />gif image/gif<br />gz STRIP application/gnuzip</pre>For a list of types, see <a href="ftp://ftp.isi.edu/in-notes/iana/assignments/media-types/media-types">ftp://ftp.isi.edu/in-notes/iana/assignments/media-types/media-types</a>
//!  type: TYPE_TEXT_FIELD
//!  name: Extensions
//
//! defvar: default
//! This is the default content type which is used if a file lacks extension or if the extension is unknown.
//!
//!  type: TYPE_STRING
//!  name: Default content type
//
