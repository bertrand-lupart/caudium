/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2005 The Caudium Group
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
 */
/*
 * $Id$
 */
//! Caudium mainconfig object

inherit "config/builders";
constant cvs_version = "$Id$";
//inherit "caudiumlib";

inherit "config/draw_things";
inherit "cachelib";  // Inherit the cache helper functions.

// import Array;
// import Stdio;

/* Work-around for Simulate.perror */
#define perror roxen_perror

#include <confignode.h>
#include <module.h>
#include <mainconfig_themeable.h>

#define dR "ff"
#define dG "ff"
#define dB "ff"

#define bdR "00"
#define bdG "50"
#define bdB "90"


#define BODY "<body bgcolor=white text=black link=darkblue vlink=black alink=red background=\"/image/cowfish-bg.gif\" leftmargin='0' marginwidth='0' topmargin='0' marginheight='0'>"

#define TABLEP(x, y) (id->supports->tables ? x : y)
#define PUSH(X) do{res+=({(X)});}while(0)

int bar=time(1);
multiset changed_port_servers;
object cache = caudium->cache_manager->get_cache("Configuration Interface");  // Get ourselves a cache to store stuff in.

object cif = ThemedConfig( caudium->QUERY(cif_theme),
			   caudium->QUERY(InternalImagePath));

//!
class Node {
  inherit "struct/node";

  mixed original;
  int changed, moredocs;
  int bar=time();
  function saver;
  string|array error;
  
  //!
  void change(int i)
  {
    changed += i;
    if(up) up->change(i);
  }

  private string show_me(string s)
  {
    string name=path(1);
    if(folded)
      return ("<a name=\""+name+"\" href=\"/(unfold)" + name + "?"+(bar++)+
	      "\">\n<img border=0 align=baseline src=/auto/unfold"
	      +(changed?"2":"")+" alt=\""+(changed?"*-":"--")+"\">"
	      "</a>\n "+s+"\n");
    else
      return ("<a name=\""+name+"\" href=\"/(fold)" + name + "?"+(bar++)+
	      "\">\n<img border=0 src=/auto/fold"+(changed?"2":"")
	      +"  alt="+(changed?"**":"\"\\/\"")+">"
	      "</a>\n "+s+"\n");
  }

  //!
  mixed describe(int i, object id)
  {
    array (string) res=({""});
    object node,prevnode;
    mixed tmp;

    if(describer)
      tmp = describer(this_object(), id);
#ifdef NODE_DEBUG
    else
    {
      perror("No describer in node "+path(1)+"\n");
      return 0;
    }
#endif
    if(mappingp(tmp)) {
//      report_notice("Got mapping.\n");
      return tmp;
    }
    if(arrayp(tmp) && sizeof(tmp))
      PUSH(tmp[0] +  "<dt>" + (i?tmp[i]:show_me(tmp[1])) + "\n");
    else if(stringp(tmp) && strlen(tmp))
      PUSH("<dt>"+(i?tmp:show_me(tmp)) + "\n");
    else if(!tmp)
      return "";

    if(!folded)
    {
      PUSH("<dl><dd>\n");
      node = down;
      array node_desc = ({});
      while(node)
      {
	if(!objectp(node))	// ERROR! Destructed node in tree!
	{
	  if(objectp(prevnode))
	    prevnode->next=0;
	  node=0;
	  break;
	}
	prevnode = node;
	node = node->next;
	node_desc += ({ prevnode->describe() });
      }
      PUSH(node_desc*"\n");
      PUSH("</dl>\n\n");
    }
    return res*"";
  }
  
  
  //!
  object config()
  {
    object node;
    node=this_object();
    while(node)
      if(node->type == NODE_CONFIGURATION)
	return node->data;
      else
	node=node->up;
  }
  
  //!
  void save()
  {
    object node;
    node=down;
    
    // depth-first save.
    while(node)
    {
      if(node->changed) node->save();
      node=node->next; 
    }
    if(changed && type == NODE_MODULE_COPY_VARIABLE &&
       data[VAR_TYPE] == TYPE_PORTS) {
      caudium->configuration_interface_obj->changed_port_servers[config()] = 1;
      // A port was changed in the current server...
    }
    if(saver) saver(this_object(), config());
    else  change(-changed);
  }
}

//!
int restore_more_mode()
{
  return !!file_stat(caudium->QUERY(ConfigurationStateDir) + ".more_mode");
}

object root=Node();
int expert_mode, more_mode=restore_more_mode();

//!
void save_more_mode()
{
  if(more_mode)
    open(caudium->QUERY(ConfigurationStateDir) + ".more_mode", "wct");
  else
    rm(caudium->QUERY(ConfigurationStateDir) + ".more_mode");
}


//!
void create()
{
  build_root(root);
  init_ip_list();
  call_out(init_ip_list, 0);
}

// Note stringification of ACTION and ALIGN
#if 0
#define BUTTON(ACTION,TEXT,ALIGN) do{PUSH("<a href=\"/(ACTION)"+(o?o->path(1):"/")+"?"+(bar++)+"\"><img border=0 hspacing=0 vspacing=0 src=\"/auto/button/"+(lm?"lm/":"")+replace(TEXT," ","%20")+"\" alt=\""+(lm?"/ ":" ")+TEXT+" /\""+(("ALIGN"-" ")=="left"?"":" align="+("ALIGN"-" "))+"></a>");lm=0;}while(0)
#else

#define BUTTON(ACTION,TEXT,ALIGN) do{buttons += ({({"<a href=\"/("#ACTION")"+(o?o->path(1):"/")+"?"+(bar++)+"\"><img border=0 hspacing=0 vspacing=0 src=\"/auto/button/"+(lm?"lm/":""),replace(TEXT," ","%20")+"\" alt=\""+(lm?"/ ":" ")+TEXT+" /\""+((#ALIGN-" ")=="left"?"":" align="+(#ALIGN-" "))+"></a>"})});lm=0;}while(0)
#define PUSH_BUTTONS(CLEAR) do{if(sizeof(buttons)){buttons[-1][0]+="rm/";res+=`+(@buttons);if(CLEAR){PUSH("<br clear=all>");}}lm=1;buttons=({});}while(0)

#endif /* 0 */


//!
object find_node(string l)
{ 
  l = Caudium.HTTP.decode_url(l);
  array tmp = l/"/"-({""});
  object o;
  if(!sizeof(tmp)) return root;
  for(o=root; sizeof(tmp) && (o=o->descend(tmp[0],1)); tmp=tmp[1..]);
  if(!o) return 0;
  return o;
}

//!
mapping file_image(string img)
{
  object o;
  o=open(cif->path()+img, "r");
  if (!o)  return 0;
  int extpos = search(reverse(img), ".");
  string type = "jpeg";
  if(extpos != -1)
    type = img[sizeof(img)-extpos..];
  return ([ "file":o, "type":"image/" + type, ]);
}

//!
mapping stores( string s )
{
  return 
    ([
      "data":replace(s, "$docurl", caudium->docurl),
      "type":"text/html",
      "extra_heads":
      ([
	"Title":"Caudium maintenance",
//      "Expires":Caudium.HTTP.date(time(1)+2),
//	"Pragma":"no-cache",
	"Last-Modified":Caudium.HTTP.date(),
	])
      ]);
}

#define CONFIG_URL caudium->config_url(id)

// Holds the default ports for various protocols.
static private constant default_ports = ([
  "ftp":21,
  "http":80,
  "https":443,
]);

