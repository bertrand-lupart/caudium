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
 * $Id$
 */

// From what module we take some functions
#define RXMLTAGS id->conf->get_provider("rxml:tags")


#include <module.h>

inherit "module";
inherit "caudiumlib";

constant cvs_version   = "$Id$";
constant thread_safe    = 1;
constant module_type   = MODULE_PARSER | MODULE_LOGGER | MODULE_EXPERIMENTAL;
constant module_name   = "Accessed counter";
constant module_doc    = "This module provides access counters, through the "
"<tt>&lt;accessed&gt;</tt> tag and the <tt>&amp;page.accessed;</tt> entity.";
constant module_unique=1;
constant language = roxen->language;

object counter;

string status() {
  return counter->size()+" entries in the accessed database.<br />";
}

void create(object c) {

  //------ Global defvars

  defvar("extcount", ({  }), "Extensions to access count",
          TYPE_STRING_LIST,
         "Always count accesses to files ending with these extensions. "
	 "By default only accessed to files that actually contain a "
	 "<tt>&lt;accessed&gt;</tt> tag or the <tt>&amp;page.accessed;</tt> "
	 "entity will be counted. "
	 "<p>Note: This module must be reloaded before a change of this "
	 "setting takes effect.</p>");

  defvar("restrict", 1, "Restrict reset", TYPE_FLAG, "Restrict the attribute reset "
	 "so that the resetted file is in the same directory or below.");

  defvar("backend", "File database", "Database backend", TYPE_MULTIPLE_STRING,
	 "Select a accessed database backend",
         ({ "File database", "SQL database", "Memory database" }) );

  //------ File database settings

  defvar("Accesslog",GLOBVAR(logdirprefix)+short_name(c?c->name:".")+"/Accessed",
	 "Access database file", TYPE_FILE|VAR_MORE,
	 "This file will be used to keep the database of file accesses.",
	 0, lambda(){ return query("backend")!="File database"; } );

  defvar("close_db", 1, "Close inactive database",
	 TYPE_FLAG|VAR_MORE,
	 "If set, the accessed database will be closed if it is not used for "
	 "8 seconds. This saves resourses on servers with many sites.",
	 0, lambda(){ return query("backend")!="File database"; } );

  //------ SQL database settings

  defvar("sqldb", "mysql://localhost", "SQL Database", TYPE_STRING, 
	 "What database to use for the database backend.",
	 0, lambda(){ return query("backend")!="SQL database"; } );

  defvar("table", "accessed", "SQL Table", TYPE_STRING,
	 "Which table should be used for the database backend.",
	 0, lambda(){ return query("backend")!="SQL database"; } );

  defvar("serverinpath",1,"Add server Id in SQL table", TYPE_FLAG|VAR_MORE,
         "Add the server Id in the SQL table. <b>Note</b>: you will lose "
	 "Roxen 2.x compatibility if this enabled.",
	 0, lambda(){ return query("backend")!="SQL database"; } );
  defvar("serverid",c->query("MyWorldLocation"),"Id to add in SQL table",
         TYPE_STRING|VAR_MORE,"This will be added in the SQL database as "
	 "unique Id. <b>Note</b>: if you change this Id, <b>ALL</b> "
	 "counter data will be reset to 0.",
	 0, lambda() { return !query("serverinpath") ||
	                      query("backend")!="SQL database"; } );
}

