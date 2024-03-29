package DoTS::Gene::Plugin::CreateGenomeDotsGene;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use CBIL::Util::Disp;
use CBIL::Util::PropertySet;

use GUS::PluginMgr::Plugin;
use DoTS::Gene::GenomeWalker;
use DoTS::Gene::Util;

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    my $purposeBrief = 'create genome-based Dots Genes from genomic alignments of DTs';
  
    my $purpose = $purposeBrief;

    my $tablesDependedOn = [['DoTS::BlatAlignment','genomic alignments of DTs']];

    my $tablesAffected = [];

    my $howToRestart = <<RESTART; 
Specify comma separated list of chroms (see log files from previous run) to skip.
RESTART

    my $failureCases;

    my $notes = <<NOTES;
=pod

=head2 F<General Description>

Create genome-based Dots Genes from genomic  alignments of DTs. 
Merger alignments 
1) with overlap of exon bases on the same strand
2) within a distance, eg 500kb, and linked by 5'-3' EST pair(s)
3) very close to each other, say <75bp apart

=head1 AUTHORS

Y Thomas Gan

=head1 COPYRIGHT

Copyright, Trustees of University of Pennsylvania 2004. 

=cut

NOTES
    
    my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};
    my $argsDeclaration  =
    [
     integerArg({name => 'taxon_id',
		 descr => 'taxon id',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0 
		 }),
     integerArg({name => 'queryTableId',
                 descr => 'table_id for the query table',
                 constraintFunc=> undef,
                 reqd  => 1,
                 isList => 0
                 }),

    integerArg({name => 'targetTableId',
                 descr => 'table_id for target table',
                 constraintFunc=> undef,
                 reqd  => 1,
                 isList => 0
                 }),

    integerArg({name => 'genome_db_rls_id',
		descr => 'genome external dabtabase release id',
		constraintFunc=> undef,
		reqd  => 1,
		isList => 0 
		}),
 
     stringArg({name => 'temp_login',
		descr => 'login for temp table usage',
		constraintFunc=> undef,
		reqd  => 1,
		isList => 0 
		}),

     stringArg({name => 'est_pair_cache',
		descr => 'table that caches info about est clone pairs',
		constraintFunc=> undef,
		reqd  => 0,
		default => 'EstClonePair',
		isList => 0 
		}),

     stringArg({name => 'blat_signals_cache',
		descr => 'table that caches info about genomic signals of blat alignments',
		constraintFunc=> undef,
		reqd  => 0,
		default => 'BlatAlignmentSignals',
		isList => 0
		}),

     stringArg({name => 'skip_chrs',
		descr => 'comma separated chromosomes for which analysis should be skipped, for whole genome analysis in restart mode',
		constraintFunc=> undef,
		reqd => 0,
		isList => 1, 
	    }),

     stringArg({name => 'chr',
		descr => 'chromosome on which to do analysis',
		constraintFunc=> undef,
		reqd => 0,
		isList => 0, 
	    }),

     integerArg({name => 'start',
		descr => 'start of chromosome region in which to do analysis',
		constraintFunc=> undef,
		reqd => 0,
		isList => 0 
		}),

     integerArg({name => 'end',
		descr => 'end of chromosome region in which to do analysis',
		constraintFunc=> undef,
		reqd => 0,
		isList => 0 
		}),

     integerArg({name => 'splice_minimum',
		descr => 'minimum length of maximum intron required for a DT to be used in gene construction',
		constraintFunc=> undef,
		reqd => 0,
		isList => 0 
		}),

     booleanArg({name => 'contains_mrna',
		descr => 'flag to indicate whether a DT has to contain mRNA to be used in gene construction',
		reqd => 0,
		default => 0,
		}),

     booleanArg({name => 'exclude_singleton',
		descr => 'flag to indicate whether to exclude singletons from analysis',
		reqd => 0,
		default => 0,
		}),

     integerArg({name => 'overlap_merge',
		descr => 'criteria to trigger merge by exon base overlap (eg 10)',
		constraintFunc=> undef,
		reqd => 0,
		default => 1,
		isList => 0, 
	    }),

     integerArg({name => 'clonelink_merge',
		descr => 'distance criteria to trigger merge by EST clone pair linkage',
		constraintFunc=> undef,
		reqd => 0,
		default => 500000,
		isList => 0, 
	    }),

     integerArg({name => 'proximity_merge',
		descr => 'distance criteria to trigger merge by alignment proximity',
		constraintFunc=> undef,
		reqd => 0,
		default => 75,
		isList => 0, 
	    }),

     booleanArg({name => 'test',
		descr => 'run plugin in a test region',
		reqd => 0,
		default => 0,
		}),

    stringArg({name => 'tableName',
		descr => 'base name for gene and transcript temporary tables',
		constraintFunc=> undef,
		reqd => 1,
		isList => 0, 
	    }), 
     
    ];

    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision$',
		       name => ref($self),
		       revisionNotes => '', 
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });
    return $self;
}

