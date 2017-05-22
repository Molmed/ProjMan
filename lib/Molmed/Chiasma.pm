package Molmed::Chiasma;

use strict;
use Carp;
use DBI;
use DBD::Sybase;

sub connect{
    my %args = @_;
    my $database = $args{-db} || 'DefaultDB';
    my $user = $args{-user} || 'DefaultUser';
    my $pass = $args{-pass} || 'DefaultPass';
    my $hostname = $args{-host} || 'DefaultHost';

    my $dbh = DBI->connect("dbi:Sybase:server=$hostname;database=$database",
			   $user, $pass, {RaiseError=>1,PrintError => 1,FetchHashKeyName=>'NAME_uc'});
    croak "Unable for connect to server $DBI::errstr"
	unless $dbh;
    return $dbh;
}

return 1;