//TAGDOCUMENTATION
#ifdef manual
/*
constant tagdoc=([
  "&page.accessed;":#"<desc ent='ent'><p>
 Generates an access counter that shows how many times the page has
 been accessed. Needs the accessed module.
</p></desc>",

"accessed":#"<desc tag='tag'><p><short>
 Generates an access counter that shows how many times the page has
 been accessed.</short> A file, AccessedDB, in the logs directory is
 used to store the number of accesses to each page. By default the
 access count is only kept for files that actually contain an
 accessed-tag, but can also be configured to count all files of a
 certain type. <ex><accessed/></ex>
</p></desc>

<attr name='add' value='number'><p>
 Increments the number of accesses with this number instead of one,
 each time the page is accessed.</p></attr>

<attr name='addreal'><p>
 Prints the real number of accesses as an HTML comment. Useful if you
 use the cheat attribute and still want to keep track of the
 real number of accesses.</p></attr>

<attr name='case' value='upper|lower|capitalize'><p>
 Sets the result to upper case, lower case or with the first letter
 capitalized.</p>
</attr>

<attr name='cheat' value='number'><p>
 Adds this number of accesses to the actual number of accesses before
 printing the result. If your page has been accessed 72 times and you
 add <tag>accessed cheat='100'</tag> the result will be 172.</p></attr>

<attr name='database'><p>
 Works like the since attribute, but counts from the day the first
 entry in the entire accessed database was made.</p>
</attr>

<attr name='factor' value='percent'><p>
 Multiplies the actual number of accesses by the factor. E.g.
 <tag>accessed factor='50'</tag> displays half the actual value.</p>
</attr>

<attr name='file' value='filename'><p>
 Shows the number of times the page filename has been
 accessed instead of how many times the current page has been accessed.
 If the filename does not begin with \"/\", it is assumed to be a URL
 relative to the directory containing the page with the
 accessed tag. Note, that you have to type in the full name
 of the file. If there is a file named tmp/index.html, you cannot
 shorten the name to tmp/, even if you've set Roxen up to use
 index.html as a default page. The filename refers to the
 virtual filesystem.</p>

 <p>One limitation is that you cannot reference a file that does not
 have its own <tag>accessed</tag> tag. You can use <tag>accessed
 silent='1'</tag> on a page if you want it to be possible to count accesses
 to it, but don't want an access counter to show on the page itself.</p>
</attr>

<attr name='lang' value='langcodes'><p>
 Will print the result as words in the chosen language if used together
 with type=string.</p>

 <ex><accessed type=\"string\"/></ex>
 <ex><accessed type=\"string\" lang=\"sv\"/></ex>
</attr>

<attr name='per' value='second|minute|hour|day|week|month|year'><p>
 Shows the number of accesses per unit of time.</p>

 <ex><accessed per=\"week\"/></ex>
</attr>

<attr name='prec' value='number'><p>
 Rounds the number of accesses to this number of significant digits. If
 prec=2 show 12000 instead of 12148.</p>
</attr>

<attr name='reset'><p>
 Resets the counter. This should probably only be done under very
 special conditions, maybe within an <tag>if</tag> statement.
 This can be used together with the file argument, but it is
 limited to files in the current- and sub-directories.</p>
</attr>

<attr name='silent'><p>
 Print nothing. The access count will be updated but not printed. This
 option is useful because the access count is normally only kept for
 pages with actual <tag>access</tag> on them. <tag>accessed
 file='filename'</tag> can then be used to get the access count for the
 page with the silent counter.</p>
</attr>

<attr name='since'><p>
 Inserts the date that the access count started. The language will
 depend on the <att>lang</att> attribute, default is English. All
 normal date related attributes can be used. Also see: <xref
 href='date.tag' />.</p>

 <ex><accessed since=\"\"/></ex>
</attr>

<attr name='type' value='number|string|roman|iso|discordian|stardate|mcdonalds|linus|ordered'><p>
 Specifies how the count are to be presented. Some of these are only
 useful together with the since attribute.</p>

 <ex><accessed type=\"roman\"/></ex>
 <ex><accessed since=\"\" type=\"iso\"/></ex>
 <ex><accessed since=\"\" type=\"discordian\"/></ex>
 <ex><accessed since=\"\" type=\"stardate\"/></ex>
 <ex><accessed type=\"mcdonalds\"/></ex>
 <ex><accessed type=\"linus\"/></ex>
 <ex><accessed type=\"ordered\"/></ex>

</attr>

<attr name='minlength' value='number'><p>
 Defines a minimum length the the resulting string should have. If it is
 shorter it is padded from the left with the padding value. Only values
 between 2 and 10 are valid.</p>
</attr>

<attr name='padding' value='character' default='0'><p>
 The padding that the minlength function should use.</p>
</attr>
"]);
*/
#endif

