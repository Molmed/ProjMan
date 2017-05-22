package Molmed::Projman::Aliquot;

use strict;
use Carp;
use Molmed::Chiasma;

our $AUTOLOAD;

sub new{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {@_};

    if(defined $self->{DEBUG}){
        $self->{VERBOSE} = 1;
    }

    bless ($self, $class);

    if(defined $self->{ID}){
	$self->load($self->{ID});
    }


    return $self;
}

sub load{
    my $self = shift;
    my $aliqId = shift;
    my $dbh = Molmed::Chiasma::connect();
    my $aliqData = $dbh->selectrow_hashref(
	qq(select aliquot.*, state.identifier as atype, seq_state.identifier as sstate, seq_type.identifier as stype, seq_app.identifier as sapp
             from dbo.tube_aliquot as aliquot 
               left join dbo.state as state on (aliquot.state_id=state.state_id) 
               left join dbo.category as seq_state  on (aliquot.seq_state_category_id=seq_state.category_id)
               left join dbo.category as seq_type on (aliquot.seq_type_category_id=seq_type.category_id)
               left join dbo.category as seq_app on (aliquot.seq_application_category_id=seq_app.category_id)
           where tube_aliquot_id=$aliqId)
	);
    unless(defined $aliqData){
	carp "Select aliquot ($aliqId) returned no data:" . $dbh->errstr . "\n";
	return 0;
    }
    $self->{ID} = $aliqId;
    $self->{DBDATA}=$aliqData;
    if(defined $aliqData->{ATYPE}){
	$self->{TYPE} = $aliqData->{ATYPE};
    }
    if(defined $aliqData->{SSTATE}){
	$self->{SEQSTATE} = $aliqData->{SSTATE};
    }
    if(defined $aliqData->{STYPE}){
	$self->{SEQTYPE} = $aliqData->{STYPE};
    }
    if(defined $aliqData->{SAPP}){
	$self->{SEQAPP} = $aliqData->{SAPP};
    }

    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or confess "$self is not an object";

    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    $name =~ tr/a-z/A-Z/; # Use uppercase

    if ( exists $self->{$name} ) {
	return $self->{$name};
    }elsif( exists $self->{DBDATA}->{$name} ){
	return $self->{DBDATA}->{$name};
    }
    
    confess "Can't access `$name' field in class $type";
}

return 1;
