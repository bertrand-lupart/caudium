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
//! module: Explicit clock
//!  One of the first modules written for Spinner, here for nostalgical
//!  reasons. It could be used as an example of how to write a simple
//!  location module.
//! inherits: module
//! inherits: caudiumlib
//! type: MODULE_LOCATION
//! cvs_version: $Id$
//

/*
 * This is a Clock Module.
 * One of the first modules written for Spinner, here for nostalgical
 * reasons. It could be used as an example of how to write a simple
 * location module.
 */

string cvs_version = "$Id$";

#include <module.h>

inherit "module";
inherit "caudiumlib";

void create()
{
  defvar("modification", 0, "Time modification", TYPE_INT, 
	 "Time difference in seconds from system clock.");

  defvar("mountpoint", "/clock/", "Mount point", TYPE_LOCATION, 
	 "Clock location in filesystem.");
}

mixed *register_module()
{
  return ({ 
    MODULE_LOCATION,
    "Explicit clock", 
    "This is the Clock Module.",
    });
}

string query_location() { return query("mountpoint"); }

int my_time() {  return time(1)+query("modification"); }

mapping find_file( string f )
{
  if((int)f)
    return http_string_answer("<title>And the time is...</title>"+
			      "<h1>Local time: "+ctime((int)f)+
			      "</h1><h1>GMT: "+http_date((int)f)+"</h1>");

  return http_string_answer("<html><head><title>" + ctime(my_time())
			    +"</title></head><body><h1>"
			    +ctime(time(1))+"</h1></body></html>\n")
    + ([ "extra_heads":
	([
	  "Expires": http_date(time(1)+5),
	  "Refresh":5-time(1)%5,
	  "Last-Modified":http_date(time(1)-1)
	  ])
	]);
}

string query_name()
{
  return query("mountpoint")+" ("+ctime(my_time())[11..15]+")";
}


/* START AUTOGENERATED DEFVAR DOCS */

//! defvar: Time modification
//! Time difference in seconds from system clock.
//!  type: TYPE_INT
//!
//! defvar: Mount point
//! Clock location in filesystem.
//!  type: TYPE_LOCATION
//!