sub run {
    my $self = shift;
    
    $self->logAlgInvocationId();
    $self->logCommit();
    $self->logArgs();

    my $db = $self->getDb();
    my $dbh = $self->getQueryHandle();
    my $args = $self->getArgs();
    my $genomeId = $self->getArg('genome_db_rls_id');
    my $tempLogin = $self->getArg('temp_login');
    my $isRerun = $self->getArg('skip_chrs');
    my $isTest = $self->getArg('test');

    $self->log("Clean out or create temp tables to hold genome dots gene analysis result...");
    my @tmpMeta = $self->createTempTables($dbh, $tempLogin, $isRerun || $isTest);
    my ($exonstarts_sp, $exonends_sp) = ('appendGdgEss', 'appendGdgEes');
    $self->createTempProcedures($dbh, $exonstarts_sp, $exonends_sp);

    $self->log("Creating genome-based DoTS genes...");
    my ($coords, $skip_chrs) = &DoTS::Gene::Util::getCoordSelectAndSkip($dbh, $genomeId, $args);
    my @done_chrs; push @done_chrs,  @$skip_chrs;

    my $baseQSel = $self->getBaseQuerySelector();
    my $baseTSel = $self->getBaseTargetSelector();
    my $optQSel = $self->getOptionalQuerySelector();
    my $sel_criteria = { baseQ=>$baseQSel, baseT=>$baseTSel, optQ=>$optQSel };
    my $mrg_criteria = $self->getMergeCriteria();
    my ($gdgId, $gdtId) = $self->getInitialGeneAndTranscriptIds($dbh, \@tmpMeta);

    foreach my $coord (@$coords) {
        $self->log("processing chr$coord->{chr}:$coord->{start}-$coord->{end}"); 
        $sel_criteria->{baseT}->{target_na_sequence_id} = $coord->{chr_id};
	$sel_criteria->{optT} = { start => $coord->{start}, end => $coord->{end} };
	my $gdg_wkr = DoTS::Gene::GenomeWalker->new($db, $sel_criteria, $mrg_criteria, $isTest);
	my $genes = $gdg_wkr->getCompositeGenomeFeatures();
	$self->log("number of genes in this region: " . scalar(@$genes));
	foreach (@$genes) {
	    $gdtId += $self->saveGene($gdgId++, $gdtId, $_, \@tmpMeta, $exonstarts_sp, $exonends_sp);
	}
	$dbh->commit();
	push @done_chrs, $coord->{chr};
	$self->log("completed/skipped chromosomoes: " . join(', ', @done_chrs));
        $db->undefPointerCache();
    }

    $self->log("analyze table statistics");
    $dbh->do("analyze table ${tempLogin}." . $tmpMeta[0] . " compute statistics");
    $dbh->do("analyze table ${tempLogin}." . $tmpMeta[3] . " compute statistics");

    return "finished genome-based dots gene creation";
}

##########################

sub getInitialGeneAndTranscriptIds {
    my ($self, $dbh, $tmpMeta) = @_;
    my $gdg_tab= $tmpMeta->[0];
    my $gdg_id_col= $tmpMeta->[1]->[0];
    my $gdt_tab= $tmpMeta->[3];
    my $gdt_id_col= $tmpMeta->[4]->[0];

    my $sql = "select min($gdg_id_col), max($gdg_id_col) from $gdg_tab";
    my $sth = $dbh->prepareAndExecute($sql);
    my ($min_gid, $max_gid) = $sth->fetchrow_array;
    my $gid = 1;
    $gid = $max_gid + 1 if ($min_gid && $min_gid < 10e6);

    $sql = "select min($gdt_id_col), max($gdt_id_col) from $gdt_tab";
    $sth = $dbh->prepareAndExecute($sql);
    my ($min_tid, $max_tid) = $sth->fetchrow_array;
    my $tid = 1;
    $tid = $max_tid + 1 if ($min_tid && $min_tid < 100e6);

    return ($gid, $tid);
}

