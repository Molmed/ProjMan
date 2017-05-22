#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use File::Basename;

my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');

while(<>){
    print STDERR;
    next if(m/#VALUE/);
    next if(m/#DIV/);
    s/\012//;
    s/\015//;
    my(@row) = split /,/, $_;
    $row[8]=~ s/\%//;
    my($xpos,$ypos) = qw(NULL NULL);
    if(defined $row[3] && $row[3] =~ m/^[A-H]\d\d?$/){
	($xpos,$ypos) = split //, $row[3];
	print STDERR "$row[3] $xpos $ypos\n";
	$xpos = ord($xpos) - 65;
	$ypos = $ypos - 1;
    }
    my $cmd = qq(insert into qpcr2012(qpcr_date,operator,tube,x_pos,y_pos,sample,konc1,length,konc2,error) values($row[0],'$row[1]','$row[2]',$xpos,$ypos,'$row[4]',$row[5],$row[6],$row[7],$row[8]));
    print STDERR "$cmd\n";
    $dbhProj->do($cmd);
}
