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

sub getgenelist {
  my ($trait_id, $pvalue_cutoff, $distance) = @_;
  my $client = Bio::KBase::Genotype_PhenotypeAPI::Client->new("http://localhost:7067");
  my $results = $client->traits_to_genes($trait_id, $pvalue_cutoff , $distance);


  my $genelistdata = $results->[1];

  my @results = ();
  foreach my $ref(@$genelistdata)
  {
    my ($kb_locus_id, $source_gene_id) = @$ref;
    push @results, $source_gene_id;
  }
  return \@results;
}

# find connected component
sub find_cc {
  my $edge_list = shift;
  my @rst = ();
  foreach my $edge ( @$edge_list ) {
    next if ! defined $edge;
    my $found = 0;
    my $hr1 = undef;
    my $hr2 = undef;
    for(my $i = 0; $i <= $#rst; $i += 1) {
      $hr1 = $i if defined $rst[$i]->{$$edge[0]};
      $hr2 = $i if defined $rst[$i]->{$$edge[1]};
    }
    if( defined $hr1 ) {
      if( defined $hr2) {
        if( $hr1 != $hr2 ) {
          # merge two list now
          foreach my $k (keys %{$rst[$hr2]} ) {
            $rst[$hr1]->{$k} = 1;
          }
          $rst[$hr2] = undef;
        } # else : we don't need to do anything...
      } else {
        $rst[$hr1]->{$$edge[1]} = 1;
      }
    } else { # $hr1 is not defined
      if( defined $hr2) {
        $rst[$hr2]->{$$edge[0]} = 1;
      } else { # both are not defined
        push @rst, {$$edge[0] => 1, $$edge[1] => 1};
      }
    }
  }
  return \@rst;
}

sub gse2gsm {
  # TODO: results should be gse => array list reference of gsm
  my $ar = shift;
  my $hostname = "devdb1.newyork.kbase.us";
  my $db = "kbase_plant";
  my $user = "networks_pdev";
  my $pass = "networks_pdev";
  
  
  my $dbh = DBI->connect("DBI:mysql:$db;host=$hostname", "$user", "",  { RaiseError => 1 } ) or die $DBI::errstr;
  my $sql = "select * from eid2cid where eid = ?";
  
  my $sth = $dbh->prepare("$sql") or die $dbh->errstr;
  
  my @results = ();
  
  foreach my $line (@$ar) {
    chomp $line;
    $sth->execute($line);
    while (my $hash_ref = $sth->fetchrow_hashref()) {
      push @results, $hash_ref->{'cid'};
      #print $hash_ref->{kbid}, "\n";
    }
  }
  return \@results;
}

sub idconv {
  my $ar = shift;
  my $hostname = "devdb1.newyork.kbase.us";
  my $db = "kbase_plant";
  my $user = "networks_pdev";
  my $pass = "networks_pdev";
  
  
  my $dbh = DBI->connect("DBI:mysql:$db;host=$hostname", "$user", "",  { RaiseError => 1 } ) or die $DBI::errstr;
  my $sql = "select * from kbid2eid where eid = ?";
  
  my $sth = $dbh->prepare("$sql") or die $dbh->errstr;
  
  my @results = ();
  
  foreach my $line (@$ar) {
    chomp $line;
    $sth->execute($line);
    if (my $hash_ref = $sth->fetchrow_hashref()) {
      push @results, $hash_ref->{kbid};
      #print $hash_ref->{kbid}, "\n";
    }
  }
  return \@results;
}

sub ridconv {
  my $ar = shift;
  my $hostname = "devdb1.newyork.kbase.us";
  my $db = "kbase_plant";
  my $user = "networks_pdev";
  my $pass = "networks_pdev";
  
  
  my $dbh = DBI->connect("DBI:mysql:$db;host=$hostname", "$user", "",  { RaiseError => 1 } ) or die $DBI::errstr;
  my $sql = "select * from kbid2eid where kbid = ?";
  
  my $sth = $dbh->prepare("$sql") or die $dbh->errstr;
  
  my @results = ();
  
  foreach my $line (@$ar) {
    chomp $line;
    $sth->execute($line);
    if (my $hash_ref = $sth->fetchrow_hashref()) {
      push @results, $hash_ref->{'eid'};
      #print $hash_ref->{kbid}, "\n";
    }
  }
  return \@results;
}

sub dump_array2file {
  my $fn = shift;
  my $ds = shift;
  open FH, ">$fn" or die "Couldn't open $fn: $!\n";

  foreach my $d (@$ds) {
    print FH "$d\n";
  }
  close FH;
}

sub getgenelist2 {

 my @results = ();
 open (FILE, "gene_list.txt") or die ("nn");

  while (<FILE>){

  $_=~s/\s*$//;
  push @results, $_;
  }

close (FILE);
return \@results;
}



