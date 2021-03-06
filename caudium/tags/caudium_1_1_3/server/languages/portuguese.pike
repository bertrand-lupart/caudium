/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2001 The Caudium Group
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

/* Bugs by: Per */
/* Trans by: cjsawaia@8415.com.br */

/*
 * name = "Portuguese language plugin ";
 * doc = "Handles the conversion of numbers and dates to Portuguese. You have to restart the server for updates to take effect. Translation by cjsawaia@8415.com.br";
 */

string cvs_version = "$Id$";
 
string month(int num)
{
  return ({ "Janeiro", "Fevereiro", "Mar�o", "Abril", "Maio",
            "Junho", "Julho", "Agosto", "Setembro", "Outubro",
            "Novembro", "Dezembro" })[ num - 1 ];
}
 
string ordered(int i)
{
    return i+"�";
}
 
string date(int timestamp, mapping|void m)
{
  mapping t1=localtime(timestamp);
  mapping t2=localtime(time(0));
 
  if(!m) m=([]);
 
  if(!(m["full"] || m["date"] || m["time"]))
  {
    if(t1["yday"] == t2["yday"] && t1["year"] == t2["year"])
      return "hoje, "+ ctime(timestamp)[11..15];
  
    if(t1["yday"]+1 == t2["yday"] && t1["year"] == t2["year"])
      return "ontem, "+ ctime(timestamp)[11..15];
  
    if(t1["yday"]-1 == t2["yday"] && t1["year"] == t2["year"])
      return "amanh�, "+ ctime(timestamp)[11..15];
  
    if(t1["year"] != t2["year"])
      return (month(t1["mon"]+1) + " " + (t1["year"]+1900));
    return (month(t1["mon"]+1) + " " + ordered(t1["mday"]));
  }
  if(m["full"])
    return ctime(timestamp)[11..15]+", "+
           month(t1["mon"]+1) + " the "
           + ordered(t1["mday"]) + ", " +(t1["year"]+1900);
  if(m["date"])
    return month(t1["mon"]+1) + " the "  + ordered(t1["mday"])
      + " no ano de " +(t1["year"]+1900);
  if(m["time"])
    return ctime(timestamp)[11..15];
}
 
 
string number(int num)
{
  if(num<0)
    return "menos "+number(-num);
  switch(num)
  {
   case 0:  return "";
   case 1:  return "um";
   case 2:  return "dois";
   case 3:  return "tres";
   case 4:  return "quatro";
   case 5:  return "cinco";
   case 6:  return "seis";
   case 7:  return "sete";
   case 8:  return "oito";
   case 9:  return "nove";
   case 10: return "dez";
   case 11: return "onze";
   case 12: return "doze";
   case 13: return "treze";
   case 14: return "catorze";
   case 15: return "quinze";
   case 16: return "dezesseis";
   case 17: return "dezessete";
   case 18: return "dezoito";
   case 19: return "dezenove";
   case 20: return "vinte";
   case 30: return "trinta";
   case 40: return "quarenta";
   case 50: return "cinquenta";
   case 60: return "sessenta";
   case 70: return "setenta";
   case 80: return "oitenta";
   case 90: return "noventa";
 
   case 21..29: 
   case 31..39: 
   case 41..49:
   case 51..59: 
   case 61..69: 
   case 71..79: 
   case 81..89: 
   case 91..99:  
     return number((num/10)*10)+ " e " +number(num%10);
 
   case 100..199: return "cento e "+number(num%100);
   case 200..299: return "duzentos e "+number(num%100);
   case 300..399: return "trezentos e "+number(num%100);
   case 400..499: return "quatrocentos e "+number(num%100);
   case 500..599: return "quinhentos e "+number(num%100);
   case 600..699: return "seiscentos e "+number(num%100);
   case 700..799: return "setecentos e "+number(num%100);
   case 800..899: return "oitocentos e "+number(num%100);
   case 900..999: return "novecentos e "+number(num%100);
 
   case 1000..1999: return "mil "+number(num%1000);
   case 2000..999999: return number(num/1000)+" mil "+number(num%1000);
 
   case 1000000..1999999: 
     return "um milh�o "+number(num%1000000);
 
   case 2000000..999999999: 
     return number(num/1000000)+" milh�es "+number(num%1000000);
 
   default:
    return "muito!!";
  }
}
 
string day(int num)
{
  return ({ "Domingo","Segunda Feira","Ter�a Feira","Quarta Feira",
            "Quinta Feira","Sexta Feira","S�bado" })[ num - 1 ];
}
 
array aliases()
{
  return ({ "pt", "port", "portuguese" });
}
