/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2003 The Caudium Group
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

constant cvs_version = "$Id$";
constant thread_safe=0;

#include <module.h>
inherit "module";
inherit "caudiumlib";

import Stdio;
import Array;

constant module_type = MODULE_PROVIDER | MODULE_EXPERIMENTAL;
constant module_name = "Authentication Provider: LDAP";
constant module_doc  = "Provides access to user and group accounts "
	"located in LDAP directories."

constant module_unique = 0;


string query_provides()
{
  return "authentication";
}


/*
 * Globals
 */

object dir=0;

int access_mode_is_user() {

  return !(QUERY(CI_access_mode) == "user");
}

int access_mode_is_guest() {

  return !(QUERY(CI_access_mode) == "guest");
}

int access_mode_is_roaming() {

  return !(QUERY(CI_access_mode) == "roaming");
}

int access_mode_is_user_or_roaming() {

  return access_mode_is_user() & access_mode_is_roaming();
}


int access_mode_is_guest_or_roaming() {

  return access_mode_is_guest() & access_mode_is_roaming();
}


int default_uid() {

#if constant(geteuid)
  return(geteuid());
#else
  return(0);
#endif
}

/*
 * Object management and configuration variables definitions
 */

void create()
{
        defvar ("CI_access_mode","user","Access mode",
                   TYPE_STRING_LIST, "There are three access modes:"
		   "<p><b>user</b><br />"
                   "The user is authenticated against his own entry"
		   " in directory."
		   "Optionally you can specify attribute/value"
		   " pair must contained in.</p>"
		   "<p><b>guest</b><br />"
		   "The mode assume public access to the directory entries "
		   "and is ment for for testing purposes. It's not recommended"
		   " for real use.</p>"
		   "<p><b>roaming</b><br />"
		   "Mode designed to works with Netscape roaming LDAP"
		   " DIT tree.</p>",
		({ "user", "guest", "roaming" }) );
        defvar ("CI_access_type","search","Access type",
                   TYPE_STRING_LIST, "Type of LDAP operation used "
		   "for authorization  checking."
		   "Only 'search' type implemented, yet ;-)",
		({ "search" }) );
		//({ "search", "compare" }) );
        defvar ("CI_search_templ","(&(objectclass=person)(uid=%u%))","Defaults: Search template",
                   TYPE_STRING, "Template used by LDAP search operation"
		   " as filter."
		   "<b>%u%</b> : Will be replaced by entered username." );
        defvar ("CI_level","subtree","LDAP query depth",
                   TYPE_STRING_LIST, "Scope used by LDAP search operation."
                   "",
		({ "base", "onelevel", "subtree" }) );

	// LDAP server:
        defvar ("CI_dir_server","localhost","LDAP server: Location",
                   TYPE_STRING, "This is the host running the LDAP server with "
                   "the authentication information.");
        defvar ("CI_basename","","LDAP server: Base name",
                   TYPE_STRING, "The distinguished name to use as a base for queries."
		   "Typically, this would be an 'o' or 'ou' entry "
		   "local to the DSA which contains the user entries.");


	// "user" access type
        defvar ("CI_required_attr","","LDAP server: Required attribute",
                   TYPE_STRING|VAR_MORE,
		   "Which attribute must be present to successfully"
		   " authenticate user (can be empty). "
		   "<br />For example: memberOf",
		   0,
		   access_mode_is_user_or_roaming
		   );
        defvar ("CI_required_value","","LDAP server: Required value",
                   TYPE_STRING|VAR_MORE,
		   "Which value must be in required attribute (can be empty)" 
		   "<br />For example: cn=KISS-PEOPLE",
		   0,
		   access_mode_is_user_or_roaming
		   );
        defvar ("CI_bind_templ","uid=%u%","LDAP server: Bind template",
                   TYPE_STRING|VAR_MORE,
		   "If <b>Base name</b> is not null will be added as suffix"
		   "<br />For example: Base name is 'c=CZ' and user is 'hop',"
		   " then bind DN will be 'uid=hop, c=CZ'.",
		   0,
		   access_mode_is_user
		   );

	// "guest" access type
        defvar ("CI_dir_username","","LDAP server: Directory search username",
                   TYPE_STRING|VAR_MORE,
		   "This username will be used to authenticate "
                   "when connecting to the LDAP server. Refer to your LDAP "
                   "server documentation, this could be irrelevant.",
		   0,
		   access_mode_is_guest_or_roaming
		   );
        defvar ("CI_dir_pwd","", "LDAP server: Directory user's password",
		    TYPE_STRING|VAR_MORE,
		    "This is the password used to authenticate "
		    "connection to directory.",
		   0,
		   access_mode_is_guest_or_roaming
		    );

	// "roaming" access type
        defvar ("CI_owner_attr","owner","LDAP server: Indirect DN attributename",
                   TYPE_STRING|VAR_MORE,
		   "Attribute name which contains DN for indirect authorization"
                   ". Value is used as DN for binding to the directory.",
		   0,
		   access_mode_is_roaming
		   );

	// Defaults:
        defvar ("CI_default_attrname_upw", "userPassword",
		   "Defaults: User password map", TYPE_STRING,
                   "The mapping between passwd:password and LDAP.");
        defvar ("CI_default_uid",default_uid(),"Defaults: User ID", TYPE_INT,
                   "Some modules require an user ID to work correctly. This is the "
                   "user ID which will be returned to such requests if the information "
                   "is not supplied by the directory search.");
        defvar ("CI_default_attrname_uid", "uidNumber",
		   "Defaults: User ID map", TYPE_STRING,
                   "The mapping between passwd:uid and LDAP.");
        defvar ("CI_default_gid", getegid(),
		"Defaults: Group ID", TYPE_INT,
                   "Same as User ID, only it refers rather to the group.");
        defvar ("CI_default_attrname_gid", "gidNumber",
		   "Defaults: Group ID map", TYPE_STRING,
                   "The mapping between passwd:gid and LDAP.");
        defvar ("CI_default_gecos", "", "Defaults: Gecos", TYPE_STRING,
                   "The default Gecos.");
        defvar ("CI_default_attrname_gecos", "gecos",
		   "Defaults: Gecos map", TYPE_STRING,
                   "The mapping between passwd:gecos and LDAP.");
        defvar ("CI_default_home","/", "Defaults: Home Directory", TYPE_DIR,
                   "It is possible to specify an user's home "
                   "directory. This is used if it's not provided.");
        defvar ("CI_default_attrname_homedir", "homeDirectory",
		   "Defaults: Home Directory map", TYPE_STRING,
                   "The mapping between passwd:homedir and LDAP.");
        defvar ("CI_default_shell","/bin/false", "Defaults: Shell", TYPE_STRING,
                   "The shell name for entries without own defined.");
        defvar ("CI_default_attrname_shell", "loginShell",
		   "Defaults: Shell map", TYPE_STRING,
                   "The mapping between passwd:shell and LDAP.");
        defvar ("CI_default_addname",0,"Defaults: Username add",TYPE_FLAG,
                   "Setting this will add username to path to default directory.");

	// Etc.
        defvar ("CI_use_cache",1,"Cache entries", TYPE_FLAG,
                   "This flag defines whether the module will cache the directory "
                   "entries. Makes accesses faster, but changes in the directory will "
                   "not show immediately. <B>Recommended</B>.");
        defvar ("CI_close_dir",1,"Close the directory if not used",
		   TYPE_FLAG|VAR_MORE,
                   "Setting this will save one filedescriptor without a small "
                   "performance loss.",0,
		   access_mode_is_guest_or_roaming);
        defvar ("CI_timer",60,"Directory connection close timer",
		   TYPE_INT|VAR_MORE,
                   "The time after which the directory is closed",0,
                   lambda(){return !QUERY(CI_close_dir) || access_mode_is_guest_or_roaming;});

}


