#!/usr/bin/perl -w

use strict;
use Molmed::Projman::Sample;
use Data::Dumper;
use Molmed::Chiasma;

my $dbh = Molmed::Chiasma::connect;
#print $dbh->tables();


my $sample = Molmed::Projman::Sample->new(ID=>26373186);
#print Dumper($sample);

print $sample->identifier(), "\t", $sample->type(), "\n";
my @aliquots = $sample->aliquotes(OBJECTS=>1);

print Dumper(\@aliquots);
