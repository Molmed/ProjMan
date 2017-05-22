#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use File::Basename;
use Encode;

my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');
my $foo = <>; #skip header

while(<>){
    s/\012//;
    s/\015//;
    next unless(m/\w/);
    my @r = split /\t/, Encode::decode('iso-8859-1', $_);

    my $pi = getPI($dbhProj,$r[2]);
    my ($contact,$app,$app2);
    if(defined $r[3] && $r[3] =~ m/\w/){
	$contact = getContact($dbhProj,$r[3]);
    }
    if(defined $r[14] && $r[14] =~ m/\w/){
	$app = getApplication($dbhProj,$r[14]);
    }
    if(defined $r[15] && $r[15] =~ m/\w/){
	$app2 = getApplication2($dbhProj,$r[15]);
    }

    print "$app, $app2\n"

}

sub getPI{
    my $dbh = shift;
    my $name = shift;
    my $id = $dbh->selectrow_arrayref("select id from pi where name='$name'");
    return $id->[0];
}

sub getContact{
    my $dbh = shift;
    my $name = shift;
    my $id = $dbh->selectrow_arrayref("select id from contact where name='$name'");
    return $id->[0];
}

sub getApplication{
    my $dbh = shift;
    my $name = shift;
    my $id = $dbh->selectrow_arrayref("select id from seq_application where name='$name'");
    return $id->[0];
}

sub getApplication2{
    my $dbh = shift;
    my $name = shift;
    my $id = $dbh->selectrow_arrayref("select id from seq_application2 where name='$name'");
    return $id->[0];
}



#    $dbhProj->do(qq(insert into pi(name, affiliation, faculty, department) values('$name', '$PI{$p}->[0]','$PI{$p}->[1]','$PI{$p}->[2]')));
