use strict;

#use lib "$ENV{GUS_HOME}/lib/perl";
#use GUS::Pipeline::Manager;
#use GUS::Pipeline::MakeTaskDirs;
#use CBIL::Util::PropertySet;
#use File::Basename;

sub createDotsPipelineDir {
  my ($propertySet, $mgr) = @_;

  my $buildName = $mgr->{buildName};

  my $dotsBuildDir = $propertySet->getProp('dotsBuildDir');
  my $serverPath = $propertySet->getProp('serverPath');
  my $nodePath = $propertySet->getProp('nodePath');
  my $rmTaskSize = $propertySet->getProp('repeatmask.taskSize');
  my $rmPath = $propertySet->getProp('repeatmask.path');
  my $rmOptions = $propertySet->getProp('repeatmask.options');
  my $dangleMax = $propertySet->getProp('repeatmask.dangleMax');
  my $bmTaskSize = $propertySet->getProp('blastmatrix.taskSize');
  my $bsTaskSize = $propertySet->getProp('blastsimilarity.taskSize');
  my $bsBparam = $propertySet->getProp('blastsimilarity.Bparam');
  my $bsVparam = $propertySet->getProp('blastsimilarity.Vparam');
  my $bsEparam = $propertySet->getProp('blastsimilarity.Eparam');
  my $wuBlastBinPathLiniac = $propertySet->getProp('wuBlastBinPathLiniac');
  my $ncbiBlastBinPathLiniac = $propertySet->getProp('ncbiBlastBinPathLiniac');

  return if (-e "$dotsBuildDir/$buildName/seqfiles");

  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/seqfiles");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/epcr");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/misc");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/genetrap");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/blastSite");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/downloadSite");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/cluster/initial");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/cluster/intermed");
  $mgr->runCmd("mkdir -p $dotsBuildDir/$buildName/cluster/gene");

  &makeRMDir("assemSeqs", $buildName, $dotsBuildDir,
	     $serverPath, $nodePath, $rmTaskSize, $rmOptions, $dangleMax, $rmPath);
  &makeRMDir("prevDots", $buildName, $dotsBuildDir,
	     $serverPath,  $nodePath, $rmTaskSize, $rmOptions, $dangleMax, $rmPath);
  &makeRMDir("intermedDots", $buildName, $dotsBuildDir,
	     $serverPath,  $nodePath, $rmTaskSize, $rmOptions, $dangleMax, $rmPath);
  &makeRMDir("finalDots", $buildName, $dotsBuildDir,
	     $serverPath,  $nodePath, $rmTaskSize, $rmOptions, $dangleMax, $rmPath);

  &makeMatrixDir("assemSeqs", "assemSeqs", $buildName, $dotsBuildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathLiniac);
  &makeMatrixDir("prevDots", "assemSeqs", $buildName, $dotsBuildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathLiniac);
  &makeMatrixDir("prevDots", "prevDots", $buildName, $dotsBuildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathLiniac);
  &makeMatrixDir("intermedDots", "intermedDots", $buildName, $dotsBuildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathLiniac);
  &makeMatrixDir("finalDots", "finalDots", $buildName, $dotsBuildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathLiniac);

  # These parm lists seem to have problems
  #  &makeSimilarityDir("finalDots", "$serverPath/$buildName/seqfiles","nrdb", $buildName, $dotsBuildDir,
  #		     $serverPath, $nodePath, $bsTaskSize,
  #		     $wuBlastBinPathLiniac,
  #		     "nrdb.fsa", ,'finalDots.fsa','(\d+)', 'blastx',
  #		     "-wordmask=seg+xnu W=3 T=1000 B=$bsBparam V=$bsVparam E=$bsEparam");
  #  &makeSimilarityDir("finalDots", "$serverPath/$buildName/seqfiles", "prodom", $buildName, $dotsBuildDir,
  #		     $serverPath, $nodePath, $bsTaskSize,
  #		     $wuBlastBinPathLiniac,
  #		     "prodom.fsa", ,'finalDots.fsa','(\S+)', 'blastx',
  #		     "-wordmask=seg+xnu W=3 T=1000 B=$bsBparam V=$bsVparam E=$bsEparam");
  #  &makeSimilarityDir("finalDots", "$serverPath/$buildName/seqfiles", "cdd", $buildName, $dotsBuildDir,
  #		     $serverPath, $nodePath, $bsTaskSize,
  #		     $ncbiBlastBinPathLiniac,
  #		     "cdd/All",  ,'finalDots.fsa','\w+\|\w+\|\d+\s+(\w+)', 'rpsblast',
  #		     "-a 2 -e .1 -p F");
  &makeSimilarityDir("finalDots", "nrdb", $buildName, $dotsBuildDir,
		     $serverPath, $nodePath, $bsTaskSize,
		     $wuBlastBinPathLiniac,
		     "nrdb.fsa", "$serverPath/$buildName/seqfiles", 'finalDots.fsa', '(\d+)', 'blastx',
		     "-wordmask=seg+xnu W=3 T=1000 B=$bsBparam V=$bsVparam E=$bsEparam");
  &makeSimilarityDir("finalDots", "prodom", $buildName, $dotsBuildDir,
		     $serverPath, $nodePath, $bsTaskSize,
		     $wuBlastBinPathLiniac,
		     "prodom.fsa", "$serverPath/$buildName/seqfiles", 'finalDots.fsa', '(\S+)', 'blastx',
		     "-wordmask=seg+xnu W=3 T=1000 B=$bsBparam V=$bsVparam E=$bsEparam");
  &makeSimilarityDir("finalDots", "cdd", $buildName, $dotsBuildDir,
		     $serverPath, $nodePath, $bsTaskSize,
		     $ncbiBlastBinPathLiniac,
		     "cdd/All", "$serverPath/$buildName/seqfiles", 'finalDots.fsa',
		     '\w+\|\w+\|\d+\s+(\w+)', 'rpsblast', "-a 2 -e .1 -p F");

  &makeAssemblyDir("initial", $buildName, $dotsBuildDir, $mgr);
  &makeAssemblyDir("intermed", $buildName, $dotsBuildDir, $mgr);

  $mgr->runCmd("chmod -R g+w $dotsBuildDir/$buildName");
}

sub makeAssemblyDir {
  my ($name, $buildName, $localDir, $mgr) = @_;

  $mgr->runCmd("mkdir -p $localDir/$buildName/assembly/$name/big");
  $mgr->runCmd("mkdir -p $localDir/$buildName/assembly/$name/small");
}