//!
mapping verify_changed_ports(object id, object o)
{
  string res = cif->head("Caudium Config: Setting Server URL") + cif->body() +
    ("<h1>Set the correct server URL</h1>"
     "As you have changed the open ports in one or more servers "
     "you might have to adjust the default server URL(s). Check the "
     "correct URL(s) below and modify it as needed. The server URLs are among "
     "other things used for redirects. "
     "<form action=\"/(modify_server_url)"+o->path(1)+"\">");
  foreach(indices(changed_port_servers), object server)
  {
    int glob;
    string name;
    if(!server) {
      glob = 1;
      server = caudium;
      name="Global Variables";
#if 0
      perror("Config Interface, URL %s, Ports %O\n",
	     GLOBVAR(ConfigurationURL), 
	     GLOBVAR(ConfigPorts));
#endif
    } else {
      glob = 0;
      name = server->name;
#if 0
      perror("Server %s, URL %s, Ports %O\n", server->name,
	     server->query("MyWorldLocation"),
	     server->query("Ports"));
#endif
    }
    
    string def;
    if(glob) {
      def = GLOBVAR(ConfigurationURL);
      res += "<h3>Select Configuration Interface URL: </h3>\n<pre>";
    } else {
      def = server->query("MyWorldLocation");
      res += sprintf("<h3>Select server URL for for %s: </h3>\n"
		     "<pre>", name);
    }
    
    foreach((glob ? GLOBVAR(ConfigPorts) : server->query("Ports")),
	     array port) {
      string prt;
      if(port[1] == "tetris")
	continue;
      switch(port[1])
      {
       case "ssl3":
	prt = "https";
	break;
       case "ftp":
       case "ftp2":
	prt = "ftp";
	break;
       case "http2":
	prt = "http";
	break;
       default:
	prt = port[1];
      }
      int portno = default_ports[prt];

      prt += "://";
      if(port[2] && port[2]!="ANY") {
	prt += port[2];
      } else {
#if constant(gethostname)
	prt += (gethostname()/".")[0] + "." +
	  (glob ? caudium->get_domain() : server->query("Domain"));
#else
	prt += "localhost";
#endif
      }

      if (portno && (port[0] == portno)) {
	// Default port.
	prt += "/";
      } else {
	prt += ":"+port[0]+"/";
      }

      if(prt != def)
	res += sprintf("     <input id='%s' type='radio' name='%s' value='%s'>     <label for='%s'>%s</label>\n",
		       prt, name, prt, prt, prt);

    }
      res += sprintf("     <input type='radio' checked='checked' value='own' name='%s'>     "
		     "<input size=70 name='%s->own' "
		     "value='%s'>\n</pre><p>",
		     name, name, def);
  }
  changed_port_servers = (<>);
  return stores(res+"<input type='submit' value='Continue...'></form>");
}

//!
mapping save_it(object id, object o)
{
    cif = ThemedConfig( caudium->QUERY(cif_theme),
			caudium->QUERY(InternalImagePath));
    changed_port_servers = (<>);
    root->save();
    caudium->update_supports_from_caudium_net();
//    caudium->initiate_configuration_port( 0 );
    id->referrer = CONFIG_URL + o->path(1);
//    caudium->update_storage_manager();
    if(sizeof(changed_port_servers))
	return verify_changed_ports(id, o);
}


//!
object find_module(string name, object in)
{
  mapping mod;
  object o;
  string s;
  int i;
  name = lower_case(name);
  if(!sscanf(name, "%s#%d", name, i))
  {
#ifdef MODULE_DEBUG
#if defined(DEBUG) && (DEBUG > 1000)
    perror("Modulename not in short form: "+name+"\n");
#endif
#endif
    foreach(values(in->modules), mod)
    {
      if(mod->copies)
      {
	foreach(values(mod->copies), o)
	  if(lower_case(s=name_of_module(o)) == name)
	    return o;
      } else 
	if(mod->enabled && (lower_case(s=name_of_module(mod->enabled))==name))
	  return mod->enabled; 
    }
  } else {
    mapping modules;
#ifdef MODULE_DEBUG
#if defined(DEBUG) && (DEBUG > 1000)
    perror("Modulename in short form: "+name+"#"+i+"\n");
#endif
#endif
    modules = in->modules;
    if(modules[name])
    {
      if(modules[name]->copies)
	return modules[name]->copies[i];
      else 
	if(modules[name]->enabled)
	  return modules[name]->enabled;
    }
  }
  return 0;
}

//!
mixed decode_form_result(string var, int type, object node, mapping allvars)
{
  mixed tmp;
  switch(type)
  {
      case TYPE_CUSTOM:
        return node->data[ VAR_MISC ][2]( var, type, node, allvars );
    
      case TYPE_MODULE_LIST:
        return Array.map(var/"\000", find_module);

      case TYPE_MODULE:
        return find_module((var/"\000")[0], node->config());

      case TYPE_PORTS:  
        /*
          Encoded like this:

          new_port    --> Add a new port
          ok[_<ID>]   --> Save the value for all or one port
          delete_<ID> --> Delete a port

          ---- { A port is defined by:
          port_<ID> == INT
          protocol_<ID> == STRING
          ip_number_<ID> == STRING
          arguments_<ID> == STRING
          } ---- 
        */
        if(allvars->new_port)
          return node->data[VAR_VALUE] + ({ ({ 80, "http", "ANY", "" }) });

        array op = copy_value(node->data[VAR_VALUE]);
        int i;
        for(i = 0; i<sizeof(op); i++)
        {
          if(!allvars["delete_"+i])
          {
            if(allvars["other_"+i] && (allvars["other_"+i] != op[i][2]))
            {
              allvars["ip_number_"+i] = allvars["other_"+i];
              ip_number_list += ({ allvars["other_"+i] });
            }
            op[i][0] = (int)allvars["port_"+i]||op[i][0];
            op[i][1] = allvars["protocol_"+i]||op[i][1];
            op[i][2] = allvars["ip_number_"+i]||op[i][2];
            string args = "";
       
            if(allvars["key_"+i] && strlen(allvars["key_"+i]))
              args += "key-file "+allvars["key_"+i]+"\n";
            if(allvars["cert_"+i] && strlen(allvars["cert_"+i]))
              args += "cert-file "+allvars["cert_"+i]+"\n";
            if(allvars["cc_"+i] && strlen(allvars["cc_"+i]))
              args += "client-cert-request "+allvars["cc_"+i]+"\n";
            if(allvars["auth_"+i] && strlen(allvars["auth_"+i]))
              args += "client-cert-authorities "+allvars["auth_"+i]+"\n";
            if(allvars["cci_"+i] && strlen(allvars["cci_"+i]))
              args += "client-cert-issuers "+allvars["cci_"+i]+"\n";
       
            if(strlen(args))
              op[i][3] = args;
       
          } else  // Delete this port.
            op[i]=0;
        }
        return op  - ({ 0 });

      case TYPE_DIR_LIST:
        array foo;
        foo=Array.map((var-" ")/",", lambda(string var, object node) {
                                       if (!strlen( var ) || !Stdio.is_dir(var))
                                       {
                                         if(node->error)	
                                           node->error += ", " +var + " is not a directory";
                                         else
                                           node->error = var + " is not a directory";
                                         return 0;
                                       }
                                       if(var[-1] != '/')
                                         return var + "/";
                                       return var;
                                     }, node);
    
        if(sizeof(foo-({0})) != sizeof(foo))
          return 0;
        return foo;

      case TYPE_FILE_LIST:
        array bar;
        bar=Array.map((var-" ")/",", lambda(string var, object node) {
                                       if (!strlen( var ) || !file_stat(var))
                                       {
                                         if(node->error)	
                                           node->error += ", " +var + " is not a directory or file";
                                         else
                                           node->error = var + " is not a directory or file";
                                         return 0;
                                       }
                                       array f=(array)file_stat(var);
                                       if(f && f[1]==-2 && var[-1] != '/')
                                         return var + "/";
                                       return var;
                                     }, node);
    
        if(sizeof(bar-({0})) != sizeof(bar))
          return 0;
        return bar;
    
      case TYPE_DIR:
        if (!strlen( var ) || !Stdio.is_dir(var))
        {
          node->error = var + " is not a directory";
          return 0;
        }
        if(var[-1] != '/')
          return var + "/";
        return var;

      case TYPE_EXISTING_FILE:
        if (!strlen(var) || !Stdio.is_file(var)) {
          node->error = "the file \"" +var + "\" cannot be found";
          return 0;
        }
        return var;
    
      case TYPE_TEXT_FIELD:
        var -= "\r";
      case TYPE_FONT:
      case TYPE_STRING:
      case TYPE_FILE:
      case TYPE_LOCATION:
        return (var/"\000")[0];
    
      case TYPE_PASSWORD:
        return crypt((var/"\000")[0]);
    
      case TYPE_FLAG:
        return lower_case((var/"\000")[0]) == "yes";
    
      case TYPE_INT:
        if (!sscanf( var, "%d", tmp ))
        {
          node->error= var + " is not an integer";
          return 0;
        }
        return tmp;
    
      case TYPE_FLOAT:
        if (!sscanf( var, "%f", tmp ))
        {
          node->error= var + " is not a arbitary precision floating point number";
          return 0;
        }
        return tmp;
    
      case TYPE_INT_LIST:
        if(node->data[VAR_MISC])
          return (int)var;
        else
          return Array.map((var-" ")/",", lambda(string s){ 
                                            return (int)s;
                                          });
    
    
      case TYPE_STRING_LIST:
        if(node->data[VAR_MISC])
          return var;
        else
          return (var-" ")/",";
    
      case TYPE_COLOR:
        int red, green, blue;
    
        if (sscanf( var, "%d:%d:%d", red, green, blue ) != 3
            || red < 0 || red > 255 || green < 0 || green > 255
            || blue < 0 || blue > 255)
        {
          node->error = var + " is not a valid color specification";
          return 0;
        }
        return (red << 16) + (green << 8) + blue;
  }
  error("Unknown type.\n");
}

