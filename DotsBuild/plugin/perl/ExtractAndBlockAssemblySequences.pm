package DoTS::DotsBuild::Plugin::ExtractAndBlockAssemblySequences;
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | absent
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | absent
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^


@ISA = qw(GUS::PluginMgr::Plugin);
use strict;
use GUS::Model::DoTS::AssemblySequence;
use CBIL::Bio::SequenceUtils;
use GUS::PluginMgr::Plugin;

use CBIL::Bio::SequenceUtils;

my $argsDeclaration =
[
 integerArg({name => 'testnumber',
             descr => 'number of iterations for testing',
             constraintFunc => undef,
             reqd => 0,
             isList => 0
	     }),

 stringArg({name => 'taxon_id_list',
            descr => 'comma delimited taxon_id list for sequences to process: 8=Hum, 14=Mus.',
            constraintFunc => undef,
            reqd => 0,
            isList => 0
	    }),

 fileArg({name => 'outputfile',
          descr => 'Name of file for output sequences',
          constraintFunc => undef,
          reqd => 1,
          mustExist => 0,
          isList => 0,
          format => 'Text'
	    }),

 stringArg({name => 'rm_options',
            descr => 'RepeatMasker options',
            constraintFunc => undef,
            reqd => 0,
            isList => 0
	    }),

 stringArg({name => 'idSQL',
            descr => 'SQL query that returns assembly_sequence_ids to be processed',
            constraintFunc => undef,
            reqd => 0,
            isList => 0
	    }),

 booleanArg({ name => 'extractonly',
              descr => 'if true then does not Block extracted sequences',
              constraintFunc => undef,
              reqd => 0,
              isList => 0
           })

];

my $purposeBrief = <<PURPOSEBRIEF;
Extract unprocessed AssembySequences, block them and write to a file for clustering
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Extract unprocessed AssembySequences, block them and write to a file for clustering
PLUGIN_PURPOSE

#check the documentation for this
my $tablesAffected = [];

my $tablesDependedOn = [
    ['DoTS::AssemblySequence', '']
];

my $howToRestart = <<PLUGIN_RESTART;
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES


my $documentation = {
             purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };


sub new {

  my $class = shift;

  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation
		    });

  return $self;
}


my $countProcessed = 0;
my $countBad = 0;
my $repLib;
my $debug = 0;
my $repMaskDir = '/usr/local/src/bio/RepeatMasker/04-04-1999';
my $tmpLib = "tmpLib.$$";
my $RepMaskCmd;

sub run {
    my $self   = shift;

    my $cla =$self->getCla; 
    
    die "You must enter repeat masker options on the command line to specify minimally the organism to be blocked\n" unless $cla->{rm_options} || $cla->{extractonly};
    die "You must enter either the --taxon_id_list or --idSQL on the command line\n" unless $cla->{taxon_id_list} || $cla->{idSQL};
    die "You must enter an outputfile name on the command line\n" unless $cla->{'outputfile'};
    
    $self->logAlert ($cla->{'commit'} ? "***COMMIT ON***\n" : "COMMIT TURNED OFF\n");
    $self->logAlert ("Testing on $cla->{'testnumber'}\n") if $cla->{'testnumber'};
    
    my $dbh = $self->getQueryHandle();
    
    if ($cla->{extractonly}) {
	$self->logAlert("Extracting sequences without blocking\n");
    } else {
	$RepMaskCmd = "RepeatMasker $cla->{rm_options}";
	$self->logAlert ("RepeatMasker command:\n  $RepMaskCmd\n");
    }
    
    ##implement restart here....
    my %finished;
    ##restart 
    if ( -e "$cla->{'outputfile'}") {
	open(F,"$cla->{'outputfile'}");
	while (<F>) {
	    if (/^\>(\d+)/) {
		$finished{$1} = 1;
	    }
	}
	close F;
	open(OUT,">>$cla->{'outputfile'}");
	$self->logAlert ("outputFile $cla->{'outputfile'} exists...Restarting: already have ".scalar(keys%finished)." sequences\n");
    } else {
	open(OUT,">$cla->{'outputfile'}");
    }
    
    my $getSeqs;
    if ($cla->{idSQL}) {
	$getSeqs = $cla->{idSQL};
    } else {
    my $taxon = $cla->{'taxon_id_list'};
	$getSeqs = "select a.assembly_sequence_id, e.source_id
  from dots.AssemblySequence a, dots.ExternalNASequence e
  where a.have_processed = 0 
  and a.na_sequence_id = e.na_sequence_id
  and e.taxon_id in (". $taxon .") and a.quality_end - a.quality_start >= 50";
    }
    
    $self->logVerbose ("$getSeqs\n");
    
    my $stmt = $dbh->prepare($getSeqs);
    $stmt->execute();
    my $count = 0;
    my $miniLib = "";
    my @todo;

    my %assIdToSourceId;
    
    ##run it into an array so does not block!!
    while (my($id, $sourceId) = $stmt->fetchrow_array()) {
	next if exists $finished{$id};
	last if ($cla->{'testnumber'} && $count >= $cla->{'testnumber'}); ##breaks 
	$self->logAlert ("Retrieving $count\n") if $count % 10000 == 0;
	push(@todo,$id);

        $assIdToSourceId{$id} = $sourceId if($sourceId);

	$count++;
    }


    $self->logAlert ("Extracting",($cla->{extractonly} ? " " : " and blocking "),"$count sequences from taxon_id(s) $cla->{'taxon_id_list'}\n or from $cla->{idSQL}\n");
    
    $count = 0;
    my $countProc = 0;
    my $reset = 0;
    foreach my $id (@todo) {
	$self->logAlert ("Processing $id\n") if $debug;
	my $ass = GUS::Model::DoTS::AssemblySequence->
	    new( { 'assembly_sequence_id' => $id } );
	$ass->retrieveFromDB();

        my $naSeqSourceId = $assIdToSourceId{$id};

	##want to set the sequence_start = quality_start etc here....has not been assembled...
	$ass->resetAssemblySequence();
#    $reset += $ass->submit() if $ass->hasChangedAttributes();


        my $fastaDefline = "assemblySeqIds|".$ass->getId() . ($naSeqSourceId ? "|$naSeqSourceId" : "");
  
	$miniLib .= CBIL::Bio::SequenceUtils::makeFastaFormattedSequence($fastaDefline, $ass->getSequence());


  ##note could add in the description to make a better defline here..deal with "NULL"



	$count++;
	$countProc++;
	$self->logAlert ("Processing $countProc\n") if $countProc % 1000 == 0;
	if ($count >= 1000) {
	    $self->processSet($miniLib);
	    $miniLib = "";            ##reset for next set of seqs
	    $count = 0;
	    $self->undefPointerCache();
	}
    }
    $self->processSet($miniLib);        ##processes last set
    
    ##clean up after self...
    unlink "$tmpLib";
    unlink "$tmpLib.masked";
    
    ############################################################
    ###  put an informative summary in the results variable
    ############################################################
    my $results = "Extracted and blocked $countProcessed AssemblySequences, marked $countBad as repeat and reset $reset to qality_start/end";
    $results = "Extracted $countProc AssemblySequences" if $cla->{extractonly};
    $self->logAlert ("\n$results\n");
    return $results;
}

