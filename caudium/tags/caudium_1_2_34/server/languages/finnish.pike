/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2004 The Caudium Group
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
 */

/* Created by Janne Edelman, Turku Unix Users Group ry, Turku, Finland
string cvs_version = "$Id$";
   http://www.tuug.utu.fi/~edelman/ or http://website.tuug.utu.fi/ 
   */
/*
 * name = "Finnish language plugin ";
 * doc = "Handles the conversion of numbers and dates to finnish. You have to restart the server for updates to take effect. Translation by Janne Edelman, Turku Unix Users Group ry, Turku, Finland";
 */

string month(int num)
{
  return ({ "tammikuu", "helmikuu", "maaliskuu", "huhtikuu", "toukokuu",
	    "kes�kuu", "hein�kuu", "elokuu", "syyskuu", "lokakuu",
	    "marraskuu", "joulukuu" })[ num - 1 ];
}

string ordered(int i)
{
  return i+".";
}

string date(int timestamp, mapping|void m)
{
  mapping t1=localtime(timestamp);
  mapping t2=localtime(time(0));

  if(!m) m=([]);

  if(!(m["full"] || m["date"] || m["time"]))
  {
    if(t1["yday"] == t2["yday"] && t1["year"] == t2["year"])
      return "t�n��n, " + ctime(timestamp)[11..15];
  
    if(t1["yday"]+1 == t2["yday"] && t1["year"] == t2["year"])
      return "eilen, "+ ctime(timestamp)[11..15];
  
    if(t1["yday"]-1 == t2["yday"] && t1["year"] == t2["year"])
      return "huomenna, "+ ctime(timestamp)[11..15];
  
    if(t1["year"] != t2["year"])
      return (month(t1["mon"]+1) + " " + (t1["year"]+1900));
    return (ordered(t1["mday"]) + " " + month(t1["mon"]+1) + "ta");
  }
  if(m["full"])
    return ctime(timestamp)[11..15]+", "+
           ordered(t1["mday"]) + ordered(t1["mon"]+1) +
           (t1["year"]+1900);
  if(m["date"])
    return ordered(t1["mday"]) + " " + month(t1["mon"]+1) + "ta"  + 
      " " + (t1["year"]+1900);
  if(m["time"])
    return ctime(timestamp)[11..15];
}


string number(int num)
{
  if(num<0)
    return "minus "+number(-num);
  switch(num)
  {
   case 0:  return "nolla";
   case 1:  return "yksi";
   case 2:  return "kaksi";
   case 3:  return "kolme";
   case 4:  return "nelj�";
   case 5:  return "viisi";
   case 6:  return "kuusi";
   case 7:  return "seitsem�n";
   case 8:  return "kahdeksan";
   case 9:  return "yhdeks�n";
   case 10: return "kymmenen";
   case 11: return "yksitoista";
   case 12: return "kaksitoista";
   case 13: return "kolmetoista";
   case 14: return "nelj�toista";
   case 15: return "viisitoista";
   case 16: return "kuusitoista";
   case 17: return "seitsem�ntoista";
   case 18: return "kahdeksantoista";
   case 19: return "yhdeks�ntoista";
   case 20: case 30: case 40: 
   case 50: case 60: case 70: 
   case 80: case 90:
     return number(num/10)+"kymment�";
   case 21..29: case 31..39: 
   case 51..59: case 61..69: case 71..79: 
   case 81..89: case 91..99: case 41..49: 
     return number((num/10)*10)+number(num%10);
   case 100..199: return "sata"+number(num%100);
   case 200..999: return number(num/100)+"sataa"+number(num%100);
   case 1000..1999: return number(num/1000)+" tuhat"+number(num%1000);
   case 2000..999999: return number(num/1000)+" tuhatta"+number(num%1000);
   case 1000000..1999999: 
     return number(num/1000000)+"miljoona"+number(num%1000000);
   case 2000000..999999999: 
     return number(num/1000000)+"miljoonaa"+number(num%1000000);
   default:
    return "paljon";
  }
}

string day(int num)
{
  return ({ "Sunnuntai","Maanantai","Tiistai","Keskiviikko",
	    "Torstai","Perjantai","Lauantai" })[ num - 1 ];
}

array aliases()
{
  return ({ "fi", "fin", "finnish" });
}
