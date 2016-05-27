#copyright by Vo Dinh Phong, 27/11/2006
my($unsorted,$sorted);

if(@ARGV != 2){
  print "Usage:$0 $unsorted $sorted";
  exit(0);
}

($unsorted,$sorted) = @ARGV;

open(MYINPUTFILE, "$unsorted"); # open for input
open(MYOUTPUTFILE, ">$sorted"); # open for output

my(@lines) = <MYINPUTFILE>; # read file into list

@lines = sort(@lines); # sort the list

my($line);

foreach $line (@lines) # loop thru list
 {
 print MYOUTPUTFILE "$line"; # print in sort order
 }

close(MYINPUTFILE);
close(MYOUTPUTFILE);
