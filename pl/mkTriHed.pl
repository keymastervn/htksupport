#!/usr/bin/perl
#
# make a .hed script to clone monophones in a phone list 
# 
# rachel morton 6.12.96


if (@ARGV != 3){
  print "usage: makehed monolist trilist\n\n"; 
  exit (0);
}

($monolist, $trilist,$trihed) = @ARGV;

# open .hed script
open(MONO, "@ARGV[0]");

# open .hed script
open(HED, ">$trihed");

print HED "CL $trilist\n";

# 
while ($phone = <MONO>) {
       chop($phone);
       if ($phone ne "") { 
	   print HED "TI T_$phone {(*-$phone+*,$phone+*,*-$phone).transP}\n";
       }
   }
