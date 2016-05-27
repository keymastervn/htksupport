#copyright by Vo Dinh Phong, 27/11/2006
my ($vfloor,$macro);

# check usage
if (@ARGV != 2) {
  print "usage: $0 vFloors macros\n\n"; 
  exit (0);
}

# read in command line arguments
($vfloor,$macro) = @ARGV;

open (VFLOOR,"$vfloor") || die ("Unable to open $vfloor file for reading");
open (MACRO,">$macro") || die ("Unable to open $macro file for writing");


#write to the file



printf(MACRO "~o\n<STREAMINFO> 1 39\n<VECSIZE> 39<NULLD><MFCC_D_A_0><DIAGC>\n");

my $line;

while( $line = <VFLOOR> ){
  chomp($line);
  print(MACRO "$line\n");
}

close(MACRO);
close(VFLOOR);