//!
mapping std_redirect(object o, object id)
{
  string loc, l2;

  if(!o)  o=root;
  
  if(id && id->referrer)
    loc=(((((id->referrer/"#")[0])/"?")[0])+"?"+(bar++)
	 +"#"+o->path(1));
  else
    loc = CONFIG_URL+o->path(1)[1..]+"?"+bar++;
  
  if(sscanf(loc, "%s/(%*s)%s",l2, loc) == 3)
    loc = l2 + loc;		// Remove the prestate.

//  http://www:22020//Configuration/ -> http://www:22202/Configurations/

  loc = replace(replace(replace(loc, "://", ""), "//", "/"), "", "://");

  return Caudium.HTTP.redirect(_Roxen.http_decode_string(loc));
}

//!
string configuration_list()
{
  string res="";
  /* FIXME
  object o;
  foreach(caudium->configurations, o)
    res += "<option>Copy of '"+o->name+"'\n";
  */
  return res;
}

//!
string configuration_types()
{
  string res="";
  foreach(sort(get_dir("server_templates")), string c)
  {
    array err;
    if (err = catch {
      if(c[-1]=='e' && c[0]!='#') {
	object o = get_template(c);
	if (o) {
	  res += sprintf("<option value=\"%s\"%s>%s\n",
			 c, (o->selected?" selected":""), o->name);
	}
      }
    }) {
      report_error(sprintf("Error initializing server template \"%s\"\n"
			   "%s\n", c, describe_backtrace(err)));
    }
  }
  return res;
}

//!
string describe_config_modules(array mods)
{
  string res = "This configuration template adds the following modules:<p><ul>";
  if(!mods||!sizeof(mods)) return "This configuration template adds no modules";
  
  foreach(mods, string mod)
  {
    sscanf(mod, "%s#", mod);
    if(!caudium->allmodules)
    {
      roxen_perror("CONFIG: Rescanning modules (doc string).\n");
      caudium->rescan_modules();
      roxen_perror("CONFIG: Done.\n");
    }
    if(!caudium->allmodules[mod]) res += "<li>The unknown module '"+mod+"'\n";
    else res += "<li>"+caudium->allmodules[mod][0]+"\n";
  }
  return res+"</ul>";
}

//!
string configuration_docs()
{
  string res="";
  foreach(get_dir("server_templates"), string c)
  {
    if( c[-1]=='e' )
      res += ("<dt><b>"+get_template(c)->name+"</b>\n"+
	      "<dd>"+get_template(c)->desc+"<br>\n"+
	      describe_config_modules(get_template(c)->modules) + "\n");
  }
  return res;
}

//!
string new_configuration_form()
{
  return ( cif->head( "" ) + cif->body()  + cif->status_row(root) +
	  "<h2>Add a new virtual server</h2>\n"
	  "<table bgcolor=#000000><tr><td >\n"
	  "<table cellpadding=3 cellspacing=1 bgcolor=lightblue><tr><td>\n"
	  "<form>\n"
	  "<tr><td>Server name:</td><td><input name=name size=40,1>"
	  "</td></tr>\n"
	  "<tr><td>Configuration type:</td><td><select name=type>"+
	  configuration_types()+configuration_list()+"</select></tr>"
	  "</td>\n"
	  "<tr><td colspan=2><table><tr><td align=left>"
	  "<input type=submit name=ok value=\" Ok \"></td>"
	  "<td align=right>"
	  "<input type=submit name=no value=\" Cancel \"></td></tr>\n"
	  "</table></td></tr></table></td></tr>\n</table>\n" +
	  "<p>The only thing the type change is the initial "
	  "configuration of the server.\n"
	  "<p>The types are:<dl>\n" + configuration_docs() +
	  /* FIXME
	  "<dt><b>Copy of ...</b>:\n"
	  "<dd>Make an exact copy of the mentioned virtual server.\n"
	  "You should change at least the listen ports.<p>\n"
	  "This can be very useful, since you can make 'template' virtual "
	  "servers (servers without any open ports), that you can copy later "
	  "on.\n"
	  */
	  "</dl>\n</body>\n");
}


//!
mapping module_nomore(string name, int type, object conf)
{
  mapping module;
  object o;
// perror("Module: "+name+"\n");
  if((module = conf->modules[name])
    && (!module->copies && module->enabled))
    return module;
  if(((type & MODULE_DIRECTORIES) && (o=conf->dir_module))
     || ((type & MODULE_AUTH)  && (o=conf->auth_module))
     || ((type & MODULE_TYPES) && (o=conf->types_module))
     || ((type & MODULE_MAIN_PARSER)  && (o=conf->parse_module)))
    return conf->modules[conf->otomod[o]];
}

//!
mixed new_module_copy(object node, string name, object id)
{
  object orig;
  int i;
  mapping module;
  module = node->config()->modules[name];
  switch(node->type)
  {
   default:
    error("Foo? Illegal node in new_module_copy\n");
    
   case NODE_MODULE_COPY:
    node=node->up;
    
   case NODE_MODULE_MASTER_COPY:
   case NODE_MODULE:
    node=node->up;
    
   case NODE_CONFIGURATION:
  }
  
  if(module) if(module->copies) while(module->copies[i])  i++;
  orig = node->config()->enable_module(name+"#"+i);

  if(!orig) return Caudium.HTTP.string_answer("This module could not be enabled.\n");
    
  module = node->config()->modules[name];
  node = node->descend(module->name);
  // Now it is the (probably unbuilt) module main node...
  
  node->data = module;
  node->describer = describe_module;
  node->type = NODE_MODULE;
  build_module(node);
  
  //  We want to see the new module..
  node->folded=0; 
  
  // If the module have copies, select the actual copy added..
  if(module->copies) node = node->descend((string)i, 1); 
  
  // Now it is the module..
  // We want to see this one immediately.
  if(node)
  {
    node->folded = 0;
    // Mark the node and all its parents as modified.
    node->change(1);
  }
  return std_redirect(root, id);
}