my $trait_id="kb|g.3907.trait.4";
my  $distance =10000;
my $pvalue_cutoff = 0.005;

#Given a trait id, pvalue cutoff and distance, return the list of genes
#my $genelist = getgenelist ($trait_id, $pvalue_cutoff, $distance);
#dump_array2file('gene_list.txt', $genelist);


my $genelist = getgenelist2 ();

#ID conversion
my $kbid_ar =  idconv($genelist);
dump_array2file('gene_list_kbid.txt', $kbid_ar);


#
# dataset to gene_id hashmap
my $nc = Bio::KBase::KBaseNetworksService::Client->new("http://localhost:7064/KBaseNetworksRPC/networks");
my %ds2desc = ();
my %ds2gene = ();
foreach my $id ( @$kbid_ar) {
  my $rst = $nc->entity2Datasets($id);
  foreach my $hr (@$rst) {
    my $ds = $hr->{'id'};
    my $desc = $hr->{'description'};
    if(! defined $ds2gene{$ds}) { 
      $ds2gene{$ds} = {$id => 1};
      $ds2desc{$ds} = $desc;
    } else {
      $ds2gene{$ds}->{$id} = 1;
    }
  }
}

# retrieve internal networks for each dataset
my @selected_ds = ();
my @results = ();
my @merged_rst =();
my %ds2rst = ();
foreach my $ds (sort { scalar keys %{$ds2gene{$b}} <=> scalar keys %{$ds2gene{$a}} || $a cmp $b } keys %ds2gene ) {
  push @selected_ds, $ds;
  my $result = $nc->buildInternalNetwork([$ds], $kbid_ar, ["GENE_GENE"]);
  #print Dumper($result);
  my %nodes = ();
  foreach my $hr (@{$result->{'nodes'}}) {
    $nodes{$hr->{'id'}} = $hr->{'entityId'};
  }
  $ds2rst{$ds} = [];
  foreach my $hr (@{$result->{'edges'}}) {
    my $id1 = $nodes{$hr->{'nodeId1'}};
    my $id2 = $nodes{$hr->{'nodeId2'}};
    my $strength = $hr->{'strength'};
    #print "$id1\t$id2\t$strength\t$ds\n";
    my $idr1 = ridconv([$id1]);
    my $idr2 = ridconv([$id2]);
    #print "$$idr1[0]\t$$idr2[0]\t$strength\t$ds\n";
    push @results, "$$idr1[0]\t$$idr2[0]\t$strength\t$ds";
    push @merged_rst, [$id1, $id2];
    push @{$ds2rst{$ds}},[$id1, $id2];
  }
  #print "$ds\t$ds2desc{$ds}\t".(scalar keys %{$ds2gene{$ds}})."\n";
  #last if scalar @selected_ds >3;
}
dump_array2file('gene2gene_network.txt', \@results);


# retrieve cluster networks for each dataset
@results = ();
my %cid2gl = ();
foreach my $ds (sort { scalar keys %{$ds2gene{$b}} <=> scalar keys %{$ds2gene{$a}} || $a cmp $b } keys %ds2gene ) {
  push @selected_ds, $ds;
  my $result = $nc->buildFirstNeighborNetwork([$ds], $kbid_ar, ["GENE_CLUSTER"]);
  #print Dumper($result);
  my %nodes = ();
  foreach my $hr (@{$result->{'nodes'}}) {
    $nodes{$hr->{'id'}} = $hr->{'entityId'};
  }
  foreach my $hr (@{$result->{'edges'}}) {
    my $id1 = $nodes{$hr->{'nodeId1'}};
    my $id2 = $nodes{$hr->{'nodeId2'}};
    my $strength = $hr->{'strength'};
    #print "$id1\t$id2\t$strength\t$ds\n";
    my $idr1 = ridconv([$id1]);
    #print "$$idr1[0]\t$id2\t$strength\t$ds\n";
    push @results, "$$idr1[0]\t$id2\t$strength\t$ds";
    $cid2gl{$id2} = [] if ! defined $cid2gl{$id2};
    push @{$cid2gl{$id2}}, $id1;
  }
  #print "$ds\t$ds2desc{$ds}\t".(scalar keys %{$ds2gene{$ds}})."\n";
  #last if scalar @selected_ds >3;
}
dump_array2file('gene2cluster_network.txt', \@results);
##my @results=();