void start() {
//  query_tag_set()->prepare_context=set_entities;
  switch(query("backend")) {
  case "SQL database":
    counter=SQLCounter();
    break;
  case "Memory database":
    counter=MemCounter();
    break;
  case "File database":
  default:
    counter=FileCounter();
    break;
  }
}

// Kiwi: Can someone do an compatible entity for this module ???

//class Entity_page_accessed {
//  int rxml_var_eval(RXML.Context c) {
//    c->id->misc->cacheable=0;
//    if(!c->id->misc->accessed) {
//      counter->add(c->id->not_query, 1);
//      c->id->misc->accessed=1;
//    }
//    return counter->query();
//  }
//}

//void set_entities(RXML.Context c) {
//  c->set_var("accessed", Entity_page_accessed(), "page");
//}


// --- File access databases -------------------------

class FileCounter {
  // The old file based access database.

  int cnum=0;
  mapping fton=([]);

  int size() {
    return sizeof(fton);
  }

  Stdio.File database, names_file;

  void create() {
    if(olf != module::query("Accesslog"))
    {
      olf = module::query("Accesslog");
      mkdirhier(module::query("Accesslog"));
      if(names_file=open(olf+".names", "wrca"))
      {
	cnum=0;
	array tmp=parse_accessed_database(names_file->read(0x7ffffff));
	fton=tmp[0];
	cnum=tmp[1];
	names_file = 0;
      }
    }
  }

  static string olf; // Used to avoid reparsing of the accessed index file...
  static mixed names_file_callout_id;
  inline void open_names_file()
  {
    if(objectp(names_file)) return;
    remove_call_out(names_file_callout_id);
    names_file=open(module::query("Accesslog")+".names", "wrca");
    names_file_callout_id = call_out(destruct, 1, names_file);
  }

#ifdef THREADS
  object db_lock = Thread.Mutex();
#endif /* THREADS */

  static void close_db_file(object db)
  {
#ifdef THREADS
    mixed key = db_lock->lock();
#endif /* THREADS */
    if (db) {
      destruct(db);
    }
  }

  static mixed db_file_callout_id;
  inline mixed open_db_file()
  {
    mixed key;
#ifdef THREADS
    catch { key = db_lock->lock(); };
#endif /* THREADS */
    if(objectp(database)) return key;
    if(!database)
    {
      if(db_file_callout_id) remove_call_out(db_file_callout_id);
      database=open(module::query("Accesslog")+".db", "wrc");
      if (!database) {
	throw(({ sprintf("Failed to open \"%s.db\". "
			 "Insufficient permissions or out of fd's?\n",
			 module::query("Accesslog")), backtrace() }));
      }
      if (module::query("close_db")) {
	db_file_callout_id = call_out(close_db_file, 9, database);
      }
    }
    return key;
  }

  static int mdc;
  int main_database_created() {
    if(!mdc) {
      mixed key = open_db_file();
      database->seek(0);
      sscanf(database->read(4), "%4c", mdc);
    }
    return mdc;
  }

  void database_set_created(string file, void|int t) {
    int p=fton[file];
    if(!p) return 0;
    mixed key = open_db_file();
    database->seek((p*8)+4);
    database->write(sprintf("%4c", t||time(1)));
  }

  int creation_date(void|string file) {
    if(!file) return main_database_created();
    int p=fton[file];
    if(!p) return 0;
    mixed key = open_db_file();
    database->seek((p*8)+4);
    int w;
    sscanf(database->read(4), "%4c", w);
    if(!w) {
      database_set_created(file, main_database_created() );
      return 0;
    }
    return w;
  }

  inline int create_entry(string file) {
    if(!cnum) {
      database->seek(0);
      database->write(sprintf("%4c", time(1)));
    }
    fton[file]=++cnum;
    int p=cnum;

    open_names_file();
    names_file->write(file+":"+cnum+"\n");

    database->seek(p*8);
    database->write(sprintf("%4c", 0));
    database_set_created(file);
    return p;
  }