//!
mixed new_module_copy_copy(object node, object id)
{
  return new_module_copy(node, node->data->sname, id);
}

//!
string new_module_form(object id, object node)
{
  mixed a,b;
  string q;
  array mods;
  string res, doubles="";
  
  if(!caudium->allmodules || sizeof(id->pragma))
  {
    roxen_perror("CONFIG: Rescanning modules.\n");
    caudium->current_configuration = node->config();
    caudium->rescan_modules();
    caudium->current_configuration = 0;
    roxen_perror("CONFIG: Done.\n");
  }
  
  a = caudium->allmodules;
  mods = Array.sort_array(indices(a), lambda(string a, string b, mapping m) { 
					return m[a][0] > m[b][0];
				      }, a);
  
  switch(caudium->QUERY(ModuleListType)) {
   case "Compact":
    res = ( cif->head("Add Modules") + cif->body() + "\n\n"+
	    cif->status_row(node)+
	    "<table cellpadding=10><tr><td colspan=2>"
	    "<h2>Select one or more modules to add to this virtual server.</h2>\n"
	    "</td></tr><tr valign=top><td>"
	    "<form method=get action=\"/(addmodule)"+node->path(1)+"\">"
	    "<select multiple size=10 name=_add_new_modules>");
     
    foreach(mods, q)
    {
      if(b = module_nomore(q, a[q][2], node->config()))
      {
 	if(b->sname != q)
 	  doubles += 
 	    ("<p><dt><b>"+a[q][0]+"</b><dd>" +
 	     "<i>A module of the same type is already enabled ("+b->name+"). "
 	     "<a href=\"/(delete)"+ node->descend(b->name, 1)->path(1) +
	     "?" + (bar++) +"\">Disable that module</a> if you want this one "
	     "instead.</i>\n");
      } else {
	res += ("<option value=\""+q+"\">"+a[q][0]+"\n");
      }
    }
    if(strlen(doubles))
      doubles = "<dl>"+doubles+"</dl>";
    else doubles = "&nbsp;";
    res += ("</select>\n"
	    "<p><input type=submit value=\"Add Modules\"></form></td><td>"
	    + doubles);
    break;
    
   default:
    res = cif->head("Add a module")+cif->body()+"\n\n"+
      cif->status_row(node)+
      //	  display_tabular_header(node)+
      "<table><tr><td>&nbsp;<td><h2>Select a module to add "
      "from the list below. Click on it's header to add it.</h2>";
  
     
    foreach(mods, q)
    {
      if(b = module_nomore(q, a[q][2], node->config()))
      {
	if(b->sname != q)
	  res += ("<div class=\"moduleentry\"><p class=\"moduletitle\"><img alt=\"Module\" src=\"/(internal,image)/add.gif\" height=\"22\" width=\"22\"> <b>"
		  + a[q][0] + "</b> " + module_descr_icons(a[q][2]) + "<blockquote>"+a[q][1] +
		  "<p><i>A module of the same type is already enabled (" +
		  b->name + "). <a href=\"/(delete)" +
		  node->descend(b->name, 1)->path(1) + "?" + (bar++) +
		  "\">Disable that module</a> if you want this one instead</i>"
		  "\n<p></blockquote></div>\n");
      } else {
		  res += ("<div class=\"moduleentry\"><p class=\"modulename\">"
	              "<a href=\"/(addmodule)/"+node->path(1)+"?"+q+"=1\">"
		      "<img alt=\"Module\" src=\"/(internal,image)/add.gif\" border=\"0\" width=\"22\" height=\"22\">" + 
                      " <b>" + a[q][0] + 
	              "</b></a> " + module_descr_icons(a[q][2])  + "<blockquote>"+ a[q][1] +"<p></blockquote></div>\n");
      }
    }
  }
  return res+"</td></tr></table>";
}

#define PASTE(X,Y) rv+=(" <img src=\"/(internal,image)/modules/" + X + ".gif\"> ")
string module_descr_icons(int type)
{
  string rv = "";
	
  if(type&MODULE_EXPERIMENTAL) PASTE("experimental","Experimental");
  if((type&MODULE_AUTH)||(type&MODULE_SECURITY)) PASTE("security","");
  if(type&MODULE_FIRST) PASTE("first","First");
  if(type&MODULE_URL) PASTE("1stfilt","Filter");
  if(type&MODULE_PROXY) PASTE("proxy","Proxy");
  if(type&MODULE_LOCATION) PASTE("find","Location");
  if(type&MODULE_DIRECTORIES) PASTE("dir","Dir");
  if((type&MODULE_EXTENSION)||(type&MODULE_FILE_EXTENSION))
    PASTE("extension","Ext.");
  if(type&MODULE_PARSER) PASTE("tag","");
  if(type&MODULE_FILTER) PASTE("lastfilt","Filter");
  if(type&MODULE_LAST) PASTE("last","Last");
  if(type&MODULE_LOGGER) PASTE("log","Logger");
  
  return rv;	
}

//!
mapping new_module(object id, object node)
{
  string varname;
  /* since Caudium 1.4, id->variables also contains empty variables
   in HTTP request but since we are called with ?190099293 for example
   we don't want to load such a module and thus remove empty entries from
   the mapping
       /vida */
  if(!sizeof(id->variables) || !sizeof(values(id->variables)[0]))
    return stores(new_module_form(id, node));
  if(id->variables->_add_new_modules) {
    // Compact mode.
    array toadd = id->variables->_add_new_modules/"\0" - ({""});
    foreach(toadd[1..], varname)
      new_module_copy(node, varname, id);
    varname = toadd[0];
  } else
    varname = indices(id->variables)[0];
  return new_module_copy(node, varname, id);
}

string ot;
object oT;

//!
object get_template(string t)
{
  t-=".pike";
  if(ot==t) return oT; ot=t;
  return (oT = compile_file("server_templates/"+t+".pike")());
}

//!
int check_config_name(string name)
{
  if(strlen(name) && name[-1] == '~') name = "";
  if(search(name, "/")!= -1) return 1;
  
  foreach(caudium->configurations, object c)
    if(lower_case(c->name) == lower_case(name))
      return 1;

  switch(name) {
   case " ": case "\t": case "CVS":
   case "Global Variables": case "global variables": case "Global variables":
    return 1;
  }
  return !strlen(name);
}

//!
int low_enable_configuration(string name, string type)
{
  object node;
  object o, o2, confnode;
  array(string) arr = replace(type,"."," ")/" ";
  object template;
  if(check_config_name(name)) return 0;
  
  if((type = lower_case(arr[0])) == "copy")
  {
    string from;
    mapping tmp;
    if ((sizeof(arr) > 1) &&
	(sscanf(arr[1..]*" ", "%*s'%s'", from) == 2) &&
	(tmp = caudium->copy_configuration(from, name)))
    {
      tmp["spider#0"]->LogFile = GLOBVAR(logdirprefix) + "/" +
	Caudium.short_name(name) + "/Log";
      caudiump()->save_it(name);
      caudium->enable_configuration(name);
    }
  } else
    (template = get_template(type))->enable(caudium->enable_configuration(name));

  confnode = root->descend("Configurations");
  node=confnode->descend(name);
  
  node->describer = describe_configuration;
  node->saver = save_configuration;
  node->data = caudium->configurations[-1];
  node->type = NODE_CONFIGURATION;
  build_configuration(node);
  node->folded=0;
  node->change(1);
  
  if(template && template->post)
    template->post(node);
  
  if(o = node->descend( "Global", 1 )) {
    o->folded = 0;
    if(o2 = o->descend( "Listen ports", 1 )) {
      o2->folded = 0;
      o2->change(1);
    }
  }
  
  if(o = node->descend( "Filesystem", 1 )) {
    o->folded=0;
    if(o = o->descend( "0", 1)) {
      o->folded=0;
      if(o2 = o->descend( "Search path", 1)) {
	o2->folded=0;
	o2->change(1);
      }
      if (o2 = o->descend("Handle the PUT method", 1)) {
	o2->folded = 0;
	o2->change(1);
      }
    }
  }
  return 1;
}