sub downloadGenbank {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "downloadGenbank";

  return if $mgr->startStep("Downloading Genbank", $signal,'downloadGenbank');

  $ENV{ftp_proxy} = 'http://proxy.pcbi.upenn.edu:3128/';

  my $externalDbDir = $propertySet->getProp('externalDbDir');
  my $genbankRel = $propertySet->getProp('genbankRel');

  my $downloadSubDir = "$externalDbDir/genbank/$genbankRel";

  my $logfile = "$mgr->{pipelineDir}/logs/downloadGenbank.log";

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $rejectFiles = $propertySet->getProp('gbRejectFiles');
  my $acceptFiles = $propertySet->getProp('gbAcceptFiles');
  #    my $cmd = "wget -t5 -o $logfile -b -m -np -nd -nH --cut-dirs=1 -R \"gbest*,gbgss*,gbhtg*,gbpat*,gbphg*,gbpln*,gbvrt*,gbvrl*,gbuna*,gbsts*,gbbct*,gbcon*,gbinv*,gbmam*\" -A \"*.seq.gz,README.genbank\"  -P $downloadSubDir ftp://ftp.ncbi.nih.gov/genbank/";
  my $cmd = "wget -t5 -o $logfile -b -m -np -nd -nH --cut-dirs=1 -R \"$rejectFiles\" -A \"$acceptFiles\" -P $downloadSubDir ftp://ftp.ncbi.nih.gov/genbank/";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}


sub downloadTaxon {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "downloadTaxon";

  return if $mgr->startStep("Downloading Taxon", $signal,'downloadTaxon');

  $ENV{ftp_proxy} = 'http://proxy.pcbi.upenn.edu:3128/';

  my $logfile = "$mgr->{pipelineDir}/logs/downloadTaxon.log";

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $downloadSubDir = "$externalDbDir/taxonomy/$date";

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $cmd = "wget -t5 -o $logfile -b -m -np -nd -nH --cut-dirs=2 -A \"gi_taxid_nucl.dmp.gz,gi_taxid_prot.dmp.gz,taxdump.tar.gz\" -P $downloadSubDir  ftp://ftp.ncbi.nih.gov/pub/taxonomy/";

  $mgr->runCmd($cmd);

  $mgr->runCmd("gunzip $downloadSubDir/taxdump.tar.gz");

  $mgr->runCmd("tar --extract --file $downloadSubDir/taxdump.tar -C $downloadSubDir");

  $mgr->runCmd("gunzip $downloadSubDir/gi_taxid_nucl.dmp.gz");

  $mgr->runCmd("gunzip $downloadSubDir/gi_taxid_prot.dmp.gz");

  $mgr->endStep($signal);

}

sub downloadNRDB {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "downloadNRDB";

  return if $mgr->startStep("Downloading NRDB", $signal, 'downloadNRDB');

  $ENV{ftp_proxy} = 'http://proxy.pcbi.upenn.edu:3128/';

  my $logfile = "$mgr->{pipelineDir}/logs/${signal}.log";

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $downloadSubDir = "$externalDbDir/nrdb/$date";

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $cmd = "wget -t5 -b -m -np -nd -nH -o $logfile --cut-dirs=4 -A \"nr.gz\"  -P $downloadSubDir  ftp://ftp.ncbi.nih.gov/blast/db/FASTA/";
	
  $mgr->runCmd($cmd);

  $mgr->runCmd("gunzip $downloadSubDir/nr.gz");

  $mgr->endStep($signal);
}

sub insertTaxon {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $downloadSubDir = "$externalDbDir/taxonomy/$date";

  my $names = "$downloadSubDir/names.dmp";
  my $nodes = "$downloadSubDir/nodes.dmp";
  my $gencode = "$downloadSubDir/gencode.dmp";
  my $restart = $propertySet->getProp('insertTaxonRestart');

  my $args = "--names $names --nodes $nodes --gencode $gencode --restart $restart";

  $mgr->runPlugin("loadTaxon", "GUS::Common::Plugin::LoadTaxon", $args,
		  "Loading Taxon tables",'downloadTaxon');
}

sub parseGenbank {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "parseGenBank";

  my $genbankRel = $propertySet->getProp('genbankRel');

  my $gb_db_rel_id = $propertySet->getProp('gb_db_rel_id');

  my @gbFiles = split (/,/, $propertySet->getProp('gbFiles'));

  my $externalDbDir = $propertySet->getProp('externalDbDir');


  foreach my $file (@gbFiles) {

    my $dirAndFile = "$externalDbDir/genbank/$genbankRel/$file";

    my $args = "--gbRel $genbankRel --file $dirAndFile  --db_rel_id $gb_db_rel_id";

    my $signal = "gbParse_${file}";

    $mgr->runPlugin($signal, "GUS::Common::Plugin::GBParser",
		    $args, "Loading GenBank files into GUS");

  }

  my $dotsBuildDir = $propertySet->getProp('dotsBuildDir');
  foreach my $file (@gbFiles) {

    my $dotsRelease = "release" . $propertySet->getProp('dotsRelease');

    my $buildName = &makeBuildName($taxonPropertySet->getProp('speciesNickname'),
				   $propertySet->getProp('dotsRelease'));

    my $subDir = "gbParse_".$file;

    my $failFiles = "$dotsBuildDir/$dotsRelease/$buildName/plugins/$subDir/gbparserFailures/*.gb";

    my @fileArr = <$failFiles>;

    if ((scalar @fileArr) >= 1) {
      die "There are GenBank entry failures - evaluate and run GBParser manually - then restart dotsbuild\n";
    }
  }

  $mgr->endStep($signal);

}


sub parsedbEST {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $restart = $propertySet->getProp('dbESTRestart');

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $args = "--log $mgr->{pipelineDir}/logs/dbest.log --fullupdate --span 500 --project 'dbEST Parser' --taxon_id $taxonId --restart_number $restart";

  $mgr->runPlugin("loadDbEst", "GUS::Common::Plugin::dbEST", $args,
		  "Loading dbEST files into GUS", 'loadDbEst');
}

sub makeAssemSeqs {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $file = $propertySet->getProp('fileOfRepeats');

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $repeatFile = "$externalDbDir/repeat/$file";
	
  my $phrapDir = $propertySet->getProp('phrapDir');

  my $args = "--taxon_id $taxonId --repeatFile $repeatFile --phrapDir $phrapDir";

  $mgr->runPlugin("makeAssemSeqs",
		  "DoTS::DotsBuild::Plugin::MakeAssemblySequences", $args,
		  "Making assembly table sequences");
}

sub extractAssemSeqs {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $outputFile = "$mgr->{pipelineDir}/seqfiles/assemSeqs.fsa";
  my $args = "--taxon_id=$taxonId --outputfile $outputFile --extractonly";

  $mgr->runPlugin("extractAssemSeqs",
		  "DoTS::DotsBuild::Plugin::ExtractAndBlockAssemblySequences",
		  $args, "Extracting assembly table sequences");

}


