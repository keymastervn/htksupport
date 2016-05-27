#copyright by Vo Dinh Phong, 27/11/2006
my ($mphones,$mphones0,$mphones1);

# check usage
if (@ARGV != 3) {
  print "usage: $0 sourcemonophones monophones0 monophones1\n\n"; 
  exit (0);
}

# read in command line arguments
($mphones,$mphones0,$mphones1) = @ARGV;

open (MPHONES,"$mphones") || die ("Unable to open $monophones file for reading");
open (MPHONES0,">$mphones0") || die ("Unable to open $monophones0 file for writing");
open (MPHONES1,">$mphones1") || die ("Unable to open $monophones1 file for writing");


#write to the file

my $line;

while( $line = <MPHONES> ){

  chomp($line);
  print MPHONES1 "$line\n";
  
  if($line ne "sp"){
	  print MPHONES0 "$line\n";
  }
}

print MPHONES0 "sil\n";
print MPHONES1 "sil\n";

close(MPHONES0);
close(MPHONES1);
close(MPHONES);