//!
mapping new_configuration(object id)
{
  if(!sizeof(id->variables - id->empty_variables))
    return stores(new_configuration_form());
  if(id->variables->no)
    return Caudium.HTTP.redirect(CONFIG_URL+id->not_query[1..]+"?"+bar++);
  
  if(!id->variables->name)
    return stores(cif->head("Bad luck") + cif->body() +
		  "<blockquote><h1>No configuration name?</h1>"
		  "Either you entered no name, or your WWW-browser "
		  "failed to include it in the request</blockquote>");
  
  id->variables->name=(replace(id->variables->name,"\000"," ")/" "-({""}))*" ";
  if(!low_enable_configuration(id->variables->name, id->variables->type))
    return stores(cif->head("Bad luck") + cif->body() +
		  "<blockquote><h1>Illegal configuration name</h1>"
		  "The name of the configuration must contain characters"
		  " other than space and tab, it should not end with "
		  "~, and it must not be 'CVS', 'Global Variables' or "
		  "'global variables', nor the name of an existing "
		  "configuration, and the character '/' cannot be included</blockquote>");
  return std_redirect(root->descend("Configurations"), id);
}

//!
int conf_auth_ok(object id)
{
  mixed u = id->get_user();
  if(!u)
    return 0;

  id->misc->cif_username = u->username;
  if(u->superuser) id->misc->cif_superuser = 1;
  return 1;  
}

//!
mapping initial_configuration(object id)
{
  object n2;
  string res, error;

  if(id->variables->nope)
    return std_redirect(root, id);
    
  
  if(id->prestate->initial && id->variables->pass)
  {
    error="";
    if(id->variables->pass != id->variables->pass2)
      error = "You did not type the same password twice.\n";
    if(!strlen(id->variables->pass))
      error += "You must specify a password.\n";
    if(!strlen(id->variables->user))
      error += "You must specify a username.\n";
    if(!strlen(error))
    {
      object node;
/*    build_root(root);*/
     
      // Should find the real node instead of assuming 'Globals'...
      node = find_node("/Globals");
      node->folded=0;
      node->change(1);
      
      if(!node)
	return stores("Fatal configuration error, no 'Globals' node found.\n");
      
      caudium->QUERY(ConfigurationPassword) = crypt(id->variables->pass);
      caudium->QUERY(ConfigurationUser) = id->variables->user;

      n2 = node->descend("Configuration interface", 1)->descend("Password", 1);
      n2->data[VAR_VALUE]=caudium->QUERY(ConfigurationPassword);
      n2->change(1);	

      n2 = node->descend("Configuration interface", 1)->descend("User", 1);
      n2->data[VAR_VALUE] = caudium->QUERY(ConfigurationUser);
      n2->change(1);	
	
      root->save();
      return std_redirect(root, id);
    }
  }
  
  res = cif->head("Welcome to Caudium " +
		     caudium->__caudium_version__ + "." + caudium->__caudium_build__);

  res += cif->body();

  res += Stdio.read_bytes("etc/welcome.html");
  if(error && strlen(error))
    res += "<blockquote>\n<p><b>"+error+"</b>";
  
  res += ("<table border=0 bgcolor=black><tr><td><table cellspacing=0 border=0 cellpadding=3 bgcolor=#e0e0ff>"
	  "<tr><td colspan=2><center><h1>Please complete this form.</h1></center>"
	  "</td></tr>"
	  "<form action=\"/(initial)/Globals/\">"
	  "<tr><td align=right>User name</td><td><input name=user type=string></td></tr>\n"
	  "<tr><td align=right>Password</td><td><input name=pass type=password></td></tr>\n"
	  "<tr><td align=right>Again</td><td><input name=pass2 type=password></td></tr>\n"
//   Avoid this trap for people who like to shoot themselves in the foot.
//   /Peter
//	  "IP-pattern <input name=pattern type=string>\n"
	  "<tr><td align=left><input type=submit value=\" Ok \">\n</td>"
	  "<td align=right><input type=submit name=nope value=\" Cancel \"></td></tr>\n"
	  "</form></table></table></blockquote>");
  
  res += "</body></html>";
  
  return stores(res);
}

//!
object module_of(object node)
{
  while(node)
  {
    if(node->type == NODE_MODULE_COPY)
      return node->data;
    if(node->type == NODE_MODULE_MASTER_COPY)
      return node->data->master;
    if(node->type == NODE_CONFIGURATION)
      return node->data;
    node = node->up;
  }
  return caudium;
}

//!
string extract_almost_top(object node)
{
  if(!node) return "";
  for(;node && (node->up!=root);node=node->up);
  if(!node) return "";
  return node->path(1);
}

//!
mapping (string:string) selected_nodes =
([
  "Configurations":"/Configurations",
  "Globals":"/Globals",
  "Accounts": "/Accounts",
  "Errors":"/Errors",
  "Actions":"/Actions",
#ifdef ENABLE_MANUAL
  "Docs":"/Docs"
#endif /* ENABLE_MANUAL */
]);

//!
array tabs = ({
  "Configurations",
  "Globals",
  "Accounts",
  "Errors",
  "Actions",
#ifdef ENABLE_MANUAL
  "Docs",
#endif /* ENABLE_MANUAL */
});

//!
array tab_names = ({
 "Virtual Servers",
 "Global Variables",
 "Accounts",
 "Event Log",
 "Actions",
#ifdef ENABLE_MANUAL
 "Manual",
#endif /* ENABLE_MANUAL */
});
		

//!
string display_tabular_header(object node)
{
  string s;
  
  array links = Array.map(tabs, lambda(string q) {
    return selected_nodes[q]+"?"+(bar++);
  });

  if(node != root)
  {
    s = extract_almost_top(node) - "/";
    selected_nodes[s] = node->path(1);

    links[search(tabs,s)]="/"+s+"/"+"?"+(bar++);
  }
  return cif->tablist(tab_names, links, search(tabs,s));
}

//! Return the number of unfolded nodes on the level directly below the passed
//! node.
int nunfolded(object o)
{
  int i;
  if(o = o->down)
    do { i+=!o->folded; } while(o=o->next);
  return i;
}


object module_font = get_font("base_server/config/font",0,0,0,"left",1.0,1.0);
object button_font = get_font("base_server/config/button_font",0,0,0,"left",1.0,1.0);
mapping(string:object) my_colortable = ([]);