# $name is prevDots or intermedDots
sub extractDots {
  my ($name, $DTprefix, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  $name = "${name}Dots";
  my $signal = "${name}Extract";

  return if $mgr->startStep("Extracting $name assemblies from GUS", $signal);

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');
  my $taxonId = $taxonPropertySet->getProp('taxonId');
  my $species = $taxonPropertySet->getProp('speciesFullname');

  my $seqFile = "$mgr->{pipelineDir}/seqfiles/$name.fsa";
  my $logFile = "$mgr->{pipelineDir}/logs/${name}Extract.log";

  my $sql = "select $DTprefix na_sequence_id,'[$species]',description,'('||number_of_contained_sequences||' sequences)','length='||length,sequence from dots.Assembly where taxon_id = $taxonId";

  my $cmd = "dumpSequencesFromTable.pl --outputFile $seqFile --gusConfigFile $gusConfigFile  --verbose --idSQL \"$sql\" 2>>  $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}


sub copyPipelineDirToLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $dotsBuildDir = $propertySet->getProp('dotsBuildDir');

  my $nickName = $taxonPropertySet->getProp('speciesNickname');
  my $dotsRelease = "release" . $propertySet->getProp('dotsRelease');
  my $serverPath = $propertySet->getProp('serverPath') . "/$dotsRelease";
  my $liniacServer = $propertySet->getProp('liniacServer');
  my $fromDir = "$dotsBuildDir/$dotsRelease";
  my $signal = "dir2liniac";
  return if $mgr->startStep("Copying $dotsBuildDir/$dotsRelease/$nickName to $serverPath on $liniacServer", $signal);

  $mgr->copyToLiniac($fromDir, $nickName, $liniacServer, $serverPath);

  $mgr->endStep($signal);
}

sub startBlastMatricesOnLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $liniacServer = $propertySet->getProp('liniacServer');
  my $serverPath = $propertySet->getProp('serverPath');
  my $signal = "runmatrices";
  return if $mgr->startStep("Starting blast matrices", $signal);

  $mgr->endStep($signal);

  my $script = "runInitialMatrices";
  if ($taxonPropertySet->getProp('firstTime') eq "yes") {
    $script = "runAssemAssemMatrices";
  }

  my $liniacCmdMsg = "submitPipelineJob $script $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $liniacLogMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToLiniac($liniacCmdMsg, $liniacLogMsg, 1);
}

sub copyBlastMatricesFromLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $liniacServer = $propertySet->getProp('liniacServer');

  my $signal = "matricesFromLiniac";
  return if $mgr->startStep("Copying matrices from $liniacServer", $signal);

  $mgr->copyFromLiniac($liniacServer,
                       "$serverPath/$mgr->{buildName}/repeatmask/assemSeqs/master/mainresult",
                       "blocked.err",
                       "$mgr->{pipelineDir}/repeatmask/assemSeqs");

  my @names = ("assemSeqs-assemSeqs", "prevDots-assemSeqs", "prevDots-prevDots");
  if ($taxonPropertySet->getProp('firstTime') eq 'yes') {
    @names = ("assemSeqs-assemSeqs");
  }

  foreach my $name (@names) {
    $mgr->copyFromLiniac($liniacServer,
			 "$serverPath/$mgr->{buildName}/matrix/$name/master/mainresult",
			 "blastMatrix.out.gz",
			 "$mgr->{pipelineDir}/matrix/$name");
  }

  $mgr->endStep($signal);
}

sub initialCluster {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  if ($taxonPropertySet->getProp('firstTime') eq 'yes') {
    &cluster($mgr, "initial", "assemSeqs-assemSeqs");
  } else {
    &cluster($mgr, "initial", "prevdots-prevDots",
	     "assemSeqs-assemSeqs", "prevDots-assemSeqs");
  }
}

sub cluster {
  my ($mgr, $name, @matrices) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Cluster";

  return if $mgr->startStep("Clustering $name", $signal);

  my $length = $propertySet->getProp("$signal.length");
  my $percent = $propertySet->getProp("$signal.percent");
  my $logbase = $propertySet->getProp("$signal.logbase");
  my $consistentEnds = $propertySet->getProp("$signal.consistentEnds");
  my $cliqueSzArray = $propertySet->getProp("$signal.cliqueSzArray");
  my $logbaseArray = $propertySet->getProp("$signal.logbaseArray");

  my @matrixFileArray;
  foreach my $matrix (@matrices) {
    push(@matrixFileArray,
	 "$mgr->{pipelineDir}/matrix/$matrix/blastMatrix.out.gz");
  }
  my $matrixFiles = join(",", @matrixFileArray);

  my $ceflag = ($consistentEnds eq "yes")? "--consistentEnds" : "";

  my $outputFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";
  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $cmd = "buildBlastClusters.pl --lengthCutoff $length --percentCutoff $percent --verbose --files '$matrixFiles' --logBase $logbase --iterateCliqueSizeArray $cliqueSzArray $ceflag --iterateLogBaseArray $logbaseArray --sort > $outputFile 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub splitCluster {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}SplitCluster";

  return if $mgr->startStep("SplitCluster $name", $signal);

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";
  my $splitCmd = "splitClusterFile $clusterFile";

  $mgr->runCmd($splitCmd);
  $mgr->endStep($signal);
}