void close_dir() {

    if (!QUERY(CI_close_dir))
	return;
    if( (time(1)-last_dir_access) > QUERY(CI_timer) ) {
	dir->unbind();
	dir=0;
	DEBUGLOG("closing the directory");
	return;
    }
    call_out(close_dir,QUERY(CI_timer));
}


object open_dir(string u, string p) {
    mixed err;
    string binddn, bindpwd;

    last_dir_access=time(1);
    dir_accesses++; //I count accesses here, since this is called before each
    //if(objectp(dir)) //already open
    if(dir) //already open
	return;
    if(dir)
	return;

    if(!access_mode_is_guest_or_roaming()) { // access type is "guest"/"roam."
	binddn = QUERY(CI_dir_username);
	bindpwd = QUERY(CI_dir_pwd);
    } else {                      // access type is "user"
	binddn = replace(QUERY(CI_bind_templ), "%u%", u);
	if (sizeof(QUERY(CI_basename)))
	    binddn += ", " + QUERY(CI_basename);
	bindpwd = p;
    }

    err = catch {
	dir = Protocols.LDAP.client(QUERY(CI_dir_server));
	dir->bind(binddn, bindpwd);
    };
    if (arrayp(err)) {
	werror ("LDAPauth: Couldn't open authentication directory!\n[Internal: "+err[0]+"]\n");
	if (objectp(dir)) {
	    werror("LDAPauth: directory interface replies: "+dir->error_string()+"\n");
	    catch(dir->unbind());
	}
	else
	    werror("LDAPauth: unknown reason\n");
	werror ("LDAPauth: check the values in the configuration interface, and "
		"that the user\n\trunning the server has adequate permissions "
		"to the server\n");
	dir=0;
	return;
    }
    if(dir->error_code) {
	werror ("LDAPauth: authentication error ["+dir->error_string+"]\n");
	dir=0;
	return;
    }
    switch(QUERY(CI_level)) {
	case "subtree": dir->set_scope(2); break;
	case "onelevel": dir->set_scope(1); break;
	case "base": dir->set_scope(0); break;
    }
    dir->set_basedn(QUERY(CI_basename));
    DEBUGLOG("directory successfully opened");
    if(QUERY(CI_close_dir) && (QUERY(CI_access_mode) != "user"))
	call_out(close_dir,QUERY(CI_timer));
}



