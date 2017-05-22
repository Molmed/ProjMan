package Molmed::Projman::Sample;

use strict;
use Carp;
use Molmed::Chiasma;
use Molmed::Projman::Aliquot;

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
    my $sampleId = shift;
    my $dbh = Molmed::Chiasma::connect();
    my $sampleData = $dbh->selectrow_hashref(
	qq(select sample.*, state.identifier as stype , series.identifier as sample_series
             from dbo.sample as sample 
               left join dbo.state as state on (sample.state_id=state.state_id) 
               left join dbo.sample_series as series on(sample.sample_series_id=series.sample_series_id)
           where sample_id=$sampleId)
	);
    unless(defined $sampleData){
	carp "Select sample ($sampleId) returned no data:" . $dbh->errstr . "\n";
	return 0;
    }
    $self->{ID} = $sampleId;
    $self->{DBDATA}=$sampleData;
    if(defined $sampleData->{STYPE}){
	$self->{TYPE} = $sampleData->{STYPE};
    }
    return 1;
}

# Make an alias to avoid frustration...
sub aliquots{
    my $self = shift;
    return $self->aliquotes(@_);
}
sub aliquotes{
    my $self = shift;
    my %args = @_;
    unless(exists $args{OBJECTS}){
	$args{OBJECTS} = 1;
    }
    unless($self->{ID}){
	croak "Attempt to get aliquotes for undefined sample. Load the sample first\n";
    }
    my $dbh = Molmed::Chiasma::connect();
    my $aliqIds = $dbh->selectcol_arrayref(
	qq(select tube_aliquot_id from dbo.tube_aliquot where sample_id=$self->{ID})
	);
    if($args{OBJECTS}){
	my @aliquots;
	foreach my $aId (@{$aliqIds}){
	    push @aliquots, Molmed::Projman::Aliquot->new(ID=>$aId);
	}
	return(@aliquots);
    }
    return(@{$aliqIds});
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