sub assemble {
  my ($old, $reassemble, $name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Assemble";

  return if $mgr->startStep("Assemble $name", $signal);

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";

  &runAssemblePlugin($clusterFile, "big", $name, $old, $reassemble, $mgr);
  &runAssemblePlugin($clusterFile, "small", $name, $old, $reassemble, $mgr);
  $mgr->endStep($signal);
  my $msg =
    "EXITING.... PLEASE DO THE FOLLOWING:
 1. check for errors in assemble.errLog and sql failures in updateDOTSAssemblies.log
 2. resume when assembly completes (validly) by re-runnning 'dotsbuild $mgr->{propertiesFile}'
";
  print STDERR $msg;
  print $msg;
  $mgr->goodbye($msg);
}

sub runAssemblePlugin {
  my ($file, $suffix, $name, $assembleOld, $reassemble, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $reass = $reassemble eq "yes"? "--reassemble" : "";
  my $args = "--clusterfile $file.$suffix $assembleOld $reass --taxon_id $taxonId";
  my $pluginCmd = "ga DoTS::DotsBuild::Plugin::UpdateDotsAssembliesWithCap4 --commit $args --comment '$args'";

  my $logfile = "$mgr->{pipelineDir}/logs/${name}Assemble.$suffix.log";

  my $assemDir = "$mgr->{pipelineDir}/assembly/$name/$suffix";
  $mgr->runCmd("mkdir -p $assemDir");
  chdir $assemDir || die "Can't chdir to $assemDir";

  my $cmd = "runUpdateAssembliesPlugin --clusterFile $file.$suffix --pluginCmd \"$pluginCmd\" 2>> $logfile";
  $mgr->runCmdInBackground($cmd);
}

sub reassemble {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "${name}Reassemble";

  return if $mgr->startStep("Reassemble $name", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $sql = "select na_sequence_id from dots.assembly where taxon_id = $taxonId  and (assembly_consistency < 90 or length < 50 or length is null or description = 'ERROR: Needs to be reassembled')";

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";

  my $suffix = "reassemble";

  my $old = "";

  my $reassemble = "yes";

  my $cmd = "makeClusterFile --idSQL \"$sql\" --clusterFile $clusterFile.$suffix";

  $mgr->runCmd($cmd);

  &runAssemblePlugin($clusterFile, $suffix, $name, $old, $reassemble, $mgr);

  $mgr->endStep($signal);
  my $msg =
    "EXITING.... PLEASE DO THE FOLLOWING:
 1. resume when reassembly completes (validly) by re-runnning 'dotsbuild $mgr->{propertiesFile}'
";
  print STDERR $msg;
  print $msg;
  $mgr->goodbye($msg);
}

sub matrix {
  my ($name, $mgr) = @_;

  &copyDotsToLiniac($name, $mgr);

  &startDotsMatrixOnLiniac($name, $mgr);

  &copyDotsMatrixFromLiniac($name, $mgr);
}

sub copyDotsToLiniac {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $liniacServer = $propertySet->getProp('liniacServer');

  my $seqfilesDir = "$mgr->{pipelineDir}/seqfiles";
  my $f = "${name}Dots.fsa";

  my $signal = "${name}Dots2liniac";
  return if $mgr->startStep("Copying $seqfilesDir/$f to $serverPath/$mgr->{buildName}/seqfiles on $liniacServer", $signal);

  $mgr->copyToLiniac($seqfilesDir, $f, $liniacServer, "$serverPath/$mgr->{buildName}/seqfiles");

  $mgr->endStep($signal);
}

sub startDotsMatrixOnLiniac {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');

  my $signal = "${name}DotsMatrix";
  return if $mgr->startStep("Starting ${name}Dots matrix", $signal);

  $mgr->endStep($signal);

  my $cmd = "run" . ucfirst($signal);

  my $liniacCmdMsg = "submitPipelineJob $cmd $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $liniacLogMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToLiniac($liniacCmdMsg, $liniacLogMsg, 0);
}

sub copyDotsMatrixFromLiniac {
  my($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $liniacServer = $propertySet->getProp('liniacServer');

  my $signal = "${name}DotsMatrixFromLiniac";

  return if $mgr->startStep("Copying ${name}Dots matrix from $liniacServer",
			    $signal);

  $mgr->copyFromLiniac($liniacServer,
		       "$serverPath/$mgr->{buildName}/matrix/${name}Dots-${name}Dots/master/mainresult",
		       "blastMatrix.out.gz",
		       "$mgr->{pipelineDir}/matrix/${name}Dots-${name}Dots");

  $mgr->endStep($signal);
}

sub sortClusters {
  my ($mgr) = @_;

  my $signal = "sortClusters";

  return if $mgr->startStep("Sort clusters into descending order", $signal);

  my $in = "$mgr->{pipelineDir}/cluster/gene/cluster.out";
  my $out = "$mgr->{pipelineDir}/cluster/gene/cluster.out.descending";

  $mgr->runCmd("sort --numeric-sort --field-separator ' ' --key 2.2 --reverse $in > $out");

  $mgr->endStep($signal);
}

sub loadRNAClusters {
  my ($mgr) = @_;
  my $file = "$mgr->{pipelineDir}/cluster/gene/cluster.out.descending";
  my $args = "--sort_desc --clusterfile $file";

  $mgr->runPlugin("loadRNAClusters", "DoTS::DotsBuild::Plugin::MakeRNAClustersForAssemblies", $args,
		  "Loading RNA Clusters");
}

sub insertNRDB {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $dbi_str = $propertySet->getProp('dbi_str');

  my $sourceDB = $propertySet->getProp('sourceDB');

  my $nrdb_maketemp = $propertySet->getProp('nrdb_maketemp');

  my $nrdb_plugin = $propertySet->getProp('nrdb_plugin');

  my $nrdb_delete = $propertySet->getProp('nrdb_delete');

  my $maketemp = $nrdb_maketemp eq "yes" ? "--maketemp" : "";

  my $plugin = $nrdb_plugin eq "yes" ? "--plugin" : "";

  my $delete = $nrdb_delete eq "yes" ? "--delete" : "";

  my $gitax = "$externalDbDir/taxonomy/$date/gi_taxid_prot.dmp";

  my $nrdb = "$externalDbDir/nrdb/$date/nr";

  my $temp_login = $propertySet->getProp('tempLogin');

  my $temp_password = $propertySet->getProp('tempPassword');

  my $restart = $propertySet->getProp('nrdbRestart') > 1 ? "--restart " . $propertySet->getProp('nrdbRestart') : "";

  my $nrdbReleaseId = $propertySet->getProp('nrdb_db_rls_id');

  my $args = "--temp_login \"$temp_login\" --sourceDB $sourceDB --temp_password \"$temp_password\" --dbi_str \"$dbi_str\" $restart --gitax $gitax --nrdb $nrdb --extDbRelId $nrdbReleaseId $maketemp $plugin $delete";

  $mgr->runPlugin("loadNRDB", "GUS::Common::Plugin::LoadNRDB", $args, "Loading NRDB", 'downloadNRDB');
}	



sub extractNRDB {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $nrdbReleaseId = $propertySet->getProp('nrdb_db_rls_id');

  my $sql = "select aa_sequence_id,'source_id='||source_id,'secondary_identifier='||secondary_identifier,description,'length='||length,sequence from dots.ExternalAASequence where external_database_release_id = $nrdbReleaseId";

  &extractProteinSeqs("nrdb", $sql, $mgr);
}

sub extractProteinSeqs {
  my ($name, $sql, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Extract";

  return if $mgr->startStep("Extracting $name protein sequences from GUS", $signal);

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $seqFile = "$mgr->{pipelineDir}/seqfiles/$name.fsa";
  my $logFile = "$mgr->{pipelineDir}/logs/${name}Extract.log";

  my $cmd = "dumpSequencesFromTable.pl --gusConfigFile $gusConfigFile  --outputFile $seqFile --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub downloadCDD {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  # produces seqfiles/cdd.tar

  my $signal = "downloadCDD";

  return if $mgr->startStep("Downloading CDD", $signal, 'downloadCDD');

  $ENV{ftp_proxy} = 'http://proxy.pcbi.upenn.edu:3128/';

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('cddDate');

  my $downloadSubDir = "$externalDbDir/cdd/$date";

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $logfile = "$mgr->{pipelineDir}/logs/$signal.log";

  $mgr->runCmd("/bin/rm -fr $downloadSubDir/*");

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $cmd = "wget -t5 -b -m -np -nd -nH -o $logfile --cut-dirs=3 -A \"cdd.tar.gz\"  -P $downloadSubDir ftp://ftp.ncbi.nih.gov/pub/mmdb/cdd/";
	
  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub unpackCDD {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "unpackCDD";
  return if $mgr->startStep("Unpacking CDD files", $signal, 'downloadCDD');

  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('cddDate');

  my $downloadSubDir = "$externalDbDir/cdd/$date";

  $mgr->runCmd("gunzip $downloadSubDir/cdd.tar.gz") unless (-e "$downloadSubDir/cdd.tar");

  $mgr->runCmd("tar --extract --file $downloadSubDir/cdd.tar -C $downloadSubDir");

  if (-e "$downloadSubDir/LOAD") {
    $mgr->runCmd("rm -f $downloadSubDir/LOAD");
  }

  $mgr->runCmd("catFiles --fileGlob  '$downloadSubDir/LOAD*.csq' --outFile $downloadSubDir/LOAD");

  if (-e "$downloadSubDir/PFAM") {
    $mgr->runCmd("rm -f $downloadSubDir/PFAM");
  }

  $mgr->runCmd("catFiles --fileGlob '$downloadSubDir/pfam*.csq' --outFile $downloadSubDir/PFAM");

  if (-e "$downloadSubDir/SMART") {
    $mgr->runCmd("rm -f $downloadSubDir/SMART");
  }

  $mgr->runCmd("catFiles --fileGlob '$downloadSubDir/smart*.csq' --outFile $downloadSubDir/SMART");

  if (-e "$downloadSubDir/COG") {
    $mgr->runCmd("rm -f $downloadSubDir/COG");
  }

  $mgr->runCmd("catFiles --fileGlob '$downloadSubDir/COG*.csq' --outFile $downloadSubDir/COG");

  if (-e "$downloadSubDir/KOG") {
    $mgr->runCmd("rm -f $downloadSubDir/COG");
  }

  $mgr->runCmd("catFiles --fileGlob '$downloadSubDir/KOG*.csq' --outFile $downloadSubDir/KOG");

  if (-e "$downloadSubDir/CD") {
    $mgr->runCmd("rm -f $downloadSubDir/CD");
  }

  $mgr->runCmd("catFiles --fileGlob '$downloadSubDir/cd*.csq' --outFile $downloadSubDir/CD");

  $mgr->runCmd("rm -r $downloadSubDir/cdd.tar");
	
  $mgr->endStep($signal);
}

sub insertCDD {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('cddDate');

  my $downloadSubDir = "$externalDbDir/cdd/$date";

  my $loadDB = $propertySet->getProp('load_db_rls_id');

  # >gnl|CDD|3794 LOAD_ACT, ACT, small ligand binding domain
  my $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(LOAD[\\_\\w]+)\\,\\s";
  my $regex_name = "^\\S+\\sLOAD[\\_\\w]+\\,\\s([\\w\\_\\s]+)\\,\\s";
  my $regex_desc = "^\\S+\\sLOAD[\\_\\w]+\\,\\s(.*)";

  my $loadArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/LOAD' --external_database_release_id $loadDB --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertLoad",
		  "GUS::Common::Plugin::InsertNewExternalSequences",
		  $loadArgs,
		  'Inserting Load', 'downloadCDD');

  my $pfamDB = $propertySet->getProp('pfam_db_rls_id');

  #>gnl|Pfam|pfam00291 PALP, Pyridoxal-phosphate dependent enzyme
  $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(pfam\\w+)";
  $regex_name = "^\\S+\\spfam\\w+\\,\\s([\\w\\_\\s]+)\\,\\s";
  $regex_desc = "^\\S+\\spfam\\w+\\,\\s(.*)";

  my $pfamArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/PFAM' --external_database_release_id $pfamDB --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertPfam", "GUS::Common::Plugin::InsertNewExternalSequences", $pfamArgs,
		  "Inserting Pfam", 'downloadCDD');

  my $smartDB = $propertySet->getProp('smart_db_rls_id');

  #>gnl|Smart|smart00238 BIR, Baculoviral inhibition of apoptosis protein repeat; Domain found in inhibitor of apoptosis proteins (IAPs) and other proteins. Acts as a direct inhibitor of caspase enzymes
  $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(smart\\w+)";
  $regex_name = "^\\S+\\ssmart\\w+\\,\\s([\\w\\_\\s]+)\\,\\s";
  $regex_desc = "^\\S+\\ssmart\\w+\\,\\s(.*)";

  my $smartArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/SMART' --external_database_release_id $smartDB  --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertSmart",
		  "GUS::Common::Plugin::InsertNewExternalSequences",
		  $smartArgs,
		  "Inserting Smart", 'downloadCDD');

  my $cogDB = $propertySet->getProp('cog_db_rls_id');

  #>gnl|CDD|9880 COG0004, AmtB, Ammonia permease [Inorganic ion transport and metabolism]

  $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(COG\\w+)";
  $regex_name = "^\\S+\\sCOG\\w+\\,\\s([\\w\\_\\s]+)\\,\\s";
  $regex_desc = "^\\S+\\sCOG\\w+\\,\\s(.*)";

  my $cogArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/COG' --external_database_release_id $cogDB  --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertCOG",
		  "GUS::Common::Plugin::InsertNewExternalSequences",
		  $cogArgs,
		  "Inserting COG", 'downloadCDD');

  my $kogDB = $propertySet->getProp('kog_db_rls_id');

  #>gnl|CDD|17806 KOG0007, KOG0007, Splicing factor 3a, subunit 1 [RNA processing and modification]

  $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(KOG\\w+)";
  $regex_name = "^\\S+\\sKOG\\w+\\,\\sKOG\\w+\\,\\s([\\w\\,\\s]+)\\[";
  $regex_desc = "^\\S+\\sKOG\\w+\\,\\sKOG\\w+\\,\\s[\\w\\,\\s]+\\[([\\w\\,\\s]+)\\]";

  my $kogArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/KOG' --external_database_release_id $kogDB  --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertKOG",
		  "GUS::Common::Plugin::InsertNewExternalSequences",
		  $kogArgs,
		  "Inserting KOG", 'downloadCDD');

  my $cdDB = $propertySet->getProp('cd_db_rls_id');

  $regex_src_id = "^\\>\\w+\\|\\w+\\|\\w+\\s(cd\\w+)";
  $regex_name = "^\\S+\\scd\\w+\\,\\s([\\w\\_\\s]+)\\,\\s";
  $regex_desc = "^\\S+\\scd\\w+\\,\\s(.*)";

  my $cdArgs = "--verbose --table_name 'DoTS::MotifAASequence' --sequencefile '$downloadSubDir/CD' --external_database_release_id $cdDB  --regex_source_id \'$regex_src_id\' --regex_name \'$regex_name\'  --regex_desc \'$regex_desc\'";

  $mgr->runPlugin("insertCD",
		  "GUS::Common::Plugin::InsertNewExternalSequences",
		  $cdArgs,
		  "Inserting CD", 'downloadCDD');

}

sub downloadProdom {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "downloadProdom";

  return if $mgr->startStep("Downloading Prodom", $signal, 'downloadProdom');

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $downloadSubDir = "$externalDbDir/prodom/$date";

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $logfile = "$mgr->{pipelineDir}/logs/$signal.log";

  $ENV{ftp_proxy} = 'http://proxy.pcbi.upenn.edu:3128/';

  $mgr->runCmd("/bin/rm -f $downloadSubDir/*");

  $mgr->runCmd("mkdir -p $downloadSubDir");

  my $cmd = "wget -t5 -b -m -np -nd -nH -o $logfile  --cut-dirs=3 -A \"prodom.cons.gz\"  -P $downloadSubDir ftp://ftp.toulouse.inra.fr/pub/prodom/current_release/";

  $mgr->runCmd($cmd);
  $mgr->runCmd("gunzip $downloadSubDir/prodom.cons.gz");

  $mgr->endStep($signal);
}

sub insertProdom {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('buildDate');

  my $downloadSubDir = "$externalDbDir/prodom/$date";

  my $prodomFile = "$downloadSubDir/prodom.cons";

  my $logFile = "$mgr->{pipelineDir}/logs/insertProdom.log";

  my $prodomDB = $propertySet->getProp('prodom_db_rls_id');

  #>PD000001 p2001.3 (5600) KIT(16) KPC1(13) CDC2(13) // KINASE TRANSFERASE ATP-BINDING SERINE/THREONINE-PROTEIN RECEPTOR TYROSINE-PROTEIN 2.7.1.-PHOSPHORYLATION PRECURSOR
  #>CONSENSUS#PD000001 | 380 | pd_PD000001; | (5600)  KINASE TRANSFERASE ATP-BINDING SERINE/THREONINE-PROTEIN RECEPTOR TYROSINE-PROTEIN 2.7.1.- PHOSPHORYLATION DOMAIN SERINE/THREONINE  as of 2003.1
  #my $regex_src_id = "^\\>(\\w+)";
  my $regex_src_id = "^\\>CONSENSUS#(\\w+)";
  my $regex_contained_seqs = "\\((\\d+)";
  #my $regex_name = "(\\(.+)\\s\\/\\/";
  #my $regex_desc = "\\/\\/\\s(.+)";
  my $regex_desc = "\\)\\s+(.+)";

  my $args = "--verbose --table_name DoTS::MotifAASequence --sequencefile $prodomFile --external_database_release_id $prodomDB --regex_source_id \"$regex_src_id\"  --regex_contained_seqs \"$regex_contained_seqs\" --regex_desc \"$regex_desc\"";

  $mgr->runPlugin("insertProdom",
		  "GUS::Common::Plugin::InsertNewExternalSequences", $args,
		  "Inserting Prodom", 'insertProdom');
}

sub extractProdom {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $prodomDB = $propertySet->getProp('prodom_db_rls_id');

  my $sql = "select aa_sequence_id,'source_id='||source_id,'secondary_identifier='||secondary_identifier,description,'length='||length,sequence from dots.MotifAASequence where external_database_release_id = $prodomDB";

  &extractProteinSeqs("prodom", $sql, $mgr);
}

sub copyProteinDBsToLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $liniacServer = $propertySet->getProp('liniacServer');

  my $signal = "proteinDBs2Liniac";
  return if $mgr->startStep("Copying NRDB, CDD and Prodom to $serverPath/$mgr->{buildName}/seqfiles on $liniacServer", $signal);

  my $release = "release" . $propertySet->getProp('dotsRelease');
  my $speciesNickname = $propertySet->getProp('speciesNickname');
  my $dotsBuildDir = $propertySet->getProp('dotsBuildDir');
  my $seqfilesDir = "$dotsBuildDir/$release/$speciesNickname/seqfiles";
  my $f = "nrdb.fsa";
  $mgr->copyToLiniac($seqfilesDir, $f, $liniacServer,
		     "$serverPath/$mgr->{buildName}/seqfiles");

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $date = $propertySet->getProp('cddDate');

  my $downloadSubDir = "$externalDbDir/cdd";

  my $tmpCddDir = "$downloadSubDir/cdd";

  die "$tmpCddDir exists but it shouldn't" if -e $tmpCddDir;

  $mgr->runCmd("ln -s $downloadSubDir/$date $tmpCddDir");

  $mgr->copyToLiniac($downloadSubDir, "cdd", $liniacServer,
		     "$serverPath/$mgr->{buildName}/seqfiles");

  $mgr->runCmd("rm -f $tmpCddDir");

  $f = "prodom.fsa";
  $mgr->copyToLiniac($seqfilesDir, $f, $liniacServer,
		     "$serverPath/$mgr->{buildName}/seqfiles");

  $mgr->endStep($signal);
}