/*
 * Statistics
 */

string status() {

    return ("<H2>Security info</H2>"
	   "Attempted authentications: "+att+"<BR>\n"
	   "Failed: "+(att-succ+nouser)+" ("+nouser+" because of wrong username)"
	   "<BR>\n"+
	   dir_accesses +" accesses to the directory were required.<BR>\n" +

	     "<p>"+
	     "<h3>Failure by host</h3>" +
	     Array.map(indices(failed), lambda(string s) {
	       return caudium->quick_ip_to_host(s) + ": "+failed[s]+"<br>\n";
	     }) * ""
	     //+ "<p>The database has "+ sizeof(users)+" entries"
#ifdef LOG_ALL
	     + "<p>"+
	     "<h3>Auth attempt by host</h3>" +
	     Array.map(indices(accesses), lambda(string s) {
	       return caudium->quick_ip_to_host(s) + ": "+accesses[s]->cnt+" ["+accesses[s]->name[0]+
		((sizeof(accesses[s]->name) > 1) ?
		  (Array.map(accesses[s]->name, lambda(string u) {
		    return (", "+u); }) * "") : "" ) + "]" +
		"<br>\n";
	     }) * ""
#endif
	   );

}


/*
 * Auth functions
 */

string get_attrval(mapping attrval, string attrname, string dflt) {

    return (zero_type(attrval[attrname]) ? dflt : attrval[attrname][0]);
}