//!
mapping auto_image(string in, object id)
{
  string key, value, imgext;
  array trans = ({ (int)("0x"+dR),(int)("0x"+dG),(int)("0x"+dB) });
  mixed e;
  object i;

  // if we have both PNG and GIF support we prefer PNG
  // GIF is just a fallback
  imgext = "";
#if constant(Image.PNG.encode)
  imgext = ".png";
#endif
#if constant(Image.GIF.encode) && !constant(Image.PNG.encode)
  imgext = ".gif";
#endif

  if (imgext == "")
     return 0; /* no img format we support */

  string img_key = "auto/"+cif->theme()+"_"+replace(in,"/","_")+imgext-" ";
  
  if(string tmp = cache->retrieve(img_key))
    return ([ "data": tmp, "type":"image/" + imgext[1..], ]);
  
  if(!sscanf(in, "%s/%s", key, value)) key=in;

  switch(key)
  {
   case "module":
     sscanf(value, "%*d/%s", value);
     i = draw_module_header(caudium->allmodules[value][0],
			    caudium->allmodules[value][2],
			    module_font);
     break;
    
   case "button":
     int lm,rm;
     if(sscanf(value, "lm/%s", value)) lm=1;
     if(sscanf(value, "rm/%s", value)) rm=1;
     i=draw_config_button(value,button_font,lm,rm,
			  cif->s->rgb_colour("titlebg"),
			  cif->s->rgb_colour("titlefg"),
			  cif->s->rgb_colour("bgcolor"));
     break;

   case "fold":
   case "fold2":
     i = draw_fold((int)reverse(key), cif->s);
     break;
    
   case "unfold":
   case "unfold2":
     i = draw_unfold((int)reverse(key), cif->s);
     break;

   case "back":
     i = draw_back((int)reverse(key), cif->s);
     break;
    
   case "selected":
     i=draw_selected_button(value,button_font);
     break;

   case "unselected":
     i=draw_unselected_button(value,button_font);
     break;

  case "tab0":
      i=cif->tab_0();
      break;

  case "tab1":
      i=cif->tab_1();
      break;

  case "tab2":
      i=cif->tab_2();
      break;

  case "tab3":
      i=cif->tab_3();
      break;

  case "tab4":
      i=cif->tab_4();
      break;

  case "tab5":
      i=cif->tab_5();
      break;

  case "cif_logo":
      i=cif->logo();
      break;

  }

  if (!i) return 0;

#if constant(Image.PNG.encode)
  e=Image.PNG.encode(i);
#endif

#if constant(Image.GIF.encode) && !constant(Image.PNG.encode)
  e=Image.GIF.encode(i);
#endif
 cache->store(cache_string(e, img_key, -1));

#if constant(Image.PNG.encode) && !constant(Image.GIF.encode)
  return Caudium.HTTP.string_answer(e,"image/png");
  #endif

#if constant(Image.GIF.encode)
  return Caudium.HTTP.string_answer(e,"image/gif");
#endif

  return 0;
}


//!
string remove_font(string t, mapping m, string c)
{
  return "<b>"+c+"</b>";
}

//!
int nfolded(object o)
{
  int i;
  if(o = o->down)
    do { i+=!!o->folded; } while(o=o->next);
  return i;
}

//!
int nfoldedr(object o)
{
  object node;
  int i;
  i = o->folded;
  node=o->down;
  while(node)
  {
    i+=nfoldedr(node);
    node=node->next; 
  }
  return i;
}

//!
string dn(object node)
{
  if(!node) return "???";
  string s = sizeof(node->_path)?node->_path[-1]:" ";
  if(((string)((int)s))==s)
    return "Instance "+s;
  switch(s)
  {
   case "Globals":
    return "Global Variables";
   case "Configurations":
    return "Servers";
   case "Accounts":
    return "Accounts";
   case "Errors":
    return "Event Log";
  }
  return s;
}

//!
mapping logged = ([ ]);

//!
void check_login(object id)
{
  if(logged[id->remoteaddr] + 1000 < time()) {
    report_notice("Administrator logged on from " +
		  caudium->blocking_ip_to_host(id->remoteaddr) + ".\n");
  }
  logged[id->remoteaddr] = time(1);
}