sub startSimilaritiesOnLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');

  my $signal = "findSimilarities";
  return if $mgr->startStep("Starting NRDB, CDD and Prodom similarites on liniac", $signal);

  $mgr->endStep($signal);

  my $liniacCmdMsg = "submitPipelineJob runSimilarities $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $liniacLogMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToLiniac($liniacCmdMsg, $liniacLogMsg, 1);
}

sub copySimilaritiesFromLiniac {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $liniacServer = $propertySet->getProp('liniacServer');

  my $signal = "copySimilaritiesFromLiniac";
  return if $mgr->startStep("Copying protein similarities from $liniacServer",
			    $signal);
  my @names = ("finalDots-nrdb","finalDots-prodom", "finalDots-cdd");
  foreach my $name (@names) {
    $mgr->copyFromLiniac($liniacServer,
			 "$serverPath/$mgr->{buildName}/similarity/$name/master/mainresult",
			 "blastSimilarity.out.gz",
			 "$mgr->{pipelineDir}/similarity/$name");
  }
  $mgr->endStep($signal);
}

sub deleteOldSimilarities {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');
  my $nrdbRel = $propertySet->getProp('nrdb_db_rls_id');
  my $prodomRel = $propertySet->getProp('prodom_db_rls_id');
  my $smartRel = $propertySet->getProp('smart_db_rls_id');
  my $pfamRel = $propertySet->getProp('pfam_db_rls_id');
  my $loadRel = $propertySet->getProp('load_db_rls_id');
  my $cogRel = $propertySet->getProp('cog_db_rls_id');
  my $cdRel = $propertySet->getProp('cd_db_rls_id');

  my $sql = "select /*+ RULE */ similarity_id from dots.similarity s, dots.assembly a, dots.aasequenceimp aas where s.query_table_id = 56 and s.query_id = a.na_sequence_id and a.taxon_id = $taxonId  and s.subject_table_id in (83,84,277) and s.subject_id = aas.aa_sequence_id and aas.external_database_release_id in ($nrdbRel,$prodomRel,$smartRel,$pfamRel,$loadRel,$cogRel,$cdRel)";

  my $args = "--idSQL \"$sql\" ";

  $mgr->runPlugin("deleteProteinSims",
		  "GUS::Common::Plugin::DeleteSimilarities", $args,
		  "Deleting old protein similarities");
}

