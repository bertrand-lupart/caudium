/*
 * 123 Session Module
 * (c) Kai Voigt, k@123.org
 *
 * _very_ BETA version for Roxen 1.3, Roxen 2.0 and Caudium
 *
 * To use an SQL database for storing the session and user variables, specify
 * the database in the config interface and create a table "variables"
 * with the following command within your database (this example is
 * from MySQL, you might need to modify it for other systems)
 *
 * create table variables (id varchar(255) not null,
 *                         region varchar(255),
 *                         lastusage int,
 *                         svalues mediumtext,
 *                         key(id));
 *
 * In your documents, you can use id->misc->session_variables as a
 * mapping for session variables that will be accessible during the entire
 * session.
 *
 * User variables are accessible as id->misc->user_variables as well.
 *
 * TODO: This module needs comments, documentation, testing and some
 * mutex stuff.  The file storage is not implemented yet, just the
 * stubs.  DBM storage can be added later.  Error handling is badly
 * needed to catch sql errors and the like.
 *
 */

string cvs_version = "$Id$";

inherit "module";
inherit "roxenlib";
#include <module.h>
import Sql;

mapping (string:mapping (string:mixed)) _variables;
object myconf;

int storage_is_not_sql() {
 return (query("storage") != "sql");
}

void start(int num, object conf) {
  if (conf) { myconf = conf; }
}

void create() {
  defvar("exclude_urls", "", "Exclude URLs", TYPE_TEXT_FIELD,
         "URLs that shouldn't be branded with a Session Identifier."
         " Examples:<pre>"
         "/images/\n"
         "/download/files/\n"
         "</pre>");
  defvar("secret", "ChAnGeThIs", "Secret Word", TYPE_STRING,
         "a secret word that is needed to create secure IDs." );
  defvar("garbage", 100, "Garbage Collection Frequency", TYPE_INT,
         "after how many connects expiration of old session should happen" );
  defvar("expire", 600, "Expiration Time", TYPE_INT,
         "after how many seconds an unactive session is removed" );
  defvar("storage", "memory",
         "Storage Method", TYPE_MULTIPLE_STRING,
         "The method to be used for storing the session and user variables."
         " Available are Memory and Database storage.  Each"
         " of them have their pros and cons regarding speed and"
         " persistance.",
         ({"memory", "sql"}));
  defvar("identify", "cookie",
         "Identifying Method", TYPE_MULTIPLE_STRING,
         "The method to be used for branding a webbrowser with a"
         " unique Session Identifier. Available are Cookies and Prestates.",
         ({"cookie", "prestate"}));
  defvar("sql_url", "",
         "Database URL", TYPE_STRING,
         "Which database to use for the session and user variables, use"
         " a common database URL",
         0, storage_is_not_sql);
}

mixed register_module() {
  return ({ MODULE_FIRST | MODULE_FILTER | MODULE_PARSER,
    "123 Sessions",
    "This Module will provide each session with a distinct set "
    "of session variables."
    "<p>"
    "Warning: This module has not been tested a lot."
    "<br>"
    "Read the module code for instructions.",
    ({}), 1, });
}

int session_size_memory() {
  if (_variables->session) {
    return (sizeof(_variables->session));
  } else {
    return(0);
  }
}

int session_size_sql() {
  object(sql) con;
  function sql_connect = myconf->sql_connect;
  con = sql_connect(query("sql_url"));
  string query = "select count(*) as size from variables where region='session'";
  array(mapping(string:mixed)) result = con->query(query);
  return ((int)result[0]->size);
}

// TODO
int session_size_file() {
 return (0);
}

string status() {
  string result = "";
  int size;

  switch(query("storage")) {
    case "memory":
      size = session_size_memory();
      break;
    case "sql":
      size = session_size_sql();
      break;
    case "file":
      size = session_size_file();
      break;
  }

  result += sprintf("%d session(s) active.<br>\n", size);
  return (result);
}

void session_gc_memory() {
  if (!_variables->session) {
    return;
  }
  foreach (indices(_variables->session), string session_id) {
    if (time() > (_variables->session[session_id]->lastusage+query("expire"))) {
      m_delete(_variables->session, session_id);
    }
  } 
}

void session_gc_sql() {
  object(sql) con;
  function sql_connect = myconf->sql_connect;
  con = sql_connect(query("sql_url"));
  int exptime = time()-query("expire");
  con->query("delete from variables where lastusage < '"+exptime+"' and region='session'");
}

// TODO
void session_gc_file() {
}

void session_gc() {
  switch(query("storage")) {
    case "memory":
      session_gc_memory();
      break;
    case "sql":
      session_gc_sql();
      break;
    case "file":
      session_gc_file();
      break;
  }
}

