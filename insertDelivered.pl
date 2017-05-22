#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use File::Basename;

my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');

while(<>){
    s/\012//;
    s/\015//;
    my @r = split /\t/, $_;
    next unless(defined $r[0] && defined $r[1] && defined $r[3]);
    my($rfId,$lane,$delivered) = @r[0,1,3];
    if( $delivered =~ m/^\d+$/ && $rfId && $lane ){
	my $fcIdAry = $dbhProj->selectrow_arrayref(qq(select flowcell_id from flowcell_runfolder where runfolder_name='$rfId'));
	my $fcId = $fcIdAry->[0];
	if(defined($fcId)){
	    print STDERR "UPDATE $fcId\t$lane\t$delivered\n";
	    $dbhProj->do(qq(UPDATE flowcell_lane_results set delivered=$delivered where flowcell_id='$fcId' and lane_num=$lane));
	}
    }
}
