/* Site-specific code. Here parsing and more of this site is.
 * $Id$
 *
 * Written by David Hedbor <david@hedbor.org>.
 *
 */

import spider;
import "..";

#include "../base.pike"

constant site = "BeRoute";
constant url  = "http://www.beroute.tzo.com/";
constant path = "ultramode.txt";
constant full_names =
({ "title", "url", "time", "author", "department", "section",
   "comments", "type", "image"});
constant names = ({ "title", "author", "section", "time", "comments" });
constant titles = ({ "Title", "Author", "Topic", "Date", "#C" });

constant sub = "Computing/BeOS/French";
array headlines;

private static void parse_reply(string data)
{
  foreach((data / "\n%%\n")[1..], string s)
  {
    array lines = s / "\n";
    if(sizeof(lines) == sizeof(full_names)) {
      lines[1] = replace(lines[1], "slashdot.org", "www.beroute.tzo.com");
      lines[-1] = sprintf("%simages/topics/%s", url, lines[-1]);
      headlines += ({ mkmapping(full_names, lines) });
    }
  }
}


string entry2txt(mapping hl)
{
  return sprintf("Title:    %s\n"
		 "URL:      %s\n"
		 "Date:     %s\n"
		 "Author:   %s\n"
		 "\n",
		 hl->title||"None", 
		 HTTPFetcher()->encode(hl->url||""),
		 hl->time, hl->author||"",
		 );
}


