#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use File::Basename;
use Encode;

my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');
my $foo = <>; #skip header

my %PI;
my %Contact;

while(<>){
    s/\012//;
    s/\015//;
    my @r = split /\t/, Encode::decode('iso-8859-1', $_);
    if(defined $r[2]  && $r[2]=~m/\w/){
	$PI{$r[2]} = [@r[8,9,10]];
    }
    if(defined $r[3] && $r[3]=~m/\w/){
	$r[3]=~ s/\s+^//g;
	$Contact{$r[3]} = 1;
    }
}

foreach my $p (keys %PI){
     $PI{$p}->[1] = '' unless defined $PI{$p}->[1];
     $PI{$p}->[2] = '' unless defined $PI{$p}->[2];
#    print qq(insert into pi(name, affiliation, faculty, department) values('$p', '$PI{$p}->[0]','$PI{$p}->[1]','$PI{$p}->[2]')), "\n";
    $dbhProj->do(qq(insert into pi(name, affiliation, faculty, department) values('$p', '$PI{$p}->[0]','$PI{$p}->[1]','$PI{$p}->[2]')));
}

foreach my $c (keys %Contact){
#    print qq(insert into contact(name) values('$c')), "\n";
    $dbhProj->do(qq(insert into contact(name) values('$c')));
}