sub getBaseQuerySelector {
    my $self = shift;
    my $taxonId = $self->getArg('taxon_id');
    my $queryTableId = $self->getArg('queryTableId');

    return { query_taxon_id => $taxonId, query_table_id => $queryTableId, is_best_alignment => 1 };
}

sub getBaseTargetSelector {
    my $self = shift;
    my $taxonId = $self->getArg('taxon_id');
    my $genomeId = $self->getArg('genome_db_rls_id');
    my $targetTableId = $self->getArg('targetTableId');

    return { target_taxon_id => $taxonId, target_table_id => $targetTableId,
	     target_external_db_release_id => $genomeId };
}

sub getOptionalQuerySelector {
    my $self = shift;
    my $containsMrna = $self->getArg('contains_mrna');
    my $spliceMin = $self->getArg('splice_minimum');
    my $excSgl = $self->getArg('exclude_singleton');
    my $sig_cache = $self->getArg('temp_login') . '.' . $self->getArg('blat_signals_cache');

    return { contains_mrna => $containsMrna, splice_minimum => $spliceMin,
	     exclude_singleton => $excSgl, blat_signals_cache =>$sig_cache };
}

sub getMergeCriteria {
    my $self = shift;
    my $oM = $self->getArg('overlap_merge');
    my $pM = $self->getArg('proximity_merge');
    my $cM = $self->getArg('clonelink_merge');
    my $epc = $self->getArg('temp_login') . '.' . $self->getArg('est_pair_cache');
    return { overlap_merge => $oM, proximity_merge => $pM,
	     clonelink_merge => $cM, est_pair_cache => $epc };
}

