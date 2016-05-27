#copyright by Vo Dinh Phong, 27/11/2006
my ($proto,$monophones0,$hmmdefs);

# check usage
if (@ARGV != 3) {
  print "usage: $0 proto monophones0\n\n"; 
  exit (0);
}

# read in command line arguments
($proto,$monophones0,$hmmdefs) = @ARGV;

open (PROTO,"$proto") || die ("Unable to open $proto file for reading");
open (MONOPHONES0,"$monophones0") || die ("Unable to open $monophones0 file for reading");
open (HMMDEFS,">$hmmdefs") || die ("Unable to open $hmmdefs file for writing");

#write to the file

my $states = "";

$line = <PROTO>;

$count = 0;

while( $line = <PROTO> ){
  chomp($line);
  $count += 1;
  
  if($count > 2){
    $states = $states . $line . "\n";
  }
}

close(PROTO);

$def = "s/";
$prephone = "proto/";

while ($line = <MONOPHONES0>){
  $temp = "" . $states;
  chomp($line);
  
  #$cat = $def . $prephone;
  #$cat = $cat . $line;
  #$cat = $cat . "/";
  #print "$cat\n";  	  
  #$temp =~ $cat;
  
  substr($temp,4,length "proto") = $line;
  #$cat = "";
  print HMMDEFS "$temp";
}

close(MONOPHONES0);
close(HMMDEFS);