  void add(string file, void|int count) {
    int p, n;

    mixed key = open_db_file();

    if(!(p=fton[file]))
      p=create_entry(file);

    if(database->seek(p*8) > -1) {
      sscanf(database->read(4), "%4c", n);
      n+=count||1;
      database->seek(p*8);
      database->write(sprintf("%4c", n));
    }
  }

  int query(string file) {
    int p,n;
    if(!(p=fton[file])) return 0;

    mixed key = open_db_file();
    if(database->seek(p*8) > -1)
      sscanf(database->read(4), "%4c", n);
    return n;
  }

  void reset(string file) {
    int p, n;

    mixed key = open_db_file();

    if(!(p=fton[file]))
      p=create_entry(file);
    else
      database_set_created(file);

    if(database->seek(p*8) > -1) {
      database->seek(p*8);
      database->write(sprintf("%4c", 0));
    }
  }
}

class SQLCounter {
  // SQL backend counter.

  Sql.sql db;
  string table,servername;
  int srvname = 0;

  void create() {
    db=Sql.sql(module::query("sqldb"));
    table = module::query("table");
    if (module::query("serverinpath")) {
      srvname = 1;
      servername = module::query("serverid");
    }
    else {
      srvname = 0;
      servername= "";
    }
    catch {
      db->query("CREATE TABLE "+table+" (path VARCHAR(255) PRIMARY KEY,"
		" hits INT UNSIGNED DEFAULT 0, made INT UNSIGNED)");
      // Kiwi: need to be fixed (used if file doesn't exist)
      db->query("INSERT INTO "+table+" (path,made) VALUES ('///',"+time(1)+")" );
    };
  }

  int creation_date(void|string file) {
    if(!file) file="///";
    array x=db->query("SELECT made FROM "+table+" WHERE path='"+servername+fix_file(file)+"'");
    return x && sizeof(x) && (int)(x[0]->made);
  }

  private void create_entry(string file) {
    if(cache_lookup("access_entry", file)) return;
    catch(db->query("INSERT INTO "+table+" (path,made) VALUES ('"+servername+file+"',"+time(1)+")" ));
    cache_set("access_entry", file, 1);
  }

  private string fix_file(string file) {
    if(sizeof(file)>255)
      file="//"+MIME.encode_base64(Crypto.md5()->update(file)->digest(),1);
    return db->quote(file);
  }

  void add(string file, int count) {
    file=fix_file(file);
    create_entry(file);
    db->query("UPDATE "+table+" SET hits=hits+"+(count||1)+" WHERE path='"+servername+file+"'" );
  }

  int query(string file) {
    file=fix_file(file);
    array x=db->query("SELECT hits FROM "+table+" WHERE path='"+servername+file+"'");
    return x && sizeof(x) && (int)(x[0]->hits);
  }

  void reset(string file) {
    file=fix_file(file);
    create_entry(file);
    db->query("UPDATE "+table+" SET hits=0 WHERE path='"+servername+file+"'");
  }

  int size() {
    array x=db->query("SELECT count(*) from "+table);
    return (int)(x[0]["count(*)"])-1;
  }
}

class MemCounter {
  //Proof-of-concept nonpersistent counter. 

  mapping(string:int) db_count=([]);
  mapping(string:int) db_time=([]);
  int created;

  void create() {
    created=time(1);
  }

  int creation_date(void|string file) {
    if(!file) return created;
    return db_time[file];
  }

  void add(string file, void|int count) {
    if(!db_time[file]) db_time[file]=time(1);
    db_count[file]+=count||1;
  }

  int query(string file) {
    return db_count[file];
  }

  void reset(string file) {
    if(!db_time[file]) db_time[file]=time(1);
    db_count[file]=0;
  }

  int size() {
    return sizeof(db_count);
  }
}


// --- Log callback ------------------------------------

int log(object id, mapping file) {
  if(id->misc->accessed || query("extcount")==({})) {
    return 0;
  }

  // Although we are not 100% sure we should make a count,
  // nothing bad happens if we shouldn't and still do.
  int a, b=sizeof(id->realfile);
  foreach(query("extcount"), string tmp)
    if(a=sizeof(tmp) && b>a &&
       id->realfile[b-a..]=="."+tmp) {
      counter->add(id->not_query, 1);
      id->misc->accessed = "1";
    }

  return 0;
}