sub insertProteinSimilarities {
  my ($name, $subjectTable, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $file = "$mgr->{pipelineDir}/similarity/$name/blastSimilarity.out.gz";
  $file .= ".correctPK" if ($name eq "finalDots-cdd");
  my $prop = "iPSRestart_$name";
  my $restart = $propertySet->getProp($prop);

  my $args = "--file $file --restartAlgInvs $restart --queryTable DoTS::Assembly --subjectTable $subjectTable --subjectsLimit 50 --hspsLimit 10";

  $mgr->runPlugin("loadSims_$name",
		  "GUS::Common::Plugin::LoadBlastSimFast", $args,
		  "Loading $name similarities");
}

sub substituteCDDPKs {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $smartDB = $propertySet->getProp('smart_db_rls_id');

  my $pfamDB = $propertySet->getProp('pfam_db_rls_id');

  my $loadDB = $propertySet->getProp('load_db_rls_id');

  my $cogDB = $propertySet->getProp('cog_db_rls_id');

  my $cdDB = $propertySet->getProp('cd_db_rls_id');

  my $kogDB = $propertySet->getProp('kog_db_rls_id');

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $signal = "substituteCDDPKs";

  return if $mgr->startStep("Substitituting primary keys into CDD similarities file",
			    $signal);

  my $file = "$mgr->{pipelineDir}/similarity/finalDots-cdd/blastSimilarity.out.gz";
  $mgr->runCmd("gunzip $file");
  my $infile = "$mgr->{pipelineDir}/similarity/finalDots-cdd/blastSimilarity.out";
  my $outfile = "$mgr->{pipelineDir}/similarity/finalDots-cdd/blastSimilarity.out.gz.correctPK";
  my $logfile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $sql = "select source_id,aa_sequence_id from dots.motifaasequence where external_database_release_id in ($smartDB,$pfamDB,$loadDB,$cogDB,$cdDB,$kogDB)";

  $mgr->runCmd("cat $infile | substitutePrimKeysInSimilarity --subjectSQL \"$sql\" --verbose --gusConfigFile $gusConfigFile > $outfile 2>> $logfile");

  $mgr->endStep($signal);
}

sub assignSequenceDescription {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $dotsRelease = $propertySet->getProp('dotsRelease');
  my $speciesNickname = $taxonPropertySet->getProp('speciesNickname');
  my $nrdbReleaseId = $propertySet->getProp('nrdb_db_rls_id');

  my $prefix = "${speciesNickname}DoTS_rel${dotsRelease}";

  my $assignDescriptionRestart = $propertySet->getProp('assignDescriptionRestart');


  my $restart = $assignDescriptionRestart > 1 ? "--restart \"select na_sequence_id from dots.assembly where row_alg_invocation_id in ($assignDescriptionRestart)\"" : "";

  my $dotsMGIfile = "$mgr->{pipelineDir}/misc/${prefix}_bestNRDBHits.dat";
  my $sql = "select na_sequence_id,na_sequence_id from dots.Assembly where taxon_id = $taxonId";

  my $args = "--update_rna_descriptions --copy_manual_descriptions --taxon_id $taxonId --table DoTS::Assembly --query_table DoTS::Assembly $restart --doNotVersion --nrdb_ext_db_rls_id $nrdbReleaseId --dots_mgi_file $dotsMGIfile  --idSQL \"$sql\"";

  $mgr->runPlugin("assignSeqDescrip",
		  "DoTS::DotsBuild::Plugin::AssignSequenceDescription",
		  $args,
		  "Assigning sequence descriptions from MGI");
}

sub deleteIndexWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "deleteIndexWords";

  return if $mgr->startStep("Deleting index_word_link_ids for assemblies from GUS", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $sql = "select index_word_link_id from dots.indexwordlink l,dots.assembly a where a.taxon_id = $taxonId and a.na_sequence_id = l.target_id and l.target_table_id = 56";

  my $cmd = "deleteEntries.pl --table DoTS::IndexWordLink --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub makeIndexWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $sql = "select na_sequence_id,description from dots.Assembly where taxon_id = $taxonId";

  my $args = "--attribute description --restart --table DoTS::Assembly --idSQL \"$sql\"";

  $mgr->runPlugin("makeIndexWords",
		  "GUS::Common::Plugin::MakeIndexWordLink", $args,
		  "Index assembly description words & add entries to IndexWordLink");
}


sub deleteNRDBIndexWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "deleteNRDBIndexWords";

  return if $mgr->startStep("Deleting nrdb index word links from GUS",
			    $signal, 'downloadNRDB');

  my $buildDate = $propertySet->getProp('buildDate');
  my $nrdbReleaseId = $propertySet->getProp('nrdb_db_rls_id');

  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $sql = "select index_word_link_id from dots.indexwordlink l,dots.externalaasequence e where e.aa_sequence_id = l.target_id and l.target_table_id = 83 and e.external_database_release_id = $nrdbReleaseId  and e.modification_date > '$buildDate'";

  my $cmd = "deleteEntries.pl --table DoTS::IndexWordLink --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub deleteMotifIndexWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "deleteMotifIndexWords";

  return if $mgr->startStep("Deleting motif index word links from GUS",
			    $signal, 'downloadCDD');

  my $buildDate = $propertySet->getProp('buildDate');

  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $sql = "select index_word_link_id from dots.indexwordlink l,dots.motifaasequence m where m.aa_sequence_id = l.target_id and l.target_table_id = 277 and m.modification_date > '$buildDate'";

  my $cmd = "deleteEntries.pl --table DoTS::IndexWordLink --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub makeNRDBIndexWordLink {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $nrdbReleaseId = $propertySet->getProp('nrdb_db_rls_id');

  my $sql = "select aa_sequence_id, description from dots.ExternalAASequence where external_database_release_id=$nrdbReleaseId and aa_sequence_id not in (select target_id from  dots.IndexWordLink where target_table_id=83)";

  my $args = "--attribute description --table DoTS::ExternalAASequence --idSQL \"$sql\"";

  $mgr->runPlugin("makeNRDBIndexWordLink",
		  "GUS::Common::Plugin::MakeIndexWordLink", $args,
		  "Making nrdb index word links", 'downloadNRDB');
}

