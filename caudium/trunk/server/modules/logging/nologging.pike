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

/*
 * This module can be used to turn off logging for some files.
 */


constant cvs_version = "$Id$";
constant thread_safe=1;

#include <module.h>
inherit "module";

array register_module()
{
  return ({ MODULE_LOGGER,
	      "Logging disabler",
	      "This module can be used to turn off logging for some files. "
	      "It is based on "/*"<a href=$docurl/regexp.html>"*/"Regular"
	      " expressions"/*"</a>"*/,
	      });
}

void create()
{
  defvar("nlog", "", "No logging for",
	 TYPE_TEXT_FIELD,
	 "All files whose (virtual)filename match the pattern above "
	 "will be excluded from logging. This is a regular expression");

  defvar("log", ".*", "Logging for",
	 TYPE_TEXT_FIELD,
	 "All files whose (virtual)filename match the pattern above "
	 "will be logged, unless they match any of the 'No logging for'"
	 "patterns. This is a regular expression");
}

string make_regexp(array from)
{
  return "("+from*")|("+")";
}


string checkvar(string name, mixed value)
{
  if(catch(Regexp(make_regexp(QUERY(value)/"\n"-({""})))))
    return "Compile error in regular expression.\n";
}


function no_log_match, log_match;

void start()
{
  no_log_match = Regexp(make_regexp(QUERY(nlog)/"\n"-({""})))->match;
  log_match = Regexp(make_regexp(QUERY(log)/"\n"-({""})))->match;
}


int nolog(string what)
{
  if(no_log_match(what)) return 1;
  if(log_match(what)) return 0;
}


int log(object id, mapping file)
{
  if(nolog(id->not_query+"?"+id->query))
    return 1;
}