// --- Tag definition ----------------------------------

string tag_accessed(string tag, mapping m, object id)
{
  NOCACHE();

  if(m->reset) {
    if( !query("restrict") || !search( (dirname(fix_relative(m->file, id))+"/")-"//",
		 (dirname(fix_relative(id->not_query, id))+"/")-"//" ) )
    {
      counter->reset(m->file);
      return "Number of counts for "+m->file+" is now 0.<br />";
    }
    else
      // On a web hotell you don't want the guests to be alowed to reset
      // eachothers counters.
      return "You do not have access to reset this counter.";
  }

  int counts = id->misc->accessed;

  if(m->file) {
    m->file = fix_relative(m->file, id);
    if(m->add) counter->add(m->file, (int)m->add);
    counts = counter->query(m->file);
  }
  else {
    if(!_match(id->remoteaddr, id->conf->query("NoLog")) &&
       !id->misc->accessed) {
      counter->add(id->not_query, (int)m->add);
    }
    m->file=id->not_query;
    counts = counter->query(m->file);
    id->misc->accessed = counts;
  }
 
  if(m->silent)
    return "";

  if(m->since) {
    object rxmltags_module = RXMLTAGS;
    if (objectp(rxmltags_module))
    {
     if(m->database)
      return rxmltags_module->api_tagtime(counter->creation_date(), m, id, language); // From rxmltags
     return rxmltags_module->api_tagtime(counter->creation_date(m->file), m, id, language);
    }
    return "<!-- No RXML Tag module ? -->";
  }

  string real="<!-- ("+counts+") -->";

  counts += (int)m->cheat;

  if(m->factor)
    counts = (counts * (int)m->factor) / 100;

  if(m->per)
  {
    int timep=time(1) - counter->creation_date(m->file) + 1;

    switch(m->per)
    {
     case "second":
      counts /= timep;
      break;

     case "minute":
      counts = (int)((float)counts/((float)timep/60.0));
      break;

     case "hour":
      counts = (int)((float)counts/(((float)timep/60.0)/60.0));
      break;

     case "day":
      counts = (int)((float)counts/((((float)timep/60.0)/60.0)/24.0));
      break;

     case "week":
      counts = (int)((float)counts/(((((float)timep/60.0)/60.0)/24.0)/7.0));
      break;

     case "month":
      counts = (int)((float)counts/(((((float)timep/60.0)/60.0)/24.0)/30.42));
      break;

     case "year":
      counts=(int)((float)counts/(((((float)timep/60.0)/60.0)/24.0)/365.249));
      break;

    default:
      return "Access count per what?";
    }
  }

  int prec, q;
  if(prec=(int)m->prec)
  {
    int n=10->pow(prec);
    while(counts>n) { counts=(counts+5)/10; q++; }
    counts*=10->pow(q);
  }

  string res;

  switch(m->type) {
  case "mcdonalds":
    q=0;
    while(counts>10) { counts/=10; q++; }
    res="More than "+language("eng", "number")(counts*10->pow(q))
        + " served.";
    break;

  case "linus":
    res=counts+" since "+ctime(counter->creation_date());
    break;

  case "ordered":
    m->type="string";
    res=number2string(counts, m, language(m->lang, "ordered"));
    break;

  default:
    res=number2string(counts, m, language(m->lang, "number"));
  }

  if(m->minlength) {
    m->minlength=(int)(m->minlength);
    if(m->minlength>10) m->minlength=10;
    if(m->minlength<2) m->minlength=2;
    if(!m->padding || !sizeof(m->padding)) m->padding="0";
    if(sizeof(res)<m->minlength)
      res=(m->padding[0..0])*(m->minlength-sizeof(res))+res;
  }

  return res+(m->addreal?real:"");
}

mapping query_tag_callers()
{
  return([ "accessed2":tag_accessed ]);
}