array(string) userinfo (string u,mixed p) {
    array(string) dirinfo;
    object results;
    mixed err;
    mapping(string:array(string)) tmp, attrsav;

    DEBUGLOG ("userinfo ("+u+")");
    //DEBUGLOG (sprintf("DEB:%O\n",p));
    if (u == "A. Nonymous") {
      DEBUGLOG ("A. Nonymous pseudo user catched and filtered.");
      return 0;
    }

    if (QUERY(CI_use_cache))
	dirinfo=cache_lookup("ldapauthentries",u);
	if (dirinfo)
	    return dirinfo;

    open_dir(u, p);

    if (!dir) {
	werror ("LDAPauth: Returning 'user unknown'.\n");
	return 0;
    }

    if(QUERY(CI_access_type) == "search") {
	string rpwd = "";

	err = catch(results=dir->search(replace(QUERY(CI_search_templ), "%u%", u)));
	if (err || !objectp(results) || !results->num_entries()) {
	    DEBUGLOG ("no entry in directory, returning unknown");
	    if(access_mode_is_guest_or_roaming() && objectp(dir)) {
		catch(dir->unbind());
		dir=0;
	    }
	    return 0;
	}
	tmp=results->fetch();
	//DEBUGLOG(sprintf("userinfo: got %O",tmp));
	if(zero_type(tmp[QUERY(CI_default_attrname_upw)]))
	      werror("LDAPuserauth: WARNING: entry doesn't have the '" + QUERY(CI_default_attrname_upw) + "' attribute !\n");
	 else
	     rpwd = tmp[QUERY(CI_default_attrname_upw)][0];
	/*
	if(!access_mode_is_guest()) {	// mode is 'guest'
	    if(zero_type(tmp[QUERY(CI_default_attrname_upw)]))
		werror("LDAPuserauth: WARNING: entry haven't '" + QUERY(CI_default_attrname_upw) + "' attribute !\n");
	    else
		rpwd = tmp[QUERY(CI_default_attrname_upw)][0];
	}
	*/
	if(!access_mode_is_user_or_roaming())	// mode is 'user'
	// this is use when no password suplied (for example fetching www.website.com/~user) 
	 rpwd = stringp(p) ? rpwd : "{x-hop}*";
	if(!access_mode_is_roaming()) {	// mode is 'roaming'
	  // OK, now we'll try to bind ...
	  string binddn = get_attrval(tmp, QUERY(CI_owner_attr), "");
	  DEBUGLOG (sprintf("LDAPauth: indirect DN: [%s]\n", binddn));
	  if(!sizeof(binddn)) {
	    DEBUGLOG ("no value for indirect attribute, returning unknown");
	    return 0;
	  }
	  err = catch (dir->bind(binddn, p));
	  if (arrayp(err)) {
	    werror ("LDAPauth: Couldn't open authentication directory!\n[Internal: "+err[0]+"]\n");
	    if (objectp(dir)) {
	      werror("LDAPauth: directory interface replies: "+dir->error_string()+"\n");
	      catch(dir->unbind());
	    } else
	      werror("LDAPauth: unknown reason\n");
	    werror ("LDAPauth: check the values in the configuration interface,"
		    " and that the user\n\trunning the server has adequate"
		    " permissions to the server\n");
	    dir=0;
	    return 0;
	  }
	  if(dir->error_code) {
	    werror ("LDAPauth: authentication error ["+dir->error_string+"]\n");
	    dir=0;
	    return 0;
	  }
	  dir->set_scope(0);
	  dir->set_basedn(binddn);
	  //err = catch(results=dir->search(replace(QUERY(CI_search_templ), "%u%", u)));
	  err = catch(results=dir->search("objectclass=*")); // FIXME: modify
							      // to conf. int!
	  if (err || !objectp(results) || !results->num_entries()) {
	    DEBUGLOG ("no entry in directory, returning unknown");
	    if(objectp(dir)) {
	      catch(dir->unbind());
	      dir=0;
	    }
	    return 0;
	  }
	  tmp=results->fetch();
	}
	dirinfo= ({
		u, 			//tmp->uid[0],
		rpwd,
		get_attrval(tmp, QUERY(CI_default_attrname_uid), QUERY(CI_default_uid)),
		get_attrval(tmp, QUERY(CI_default_attrname_gid), QUERY(CI_default_gid)),
		get_attrval(tmp, QUERY(CI_default_attrname_gecos), QUERY(CI_default_gecos)),
		QUERY(CI_default_addname) ? QUERY(CI_default_home)+u : get_attrval(tmp, QUERY(CI_default_attrname_homedir), ""),
		get_attrval(tmp, QUERY(CI_default_attrname_shell), QUERY(CI_default_shell)),
		sizeof(QUERY(CI_required_attr)) && !access_mode_is_user() && !zero_type(tmp[QUERY(CI_required_attr)]) ? mkmapping(({QUERY(CI_required_attr)}),tmp[QUERY(CI_required_attr)]) : 0
	});
    } else {
	// Compare method is unimplemented, yet
    }
    #if 0
    if (QUERY(CI_use_cache))
	cache_set("ldapauthentries",u,dirinfo);
    #endif
    if(!access_mode_is_user()) { // Should be 'closedir' method?
      dir->unbind();
      dir=0;
    }
    if(!access_mode_is_roaming()) { // We must rebind connection
      dir->bind(QUERY(CI_dir_username), QUERY(CI_dir_pwd));
    }

    if(zero_type(uids[(string)dirinfo[2]]))
	uids = uids + ([ dirinfo[2] : ({ dirinfo[0] }) ]);
    else
	uids[dirinfo[2]] = uids[dirinfo[2]] + ({dirinfo[0]});
#if 0
    if(zero_type(gids[(string)dirinfo[3]]))
	gids = ([ dirinfo[3]:({dirinfo[0]}) ]);
    else
	gids[dirinfo[3]] = gids[dirinfo[3]] + ({dirinfo[0]});
#endif // FIXME: hacked - returns gidname = uidname !!!

    //DEBUGLOG(sprintf("Result: %O",dirinfo)-"\n");
    return dirinfo;
}

array(string) userlist() {

    //if (QUERY(disable_userlist))
    return ({});
}

string user_from_uid (int u) 
{

    if(!zero_type(uids[(string)u]))
	return(uids[(string)u][0]);
    return 0;
}