sub processSet {

    my $self   = shift;

    my($miniLib) = @_;

    my $cla = $self->getCla;
    if ($cla->{extractonly}) {
	print OUT $miniLib;
	return;
    }
    
    open(S, ">$tmpLib");
    print S $miniLib;
    close S;
    
    ##RepeatMasker
    system("$repMaskDir/$RepMaskCmd $tmpLib");
    
    ##generate better sequence....
    open(S,"$tmpLib.masked");
    my $seq;
    my $na_seq_id;
    while (<S>) {
	if (/^\>(\d+)/) {           ##$1 = na_sequence_id
	    $self->processBlockedSequence($na_seq_id,$seq) if $na_seq_id;
	    $na_seq_id = $1;
	    $seq = "";
	    $self->logAlert ("Processed: $countProcessed, repeats: $countBad\n") if $countProcessed % 100 == 0;
	} else {
	    $seq .= $_;
	}
    }
    $self->processBlockedSequence($na_seq_id,$seq) if $na_seq_id;
    close S;
}

sub processBlockedSequence{


  my $self   = shift; 
  my $ctx = shift;
  my($ass_seq_id,$seq) = @_;
    
  my $length = length($seq);

  $countProcessed++;
    
  $seq =~ s/\s+//g;
  $seq =~ s/X/N/g;
  ##trim dangling NNNN.s
  my $sequence = $self->trimDanglingNNN($seq);
    
  ##check for lenth..
  my $tmpSeq = $sequence;
  $tmpSeq =~ s/N//g;
    
  ##if too short then update AssemblySquence else print to file...
  if (length($tmpSeq) < 50) {
    $self->logAlert ("Sequence $ass_seq_id too short (".length($tmpSeq).") following blocking\n") if $debug;
    ##update AssSeq..
    my $ass = $ctx->{'self_inv'}->getFromDbCache('AssemblySequence',$ass_seq_id);
    if (!$ass) {
      $self->logAlert ("ERROR: $ass_seq_id not in cache...retrieving from Database\n");
      $ass = GUS::Model::DoTS::AssemblySequence->
	new( { 'assembly_sequence_id' => $ass_seq_id });
      $ass->retrieveFromDB();
      if (!$ass->get('assembly_strand')) {
	##this is invalid sequence.....is reverse strand..
	$self->logAlert ("ERROR:  AssemblySequence $ass_seq_id is invalid\n");
	return undef;
      }
    }
    $ass->set('have_processed',1);
    $ass->set('processed_category','repeat');
    $ass->submit();
    $countBad++;
  } else {
    my $length = length($sequence);
    print OUT "\>$ass_seq_id\slength=$length\n".CBIL::Bio::SequenceUtils::breakSequence($sequence);
  }
}

sub trimDanglingNNN {

    my $self   = shift;
    my($seq) = @_;
    if ($seq =~ /^(.*?)NNNNNNNNNN+(.*?)$/) {
	$seq = $2 if length($1) < 20; ##don't want to leave 20 bp at end...
    }
    
    if ($seq =~ /N/) {            ##still has at least one N so..
	my $rev = CBIL::Bio::SequenceUtils::reverseComplementSequence($seq);
	if ($rev =~ /^(.*?)NNNNNNNNNN+(.*?)$/) {
	    #	 $self->logAlert ("matched ending NNNN length\$1=".length($1)." length\$2=".length($2)."\nSEQ:$seq\n");
	    $rev = $2 if length($1) < 20; ##don't want to leave 20 bp at end...
	}
	if (length($rev) == length($seq)) {
	    return $seq;
	} else {
	    return CBIL::Bio::SequenceUtils::reverseComplementSequence($rev);
	}
    } else {
	return $seq;
    }
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.AssemblySequence');
}


1;