#
# retrieve ontology information
@results = ();
my $oc = Bio::KBase::OntologyService::Client->new("http://localhost:7062");
my $csEO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script();
my $fdH = $csEO->get_entity_Feature($kbid_ar, ['id','function', 'feature-type','alias']);
my $rst = $oc->get_goidlist($kbid_ar,[],[]);
foreach my $id ( @$kbid_ar) {
  #print Dumper($rst);
  foreach my $goid (keys %{$rst->{$id}}) {
    foreach my $hr (@{$rst->{$id}->{$goid}}) {
      push @results, "$id\t$goid\t$hr->{'domain'}\t$hr->{'desc'}\t$hr->{'ec'}\t$fdH->{$id}->{'function'}";
    }
  }
}
dump_array2file('gene2ontology.txt', \@results);

#
# print expression tables
# TODO: need to update function
my $gse_ar = gse2gsm(['GSE13990']); # TODO: move this function to plant_expression_service
@results = ();
my $pec = Bio::KBase::PlantExpressionService::Client->new("http://localhost:7063");
my $exp_rst = $pec->get_experiments_by_sampleid_geneid($gse_ar,$kbid_ar);
my $apo_rst = $pec->get_all_po();
my @po_lst = keys %{$apo_rst};
my $po_gsm_rst = $pec->get_po_sampleidlist(\@po_lst);
my $rh_sid2values = $exp_rst->{"series"};
my @genes = @{$exp_rst->{"genes"}};
my @sids = sort keys %{$rh_sid2values};

print "GSE=>", Dumper($gse_ar);
#print "KBID=>", Dumper($kbid_ar);
#print "ALL_PO=>", Dumper($apo_rst);
#print "PO_GSM=>", Dumper($po_gsm_rst);

for(my $i = 0; $i <= $#genes; $i = $i+1) {
  my $id = $genes[$i];
  foreach my $po (@po_lst) {
    #print "Processing $po\n";
    my $po_avg = 0;
    my $counter = 0;
    foreach my $sidr(@{$po_gsm_rst->{$po}}) {
      my $sid = $$sidr[1];
      if(defined $rh_sid2values->{$sid} ) {
        next if ! defined ${$rh_sid2values->{$sid}}[$i] or ${$rh_sid2values->{$sid}}[$i] eq "";
        $counter += 1;
        $po_avg += ${$rh_sid2values->{$sid}}[$i];
      }
    }
    if($counter > 0) {
      $po_avg /= $counter;
      push @results, "$id\t$po\t$po_avg\t$apo_rst->{$po}";
    }
  }
}
dump_array2file('gene2expression-po-averaged.txt', \@results);


#
# gene overlap enrichment
@results = ();
my $dl = ['biological_process','molecular_function','cellular_component'];
my @el = qw(IEA IDA IPI IMP IGI IEP ISS ISS ISO ISA ISM IGC IBA IBD IKR IRD RCA TAS NAS IC ND NR);
foreach my $cid (keys %cid2gl) {
  next if scalar @{$cid2gl{$cid}} < 3;
  my $rst = $oc->get_go_enrichment($cid2gl{$cid}, $dl, \@el, 'hypergeometric', 'GO');
  foreach my $hr (@$rst) {
    if($hr->{'pvalue'} < 0.05) {
      push @results, "$cid\t$hr->{'goID'}\t$hr->{'pvalue'}\t${$hr->{'goDesc'}}[0]";
    }
  }
}
dump_array2file('cluster2go_enr.txt', \@results);

#
# gene overlap enrichment for the each dataset
@results = ();
foreach my $ds (keys %ds2rst) {
  next if scalar @{$ds2rst{$ds}} < 3;
  my $ar = find_cc($ds2rst{$ds});
  foreach my $hr (@$ar) {
    next if ! defined $hr;
    my @gl = keys %$hr;
    next if scalar @gl < 3;
    my $rst = $oc->get_go_enrichment(\@gl, $dl, \@el, 'hypergeometric', 'GO');
    my $gls = join(',',@gl);
    foreach my $hr (@$rst) {
      if($hr->{'pvalue'} < 0.05) {
        push @results, "$ds\t$hr->{'goID'}\t$hr->{'pvalue'}\t${$hr->{'goDesc'}}[0]\t$gls";
      }
    }
  }
}
dump_array2file('ds_cc2go_enr.txt', \@results);

#
# gene overlap enrichment for the merged dataset
#my @merged_rst =();
@results = ();
my $ar = find_cc(\@merged_rst);
  foreach my $hr (@$ar) {
    next if ! defined $hr;
    my @gl = keys %$hr;
    next if scalar @gl < 3;
    my $rst = $oc->get_go_enrichment(\@gl, $dl, \@el, 'hypergeometric', 'GO');
    my $gls = join(',',@gl);
    foreach my $hr (@$rst) {
      if($hr->{'pvalue'} < 0.05) {
        push @results, "MERGED\t$hr->{'goID'}\t$hr->{'pvalue'}\t${$hr->{'goDesc'}}[0]\t$gls";
      }
    }
  }
dump_array2file('merged_cc2go_enr.txt', \@results);


