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
 * $Id$
 */

/*
 * Authors : David Gourdelier <vida@caudium.net>
 */
 
constant cvs_version = "$Id$";
constant thread_safe=1;

#include <module.h>
#define NSESSION id->misc->session_variables->navbar

#ifdef Caudium.parse_html
#define PARSER Caudium.parse_html
#else
#ifdef CAMAS.Parse.parse_html
#define PARSER CAMAS.Parse.parse_html
#else
#define PARSER parse_html
#endif
#endif

inherit "module";
inherit "caudiumlib";

constant module_type = MODULE_PARSER|MODULE_PROVIDER; 
constant module_name = "Navigation bar container";
constant module_doc  = "Adds the &lt;navbar&gt; &lt;/navbar&gt; container."
	       " This way you can have navigation bar more easily in your pike scripts. "
	       "This module is a provider and a container. That means it can only be used "
    		"in Pike code (Caudium modules or script). You have to call the following "
        "functions before this module is parsed: <br/><br/>"
        "<ul><li>Set the number of total elements"
        "<pre>id-&gt;conf-&gt;get_provider(&quot;navbar&quot;)-&gt;set_nb_elements(object id, int n)</pre></li>"
        "<li>Set the number of elements per page"
        "<pre>id-&gt;conf-&gt;get_provider(&quot;navbar&quot;)-&gt;set_nb_elements_per_page(object id, int x)</pre></li></ul>"
        "Then you can call these functions:<br/><br/>"
        "<ul><li>Get the minimum element number to display in this page"
        "<pre>id-&gt;conf-&gt;get_provider(&quot;navbar&quot;)-&gt;get_min_element()</pre></li>"
        "<li>Get the maximum element number to display in this page"
        "<pre>id-&gt;conf-&gt;get_provider(&quot;navbar&quot;)-&gt;get_max_element()</pre></li></ul>"
        "In your RXML page, use the following code to display a navigation bar:<pre>"
        "&lt;navbar&gt;<br/>"
        "&nbsp;&lt;!-- the first page of the navigation bar --&gt;<br/>"
        "&nbsp;&lt;previous&gt; &lt;href action=\"prevpage\"&gt; &amp;lt &lt;/href&gt; &lt;/previous&gt;<br/>"
        "&nbsp;&lt;!-- the previous pages --&gt;<br/>"
        "&nbsp;&lt;loop_previous&gt; &lt;href action=\"gopage\"&gt; #number# &lt;/href&gt; &lt;/loop_previous&gt;<br/>"
        "&nbsp;&lt;!-- the current page --&gt;<br/>"
        "&nbsp;&lt;current/&gt;<br/>"
        "&nbsp;&lt;!-- the next pages --&gt;<br/>"
        "&nbsp;&lt;loop_next&gt;&lt;href action=\"gopage\"&gt; #number# &lt;/href&gt; &lt;/loop_next&gt;<br/>"
        "&nbsp;&lt;!-- the last page --&gt;<br/>"
        "&nbsp;&lt;next&gt;  &lt;href action=\"prevpage\"&gt; &amp;gt &lt;/href&gt;  &lt;/next&gt;<br/>"
        "&lt;/navbar&gt;<br/>"
        "</pre>";

constant module_unique = 1;

void create()
{
  defvar("session_module", "123session", "The session module to use",
        TYPE_STRING_LIST, "The session module to use", ({ "123session", "gsession" }));
}

string query_provides()
{
  return "navbar";
}

/* PROVIDER PART */

private void create_session(object id)
{
  if(!NSESSION)
    NSESSION = allocate(3);
}

private void wrong_usage(object id)
{
  if(!NSESSION)
    throw("You must call set_nb_elements() and set_nb_elements_per_page() before using this function\n");
}

private void fetch_args(object id)
{
  // fetch arguments from links only one time for each HTTP request
  if(!id->misc->navbar_args_fetched)
  {
    if(id->variables->navbarnextblock)
      set_current_page(id, get_current_page(id) + 1);
    if(id->variables->navbarprevblock)
      set_current_page(id, get_current_page(id) - 1);
    if(id->variables->navbargotoblock)
      set_current_page(id, (int)id->variables->navbarelement);
    id->misc->navbar_args_fetched = 1;
  }
}

int get_current_page(object id)
{
  wrong_usage(id);
  if(!NSESSION[2])
  {
    NSESSION[2] =
     ceil((float) NSESSION[0] / NSESSION[1]);
    NSESSION[2] = (int) NSESSION[2];
  }
  return NSESSION[2];
}

private int get_nb_elements(object id)
{
  return NSESSION[0];
}

private int get_nb_elements_per_page(object id)
{
  return NSESSION[1];
}

private int get_lastpage(object id)
{
  return (int)ceil((float)get_nb_elements(id)/(float)get_nb_elements_per_page(id));
}

void start(int num, object conf)
{
  if(QUERY(session_module) == "123session")
    module_dependencies(conf, ({ "123session" }));
  if(QUERY(session_module) == "gsession")
    module_dependencies(conf, ({ "gsession" }));
}

void set_nb_elements(object id, int nb)
{
  create_session(id);
  NSESSION[0] = nb;
}

void set_nb_elements_per_page(object id, int nb)
{
  create_session(id);
  NSESSION[1] = nb;
}

void set_current_page(object id, int page)
{
  wrong_usage(id);
  NSESSION[2] = page;
}

