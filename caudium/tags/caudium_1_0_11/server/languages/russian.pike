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

/* Bugs by: Per */
/*
 * name = "Russian language plugin ";
 * doc = "Handles the conversion of numbers and dates to Russian. You have to restart the server for updates to take effect.";
 */

string cvs_version = "$Id$";

#define error(x) throw( ({ x, backtrace() }) )

string month(int num)
{
  return ({ "������", "�������", "����", "������", "���",
	      "����", "����", "�������", "��������", "������",
	      "������", "�������" })[num - 1];
}

string day(int num)
{
  return ({ "�����������","�����������","�������","�����", "�������",
	      "�������", "�������" }) [ num - 1 ];
}

string ordered(int i)
{
  return (string) i + "-�";
}

string date(int timestamp, mapping m)
{
  mapping t1=localtime(timestamp);
  mapping t2=localtime(time(0));

  if(!m) m=([]);

  if(!(m["full"] || m["date"] || m["time"]))
  {
    if(t1["yday"] == t2["yday"] && t1["year"] == t2["year"])
      return "�������, � " + ctime(timestamp)[11..15];
  
    if(t1["yday"] == t2["yday"]-1 && t1["year"] == t2["year"])
      return "�����, v " + ctime(timestamp)[11..15];
  
    if(t1["yday"] == t2["yday"]+1 && t1["year"] == t2["year"])
      return "������, okolo "  + ctime(timestamp)[11..15];
  
    if(t1["year"] != t2["year"])
      return month(t1["mon"]+1) + " " + (t1["year"]+1900);
    else
      return "" + t1["mday"] + " " + month(t1["mon"]+1);
  }
  if(m["full"])
    return sprintf("%s, %s %s %d", 
		   ctime(timestamp)[11..15],
		   ordered(t1["mday"]), 
		   month(t1["mon"]+1), t1["year"]+1900);
  if(m["date"])
    return sprintf("%s %s %d", ordered(t1["mday"]),
		   month(t1["mon"]+1), t1["year"]+1900);

  if(m["time"])
    return ctime(timestamp)[11..15];
}

/* Help funtions */
/* gender is "f", "m" or "n" */
string _number_1(int num, string gender)
{
  switch(num)
  {
   case 0:  return "";
   case 1:  return ([ "m" : "����",
		      "f" : "����",
		      "n" : "����" ])[gender];
   case 2:  return ("f" == gender) ? "��e" : "���";
   case 3:  return "���";
   case 4:  return "������";
   case 5:  return "����";
   case 6:  return "�����";
   case 7:  return "����";
   case 8:  return "������";
   case 9:  return "������";
   default:
     error("russian->_number_1: internal error.\n");
  }
}

string _number_10(int num)
{
  switch(num)
  {
   case 2: return "��������";
   case 3: return "��������";
   case 4: return "�����";
   case 5: return "���������";
   case 6: return "����������";
   case 7: return "���������";
   case 8: return "�����������";
   case 9: return "���������";
   default:
     error("russian->_number_10: internal error.\n");
  }
}

string _number_100(int num)
{
  switch(num)
  {
   case 1: return "���";
   case 2: return "������";
   case 3: case 4:
     return _number_1(num, "m")+"���";
   case 5: case 6: case 7: case 8: case 9:
     return _number_1(num, "m")+"���";
   default:
     error("russian->_number_10: internal error.\n");
  }
}

string _number(int num, string gender);

string _number_1000(int num)
{
  if (num == 1)
    return "������";

  string pre = _number(num, "f");
  switch(num % 10)
  {
   case 1: return pre + " ������";
   case 2: case 3: case 4:
     return pre + " ������";
   default:
     return pre + " �����";
  }
}

string _number_1000000(int num)
{
  if (num == 1)
    return "�������";

  string pre = _number(num, "m");
  switch(num % 10)
  {
   case 1: return pre + " �������";
   case 2: case 3: case 4:
     return pre + " ��������";
   default:
     return pre + " ���������";
  }
}
  
string _number(int num, string gender)
{
  if (!gender)   /* Solitary numbers are inflected as masculine */
    gender = "m";
  if (!num)
    return "";

  if (num < 10)
    return _number_1(num, gender);

  if (num < 20)
    return ([ 10: "������",
	      11: "�����������",
	      12: "����������",
	      13: "����������",
	      14: "������������",
	      15: "����������",
	      16: "�����������",
	      17: "����������",
	      18: "������������",
	      19: "������������" ])[num];
  if (num < 100)
    return _number_10(num/10) + " " + _number_1(num%10, gender);

  if (num < 1000)
    return _number_100(num/100) + " " + _number(num%100, gender);

  if (num < 1000000)
    return _number_1000(num/1000) + " " + _number(num%1000, gender);

  return _number_1000000(num/1000000) + " " + _number(num%1000000, gender);
}


string number(int num, string|void gender)
{
  if (!gender)   /* Solitary numbers are inflected as masculine */
    gender = "m";
  if (num<0) {
    return("�����"+_number(-num, gender));
  } if (num) {
    return(_number(num, gender));
  } else {
    return("����");
  }
}

array aliases()
{
  return ({ "ru", "rus", "russian", "�������" });
}

