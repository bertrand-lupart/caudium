/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000 The Caudium Group
 * Copyright � 1994-2000 Roxen Internet Software
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
//! module: Java Servlet tag
//!  This module adds a new tag, &lt;servlet&gt;&lt;/pike&gt;. It makes
//!  it possible to use Java Servlets directly in RXML.
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_PARSER
//! cvs_version: $Id$
//

constant cvs_version = "$Id $";
constant thread_safe=1;


// Does not work yet
#if 0

inherit "caudiumlib";
inherit "module";
#include <module.h>;

constant module_type = MODULE_PARSER;
constant module_name = "Java Servlet tag";
constant module_doc  = "This module adds a new tag, &lt;servlet&gt;&lt;/pike&gt;. It makes"
	    " it possible to use Java Servlets directly in RXML."
	    "NOTE: This module should not be enabled if you allow anonymous"
	    " PUT!<br>\n"
	    "NOTE: Enabling this module is the same thing as letting your"
	    " users run programs with the same right as the server!"
	    "<p>Example:<p><pre>"
	    " &lt;servlet code=MyLittleServlet initparam_foo=bar&gt;\n "
	    "   <param name=\"foo\" value=\"bar\">"
	    " &lt;/servlet&gt;\n</pre>";
constant module_unique = 1;

void create()
{
  defvar("debugmode", "Log", "Error messages", TYPE_STRING_LIST | VAR_MORE,
	 "How to report errors (e.g. backtraces generated by the Pike code):\n"
	 "\n"
	 "<p><ul>\n"
	 "<li><i>Off</i> - Silent.\n"
	 "<li><i>Log</i> - System debug log.\n"
	 "<li><i>HTML comment</i> - Include in the generated page as an HTML comment.\n"
	 "<li><i>HTML text</i> - Include in the generated page as normal text.\n"
	 "</ul>\n",
	 ({"Off", "Log", "HTML comment", "HTML text"}));

  defvar("codebase","", "Code base", TYPE_STRING,
	 "This can either be a directory or an URL.");	  
}

string reporterr (string header, string dump)
{
  if (QUERY (debugmode) == "Off") return "";

  report_error (header + dump + "\n");

  switch (QUERY (debugmode)) {
    case "HTML comment":
      return "\n<!-- " + header + dump + "\n-->\n";
    case "HTML text":
      return "\n<br><font color=red><b>" + html_encode_string (header) +
	"</b></font><pre>\n" + html_encode_string (dump) + "</pre><br>\n";
    default:
      return "";
  }
}

mapping(string:array|string) servlet_cache = ([]);

string|object get_servlet(string classfile, string codebase,
			  mapping initparams, object conf)
{
  array|string temp = servlet_cache[codebase+classfile];

  if(temp && equal(temp[0],initparams))
    return temp[1];

  if(temp)
  {
    if(temp[1])
      destruct(temp[1]);
    temp=servlet_cache[codebase+classfile]=0;
  }
   
  object servlet;
  mixed exc = catch(servlet = Servlet.servlet(classfile,
					      codebase));
  if(exc)
    temp=exc[0];
  else
    if(servlet)
      servlet->init(Servlet.conf_context(conf), initparams);
}

void start(int x, object conf)
{
  if(x == 2)
  {
    foreach(values(servlet_cache), array|string temp)
      if(arrayp(temp))
	catch(destruct(temp[1]));
    servlet_cache=([]);
  }
}

string tag_servlet(string tag, mapping m, string s, object id,
		   object file, mapping defs)
{
  mapping params=([]);
  parse_html(s,(["param":lambda(string tag, mapping args, mapping params)
			 {
			   if(args->name && args->value)
			     params[args->name]=args->value;
			 } ]),
	     ([]),params);
  array|string servlet=get_servlet(m->code, m->codebase||query("codebase"),
				   m-(["code":0,"codebase":0]),id->conf);
  if(stringp(servlet))
    return reporterr("Servlet loading failed",servlet);

  
}

mapping query_container_callers()
{
  return ([ "servlet":tag_servlet ]);
}
#endif

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: Error messages
//! How to report errors (e.g. backtraces generated by the Pike code):
//!
//!<p><ul>
//!<li><i>Off</i> - Silent.
//!<li><i>Log</i> - System debug log.
//!<li><i>HTML comment</i> - Include in the generated page as an HTML comment.
//!<li><i>HTML text</i> - Include in the generated page as normal text.
//!</ul>
//!
//!  type: TYPE_STRING_LIST|VAR_MORE
//!
//! defvar: Code base
//! This can either be a directory or an URL.
//!  type: TYPE_STRING
//!
