/*
 * Linux Weekly News
 */

import Headlines;

#include <headlines/base.h>
#include <headlines/RDF.h>

constant name = "lwn";
constant site = "Linux Weekly News";
constant url  = "http://lwn.net/";
constant path  = "headlines/rss";

constant names = ({ "title", "time" });
constant titles = ({" Application ", " Date " });

constant sub = "Computing/News";
array headlines;

string entry2txt(mapping hl)
{
  return sprintf("Program: %s\n"
		 "URL:     %s\n"
		 "Date:    %s\n\n",
		 hl->title||"None", HTTPFetcher()->encode(hl->url||""),
		 hl->time);
}

private static void parse_reply(string data)
{
  rdf_parse_reply(data);

  foreach(headlines, mapping hl) {
    array tmp = hl->url / "/";
    hl->time = ctime((int)tmp[-1])[4..23];
  }
}