int get_min_element(object id)
{
  wrong_usage(id); 
  fetch_args(id);
  int min_elem = (get_current_page(id) -1) * get_nb_elements_per_page(id);
  int offset = min_elem%get_nb_elements_per_page(id);

  // always begin the list at the beginning of a page
  if(offset != 0)
    min_elem -= offset;
  if(min_elem > get_nb_elements(id))
    min_elem = get_nb_elements(id) - 1;
  return min_elem;
}

int get_max_element(object id)
{
  wrong_usage(id);
  fetch_args(id);
  int max_elem = get_min_element(id) + get_nb_elements_per_page(id) - 1;
  if(max_elem >= get_nb_elements(id))
    max_elem = get_nb_elements(id) - 1;
  return max_elem;
}

/* PARSER PART */
mapping query_container_callers ()
{
  return ([
      "navbar": container_navbar
    ]);
}

//! container: navbar
//!  Zone for the navigation bar
//! childcontainer : current
//! childcontainer : previous
//! childcontainer : loop_previous
//! childcontainer : loop_next
//! childcontainer : next
string container_navbar(string tag_name, mapping args, string contents,object id)
{
  string out = "";                                              // string to output

  if(get_nb_elements(id) > get_nb_elements_per_page(id))
  {
    out += PARSER(contents,
                      ([
                       "current"       : tag_navbar_current,
                       ]),
                      ([
                     "previous"      : container_noloop_navbar,
                     "loop_previous" : container_loop_navbar,
                     "loop_next"     : container_loop_navbar,
                     "next"          : container_noloop_navbar
                       ]),
                      id);
  }
  return out;
}

//! tag: current
//!  Zone for current page
//! parentcontainer : navbar
string tag_navbar_current(string tag_name, mapping args, object id)
{
  return (string)get_current_page(id);
}

// Code for <navbar></> nested containers
string container_noloop_navbar(string tag_name, mapping args, string contents, object id)
{
  string out = "";                                              // The string to output
  string originalcontents = contents;                           // Backup the original contents for parsing it several times

  switch(tag_name)
  {
    case "previous":
      //! container: previous
      //!  Zone for the previous screen
      //! parentcontainer : navbar
      //! note: screen: mailindex
      if (get_current_page(id) > 1)
      {
        out += PARSER(contents,
              ([
              ]),
              ([
                "href"          : container_navbar_href,
              ]),
              id, 0);

      }
      break;

    case "next":
      //! container: next
      //!  Zone for the next screen
      //! parentcontainer : navbar
      //! note: screen: mailindex
      if (get_current_page(id) < get_lastpage(id))
      {
        out += PARSER(contents,
              ([
              ]),
              ([
                "href"          : container_navbar_href,
              ]),
              id, 0);
      }
      break;
  }

  return out;
}

//! container: href
//!  Links for going to the correct page
//! parentcontainer : navbar
string container_navbar_href(string tag_name, mapping args, string contents, object id, int countpageloop)
{
  mapping vars = ([ ]);
 
  switch(args->action)
  {
    case "nextpage":
      vars += ([ "navbarnextblock":"1" ]);
    break;

    case "previouspage":
    case "prevpage":
      vars += ([ "navbarprevblock":"1" ]);
    break;

    case "gopage":
      vars += ([
              	"navbargotoblock":"1",
              	"navbarelement":(string)(countpageloop)
      ]);
  }

  args->href = id->not_query + "?" + Protocols.HTTP.http_encode_query(vars); 
  args->target = "_self";

  return make_container("a", args, contents);
}

// Code for <navbar></> nested loop containers
string container_loop_navbar(string tag_name, mapping args, string contents, object id)
{
  string out = "";                                              // The string to output
  string originalcontents = contents;                           // Backup the original contents for parsing it several times
  mapping href_args;
  string href_contents;
  string rands = "thisisarandomstring3294832094832904832RJKZEJRKZKjfn43249832U432";
  string parsed_contents = PARSER(originalcontents,
      ([ ]),
      ([
        "href"          : lambda(string name, mapping _href_args, string _href_contents)
                                { 
                                  href_args = _href_args;
                                  href_contents = _href_contents;
                                  return rands;
                                }
       ]));

  int count = 0;

  switch(tag_name)
  {
    case "loop_previous":
      //! container: loop_previous
      //!  Zone for each previous page available
      for(count=1; count<get_current_page(id); count++)
      {
        int countpageloop=count;
        array outlet = ({
          ([
            "number" : count,
          ])
        });
       
        contents = replace(parsed_contents, rands,
            container_navbar_href("loop_previous", href_args, href_contents, id, countpageloop));

          

        out += do_output_tag(args, outlet, contents, id);
      }
      break;

    case "loop_next":
      //! container: loop_next
      //!  Zone for each next page available
      for(count=get_current_page(id)+1; count<=get_lastpage(id); count++)
      {
        int countpageloop=count;
        array outlet = ({
                          ([
                       "number" : count,
                           ])
                        });
        contents = replace(parsed_contents, rands,
            container_navbar_href("loop_previous", href_args, href_contents, id, countpageloop));
        out += do_output_tag(args, outlet, contents, id);
      }
      break;
  }

  return out;
}


/*
 * If you visit a file that doesn't contain these lines at its end, please
 * cut and paste everything from here to that file.
 */

/*
 * Local Variables:
 * c-basic-offset: 2
 * End:
 *
 * vim: softtabstop=2 tabstop=2 expandtab autoindent formatoptions=croqlt smartindent cindent shiftwidth=2
 */
