
constant h2c =
([
  "&lt;":"<", "&gt;":">", "&amp;":"&",
  "&nbsp;": "�", "&iexcl;": "�", "&cent;": "�", "&pound;": "�",
  "&curren;": "�", "&yen;": "�", "&brvbar;": "�", "&sect;": "�",
  "&uml;": "�", "&copy;": "�", "&ordf;": "�", "&laquo;": "�",
  "&not;": "�",  "&quot;": "\"", "&shy;": "�", "&reg;": "�", "&macr;": "�",
  "&deg;": "�",  "&plusmn;": "�", "&sup2;": "�", "&sup3;": "�",
  "&acute;": "�",  "&micro;": "�", "&para;": "�", "&middot;": "�",
  "&cedil;": "�",  "&sup1;": "�", "&ordm;": "�", "&raquo;": "�",
  "&frac14;": "�",  "&frac12;": "�", "&frac34;": "�", "&iquest;": "�",
  "&Agrave;": "�",  "&Aacute;": "�", "&Acirc;": "�", "&Atilde;": "�",
  "&Auml;": "�",  "&Aring;": "�", "&AElig;": "�", "&Ccedil;": "�",
  "&Egrave;": "�",  "&Eacute;": "�", "&Ecirc;": "�", "&Euml;": "�",
  "&Igrave;": "�",  "&Iacute;": "�", "&Icirc;": "�", "&Iuml;": "�",
  "&ETH;": "�",  "&Ntilde;": "�", "&Ograve;": "�", "&Oacute;": "�",
  "&Ocirc;": "�",  "&Otilde;": "�", "&Ouml;": "�", "&times;": "�",
  "&Oslash;": "�",  "&Ugrave;": "�", "&Uacute;": "�", "&Ucirc;": "�",
  "&Uuml;": "�",  "&Yacute;": "�", "&THORN;": "�", "&szlig;": "�",
  "&agrave;": "�",  "&aacute;": "�", "&acirc;": "�", "&atilde;": "�",
  "&auml;": "�",  "&aring;": "�", "&aelig;": "�", "&ccedil;": "�",
  "&egrave;": "�",  "&eacute;": "�", "&ecirc;": "�", "&euml;": "�",
  "&igrave;": "�",  "&iacute;": "�", "&icirc;": "�", "&iuml;": "�",
  "&eth;": "�",  "&ntilde;": "�", "&ograve;": "�", "&oacute;": "�",
  "&ocirc;": "�",  "&otilde;": "�",   "&ouml;": "�", "&divide;": "�",
  "&oslash;": "�", "&ugrave;": "�",  "&uacute;": "�", "&ucirc;": "�",
  "&uuml;": "�", "&yacute;": "�",  "&thorn;": "�", "&yuml;": "�",
  "&apos;": "'"
]); 

string trim(string s)
{
  return replace(String.trim_whites(s), indices(h2c), values(h2c));
}
