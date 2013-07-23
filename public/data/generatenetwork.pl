
 use strict;

 my $filenetwork = $ARGV[0];
 my $fileannotation = $ARGV[1];
 my $filego = $ARGV[2];
 my $json="";
 my %hashgo = ();
my %hashat = ();

my %hashcount = ();
my %hashlink = ();
my %hashannotation = ();
my %hashcolor = ();


 open (FILE, $filenetwork) or die ("nn");

  while (<FILE>){

  my @cr = split, ("\t", $_);

  $hashcount{$cr[0]}++;
  $hashcount{$cr[1]}++;
  
 my @smr = ($cr[0], $cr[1]);
  my @sortsmr = sort @smr;
  my $id = "$smr[0]-$smr[1]";
$hashlink{$id} ="{\n\"source\": \"$cr[0]\", \n\"target\": \"$cr[1]\"\n}";
  }

close (FILE);


 open (FILEX, $fileannotation) or die ("nn");

  while (<FILEX>){
   
     

        $_=~s/\s*$//;
    
        my ($id,$at,$anno) = split ("\t", $_);

        $hashannotation{$id} = $anno;
        $hashat{$id} = $at;        

  }
close (FILEX);

  
open (FILEZ, "$filego") or die ("nn");

 while (<FILEZ>){
  my @cr = split ("\t", $_);
  $hashgo{$cr[0]} .="$cr[3] - ";
 }

close (FILEZ);

my $string = "\"links\": [\n";
while (my ($key, $val) = each (%hashlink)){

   $string .= "$val,";
   $string .="\n";
}

$string =~s/\s*$//;
$string =~s/,$//;
$string .="\n]\n";

  

 my $stringnode = "\"nodes\": [\n";

 while (my ($key, $val) = each (%hashcount)){

  if (!$hashcolor{$key}){
   $hashcolor{$key}="#088da5";
  }

$hashannotation{$key}=~s/\"//;
 my $x=<<"XCMR";
      {
      "match": 1.0,
      "name": "$key AT: $hashat{$key}<br>Annotation: $hashannotation{$key}<br>GO : $hashgo{$key}",
      "artist": "$key",
      "id": "$key",
      "color": "$hashcolor{$key}",
      "playcount": $val
      }, 
XCMR
   
  $stringnode .=$x;
 } 


 open (FILEP, "gene_list.txt") or die ("nnc");

  while (<FILEP>){
       $_=~s/\s*$//;
my $key=$_;
if (!$hashcount{$key}){
 if (!$hashcolor{$key}){
   $hashcolor{$key}="#FF33FF";
  }

$hashannotation{$key}=~s/\"//;
 my $x=<<"XCMR";
      {
      "match": 1.0,
      "name": "$key AT: $hashat{$key}<br>Annotation: $hashannotation{$key}<br>GO : $hashgo{$key}",
      "artist": "$key",
      "id": "$key",
      "color": "$hashcolor{$key}",
      "playcount": 1
      }, 
XCMR

  $stringnode .=$x;
 } 

  }



 $stringnode=~s/\s*$//;
 $stringnode =~s/,$//;
 $stringnode .="],\n";

my $json = "{\n";
$json .=$stringnode;
$json .=$string;
$json .="}\n";

print $json;