//!
mapping configuration_parse(object id)
{
  array (string) res=({});
  mixed          tmp;
  string         varval = 0;
  
  // Is it an image?
  if(sscanf(id->not_query, "/image/%s", tmp))
    return file_image(tmp) || (["data":"No such image"]);

  // Serve favicon.ico
  if(id->not_query == "/favicon.ico")
    return file_image("favicon.ico") || ([ "data":"No favicon available" ]);
  
  object o;
  int i;

  id->since = 0; // We do not want 'get-if-modified-since' to work here.

  
  // Permission denied by userid?
  if(!id->misc->read_allow)
  {
    if(!conf_auth_ok(id))
      return Caudium.HTTP.auth_required("Caudium maintenance"); // Denied
  } else {
    
    id->prestate = aggregate_multiset(@indices(id->prestate)
                                      &({"fold","unfold"}));

    if(sizeof(id->variables)) // This is not 100% neccesary, really.
      id->variables = ([ ]);
  }

  // Automatically generated image?
  if(sscanf(id->not_query, "/auto/%s", tmp))
    return auto_image(tmp,id) || (["data":"No such image"]);

  o = find_node(id->not_query); // Find the requested node (from the filename)
  
  if(!o) // Bad node, perhaps an old bookmark or something.
  {
    id->referrer = 0;
    foreach(indices(selected_nodes), string n)
      if(selected_nodes[n] == id->not_query)
        selected_nodes[n] = "/"+n;
    return std_redirect(0, id);
  } else if(o == root) {
    // The URL is http://config-url/, not one of the top nodes, but
    // _above_ them. This is supposed to be some nice introductory
    // text about the configuration interface...

    // We also need to determine wether this is the full or the
    // lobotomized international version.
    return Caudium.HTTP.string_answer(cif->head("Caudium " +
                                        caudium->__caudium_version__ + "." +
                                        caudium->__caudium_build__)+
                              cif->body() +
                              cif->status_row(root)+
                              display_tabular_header(root)+
                              replace(Stdio.read_bytes("etc/config.html"), "$version", __caudium_version__+"."+__caudium_build__), "text/html");
  }

  // ok, we should do some permission checking at this point.
  // if the user is a "superuser", we short circuit things and just let 'em through.
  // otherwise, we act accordingly.
  if(!id->misc->cif_superuser)	
  {
	// first, we see where we are.
    object mn = o;
    while(!(<NODE_CONFIGURATION, NODE_CONFIGURATIONS, NODE_ERRORS, NODE_ACCOUNTS, NODE_WIZARDS, NODE_GLOBAL_VARIABLES>)[mn->type])
    {
	  mn = mn->up;
    }
    switch(mn->type)
    {
	  case NODE_CONFIGURATIONS:
	  case NODE_ERRORS:
	  case NODE_WIZARDS:
	  case NODE_GLOBAL_VARIABLES:
	    // users can see the configurations page, but we're read-only.
	    id->misc->read_only = 1;
		break;
	  case NODE_ACCOUNTS:
            if(!is_superuser(id->misc->cif_username))
		return Caudium.HTTP.string_answer("Error: you are not permitted to view this configuration.\n");
	  case NODE_CONFIGURATION:
	    mn = mn->descend("Global");
	    mn = mn->descend("AdminUsers");
	    if(mn && mn->data[0] && sizeof(mn->data[0]) && (search((mn->data[0]/"\n"), id->misc->cif_username)!=-1))
        {
			int stop;
			object mn2 = o;
			mn = mn->up; // should be "Global"
			// we're a valid user; but we should make sure that we're not setting anything in the "globals" section.
			do
			{
			  if(mn2 == mn)
			  { 
			    id->misc->read_only = 1;
			    stop = 1;
			  }
			  else mn2 = mn2->up;
			} while(mn2 && !stop);
        }
        else
        {
			return Caudium.HTTP.string_answer("Error: you are not permitted to view this configuration.\n");
        }
    }
  }

  if(sizeof(id->prestate))
  {
    object mod;

    // this is dumb - why restrict to just one prestate? /grendel
    switch(indices(id->prestate)[0])
    {
      // It is possible to mark variables as 'VAR_EXPERT', this
      // will make it impossible to configure them whithout the
      // 'expert' mode. It can be useful.
        case "expert":   expert_mode = 1;  break;
        case "noexpert": expert_mode = 0;  break;

        case "morevars":   more_mode = 1; save_more_mode(); break;
        case "nomorevars": more_mode = 0; save_more_mode(); break;
      
          // Fold and unfold nodes, this is _very_ simple, once all the
          // supporting code was writte.
        case "fold":     o->folded=1;      break;
        case "unfold":   o->folded=0;      break;

        case "moredocs":   o->moredocs=1;      break;
        case "lessdocs":   o->moredocs=0;      break;

        case "foldall":
          o->map(lambda(object o) {	o->folded=1; });
          break;


        case "unfoldmodified":
          o->map(lambda(object o) { if(o->changed) o->folded=0; });
          break;


          // There is no button for this in the configuration interface,
          // the results are quite horrible, especially when applied to
          // one of the top nodes.
        case "unfoldall":
          o->map(lambda(object o) { o->folded=0; });
          break;

        case "unfoldlevel":
          object node;
          node=o->down;
          while(node)
          {
            node->folded=0;
            node = node->next;
          }
          break;

      
          // And now the actual actions..
      
          // Re-read a module from disk
          // This is _not_ as easy as it sounds, since quite a lot of
          // caches and stuff have to be invalidated..
        case "refresh":
        case "reload":
          string name, modname;
          mapping cmod;
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          mod = module_of(o);
          if(!mod || mod==caudium || object_program(mod) == caudium->Configuration)
            error("This module cannot be updated.\n");
          name = module_short_name(mod, o->config());
          if(!name)
            error("This module cannot be updated");
          sscanf(name, "%s#%*s", modname);

          if(!(cmod = o->config()->modules[ modname ]))
            error("This module cannot be updated");
      
          o->save();
          program oldprg = cache_lookup ("modules", modname);
          mapping oldprgs = copy_value (master()->programs);
          cache_remove("modules", modname);

          if(!o->config()->load_module(modname))
          {
            mapping rep;
            rep = Caudium.HTTP.string_answer("The reload of this module failed.\n"
                                     "This is (probably) the reason:\n<pre>"
                                     + caudium->last_error + "</pre>" );
            return rep;
          }
          program newprg = cache_lookup ("modules", modname);
          if(!o->config()->disable_module(name)) {
            mapping rep;
            rep = Caudium.HTTP.string_answer("Failed to disable this module.\n"
                                     "This is (probably) the reason:\n<pre>"
                                     + caudium->last_error + "</pre>" );
            return rep;
          }
          cache_set ("modules", modname, newprg, 21600); // Do not compile again in enable_module.
          if(!(mod=o->config()->enable_module(name))) {
            mapping rep;
            rep = Caudium.HTTP.string_answer("Failed to enable this module.\n"
                                     "This is (probably) the reason:\n<pre>"
                                     + caudium->last_error + "</pre>" );
            // Recover..
            master()->programs = oldprgs;
            cache_set ("modules", modname, oldprg, 21600);
#ifdef MODULE_DEBUG
            perror ("Modules: Trying to re-enable the old module.\n");
#endif
            o->config()->enable_module(name);
            return rep;
          }

          o->clear();
//    caudium->fork_it();
      
          if(mappingp(o->data))
          {
            o->data = o->config()->modules[modname];
            build_module(o);
          } else {
            object n = o->up;
            n->clear();
            n->data = n->config()->modules[modname];
            build_module(n);
          }
          break;
      
          /* Shutdown Caudium... */
        case "shutdown":	
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          return caudium->shutdown();
      
          /* Restart Caudium, somewhat more nice. */
        case "restart":	
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          return caudium->restart();
      
          /* Rename a configuration. Not Yet Used... */
#if 0
        case "rename":
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          if(o->type == NODE_CONFIGURATION)
          {
            mv("configurations/"+o->data->name, 
               "configurations/"+id->variables->name);
            o->data->name=id->variables->name;
          }
          break;
#endif /* 0 */
      
          /* Clear any memory caches associated with this configuration */
        case "zapcache":
          object c = o->config();
          if (c && c->clear_memory_caches)
          {
            c->clear_memory_caches();
          }
          break;

          /* This only asks "do you really want to...", it does not delete
           * the node */
        case "delete":	
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          PUSH(cif->head("Caudium Configuration")+cif->body()+
               cif->status_row(o));
//     PUSH("<hr noshade>");
       
          switch(o->type)
          {
              case NODE_CONFIGURATION:
                if(o->data->name =="ConfigurationInterface")
                {
                  PUSH("<font size=\"+2\">The Configuration Interface server cannot be deleted."
                     "\n\n<p></font>");
                  return stores(res*"");
                }
		else 
                  PUSH("<font size=\"+2\">Do you really want to delete the configuration "+
                     o->data->name + ", all its modules and their copies?"
                     "\n\n<p></font>");
                break;
	
              case NODE_MODULE_MASTER_COPY:
              case NODE_MODULE:
                PUSH("<font size=\"+2\">Do you really want to delete the module "+
                     o->data->name + ", and its copies?\n\n<p></font>");
                break;
	
              case NODE_MODULE_COPY_VARIABLES:
	
              case NODE_MODULE_COPY:
                PUSH("<font size=\"+2\">Do you really want to delete this copy "
                     " of the module "+ o->up->data->name + "?\n\n<p></font>");
                break;
	
              case NODE_CONFIGURATIONS:
                return stores("You don't want to do that...\n");
          }
          PUSH("<blockquote><font size=\"+2\"><i>This action cannot be"
               " undone.\n\n<p></font>"+ TABLEP("<table>", "")+
               "<tr><td><form action=\""+ o->path(1)+"\">"
               "<input type=submit value=\"No, I do not want to delete it\"> "
               "</form></td><td><form action=\"/(really_delete)"+ o->path(1)+
               "\"><input type=submit value=\"Go ahead\"></form></td></tr> "
               "</table></blockquote>");
      
          return stores(res*"");
          break;
      
          /* When this has been called, the node will be * _very_ deleted
           * The amount of work needed to delete a node does vary
           * depending on the node, since there is no 'zap' function in
           * the nodes at the moment. I will probably move this code into
           * function-pointers in the nodes.
           */

        case "really_delete":
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          id->referrer = CONFIG_URL + o->up->path(1);
      
          switch(o->type)
          {
              case NODE_CONFIGURATION:
                for(i=0; i<sizeof(caudium->configurations); i++)
                  if(caudium->configurations[i] == o->data)
                    break;
	
                if(i==sizeof(caudium->configurations))
                  error("Configuration not found.\n");
	
                if(o->data->name =="ConfigurationInterface")
                  throw(Error.Generic("ConfigurationInterface cannot be deleted.\n"));
                caudium->remove_configuration(o->data->name);

                if(caudium->configurations[i]->ports_open)
                  Array.map(values(caudium->configurations[i]->ports_open), destruct);
                destruct(caudium->configurations[i]);
	
                caudium->configurations = 
                  caudium->configurations[..i-1] + caudium->configurations[i+1..];
	
                o->change(-o->changed);
                o->dest();
                break;
	
              case NODE_MODULE_COPY_VARIABLE:
              case NODE_MODULE_COPY_VARIABLES:
                // Ehum? Lets zap the module instead of it's variables...
                o=o->up;
	
              case NODE_MODULE_COPY:
                string name;
                object n;
	
                name = module_short_name(o->data, o->config());
                o->config()->disable_module(name);
                // Remove the suitable part of the configuration file.
                caudium->remove(name, o->config());
                o->change(-o->changed);
                n=o->up;
                o->dest();
	
                if(!objectp(n))
                {
                  o=root; 
                  // Error, really, no parent module for this module class.
                } else {
                  if(!sizeof(n->data->copies))
                  {
                    // No more instances in this module, let's zap the whole class.
                    o=n->up; 
	    
                    n->change(-n->changed);
                    n->dest();
                    build_configuration(o);
                    return std_redirect(o, 0); 
                  } else
                    o = n;
                }
                break;
	
              case NODE_MODULE_MASTER_COPY:
              case NODE_MODULE:
                if(o->data->copies)
                {
                  if(sizeof(o->data->copies))
                  {
                    int i;
                    array a,b;
                    a=indices(o->data->copies);
                    b=values(o->data->copies);
                    name=o->config()->otomod[b[0]];
                    i=sizeof(a);
                    while(i--) 
                    {
                      o->config()->disable_module(name+"#"+a[i]);
                      caudium->remove(name+"#"+a[i], o->config());
                    }
                  } else if(o->data->master) {
                    name=o->config()->otomod[o->data->enabled];
                  } 
                } else if(o->data->enabled) {
                  name=o->config()->otomod[o->data->enabled];
                  o->config()->disable_module(name+"#0");
                  caudium->remove(name+"#0", o->config());
                }
                o->change(-o->changed);
                o->dest();
                break;
          }
          break;


          // Create a new configuration. All the work is done in another
          // function.. This _should_ be the case with some of the other
          // actions too.
        case "newconfig":
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          id->referrer = CONFIG_URL + o->path(1);
          return new_configuration(id);


          // When a port has been changed the admin is prompted to
          // change the server URL. This is where we come when we are
          // done.
       
        case "modify_server_url":
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");

          string srv, url;
          object thenode;
          foreach(indices(id->variables), string var)
          {
            if(sscanf(var, "%s->own", srv)) {
              url = id->variables[srv] == "own" ?
                id->variables[var] : id->variables[srv];
              if(srv == "Global Variables")
                thenode = find_node("/Globals/Configuration interface/URL");
              else {
                thenode = find_node("/Configurations/"+srv+
                                    "/Global/MyWorldLocation");
              }
              if(thenode) {
                thenode->data[VAR_VALUE] = url;
                thenode->change(1);
                thenode->up->save();
              } else {
                report_debug(sprintf("Attempt to set the Server URL for "
                                     "a non-existent server \"%s\".\n", srv));
              }
            }
          }
          id->referrer = CONFIG_URL + o->path(1);
          break;
          // Save changes done to the node 'o'. Currently 'o' is the root
          // node most of the time, thus saving _everything_.
        case "save":
          mapping cf;
          if(cf = save_it(id, o))
            return cf;
          break;


          // Set the password and username, the first time, or when
          // the action 'changepass' is requested.
        case "initial":
        case "changepass":
          return initial_configuration(id);
      

          // Hmm. No idea, really. Beats me :-)  /Per
        case "new":
          if(!id->misc->cif_superuser) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          o->new();
          break;

          // Add a new module to the current configuration.
        case "newmodule": // For backward compatibility
        case "addmodule":
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          id->referrer = CONFIG_URL + o->path(1);
          return new_module(id,o);


          // Add a new copy of the current module to the current configuration.
        case "newmodulecopy":
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          id->referrer = CONFIG_URL + o->path(1);
          new_module_copy_copy(o, id);
          break;


          // Set a variable to a new (or back to an old..) value.
        case "set":
          if(id->misc->read_only) return Caudium.HTTP.string_answer("Error: you are not permitted to perform this action.\n");
          o->error = 0;
          if (!varval)
            varval = values(id->variables)[0];
          
          if(sizeof(id->variables))
            tmp=decode_form_result(varval,o->data[VAR_TYPE], o, id->variables);
          else
            tmp=0;
          if(!module_of(o)) perror("No module for this node.\n");
          if(!o->error && module_of(o) 
             && module_of(o)->check_variable)
            o->error = module_of(o)->check_variable(o->data[VAR_SHORTNAME], tmp);
	
          if(!o->error)
            if(!equal(tmp, o->data[VAR_VALUE]))
            {
              if(!o->original)
                o->original = o->data[VAR_VALUE];
              o->data[VAR_VALUE]=tmp;
              if(equal(o->original, tmp))
                o->change(-1);
              else if(!o->changed)
                o->change(1);
            } 
          break;
    }
  
// netcraft  
//      save_it(id, o);
    
    return std_redirect(o, id);
  }

  check_login(id);
  
  PUSH(cif->head("Caudium configuration v" +
                 (string)caudium->__caudium_version__ + "." +
                 (string)caudium->__caudium_build__)+cif->body());
//  PUSH("<table><tr><td>&nbsp;<td>"
  PUSH("<dl>\n");
  PUSH("\n"+cif->status_row(o)+"\n"+display_tabular_header( o )+"\n");
  PUSH("<p>");
  if(o->up != root && o->up)
    PUSH("<a href=\""+ o->up->path(1)+"?"+(bar++)+"\">"
         "<img src=/auto/back alt=\"[Up]\" align=left hspace=0 border=0></a>\n");

  if(i=o->folded) o->folded=0;
  tmp = o->describe(1,id);
  if(mappingp(tmp)) return tmp;
  if(!id->supports->font)
    tmp = Caudium.parse_html(tmp, ([]),(["font":remove_font, ]));
  PUSH("<dl><dt>");
  PUSH(tmp);
  PUSH("</dl>");
  o->folded=i;
  
  PUSH("<p><br clear=all>&nbsp;\n");

  int lm=1;
  array(mixed) buttons = ({});
  
  if(o->type == NODE_CONFIGURATIONS && id->misc->cif_superuser)
    BUTTON(newconfig, "New virtual server", left);
  
  if(o->type == NODE_CONFIGURATION)
    BUTTON(addmodule, "Add module", left);
  
  if(o->type == NODE_MODULE)
  {
    BUTTON(delete, "Delete module", left);
    if(o->data->copies)
      BUTTON(newmodulecopy, "Copy module", left);
  }

  i=0;
  if(o->type == NODE_MODULE_MASTER_COPY || o->type == NODE_MODULE_COPY 
     || o->type == NODE_MODULE_COPY_VARIABLES)
  {
    BUTTON(delete, "Delete module", left);
    if(more_mode)
      BUTTON(refresh, "Reload module", left);
  }
  
  if(o->type == NODE_CONFIGURATION && id->misc->cif_superuser &&
    o->data->name !="ConfigurationInterface")
    BUTTON(delete,"Delete this server", left);

  if(nunfolded(o))
    BUTTON(foldall, "Fold all",left);
  if(o->changed)
    BUTTON(unfoldmodified, "Unfold modified", left);

  if(nfolded(o))
    BUTTON(unfoldlevel, "Unfold level", left);
//  else if(nfoldedr(o))
//    BUTTON(unfoldall, "Unfold all", left);

  PUSH_BUTTONS(1);

  if (more_mode) {
    BUTTON(zapcache, "Clear module caches", left);
  }

  if(!more_mode)
    BUTTON(morevars, "More options", left);
  else
    BUTTON(nomorevars, "Fewer options", left);
    
  if((o->changed||root->changed))
    BUTTON(save, "Save", left);
  if(expert_mode && id->misc->cif_superuser) {
    BUTTON(restart, "Restart", left);
    BUTTON(shutdown,"Shutdown", left);
  }

  PUSH_BUTTONS(0);

//  PUSH("<br clear=all>");
//  PUSH("<p align=right><font size=-1 color=blue><a href=\"$docurl\"><font color=blue>"+caudium->real_version +"</font></a></font></p>");
//  PUSH("</table>");
  PUSH("</body>\n");
  return stores(res*"");
}

int is_superuser(string username)
{
  return 1;
}

/*
 * Local Variables:
 * c-basic-offset: 2
 * End:
 */