sub makeMotifIndexWordLink {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $prodomReleaseId = $propertySet->getProp('prodom_db_rls_id');
  my $smartReleaseId = $propertySet->getProp('smart_db_rls_id');
  my $loadReleaseId = $propertySet->getProp('load_db_rls_id');
  my $pfamReleaseId = $propertySet->getProp('pfam_db_rls_id');
  my $cogReleaseId = $propertySet->getProp('cog_db_rls_id');
  my $cdReleaseId = $propertySet->getProp('cd_db_rls_id');

  my $sql = "select aa_sequence_id, description from dots.MotifAASequence where external_database_release_id in ($prodomReleaseId,$smartReleaseId,$loadReleaseId,$pfamReleaseId,$cogReleaseId,$cdReleaseId) and aa_sequence_id not in (select target_id from  dots.IndexWordLink where target_table_id=277)";

  my $args = "--attribute description --table DoTS::MotifAASequence --idSQL \"$sql\"";

  $mgr->runPlugin("makeMotifIndexWordLink",
		  "GUS::Common::Plugin::MakeIndexWordLink", $args,
		  "Making motif index word links", 'downloadCDD');
}

sub indexSimilarityWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $sql = "select a.na_sequence_id from dots.assembly a where a.taxon_id = $taxonId";

  my $args = "--similarity_table DoTS::MotifAASequence --target_table DoTS::Assembly --idSQL \"$sql\"";

  $args .= " --restart"
    if ($propertySet->getProp('indexSimilarityWordsRestart') eq "yes");

  $mgr->runPlugin("indexSimilarityWords",
		  "GUS::Common::Plugin::MakeIndexWordSimLink", $args,
		  "Indexing words in similarity descriptions");
}

