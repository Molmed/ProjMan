#!/usr/bin/perl -w

use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs

use strict;
use Molmed::Chiasma;

my $dbhChiasma= Molmed::Chiasma::connect();
my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');

my $projects = $dbhProj->selectall_hashref(q(select * from projects),'PROJECT_ID'); #state!='COMPLETE'),'PROJECT_ID');

my @phases = (
	      'Fragmentation',
	      'Adapter ligation',         # End repair, A-base and ligation
	      'Enrichment',
	      'Size selection',
	      'QC1 Frag Bioanalyzer',     # QC after fragmentation
	      'PCR amplification',
	      'QC2 Lib Bioanalyzer',      # After PCR
	      'QC2 Lib qPCR',             # After PCR
	      'QC2 Lib Rerun-gel',        # Bioanalyzer efter omrening på gel
	      'QC3 Enrich Bioanalyzer',   # After enrichment
	      'QC3 Enrich qPCR',          # After enrichment
	      'FAILED',                   # Sample has failed during library prep
	      'PASSED',                   # Library is ready for sequencing
	      'Cluster generation',       # Library diluted for clustering
);

foreach my $p (values %{$projects}){
    my $sx = $p->{SAMPLE_SERIES};

    # When did we get the last sample
    $p->{DATE} = $dbhChiasma->selectrow_arrayref( qq(
                                 select convert(varchar, max(changed_date),21) from sample_history sh
                                 left join sample_series ss on(sh.sample_series_id=ss.sample_series_id)
                                 where sh.changed_action='I' and ss.identifier='$sx'
                                 ))->[0];

    # Get the number of logged in samples
    $p->{SAMPLES} = $dbhChiasma->selectrow_arrayref(
		    qq(select count(sample_id) from sample sa
                       left join sample_series ss on(sa.sample_series_id=ss.sample_series_id)
                       where ss.identifier='$sx'
                    ))->[0];

    # Count tube aliquots in each phase
    $p->{PHASES} = $dbhChiasma->selectall_hashref(
		     qq(select count(ta.tube_aliquot_id) cnt, ca.identifier phase from tube_aliquot ta
                        left join category ca on(ta.seq_state_category_id=ca.category_id)
                        left join sample sa on(ta.sample_id=sa.sample_id)
                        left join sample_series ss on(sa.sample_series_id=ss.sample_series_id)
                        where ss.identifier='$sx'
                        group by ca.identifier
                       ), 'PHASE');

#    print "$sx\t$p->{DATE}\n";
#    use Data::Dumper;
#    print Dumper($p);
}

startTable('Date', 'Project','Sample Series', 'Application', 'Samples/lane', 'Samples', @phases, 'Completed');

foreach my $p (sort {&datesort} values %{$projects}){
    my @row = ($p->{DATE}, $p->{PROJECT_ID}, $p->{SAMPLE_SERIES}, $p->{APPLICATION}, '', $p->{SAMPLES});
    foreach my $ph (@phases){
	push @row, exists($p->{PHASES}->{$ph}) ? $p->{PHASES}->{$ph}->{CNT} : 0;
    }
    push @row, ''; # Number of completed samples
    tableRow(@row);
}

endTable();

sub datesort{
     $a =~ s/\D//g;
     $b =~ s/\D//g;
     return($a<=>$b);
}


sub startTable{
    print "<table>\n";
    print "<tr>\n";
    foreach my $e (@_){
	print "<th>$e</th>\n";
    }
    print "</tr>\n";
}

sub tableRow{
    print "<tr>\n";
    foreach my $e (@_){
	print "<td>$e</td>\n";
    }
    print "</tr>\n";
}

sub endTable{
    print "</table>\n";
}
