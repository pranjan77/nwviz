#!/kb/runtime//bin/perl
use strict;
use Data::Dumper;
use Bio::KBase::Genotype_PhenotypeAPI::Client;
use Bio::KBase::KBaseNetworksService::Client;
use Bio::KBase::OntologyService::Client;
use Bio::KBase::PlantExpressionService::Client;
use Bio::KBase::CDMI::CDMIClient;
use JSON;
use DBI;



#my $x ='kb|g.3907.locus.22932';
#my $y ='kb|g.3907.locus.22932';

#my $r = ridconv([$x,$y]);

#print @$r;






write_column("gene2ontology.txt");
write_column("gene2expression-po-averaged.txt");




write_column2("merged_cc2go_enr.txt");
write_column2("ds_cc2go_enr.txt");



	sub write_column2 {

		my ($filename) = @_;

		my %res = ();

		open (FILE, $filename) or die ("nn");
		my @filedata = <FILE>;
		close (FILE);

			foreach (@filedata){ 
				$_=~s/\s*$//;
				my @cr = split ("\t", $_);
                                my @arr = split (",", $cr[-1]);

				while ($#arr > 0) {
				    my $key = shift @arr;
				    $res{$key} = 1;


				}
				
			}

		open (OUT, ">$filename.tmp") or die ("nn");
		my $hashmap = ridconvy (\%res);

			foreach (@filedata){
				$_=~s/\s*$//;
				my @cr = split ("\t", $_);
				my $i=-1;
					foreach my $line (@cr){    
						$i++;
						if ($i==@cr-1){
                                    
							 my $string = "";
                                                        my @mq = split (",", $cr[$i]);
                                                        foreach my $linex (@mq){
							$string .= "$hashmap->{$linex}, ";
					                 }     
                                                        $string=~s/, $//;
                                                         print OUT $string;	
							}
						else {
							print OUT "$line\t";
						}
					}
				print OUT "\n";
			}

		close (OUT);

	}














	sub write_column {

		my ($filename) = @_;

		my @res = ();

		open (FILE, $filename) or die ("nn");
		my @filedata = <FILE>;
		close (FILE);

			foreach (@filedata){ 
				$_=~s/\s*$//;
				my @cr = split ("\t", $_);
				push (@res, $cr[0]);
			}

		open (OUT, ">$filename.tmp") or die ("nn");
		my $hashmap = ridconvx (\@res);

			foreach (@filedata){
				$_=~s/\s*$//;
				my @cr = split ("\t", $_);
				my $i=-1;
					foreach my $line (@cr){    
						$i++;
						if ($i==0){
							print OUT "$hashmap->{$line}\t";
						}
						else {
							print OUT "$line\t";
						}
					}
				print OUT "\n";
			}

		close (OUT);

	}



sub ridconvy {
  my $ar = shift;
  my $hostname = "devdb1.newyork.kbase.us";
  my $db = "kbase_plant";
  my $user = "networks_pdev";
  my $pass = "networks_pdev";

  my %hashmap = ();

  my $dbh = DBI->connect("DBI:mysql:$db;host=$hostname", "$user", "",  { RaiseError => 1 } ) or die $DBI::errstr;
  my $sql = "select * from kbid2eid where kbid = ?";

  my $sth = $dbh->prepare("$sql") or die $dbh->errstr;

  my @results = ();

while (my ($line, $val) = each (%$ar)){
    chomp $line;
    $sth->execute($line);
    if (my $hash_ref = $sth->fetchrow_hashref()) {
      #push @results, $hash_ref->{'eid'};
      $hashmap{$line}=$hash_ref->{'eid'};
    }
  }
  return \%hashmap;
}

sub ridconvx {
  my $ar = shift;
  my $hostname = "devdb1.newyork.kbase.us";
  my $db = "kbase_plant";
  my $user = "networks_pdev";
  my $pass = "networks_pdev";

  my %hashmap = ();

  my $dbh = DBI->connect("DBI:mysql:$db;host=$hostname", "$user", "",  { RaiseError => 1 } ) or die $DBI::errstr;
  my $sql = "select * from kbid2eid where kbid = ?";

  my $sth = $dbh->prepare("$sql") or die $dbh->errstr;

  my @results = ();

  foreach my $line (@$ar) {
    chomp $line;
    $sth->execute($line);
    if (my $hash_ref = $sth->fetchrow_hashref()) {
      #push @results, $hash_ref->{'eid'};
      $hashmap{$line}=$hash_ref->{'eid'};
    }
  }
  return \%hashmap;
}
