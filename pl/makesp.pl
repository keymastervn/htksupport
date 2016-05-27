#copyright by Vo Dinh Phong, 27/11/2006

 if (@ARGV != 4) {
   print "usage: $0 sourceHmmdef destHmmdef sourceMacros destMacros\n";
   exit(0);
 }


use File::Copy;

copy("@ARGV[0]","@ARGV[1]");
copy("@ARGV[2]","@ARGV[3]");

 $okprint = "FALSE";
 $silprint = "FALSE";

#string variable for storing sp model
$sp = "";

 unless (open(FILE, "@ARGV[1]")) {
   die ("can't open @ARGV[1]");
 }
 
 
 while ($line = <FILE>) {
  chop ($line);
  
 if ($line =~ /STREAMINFO/) {
   $streaminfo = $line;
 }

 if ($line =~ /VECSIZE/) {
   $vecsize = $line;
 }

 if ($line =~ /"sil"/) {
   $okprint = "TRUE";
   $sp .= "~h \"sp\"\n";
   $sp .= "<BEGINHMM>\n";
   $sp .= "<NUMSTATES> 3\n";
   $sp .= "<STATE> 2\n";
 }

 if ($okprint eq "TRUE" && ($line =~ /<STATE> 3/)) {
   $silprint = "TRUE";
   $line = <FILE>;
   chop ($line);
   #printf NEWFILE "$line\n";
 } 

 if ($okprint eq "TRUE" && ($line =~ /<STATE> 4/)) {
   $silprint = "FALSE";
 } 

 if ($okprint eq "TRUE" && ($line =~ /TRANSP/)) {
   $silprint = "FALSE";
   $sp .= "<TRANSP> 3\n";
   $sp .= " 0.000000e+00 5.000000e-01 5.000000e-01\n";
   $sp .= " 0.000000e+00 5.000000e-01 5.000000e-01\n";
   $sp .= " 0.000000e+00 0.000000e+00 0.000000e+00\n";
 } 

 if ($okprint eq "TRUE" && ($line =~ /ENDHMM/)) {
     $sp .= "$line\n";
   $silprint = "FALSE";
   $okprint = "FALSE";
 } 


 if ($silprint eq "TRUE") {
    $sp .= "$line\n";
 }

}

close(FILE);

unless (open(FILE, ">>@ARGV[1]")) {
  die ("can't open @ARGV[1]");
}

print FILE "$sp";

close(FILE);
 
 

