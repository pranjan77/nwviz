

open (HTML, ">htmloption.txt") or die ("nn");
my $x =`pwd`;
my @x = split ("\/", $x);

my $templatename= "$x[-1]";
chomp ($templatename);

use strict;
my %hash = ();
my %hashdesc = ();
my %hashuedge = ();
my $count = 0;

open (FILE, "gene2gene_network.txt") or die ("nn");

while (<FILE>){
  $_=~s/\s*$//;
  my @cr = split ("\t", $_);
  $cr[-1]=~s/kb.//g;
  $hash{$cr[-1]}++;

 my @ax= ($cr[0], $cr[1]);
 my @sax = sort @ax;
 ($cr[0], $cr[1]) = @sax;
 my $id = "$cr[0]-$cr[1]";
 if (!$hashuedge{$id}){
   $count++;
$hashuedge{$id}++;
 }
}

close (FILE);

open (FILE, "../data/network_detail.txt") or die ("nn");

  while (<FILE>){
    $_=~s/\s*$//;
    my @cr = split ("\t", $_);
    $cr[0]=~s/kb.//;
    $hashdesc{$cr[0]} = $cr[1];

  }

close (FILE);


  print HTML "<option value=\"$templatename-merged.json\">($count) $templatename-merged-all-networks.json</option>\n";

system ("perl generatenetwork.pl gene2gene_network.txt ../data/Popgenie2_import.txt.parse  gene2ontology.txt.tmp  >$templatename-merged.json");
  my @array = ();

  while (my ($key, $val) = each (%hash)){
       push (@array,  "$val\t$key\t$templatename-$key.json\t($val) $templatename $val$hashdesc{$key}\n");
  }

my @sarray = sort {$b<=>$a} @array;

foreach my $line (@sarray){
my ($t,$key, $json, $desc) = split ("\t", $line);
  print HTML "<option value=\"$json\">$desc</option>\n";

system ("grep $key gene2gene_network.txt >tmp");
system ("perl generatenetwork.pl tmp ../data/Popgenie2_import.txt.parse  gene2ontology.txt.tmp  >$json");
}

close (HTML);