sub indexNRDBWords {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $sql = "select a.na_sequence_id from dots.assembly a where a.taxon_id = $taxonId";

  my $args = "--similarity_table DoTS::ExternalAASequence --target_table DoTS::Assembly --idSQL \"$sql\"";

  $args .= " --restart"
    if ($propertySet->getProp('indexNRDBWordsRestart') eq "yes");

  $mgr->runPlugin("indexNRDBWords",
		  "GUS::Common::Plugin::MakeIndexWordSimLink", $args,
		  "Indexing words in NRDB descriptions");
}


sub getIdsPerAssembly {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "getIdsPerAssembly";

  return if $mgr->startStep("Getting ids per assembly", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $dotsRelease = $propertySet->getProp('dotsRelease');
  my $speciesNickname = $taxonPropertySet->getProp('speciesNickname');

  my $prefix = "${speciesNickname}DoTS_rel${dotsRelease}";

  my $output  = "$mgr->{pipelineDir}/misc/${prefix}_accessionsPerAssembly.dat";

  my $cmd = "getIdsPerAssembly --taxon_id $taxonId --gusConfigFile $gusConfigFile  > $output";

  $mgr->runCmd($cmd);

  my $cmd = "gzip $output";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);

}

sub getAssembliesPerGene {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "getAssembliesPerGene";

  return if $mgr->startStep("Getting assemblies per gene", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $dotsRelease = $propertySet->getProp('dotsRelease');

  my $speciesNickname = $taxonPropertySet->getProp('speciesNickname');

  my $prefix = "${speciesNickname}DoTS_rel${dotsRelease}";

  my $output  = "$mgr->{pipelineDir}/misc/${prefix}_DTperDG.dat";

  my $cmd = "getAssPerGene --taxon_id $taxonId --gusConfigFile $gusConfigFile  > $output";

  $mgr->runCmd($cmd);

  my $cmd = "gzip $output";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);

}

sub getmRNAPerAssembly {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "getmRNAPerAssembly";

  return if $mgr->startStep("Getting mRNA per Assembly", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $dotsRelease = $propertySet->getProp('dotsRelease');

  my $speciesNickname = $taxonPropertySet->getProp('speciesNickname');

  my $prefix = "${speciesNickname}DoTS_rel${dotsRelease}";

  my $output  = "$mgr->{pipelineDir}/misc/${prefix}_mRNAaccessionsPerAssembly.dat";

  my $cmd = "getmRNAperAssembly --taxon_id $taxonId --gusConfigFile $gusConfigFile  > $output";

  $mgr->runCmd($cmd);

  my $cmd = "gzip $output";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);

}

sub prepareBlastSiteFiles {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "prepareBlastSiteFiles";

  return if $mgr->startStep("Preparing files for blast site", $signal);

  # make blast files for this species
  my $dotsRelease = $propertySet->getProp('dotsRelease');
  my $speciesNickname = $taxonPropertySet->getProp('speciesNickname');
  my $blastBinDir = $propertySet->getProp('wuBlastBinPath');

  my $prefix = "${speciesNickname}DoTS_rel${dotsRelease}";
  my $fastafile = "$mgr->{pipelineDir}/downloadSite/${prefix}.fasta.gz";
  my $cmd = " gunzip $mgr->{pipelineDir}/downloadSite/${prefix}.fasta.gz";
  $mgr->runCmd($cmd);
  $fastafile = "$mgr->{pipelineDir}/downloadSite/${prefix}.fasta";
  my $fastalink = "$mgr->{pipelineDir}/blastSite/${speciesNickname}DoTS";
  $mgr->runCmd("ln -s $fastafile $fastalink");
  $mgr->runCmd("$blastBinDir/xdformat -n $fastalink");

  # make blast files for all species.  combine this build w/ latest of other species
  my $dotsBuildDir = $propertySet->getProp('dotsBuildDir');
  my $otherSpeciesNickname = $speciesNickname eq 'mus'? 'hum' : 'mus';
  my $otherSpeciesRelease = $propertySet->getProp('otherSpeciesRelease');
  my $otherSpeciesBuildName = &makeBuildNameRls($otherSpeciesNickname, $otherSpeciesRelease);
  my $otherPipelineDir = "$dotsBuildDir/$otherSpeciesBuildName";
  my $prefix = "${otherSpeciesNickname}DoTS_rel${otherSpeciesRelease}";

  my $cmd = "gunzip $otherPipelineDir/downloadSite/${prefix}.fasta.gz";
  $mgr->runCmd($cmd);
  my $fastafile2 = "$otherPipelineDir/downloadSite/${prefix}.fasta";
  my $fastalink2 = "$mgr->{pipelineDir}/blastSite/${otherSpeciesNickname}DoTS";
  $mgr->runCmd("ln -s $fastafile2 $fastalink2");
  $mgr->runCmd("cat $fastalink $fastalink2 > $mgr->{pipelineDir}/blastSite/allDoTS");
  $mgr->runCmd("$blastBinDir/xdformat -n $mgr->{pipelineDir}/blastSite/allDoTS");
  $mgr->runCmd("gzip $fastafile2");
  $mgr->runCmd("rm -rf $fastalink2");
  $mgr->runCmd("rm -rf $mgr->{pipelineDir}/blastSite/allDoTS");


  $mgr->runCmd("rm -rf $fastalink");

  $mgr->runCmd("gzip $fastafile");

  $mgr->endStep($signal);

}

sub markBadSeqs {
  my ($mgr) = @_;

  my $file = "$mgr->{pipelineDir}/repeatmask/assemSeqs/blocked.err";

  my $regex = "\\>(\\d+)";

  my $args = "--filename $file --processed_category repeat --regex_id \"$regex\"";

  $mgr->runPlugin("markBadSeqs",
		  "DoTS::DotsBuild::Plugin::MarkAssemblySequencesBad",
		  $args,
		  "Marking bad assembly table sequences");
}
sub makeProjectLink {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $taxonPropertySet = $mgr->{taxonPropertySet};

  my $signal = "makeProjectLink";

  return if $mgr->startStep("Insert links between projectinfo and nasequence into projectlink table", $signal);

  my $taxonId = $taxonPropertySet->getProp('taxonId');

  my $allgenesVer = $propertySet->getProp('allgenesVersion');

  my $project_id = $propertySet->getProp('project_id');

  my $logFile = "$mgr->{pipelineDir}/logs/${signal}.log";

  my $args;

  my $project = $project_id > 0 ? "--project_id ".$project_id : "";
  $args = "--commit --verbose --allgenes_num $allgenesVer --taxon $taxonId $project";

  $args .= " --restart"
    if ($propertySet->getProp('projectLinkRestart') eq "yes");

  my $cmd = "makeProjectLink.pl $args 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub makeBuildName {
  my ($nickName, $release) = @_;

  return makeBuildNameRls($nickName, $release);
}

sub makeBuildNameRls {
  my ($nickName, $release) = @_;

  return "release${release}/" . $nickName;
}

sub usage {
  print STDERR "usage:  dotsbuild propertiesfile\n";
  exit 1;
}

1;