sub createTempTables {
  my ($self, $dbh, $tmpLogin, $donotCreate) = @_;

  my $tableBase = $self->getArg('tableName');

  my $gdg_tab = "${tableBase}Gene";
  my @gdg_cols = ('genome_dots_gene_id', 'taxon_id', 'genome_external_db_release_id',
		  'chromosome', 'chromosome_start', 'chromosome_end', 'strand', 'gene_size',
		  'number_of_exons', 'min_exon', 'max_exon', 'min_intron', 'max_intron',
		  'exonstarts', 'exonends', 'deprecated', 'est_plot_score',
		  'number_of_splice_signals', 'has_human_mouse_orthology',
		  'polya_signal_type', 'has_polya_track', 'number_of_est_libraries',
		  'number_of_est_clones', 'number_of_est_p53pairs', 'confidence_score',
		  'number_of_rnas', 'contains_mrna', 'max_orf_length', 'max_orf_score', 'min_orf_pval',
		  'gene_id', 'overlap_merge_count', 'clonelink_merge_count', 'proximity_merge_count');
  my @gdg_types = ('NUMBER(10) NOT NULL', 'NUMBER(10) NOT NULL', 'NUMBER(10)',
		   'VARCHAR2(32)', 'NUMBER(12)', 'NUMBER(12)', 'CHAR(1)', 'NUMBER(8)',
		   'NUMBER(4)', 'NUMBER(8)', 'NUMBER(8)', 'NUMBER(8)', 'NUMBER(8)',
		   'CLOB', 'CLOB', 'NUMBER(1)', 'NUMBER(4)',
		   'NUMBER(4)', 'NUMBER(1)',
		   'NUMBER(1)', 'NUMBER(1)', 'NUMBER(4)',
		   'NUMBER(6)', 'NUMBER(4)', 'NUMBER(3)',
		   'NUMBER(4)', 'NUMBER(1)', 'NUMBER(8)', 'FLOAT(126)', 'FLOAT(126)',
		   'NUMBER(10)', 'NUMBER(6)', 'NUMBER(4)', 'NUMBER(4)');
  my @gdg_csts = ("alter table ${tmpLogin}.$gdg_tab add constraint PK_" . uc($gdg_tab) . " primary key ($gdg_cols[0])",
                  "create index " . uc($gdg_tab) . "_IND02 on ${tmpLogin}.$gdg_tab($gdg_cols[1],$gdg_cols[2])"); 

  my $gdt_tab = "${tableBase}Transcript";
  my @gdt_cols = ('genome_dots_transcript_id', 'taxon_id', 'genome_external_db_release_id',
		  $gdg_cols[0], 'blat_alignment_id', 'na_sequence_id');
  my @gdt_types = ('NUMBER(10) NOT NULL', 'NUMBER(10) NOT NULL', 'NUMBER(10)',$gdg_types[0],
		   'NUMBER(10)', 'NUMBER(10)');
  my @gdt_csts = ("alter table ${tmpLogin}.$gdt_tab add constraint PK_" . uc($gdt_tab) . " primary key ($gdt_cols[0])",
		  "alter table ${tmpLogin}.$gdt_tab add constraint " . uc($gdt_tab)
		  . "_FK01 foreign key ($gdt_cols[3]) references ${tmpLogin}.$gdg_tab ($gdg_cols[0])",
		  "create index GENOME_DG_TRANS_IND01 on ${tmpLogin}.$gdt_tab($gdt_cols[4],$gdt_cols[5])",
                  "create index GENOME_DG_TRANS_IND02 on ${tmpLogin}.$gdt_tab($gdt_cols[5])",
                   ); 

  unless ($donotCreate) {
    #  $dbh->do("drop table ${tmpLogin}.$g2s_tab");
      $dbh->do("drop table ${tmpLogin}.$gdt_tab") or print "";
      $dbh->do("drop table ${tmpLogin}.$gdg_tab") or print "";
      $dbh->do("drop index " . uc($gdg_tab) . "_IND01") or print "";
      $dbh->do("drop index GENOME_DG_TRANS_IND01") or print "";
      $dbh->do("drop index GENOME_DG_TRANS_IND02") or print "";
  
      $self->createTable($dbh, $tmpLogin, $gdg_tab, \@gdg_cols, \@gdg_types, \@gdg_csts);
      $self->createTable($dbh, $tmpLogin, $gdt_tab, \@gdt_cols, \@gdt_types, \@gdt_csts);
      # &createTable($dbh, $tmpLogin, $g2s_tab, \@g2s_cols, \@g2s_types, \@g2s_csts);
  }

  return ($gdg_tab, \@gdg_cols, \@gdg_types, $gdt_tab, \@gdt_cols, \@gdt_types);
}

sub createTable {
    my ($self, $dbh, $schema, $tab, $cols, $types, $constraints) = @_;

    my $num_cols = scalar(@$cols);
    die "number of columns and number of column types mismatch" if scalar(@$types) != $num_cols;

    my $sql = "CREATE TABLE ${schema}.$tab\n(";
    for (my$i=0; $i<$num_cols; $i++) {
	$sql .= $cols->[$i] . ' ' . $types->[$i] . ($i < $num_cols - 1 ? ',' : '') . "\n";
    }
    $sql .= ")";
    $self->log("creating ${schema}.$tab table...");
    $dbh->sqlexec($sql);
    $dbh->sqlexec("GRANT SELECT ON ${schema}.$tab to PUBLIC");
    foreach (@$constraints) { $dbh->sqlexec($_); }
}

sub createTempProcedures {
    my ($self, $dbh, $essSp, $eesSp) = @_;
    my $tableBase = $self->getArg('tableName');
    my $tab = "${tableBase}Gene";
    $self->createStoredProcedure($dbh, $essSp, $tab, 'genome_dots_gene_id', 'exonstarts');
    $self->createStoredProcedure($dbh, $eesSp, $tab, 'genome_dots_gene_id', 'exonends');
}

