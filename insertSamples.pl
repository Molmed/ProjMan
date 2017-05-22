#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use File::Basename;

my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');

while(<>){
    next unless m/\w/;
    s/\012//;
    s/\015//;
    my($sample,$batch) = split /\t/, $_;
    $sample =~ s/_org_120807$//;
    $sample =~ s/-/_/g;
    $sample =~ s/\.1$//;
    $sample =~ s/^SX124_//;

    print STDERR "$sample\t$batch\n";
    eval{
	$dbhProj->do(qq(INSERT INTO HE17(sample_name, batch)VALUES('$sample', $batch)));
    }
}
