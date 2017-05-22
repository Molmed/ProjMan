#!/usr/bin/perl -w

use strict;
use FindBin;                # Find the script location
use lib "$FindBin::Bin/lib";# Add the script libdir to libs
use Molmed::Chiasma;
use XML::Simple;
use File::Basename;
use Getopt::Long;

my $replace = 0;
my ($help,$man) = (0,0);

GetOptions('help|?'=>\$help,
           'man'=>\$man,
           'replace' => \$replace,
          ) or pod2usage(-verbose => 0);
pod2usage(-verbose => 1)  if ($help);
pod2usage(-verbose => 2)  if ($man);

while(my $runfolder = shift ){
    die "Runfolder '$runfolder' does not exist" unless(-e $runfolder);

    my $fcId = getFcId($runfolder);
    my $rfName = basename($runfolder);
    (my $runDate = $rfName) =~ s/^(\d\d)(\d\d)(\d\d).*/20$1-$2-$3/;

    my $dbhProj = Molmed::Chiasma::connect(-db=>'ProjectMan');

    print STDERR "$rfName\t$fcId\t$runDate\n";

    if($replace){
	removeOld($fcId, $dbhProj);
    }

    my $fcExists = $dbhProj->selectrow_arrayref(qq(select distinct flowcell_id from sample_results where flowcell_id='$fcId'));
    if(defined $fcExists && $fcExists->[0] eq $fcId){
	print STDERR "$fcId already exists in database\n";
	next;
    }

    eval{
	$dbhProj->do(qq(INSERT INTO flowcell_runfolder(flowcell_id, runfolder_name, run_date) VALUES('$fcId', '$rfName', '$runDate')));
    };

    opendir(my $fhRF, "$runfolder/Summary") or die "Failed to open $runfolder/Summary";

    foreach my $dir (grep /^[^\.]/, readdir($fhRF)){
	next if($dir eq 'Plots' || $dir eq 'Undetermined_indices');
	next unless(-d "$runfolder/Summary/$dir");
	readStats("$runfolder/Summary/$dir/report.xml", $dir, $dbhProj, $fcId);
    }
    closedir($fhRF);
}

sub removeOld{
    my $fcId = shift;
    my $dbh = shift;
    $dbh->do(qq(DELETE FROM sample_results where flowcell_id='$fcId'));
    $dbh->do(qq(DELETE FROM flowcell_lane_results where flowcell_id='$fcId'));
    $dbh->do(qq(DELETE FROM flowcell_runfolder where flowcell_id='$fcId'));
}