sub saveGene {
    my ($self, $dgid, $dtid, $gene, $tmpMeta, $exonstarts_sp, $exonends_sp) = @_;

    my ($gdg_tab, $gdg_cols, $gdg_types, $gdt_tab, $gdt_cols, $gdt_types) = @$tmpMeta;

    my $dbh = $self->getQueryHandle();
    my $taxonId = $self->getArg('taxon_id');
    my $genomeId = $self->getArg('genome_db_rls_id');
    my $tmpLogin = $self->getArg('temp_login');
    my $isTest = $self->getArg('test');

    my $ess = join(',', $gene->getSpanStarts);
    my $ees = join(',', $gene->getSpanEnds);
    my $tooBig = length($ess) >= 4000 || length($ees) >= 4000;

    my $sql = "insert into ${tmpLogin}.$gdg_tab ($gdg_cols->[0], $gdg_cols->[1], "
	. "$gdg_cols->[2], $gdg_cols->[3], $gdg_cols->[4], $gdg_cols->[5], "
	. "$gdg_cols->[6], $gdg_cols->[7], $gdg_cols->[8], $gdg_cols->[9], "
	. "$gdg_cols->[10], $gdg_cols->[11], $gdg_cols->[12], $gdg_cols->[13], "
	. "$gdg_cols->[14], $gdg_cols->[31], $gdg_cols->[32], $gdg_cols->[33]) "
	. "values ($dgid, $taxonId, $genomeId, " . "'" . $gene->getChrom . "',"
	. $gene->getChromStart . "," . $gene->getChromEnd . ",'" . $gene->getStrand . "',"
	. $gene->getTotalSpanSize . "," . $gene->getNumberOfSpans . ","
	. $gene->getMinSpanSize . "," . $gene->getMaxSpanSize . ","
	. $gene->getMinInterspanSize. "," . $gene->getMaxInterspanSize. ","
	. "'" . ($tooBig ? substr($ess, 0, 1) : $ess) . "', '" . ($tooBig ? substr($ees, 0, 1) : $ees) . "',"
	. $gene->getAnnotationProperties->{'omc'} . ","
	. $gene->getAnnotationProperties->{'cmc'} . ","
	. $gene->getAnnotationProperties->{'pmc'} . ")";
    if ($isTest) {
	$self->log("In testing mode, o.w. would run $sql");
    } else {
	$dbh->sqlexec($sql);
	if ($tooBig) {
	    &appendClob($dbh, $exonstarts_sp, $dgid, $ess); 
	    &appendClob($dbh, $exonends_sp, $dgid, $ees);
	}
    }

    my @transcripts = $gene->getConstituents();
    foreach my $t (@transcripts) {
	my $bid = $t->getId();
        my $dots = $t->getAnnotationProperties()->{na_sequence_id};

	my $sql = "insert into ${tmpLogin}.$gdt_tab "
	    . "($gdt_cols->[0], $gdt_cols->[1], $gdt_cols->[2], $gdt_cols->[3], $gdt_cols->[4], "
	    . "$gdt_cols->[5]) values (" . $dtid++ . ", $taxonId, $genomeId, $dgid, $bid, $dots)";
	if ($isTest) {
	    $self->log("In testing mode, o.w. would run $sql");
	} else {
	    $dbh->sqlexec($sql);
	}
    }
    return scalar(@transcripts);
}

# Write the complete contents of the current sequence buffer to the CLOB 
# in the database
#
sub appendClob {
    my($dbh, $sp, $id, $val) = @_;
    my $appender = $dbh->prepare("BEGIN $sp(?, ?); END;");

    my $len = length($val) - 1;
    print STDERR "appending $len chars using stored procedure $sp for id: $id ...\n";
    my $actual_len = 0;
    for (my $i=1; $i<$len; $i += 4000) {
	my $substr = substr($val, $i, 4000);
	$appender->execute($id, $substr);
	$actual_len += length($substr);
    }
    if ($actual_len != $len) {
	die "unexpected error: not able to append $len char using $sp for $id\n";
    }
}

sub createStoredProcedure {
  my ($self, $dbh, $spName, $tab, $idCol, $col) = @_;

  my $sp =<<SP;
CREATE OR REPLACE PROCEDURE $spName (id NUMBER, val VARCHAR) IS
	clob_loc CLOB;
   BEGIN
	SELECT $col INTO clob_loc
	FROM $tab where $idCol = id
	FOR UPDATE;
	DBMS_LOB.WRITEAPPEND(clob_loc, length(val), val);
   END $spName;
SP
  $dbh->do($sp);
}

1;
