#!/usr/env perl
# Eazy Perl Weekly Challenge EZPWC  
# This is a script that attempts to make Perl Weekly Challenges submission
# throgh github easier to do.  forks, clones, fetches, create new branch,
# views challenges, edits responses, tests code, then submits pull requests

use strict;use warnings;
use LWP::Simple qw($ua get head getstore);
use Cwd qw(getcwd);
use Data::Dumper ();
use Term::ANSIColor;

my $VERSION=0.13;

my $PWC_SITE = 'https://theweeklychallenge.org';

print color('bold green'),"Starting EZPWC $VERSION\n",color('reset');
# version notes

print color('bold yellow'),<<ENDMSG;
Version 0.13
now includes a branch manager.
Entering  '!' at any prompt allows you to submit an issue.
ENDMSG

print color("reset");       
my $OS=$^O;
my $directorySeparator= "/";  

if ($OS=~/Win/){
	unless( $ENV{HOME}){
		if ($ENV{USERPROFILE}) {$ENV{HOME}=$ENV{USERPROFILE} }
        elsif ( $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {$ENV{HOME} = $ENV{HOMEDRIVE} . $ENV{HOMEPATH};}
        else {$ENV{HOME} = '.';}  
  };
  $directorySeparator="\\";
};

####   Edit the following line to set working directory to be elsewhere    ####
my $workingDirectory=$ENV{HOME}.$directorySeparator."PerlChallenges";

my $codeExtensions="(\.pl|\.p6|\.py|\.sh)\$";
my %config;


setupDirectory();        # step 1 set up a directory locally if it has not been setup
versionCheck();          
setupGithub();           # step 2 set up user's existing github account or setting up a new one
makeFork();              # step 3 set up fork if not already forked
clone();                 # step 4 clone if not already cloned
setupGithub2();          # step 5 try and set up github credentials (issue raised by cpritchett)
addUpstream();           # step 6 ensure upstream has been set up 
fetchUpstream();         # step 7 fetch upstream
getBranches();           # step 8 get branches, and set one up for this week if required
getChallenges();         # step 9 get challenges from manwar's PWC blog

viewCodeTestCycle();     # step 10 view tasks, edit code, test the code unitl you are finished

readyToAdd();            # step 12 ready to add
saveConfig();	
print color('bold green'),"\n\nAll done...good bye!!\n",color('reset');
exit 0;

sub versionCheck{
	my $vc;
	my $check=$config{versionCheck};
	if (!$check){
		$vc=prompt("Do you wish to check for newer versions?:-",["Yes, every time","Yes this time only","Not at this time"]);
		$check=($vc=~/Yes/)?1:0;
		$config{versionCheck}=($vc=~/every time/);
	 }
	 if ($check){
		my $source="https://raw.githubusercontent.com/saiftynet/EZPWC/master/EZPWC.pl";
        my $latest= findItem($source,qr/VERSION=([\d\.]+);/m);
		if ($latest==$VERSION){
		  print "This is the latest version\n";
		  
		}
		elsif ($latest>$VERSION){
		  my $input=prompt("Newer version exists\nDo you wish to",["Download latest version into working directory",
		                                     "Download here (e.g if working from clone)",
		                                     "Stop checking for updates",
		                                     "Skip this"]);
           getstore($source, $config{workingDirectory}.$directorySeparator."EZPWC.pl")  if $input =~/working directory/;
           getstore($source, "EZPWC.pl") if $input =~/here/;
		}
		else {
		  print "You are more recent than github\n";
		}
	}
}

sub setupDirectory{
	if ( -e $workingDirectory and -d $workingDirectory){
		print "Working directory found\n";
	}
	else{
		print "Attempting to create working directory workingDirectory...\n";
		mkdir $workingDirectory
			or die "Could not create working directory $workingDirectory $!";
		chdir $workingDirectory;
		print "working directory created\n";
	}
	loadConfig();
}

sub setupGithub{
	if (($config{githubUN})&&(URLexists("https://github.com/$config{githubUN}"))){
		print "Github account for $config{githubUN} found...\n";
		return;		
	};
	
	print "Attempting to setup github...\n";

	while (not $config{githubUN}){  # setup github, and fork the repo   
	   $config{githubUN} = prompt ("Enter your github username or S to skip or C to create one: \n"); 
	   if ($config{githubUN} =~/^s$/i){
		   $config{githubUN}="..Skipped";
		   print "Skipping... \n";
		   }
	   elsif ($config{githubUN} =~/^c$/i){
			print "Browser should open page to join Github and create an account\n";
			print "After signing up you can fork manwar's perlweeklychallenge-club\n";
			browse2("https://github.com/join?source_repo=manwar%2Fperlweeklychallenge-club");
			my $response=prompt ( "Click enter after signing up\n");
		    $config{githubUN} = "";
		}
	   elsif (URLexists("https://github.com/$config{githubUN}")){
		   print "Found your github\n";
		   $config{githubEmail} = prompt ("Enter your github email: \n");
	   }
	   else {
		   print "User '$config{githubUN}' not found on GitHub\n";
		   $config{githubUN} = "";
	   }
   }
   $config{githubUN}=undef if ($config{githubUN} eq "..Skipped");
   saveConfig();
}

sub makeFork{
	
    if (!$config{githubUN}) {print "GitHub account not setup so cannot fork\n";return};
    if ($config{githubUN} eq $config{repoOwner}) { print "repo owner so no need to fork\n";return}
    if ($config{"fork"})    {print "Fork already set up\n";return};
	
	print "Checking for fork $config{repoName};...\n";
	$config{"fork"}=undef;
    while (!$config{"fork"}){
		if (URLexists("https://github.com/".$config{githubUN}."/".$config{repoName})){
		      print "Found your fork https://github.com/".$config{githubUN}."/".$config{repoName}."\n";
		      $config{"fork"}="found";
	    }
	    else{
			my $response=prompt ( "Fork not found\nDo you wish to create a fork y/n?");
			if ($response=~/^y/i){
			   print "Browser should open the master repo after a login request\n";
			   print "click on 'Fork' to fork the repo\n";
			   browse2("https://github.com/login?return_to=%2F".$config{repoOwner}."%2F".$config{repoName});
			   my $response=prompt ( "\nPress enter once fork completed");
			}
			else{
			   print "Skipping creation of fork.  This will need to be completed later\n";
			   $config{"fork"}="skipped";
			}
		}
	}
	$config{"fork"}=undef if ($config{"fork"} eq "skipped");
}

sub clone{
	if (!$config{"fork"} && (($config{githubUN} ne $config{repoOwner}) )) 
	   {print "Fork not setup so cannot clone \n";return};  
	if ($config{"clone"})   {print "Clone found\n";return};
	
	print "cloning repo\n";
	if  ( -e "$config{workingDirectory}".$directorySeparator."$config{repoName}" and 
	                  -d "$config{workingDirectory}".$directorySeparator."$config{repoName}") {
		print "Clone already appears to exist\n";
		$config{clone}=1;
	}					  
	else {
		$config{clone}=0;
		chdir $config{workingDirectory};
		print "Attempting to clone repo https://github.com/$config{githubUN}/$config{repoName}\n";	
		my $response= `git clone https://github.com/$config{githubUN}/$config{repoName}`;
		if ($response !~/^fatal/g){
			print "Success cloning repo";
			$config{clone}=1;
		};
	}
}

sub setupGithub2{
  if (!$config{githubUN}) {print "GitHub account not setup so cannot auto-authenticate\n";return};
  if (!$config{githubEmail}) {
		 $config{githubEmail} = prompt ("Enter your github email: \n"); 
		 };
   chdir "$config{workingDirectory}".$directorySeparator."$config{repoName}";
   print "Declaring  username=$config{githubUN} to git\n", `git config --global user.name '$config{githubUN}'`;
   print "Declaring  email   =$config{githubEmail} to git\n"   , `git config --global user.email '$config{githubEmail}'`;
     
   print `git config --global credential.helper wincred`     and return if $OS =~/Win/;
   print `git config --global credential.helper osxkeychain` and return if $OS =~/darwin/; 
   print `git config credential.helper store`;
   return;                
}

sub addUpstream{
	print "Checking out master\n";
	chdir "$config{workingDirectory}".$directorySeparator."$config{repoName}";
	`git checkout master`;
	if (upstreamExists()){
		print "Upstream already set up\n";
		$config{upstream}=1 ;
		return;
	}
	else{
		print "Attempting to add upstream\n";
		`git remote add upstream https://github.com/$config{repoOwner}/$config{repoName}`;
		if (upstreamExists()){
		 $config{upstream}=1 ;
		 print "Upstream added successfully\n" ; 
		}
		else{
		 $config{upstream}=0;
		 print "Upstream not added\n" ; 
		}
	}
}
	
sub fetchUpstream{
	if (!$config{"upstream"}){print "Upstream not setup so cannot Fetch Upstream\n";return}; 
	
	# Now we need to fetch latest changes from the upstream
	print "Fetching upstream\n";
	print `git fetch upstream`;
	
	# We will now merge the changes into your local master branch
	print `git merge upstream/master --ff-only`;   
	
	# Then push your master changes back to the repository.
	my $pushed;
	while (!$pushed ){
		my $response= `git push -u origin master`;
		if ($response){
			$pushed=1
		}
		else{
			my $try=prompt ("Failed to push changes back to repository\n".
			                "Print any key to try again or 's' to skip");
			$pushed=1 if $try =~/s/i;
		}
	}
}

sub getBranches{
	print "Getting branches\n";
	my $br=`git branch --remote`;
	my @matches = grep ($_ !~/HEAD|master|$config{currentweek}/,($br =~ /origin\/([^\s\n]+)/mg) );
	print "Old Remote Branches found : -",join ", ",@matches if @matches>0;
	if (@matches and prompt("\nDo you wish to delete old remote branches?") =~/y/i){
		foreach (@matches){
			print `git push -d origin $_\n` unless m/branch-$config{currentweek}/;
		}
	}
	my $abr=`git branch`;
	$abr=~s/\s+/ /gm;
	print "\nLocal Branches found : - $abr\n";
	@matches= grep ($_ !~/\*|master|$config{currentweek}/, split /\s+/m,$abr);
	if (scalar @matches>1 and prompt("\nDo you wish to delete old local branches?") =~/y/i){
		my @matches= grep (/branch-/, split / /,$abr);
		foreach (@matches){
			print `git branch -d $_\n` unless m/branch-$config{currentweek}/;
		}
	}
	
	my $week   = findItem($PWC_SITE,qr/perl-weekly-challenge-(\d+)/m);
	unless ((exists $config{currentweek})&&($config{currentweek} eq $week)){
		$config{currentBranch}=undef;      # undefines current branch
		$config{currentweek}="$week" ;     # sets current week
	}
	
	if ($abr=~/\bbranch-$config{currentweek}\b/gm){
		print "\nBranch for current week ($config{currentweek}) found\n\n";
		print `git checkout branch-$config{currentweek}`;
		$config{currentBranch}//="branch-$config{currentweek}";
	}
	else{
		print "\nBranch for current week ($config{currentweek}) not found\nCreating branch-$config{currentweek}\n";
		print `git checkout -b branch-$config{currentweek}`;
		$config{currentBranch}="branch-$config{currentweek}";
	}
}

sub getChallenges{   # extracts week number from index page,
	print "\nGetting challenges\n";
	$config{task1}  = stripWrap(       # extracts tasks and stores them
					  findItem("${PWC_SITE}/blog/perl-weekly-challenge-$config{currentweek}",
					  qr/Task 1:([\s\S]*)<h2 id="TASK2/m),60);
	$config{task2}  = stripWrap(
					  findItem("${PWC_SITE}/blog/perl-weekly-challenge-$config{currentweek}",
					  qr/Task 2:([\s\S]*)<p>Last date /m),60);

}

sub viewCodeTestCycle{
	while (1){
		print color("magenta","bold"),"\n\n---------    MAIN Menu    ----------\n\n";
		my $response = prompt("Now ready to view tasks, create/edit code, or test code\nWhat do you want to do?\nPress [ENTER] to exit",
	              ["View tasks","Create/Edit code","Test code"]);
		last unless $response;
		viewTasks()    if $response =~ /View/;
		readyToCode()  if $response =~ /Edit/;
		readyToTest()  if $response =~ /Test/;
	}
};

sub viewTasks{
  while (1){
    print color("magenta","bold"),"\n----    Tasks for Week $config{currentweek}    -------\n\n";
    my $task=prompt ("Select Task to see",["Task 1","Task 2"]);
    last unless $task;
    print color('bold green'),"#" x 24,"  $task  Week $config{currentweek}  ","#" x 24,"\n",color('reset'),
	        ($task =~/1/)?comment($config{task1},"#",65):comment($config{task2},"#",65),
	        color('bold green'),"#" x 68,"\n",color('reset');
    }
}

sub readyToCode{
	print color("magenta","bold"),"\n\n----   Coding Tasks for Week $config{currentweek}    -------\n\n";
	my $task;
	my %languages=(
	    Perl=>{
			ext=>".pl",
			path=>"perl$directorySeparator",
			shebang=>"#!/usr/env/perl\n",
		},
		Raku=>{
			ext=>".p6",
			path=>"perl/",
			shebang=>"#!perl6\n",
		},
		Python=>{
			ext=>".py",
			path=>"python/",
			shebang=>"#!python\n",
		},
	);
	while (1){  
		# Auto generate perl scripts for PWC solutions
		my $language=prompt ("Select Language (or just [ENTER] to abort):-",[keys %languages]);
		last unless $language;
		my $dir=pathToChallenge().$languages{$language}{path};
		print "Making directory $dir, if not already present\n";
		mkdir $dir unless -d $dir;
		($task=prompt ("Select Task to work on (or just [ENTER] to abort):-",["Task 1","Task 2"]))=~s/[^\d]//g ;
		last unless $task;
		my $file=$dir.$directorySeparator."ch-".$task.$languages{$language}{ext};
		if (-e $file){
			browse2 ($file);
		}
		else{
			writeFile($file,"$languages{$language}{shebang}# Task $task Challenge $config{currentweek} Solution by $config{githubUN}\n".
							 comment($config{"task$task"},"#"));
			browse2 ($file);
		}
	}
}	
    
sub readyToTest{
	print color("magenta","bold"),"\n\n---------    Testing code    -----------\n\n";
	prompt ("NOTE:- In testing your code will be executed as written\n".
	        "there will be no safety checks, so please be satisfied that\n".
	        "it is safe to do so.");
	my $dir=pathToChallenge();
	my (@dirs,@scripts);
	foreach (<$dir*>){
		push @scripts, $_ if (-f $_) and ($_=~/$codeExtensions/);
		push @dirs,    $_ if (-d $_);
	}
	
	foreach $dir (@dirs){
		$dir.=$directorySeparator;
		foreach (<$dir*>){
			push @scripts, $_ if (-f $_) and ($_=~/$codeExtensions/);
		}
	}
	my %files=map {/$directorySeparator([^$directorySeparator]+)$/;$1=>$_} @scripts;
	while (1){
	    my $response=prompt("Select file to test or 's' to skip",[keys %files]);
	    last if  !$response or $response!~/\d/;
	    testCode($files{$response});
    }
}



sub testCode{
	my ($file,$dir,$extension)=pathToFileDirExtension ( shift );
	return unless $file and $dir and $extension;
	my $parameters=prompt("Enter any parameters you want to pass");
	my $cwd=getcwd();
	chdir $dir;
	print "\n\n** Testing: Response to Challenge $config{currentweek} ","$file $parameters","  **\n\n";
	system("perl $file $parameters") if $extension=~/^pl$/i;
	system("perl6 $file $parameters") if $extension=~/^p6$/i;
	system("python $file $parameters") if $extension=~/^py$/i;
	print "\n********* Finished Testing:  ",$file,"  **********\n\n";
	chdir $cwd
}

sub pathToChallenge{
	my $challengeDir=$config{workingDirectory}.$directorySeparator.
		      $config{repoName} .$directorySeparator.
		       "challenge-".$config{currentweek}.$directorySeparator;
	my $dirName=$config{pwcUN}?$config{pwcUN}:$config{githubUN};
	return $challengeDir.$dirName.$directorySeparator if (-d $challengeDir.$dirName);
	
	my $response=prompt ("Challenge directory not found\n".
		     "This may occur if your github username is not your username\n".
		     "for the perl weekly challenge club, or if this your first\n".
		     "ever submission.  Select one of the following:\n",
		     ["This is my first ever submission, I wish to use my Github username",
		       "My PWC user name is different from my github username",
		       "Something else is wrong (raise an issue)"] );
    if ($response eq "1"){
		 $dirName=$config{githubUN}?$config{githubUN}:prompt("Enter github username");
	} 
	elsif($response eq "2"){
		$dirName=prompt("Enter $config{repoName} UserName");
		$config{pwcUN}=$dirName;
	}
	else{
		 raiseAnIssue();
		 return undef;
	} 
    mkdir $challengeDir.$dirName;
	return $challengeDir.$dirName.$directorySeparator

}

sub stripWrap{                 # strip tags and wrap text 
	my ($text,$columns)=@_;
	$text=~s/\n+/ /gm;           # remove newlines
	$text=~s/<\/p>|<\/h3>/\n/gm;      # replace paragraph ends with newlines
	$text=~s/<[^>]*>/ /gm;      # remove all other tags
	my %ent = (
		'gt' => '>',
		'lt' => '<',
		'amp' => '&',
	);
	$text =~ s/&$_;/$ent{$_}/ge for keys %ent;
	$columns//=60;             # default characters per column approx 60
	my $count=0; my $wrapped="";
	foreach my $ch(split //,$text){
		$wrapped.=$ch;
		if ($ch eq "\n"){
			$count=0;
		}
		elsif (($count>$columns)&&($ch=~/\s/)){
			$wrapped.="\n";
			$count=0;
			}
		else {$count++}
	}
	return $wrapped;
}

sub pathToFileDirExtension{
	my $path=shift;
	$path=~/^(.*)$directorySeparator([^$directorySeparator]+)\.([a-z]*)$/i;
	return ($2."\.".$3,$1,$3);
}

sub comment{
	my  ($text,$commentString,$width)=@_;
	my $ret="";my $padding;
	foreach my $line (split "\n",$text){
		$padding=($width and ($width-length $line>=0))?" "x($width-length $line).$commentString:"";
		$ret.="$commentString $line$padding\n";
		
	}
	return $ret; 
}

sub readyToAdd{
	my $response=prompt ("\n\nIf you have added your responses to the folder and\n".
	      "you have tested them finally to your satisfaction \n".
	      "you can commit the answers - press 'y' if ready.\n".
	      "If you are not ready, just press 'n' and come back next time.\n\n".
	      "Are you ready to commit your changes? (y/n)");
	if ($response =~/y/i){
		print "Adding current week's ($config{currentweek}) challenges...\n";
		my $dirName=$config{pwcUN}?$config{pwcUN}:$config{githubUN};  # some PWC usernames do not match GH usernames
		print `git add challenge-$config{currentweek}/$dirName`;
		print "Commiting changes...\n";
		my $message="Challenge-$config{currentweek} solutions by $dirName";
		$response=prompt("Default message is:\n".color("green").$message.color("red")."\nPress Enter to select, or enter new message\n");
		$message=$response if $response=~/\w/;
		print `git commit --author=$config{githubUN} --message="$message"`;
		print "Pushing results to your github...\n";
		print `git  push -u origin branch-$config{currentweek}`;
		print "Now time to create a pull request.  Browser should open\n".
		      "and you should see a button to create pull request...\n";
		browse2("https://github.com/login?return_to=%2F$config{githubUN}%2Fperlweeklychallenge-club/pull/new/branch-$config{currentweek}");
	}
} 

sub clearScreen{ # https://www.perlmonks.org/?node_id=18774
	system $^O eq 'MSWin32' ? 'cls' : 'clear';
}

sub prompt{
	my ($message,$options,$validation)=@_;

	print color('bold red'),$message;
	if (ref $options eq "ARRAY"){
		my $index=1;
		print "\n";
		foreach (@$options){
			print color('bold green'),$index++,") ",$_,"\n";
		}
		my $validOps="1-".scalar @$options;   # valid numbers for options
		print color('bold red'),"Enter $validOps >>";
	    print color('bold yellow');
	    chomp(my $response=<>);print color('reset');
	    return undef if $response !~/^[$validOps]|!$/; 
	    return $$options[$response-1] unless $response =~/^!/;;
	}
	else{
	   print color('bold red')," >>";
	   print color('bold yellow');
	   chomp(my $response=<>);print color('reset');
	   return $response unless $response =~/^!/;;
    }
	raiseAnIssue();
	prompt("Press [Enter] to resume");
	prompt($message,$options,$validation)
}

sub URLexists{
	my $url = shift;
	print "Checking if $url exists...\n";
	$ua->timeout(10);
	return head($url)? 1 : 0;
}

sub upstreamExists{
	return 1 if ($config{upstream});
	my $remote=`git remote -v`;
	return $remote =~/^upstream/m;
}

sub findItem{   #ultra-simple scraper LWP::get->regexp
	my ($url,$re)=@_;
	return (get($url)=~/$re/)? $1:-1;
}

sub browse2{
	my ($URL)=(shift);
	print color('bold cyan');
	print "Opening $URL, ($OS)\n";
	if     ($OS eq "linux")   {`xdg-open $URL`   }
	elsif  ($OS eq "MSWin32") {	`start /max $URL`}
	elsif  ($OS eq "darwin") {	`open "$URL"`};
	print color('reset');
}


sub writeFile{
	my ($file,$text)=@_;
	open(my $fh, '>', $file) or
         die "Could not open file '$file' $!";
    print $fh $text;
    close $fh;
}

sub raiseAnIssue{
   prompt("\nThank you for raising an issue. Press return to open a browser\n".
          "window.  You may need to log in to github and submit a bug report\n".
          "or feature request");
   browse2("https://github.com/login?return_to=%2Fsaiftynet%2FEZPWC%2Fissues%2Fnew%2Fchoose");
	
}

sub saveConfig{  ## crude way to save %config into a file
    open(my $fh, '>', $config{workingDirectory}.'/Config') or
         die "Could not open file '$config{workingDirectory}/Config' $!";
	print {$fh} Data::Dumper->new([\%config])->Purity(1)->Terse(1)->Deepcopy(1)->Dump();
	close $fh;
}

sub loadConfig{
	if (-e "$workingDirectory/Config") { 
		my $VAR1;
		if (my @config = do "$workingDirectory/Config" ){   ## crude way to load %config from a file
			%config = (ref($config[0]) eq 'HASH') ? %{ $config[0] } : @config;
			print "Config successfully loaded\n";
			return;
		}
		else {
		      print "Config exists but contains errors, please report.\n";
		}
	}


	print "Failed to load config, continuing with defaults\n";
	unlink ("$workingDirectory/Config");
	%config=(
				repoName			 => "perlweeklychallenge-club",
				repoOwner			 => "manwar",
				workingDirectory     => $workingDirectory,
				clone                => undef,
				githubUN			 => "",
				"fork"				 => undef,
				upstream			 => undef,
			);
	saveConfig()
		
}