mapping (string:mixed) variables_retrieve_memory(string region, string key) {
  if (!_variables[region]) {
    _variables[region] = ([]);
  }
  if (!_variables[region][key]) {
    _variables[region][key] = ([]);
  }
  if (!_variables[region][key]->values) {
    _variables[region][key]->values = ([]);
  }
  return (_variables[region][key]->values);
}

mapping (string:mixed) variables_retrieve_sql(string region, string key) {
  object(sql) con;
  function sql_connect = myconf->sql_connect;
  con = sql_connect(query("sql_url"));
   string query = "select svalues from variables where region='"+region+"' and id='"+key+"'";
  array(mapping(string:mixed)) result = con->query(query);
  if (sizeof(result) != 0) {
    return (string2values(result[0]->svalues));
  } else {
    return ([]);
  }
}

// TODO
mapping (string:mixed) variables_retrieve_file(string region, string key) {
  return ([]);
}

mapping (string:mixed) variables_retrieve(string region, string key) {
  switch(query("storage")) {
    case "memory":
      return (variables_retrieve_memory(region, key));
      break;
    case "sql":
      return (variables_retrieve_sql(region, key));
      break;
    case "file":
      return (variables_retrieve_file(region, key));
      break;
  }
}

void variables_store_memory(string region, string key, mapping values) {
  _variables[region][key]->lastusage = time();
  _variables[region][key]->values = values;
}

string values2string(mixed values) {
  return (MIME.encode_base64(encode_value(values)));
}

mixed string2values(string encoded_string) {
  return (decode_value(MIME.decode_base64(encoded_string)));
}

void variables_store_sql(string region, string key, mapping values) {
  object(sql) con;
  function sql_connect = myconf->sql_connect;
  con = sql_connect(query("sql_url"));
  con->query("delete from variables where region='"+region+"' and id='"+key+"'");
  con->query("insert into variables(id, region, lastusage, svalues) values ('"+key+"', '"+region+"', '"+time()+"', '"+values2string(values)+"')");
}

// TODO
void variables_store_file(string region, string key, mapping values) {
}

void variables_store(string region, string key, mapping values) {
  switch(query("storage")) {
    case "memory":
      variables_store_memory(region, key, values);
      break;
    case "sql":
      variables_store_sql(region, key, values);
      break;
    case "file":
      variables_store_file(region, key, values);
      break;
  }
}

string sessionid_create() {
  object md5 = Crypto.md5();
  md5->update(query("secret"));
  md5->update(sprintf("%d", roxen->increase_id()));
  md5->update(sprintf("%d", time(1)));
  return(Crypto.string_to_hex(md5->digest()));
}

mixed sessionid_set_prestate(object id, string SessionID) {
  string url=strip_prestate(strip_config(id->raw_url));
  string new_prestate = "SessionID="+SessionID;
  id->prestate += (<new_prestate>);
  return(http_redirect(url, id));
}

void sessionid_set_cookie(object id, string SessionID) {
  string Cookie = "SessionID="+SessionID+"; path=/";
  id->cookies->SessionID = SessionID;
  id->misc->moreheads = ([ "Set-Cookie": Cookie,
                           "Expires": "Mon, 26 Jul 1997 05:00:00 GMT",
                           "Pragma": "no-cache",
                           "Last-Modified": http_date(time(1)),
                           "Cache-Control": "no-cache, must-revalidate" ]);
}

string sessionid_get(object id) {
  string SessionID;

  if (id->cookies->SessionID) {
    SessionID = id->cookies->SessionID;
  }
  
  foreach (indices(id->prestate), string prestate) {
    if (prestate[..8] == "SessionID" ) {
      SessionID = prestate[10..];
    }
  }

  return(SessionID);
}

mixed first_try(object id) {
  
  foreach (query("exclude_urls")/"\n", string exclude) {
    if ((strlen(exclude) > 0) &&
        (exclude == id->not_query[..strlen(exclude)-1])) {
      return (0);
    }
  }

  if (random(query("garbage")) == 0) {
    session_gc();
  }

  string SessionID = sessionid_get(id);

  if (!SessionID) {
    SessionID = sessionid_create();
    switch(query("identify")) {
      case "cookie":
        sessionid_set_cookie(id, SessionID);
        break;
      case "prestate":
        return (sessionid_set_prestate(id, SessionID));
        break;
    }
  }

  id->misc->session_variables = variables_retrieve("session", SessionID);
  id->misc->session_id = SessionID;

  if (id->misc->session_variables->username) {
    id->misc->user_variables =
      variables_retrieve("user", id->misc->session_variables->username);
  } else {
    id->misc->user_variables = ([]);
  }
}

void filter(mapping m, object id) {
  string SessionID = id->misc->session_id;
  variables_store("session", SessionID, id->misc->session_variables);
  if (id->misc->session_variables->username) {
    variables_store("user", id->misc->session_variables->username, id->misc->user_variables);
  }
}
