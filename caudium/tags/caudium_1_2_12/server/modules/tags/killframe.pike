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
//! module: Killframe tag
//!  Adds some java script that will prevent others from putting
//!  your page in a frame.
//!  Will also remove occuranses of "indexfiles" from the end of the URL.
//! inherits: module
//! type: MODULE_PARSER
//! cvs_version: $Id$
//
//! tag: killframe
//!  Prevents your page from being placed in a frame, by adding some
//!  JavaScript code.
//!
//!  As an added bonus index.html will be removed from the end of the URL,
//!  as shown in the Location field in your browser.
//

/* 
 * 
 * made by Peter Bortas <peter@idonex.se> January -97
 *
 * Thanks for suggestions and bugreports:
 * Barry Treahy <treahy@allianceelec.com>
 * Chris Burgess <chris@ibex.co.nz>
 */

constant cvs_version = "$Id$";
constant thread_safe=1;

#include <module.h>
inherit "module";

constant module_type = MODULE_PARSER;
constant module_name = "Killframe tag";
constant module_doc  = "Makes pages frameproof."
     "<br>This module defines a tag,"
     "<pre>"
     "&lt;killframe&gt;: Adds some java script that will prevent others\n"
     "             from putting your page in a frame.\n\n"
     "             Will also strip any occurrences of 'indexfiles'\n"
     "             from the end of the URL."
     "</pre>";
constant module_unique = 1;

void create()
{
  defvar( "killindex", 1, "Kill trailing 'indexfiles'?", TYPE_FLAG|VAR_MORE,
	  "When set, the killframe module will remove occurrences of "
	  "'indexfiles' (as set in the active directory module) from "
	  "the end of the URL, leaving only a slash." );
}


string tag_killframe( string tag, mapping m, object id )
{
  NOCACHE();

  if(m->help) return module_doc;
  
  if( !id->supports->javascript ) return "";
  
  string javascript;
  
  while( id->misc->orig )
    id = id->misc->orig;
  
  // Some versions of IE will choke on :80. (Reload and repeat..)
  string tmp;
  string prestate;
  string my_url = id->conf->query("MyWorldLocation");

  //Get the prestates in correct order. id->prestates is sorted.
  if( sscanf(id->raw_url, "/(%s)", tmp) )
    prestate = "("+ tmp +")/";

  if( sscanf(my_url, "%s:80/", tmp ) )
    my_url = tmp +"/"+ (prestate?prestate:"") + id->not_query[1..];
  else
    my_url += (prestate?prestate:"") + id->not_query[1..];
  
  // Links to index.html are ugly. All pages deserve a uniqe URL, and for
  // index-pages that URL in /.
  if( query("killindex") )
  {
    //Get indexfiles from the directory-module if there is one.
    array indexfiles = ({});
    if( id->conf->dir_module )
      indexfiles = id->conf->dir_module->query("indexfiles");

    int l=strlen(my_url)-1;
    
    foreach( indexfiles, string index )
      if( my_url[l-strlen(index)..] == "/" +index )
	my_url = my_url[..l-strlen(index)];
  }

  // Put back the variables if there were any.
  if(id->query)
    my_url += "?"+ id->query;

  //top.location = self.location breaks some versions of IE.
  //Mozilla 3 on Solaris cows with top.frames.length
  if( id->useragent && id->useragent[..8] == "Mozilla/3" )
    javascript = ( "   if(top.location != \""+ my_url  +"\")\n"
		   "     top.location = \""+ my_url  +"\";\n" );
  else
    javascript = ( "   if(top.frames.length>1)\n"
		   "     top.location = \""+ my_url +"\";\n" );

  return("<script language=javascript type=\"text/javascript\"><!--\n"
	 + javascript
	 + "//--></script>\n");
}

mapping query_tag_callers()
{
  return ([ "killframe" : tag_killframe ]);
}

/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: killindex
//! When set, the killframe module will remove occurrences of 'indexfiles' (as set in the active directory module) from the end of the URL, leaving only a slash.
//!  type: TYPE_FLAG|VAR_MORE
//!  name: Kill trailing 'indexfiles'?
//