#if LOG_ALL
int chk_name(string x, string y) {

    return(x == y);
}
#endif

array|int auth (array(string) auth, object id)
{
    string u,p,pw;
    array(string) dirinfo;
    mixed attr,value;
    mixed err;

    att++;
    sscanf (auth[1],"%s:%s",u,p);

#if LOG_ALL
    if(!zero_type(accesses[id->remoteaddr]) && !zero_type(accesses[id->remoteaddr]["cnt"])) {
      accesses[id->remoteaddr]->cnt++;
      if(Array.search_array(accesses[id->remoteaddr]->name, chk_name, u) < 0)
	accesses[id->remoteaddr]->name = accesses[id->remoteaddr]->name + ({ u });
    } else
      accesses[id->remoteaddr] = (["cnt" : 1, "name":({ u })]);
#endif
    if (!p||!strlen(p)) {
	DEBUGLOG ("no password supplied by the user");
	failed[id->remoteaddr]++;
	caudium->quick_ip_to_host(id->remoteaddr);
	return ({0, auth[1], -1});
    }

    dirinfo=userinfo(u,p);
    if (!dirinfo||!sizeof(dirinfo)) {
	//DEBUGLOG ("password check ("+dirinfo[1]+","+p+") failed");
	DEBUGLOG ("password check failed");
	DEBUGLOG ("no such user");
	nouser++;
	failed[id->remoteaddr]++;
	caudium->quick_ip_to_host(id->remoteaddr);
	return ({0,u,p});
    }
    pw = dirinfo[1];
    if(pw == "{x-hop}*")  // !!!! HACK
	pw = p;
    if(p != pw) {
	// Digests {CRYPT}, {SHA1} and {MD5}
	int pok = 0;
	if (sizeof(pw) > 6)
	    switch (upper_case(pw[..4])) {
		case "{SHA}" :
		    pok = (pw[5..] == MIME.encode_base64(Crypto.sha()->update(p)->digest()));
		    DEBUGLOG ("Trying SHA digest ...");
		    break;

		case "{MD5}" :
		    pok = (pw[5..] == MIME.encode_base64(Crypto.md5()->update(p)->digest()));
		    DEBUGLOG ("Trying MD5 digest ...");
		    break;

		case "{CRYP" :
		    if (sizeof(pw) > 7 && upper_case(pw[5..6]) == "T}") {
			pok = crypt(p,pw[7..]);
			DEBUGLOG ("Trying CRYPT digest ...");
		    }
		    break;
	    } // switch
	if (!pok) {
	    //DEBUGLOG ("password check (" + pw + ", " + p + ") failed");
	    DEBUGLOG ("password check failed");
	    //fail++;
	    failed[id->remoteaddr]++;
	    caudium->quick_ip_to_host(id->remoteaddr);
	    return ({0,u,p});
	}
    }

    if(!access_mode_is_user()) {
	// Check for the Atributes
	if(sizeof(QUERY(CI_required_attr))) {
	    attr=QUERY(CI_required_attr);
	    if (mappingp(dirinfo[7]) && dirinfo[7][attr]) {
		mixed d;
		d=dirinfo[7][attr];
		// werror("User "+u+" has attr "+attr+"\n");
		if(sizeof(QUERY(CI_required_value))) {
		    mixed temp;
		    int found=0;
		    value=QUERY(CI_required_value);
		    foreach(d, mixed temp) {
			// werror("Looking at "+temp+"\n");
			if (search(temp,value)!=-1)
			    found=1;
		    }
		    if (found) {
			// werror("User "+u+" has value "+value+"\n");
		    } else {
			werror("LDAPuserauth: User "+u+" has not value "+value+"\n");
			failed[id->remoteaddr]++;
			caudium->quick_ip_to_host(id->remoteaddr);
			return ({0,u,p});
		    }
		}
	    } else {
		werror("LDAPuserauth: User "+u+" has no attr "+attr+"\n");
		failed[id->remoteaddr]++;
		caudium->quick_ip_to_host(id->remoteaddr);
		return ({0,u,p});
	    }

	}
    } // if access_mode_is_user

    // Its OK so save them
    if (QUERY(CI_use_cache))
	cache_set("ldapauthentries",u,dirinfo);

    id->misc->uid = dirinfo[2];
    id->misc->gid = dirinfo[3];
    id->misc->gecos = dirinfo[4];
    id->misc->home = dirinfo[5];
    id->misc->shell = dirinfo[6];

    DEBUGLOG (u+" positively recognized");
    succ++;
    return ({1,u,0});
}