sub readStats{
    my $xml = shift;
    my $proj = shift;
    my $dbh = shift;
    my $fcId = shift;
    my $stats;

    local $dbh->{RaiseError} = 0;
    local $dbh->{PrintError} = 1;

    if(-e $xml){
        $stats = XMLin($xml, ForceArray=>['Lane','Read','Sample','Tag']) || die "Failed to read $xml\n";
    }elsif(-e "$xml.gz"){
        open(my $xfh, '<:gzip', "$xml.gz") || die "Failed to open $xml.gz\n";
        local $/='';
        my $str = <$xfh>;
        local $/="\n";
        $stats = XMLin($str,ForceArray=>['Lane','Read','Sample','Tag']) || die "Failed to read $xml.gz\n";
    }else{
	die "Failed to find $xml";
    }

#    use Data::Dumper;
#    print Dumper($stats);
#    print "-----------------------------------\n\n";
#    exit;

    if(defined $stats->{MetaData}->{FlowCellId} && $stats->{MetaData}->{FlowCellId} ne $fcId){
	die "Flowcell Id does not match with runfolder!";
    }

#    open(my $fhL, ">>${fcId}-LaneMetrics.csv") or die "Failed to open '${fcId}-LaneMetrics.csv'";
#    open(my $fhS, ">>${fcId}-SampleMetrics.csv") or die "Failed to open '${fcId}-SampleMetrics.csv'";

    foreach my $lane (@{$stats->{LaneMetrics}->{Lane}}){
	foreach my $read (@{$lane->{Read}}){
	    $read->{DensityRaw} = defined $read->{DensityRaw} ? $read->{DensityRaw} : 'NULL';
	    $read->{DensityPF} = defined $read->{DensityPF} ? $read->{DensityPF} : 'NULL';
	    $read->{ErrRate} = defined $read->{ErrRate} ? $read->{ErrRate} : 'NULL';
	    $read->{Raw} = defined $read->{Raw} ? $read->{Raw} : 'NULL';
	    $read->{PF} = defined $read->{PF} ? $read->{PF} : 'NULL';
	    $read->{Cycles} = defined $read->{Cycles} ? $read->{Cycles} : 'NULL';
	    $read->{PctQ30} = defined $read->{PctQ30} ? $read->{PctQ30} : 'NULL';
	    $read->{AvgQ} = defined $read->{AvgQ} ? $read->{AvgQ} : 'NULL';
	    print STDERR join("\t", $fcId, $lane->{Id}, $read->{Id}, "\n");#, $read->{DensityRaw}, $read->{DensityPF},
#		       $read->{ErrRate}, $read->{Raw}, $read->{PF}, $read->{Cycles}, $read->{PctQ30},
#		       $read->{AvgQ}), "\n";
	    $dbh->do(qq( INSERT INTO flowcell_lane_results(flowcell_id, lane_num, read_num, raw_density, pf_density,\
                           error_rate, raw_clusters, pf_clusters, cycles, pct_q30, mean_q)\
                         VALUES('$fcId', $lane->{Id}, $read->{Id}, $read->{DensityRaw}, $read->{DensityPF},\
		               $read->{ErrRate}, $read->{Raw}, $read->{PF}, $read->{Cycles}, $read->{PctQ30},\
	                       $read->{AvgQ})
                         )
		    );
	}
    }
    foreach my $sample (@{$stats->{SampleMetrics}->{Sample}}){
	foreach my $tag (@{$sample->{Tag}}){
	    foreach my $lane (@{$tag->{Lane}}){
		foreach my $read (@{$lane->{Read}}){
		    $tag->{Id} = defined $tag->{Id} ? $tag->{Id} : '';
		    $sample->{Id} = defined $sample->{Id} ? $sample->{Id} : '';
		    $read->{Cycles} = defined $read->{Cycles} ? $read->{Cycles} : 'NULL';
		    $read->{PctLane} = defined $read->{PctLane} ? $read->{PctLane} : 'NULL';
		    $read->{PF} = defined $read->{PF} ? $read->{PF} : 'NULL';
		    $read->{PctQ30} = defined $read->{PctQ30} ? $read->{PctQ30} : 'NULL';
		    $read->{TagErr} = defined $read->{TagErr} ? $read->{TagErr} : 'NULL';
		    $read->{LibraryName} = defined $read->{LibraryName} ? $read->{LibraryName} : 'NULL';
		    $read->{AvgQ} = defined $read->{AvgQ} ? $read->{AvgQ} : 'NULL';

#		    print STDERR join("\t", $fcId, $proj, $sample->{Id}, $tag->{Id}, $lane->{Id}, $read->{Id},
#			       $read->{Cycles}, $read->{PctLane}, $read->{PF}, $read->{PctQ30},
#			       $read->{TagErr}, $read->{LibraryName}, $read->{AvgQ}), "\n";

		    $dbh->do(qq( INSERT INTO sample_results(flowcell_id, project_id, sample_name, tag_seq, lane_num, read_num,\
                                   cycles, pct_lane, pf_clusters, pct_q30, pct_tag_err, library_name, mean_q)\
                                 VALUES('$fcId', '$proj', '$sample->{Id}', '$tag->{Id}', $lane->{Id}, $read->{Id},\
			                $read->{Cycles}, $read->{PctLane}, $read->{PF}, $read->{PctQ30},\
			                $read->{TagErr}, '$read->{LibraryName}', $read->{AvgQ})
                               )
                    );
		}
	    }
	}
    }
}

sub getFcId{
    my $runfolder = shift;
    my $runInfo;
    if(-e "$runfolder/RunInfo.xml"){
	$runInfo = XMLin("$runfolder/RunInfo.xml", ForceArray=>['Read']) || die "Failed to read RunInfo.xml\n";
    }elsif(-e "$runfolder/RunInfo.xml.gz"){
	open(my $rfh, '<:gzip', "$runfolder/RunInfo.xml.gz") || die "Failed to open RunInfo.xml.gz\n";
	local $/='';
	my $str = <$rfh>;
	local $/="\n";
	close($rfh);
	$runInfo = XMLin($str, ForceArray=>['Read']) || die "Failed to read RunInfo.xml.gz\n";
    }
    return($runInfo->{Run}->{Flowcell});
}

