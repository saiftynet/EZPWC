#!/usr/env perl
# Eazy Perl Weekly Challenge EZPWC  
# This is a script that attempts to make Perl Weekly Challenges easier to do
# It creates a PerlChallenges directory in the home folder if not already
# present, forks the repo if needed, creates a clone, registers upstream,
# fetches the upstream and gets the most recent challenges.

use strict;use warnings;
use LWP::Simple qw($ua get head getstore);
use Cwd qw(getcwd);
use Term::ANSIColor;

my $VERSION=0.085;

my $OS=$^O;
my $directorySeparator= ($^O=~/Win/)?"\\":"/";  # should probably use File::Spec
my $codeExtensions="(\.pl|\.p6|\.py|\.sh)\$";
my %config;
my $workingDirectory="$ENV{HOME}".$directorySeparator."PerlChallenges";

print color('bold green'),"Starting EZPWC $VERSION\n",color('reset');
# version notes
print color('bold yellow'),
       "\nVersion 0.085 attempts to address a possible issue\n".
       "caused by some situations when the PWC user name does\n".
       "not match the github user name\n\n" ,color('reset');

loadConfig();
versionCheck();          
setupDirectory();        # step 1 set up a directory locally if it has not been setup
setupGithub();           # step 2 set up user's existing github account or setting up a new one
makeFork();              # step 3 set up fork if not already forked
clone();                 # step 4 clone if not already cloned
addUpstream();           # step 5 ensure upstream has been set up 
fetchUpstream();         # step 6 fetch upstream
getChallenges();         # step 7 get challenges from manwar's PWC blog
getBranches();           # step 8 get branches, and set one up for this week if required
readyToCode();           # step 9 start coding
readyToTest();           # step 10 test code (experimental)
readyToAdd();            # step 11 ready to add
saveConfig();	
print color('bold green'),"\n\nAll done...good bye!!\n",color('reset');
exit 0;


sub versionCheck{
	my $vc;
	my $check=$config{versionCheck};
	if (!$check){
		$vc=prompt("Do you wish to check for newer versions?:-",["Yes, every time","Yes this time only","Not at this time"]);
		$check=($vc=~/^1|2$/)?1:0;
		$config{versionCheck}=(1==$vc);
	 }
	 if ($check){
		my $source="https://raw.githubusercontent.com/saiftynet/EZPWC/master/EZPWC.pl";
        my $latest= findItem($source,qr/VERSION=([\d\.]+);/m);
		if ($latest==$VERSION){
		  print "This is the latest version\n";
		  
		}
		elsif ($latest>$VERSION){
		  my $input=prompt("Newer version exists\nDo you wish to",["Download latest version into working directory and restart",
		                                     "Download here (e.g if working from clone)",
		                                     "Stop checking for updates",
		                                     "Skip this"]);
           getstore($source, $config{workingDirectory}.$directorySeparator."EZPWC.pl") if $input eq 1;
           getstore($source, "EZPWC.pl") if $input eq 2;
		}
		else {
		  print "You are more recent than github\n";
		}
	}
}

sub setupDirectory{
	if ( -e $config{workingDirectory} and -d $config{workingDirectory}){
		print "Working directory found\n";
	}
	else{
		print "Attempting to create working directory $config{workingDirectory}...\n";
		mkdir $config{workingDirectory} 
			or die "Could not create working directory '$config{workingDirectory}' $!";
		chdir $config{workingDirectory};
		print "working directory created\n";
	}
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
	   }
	   else {
		   print "User '$config{githubUN}' not found on GitHub\n";
		   $config{githubUN} = "";
	   }
   }
   $config{githubUN}=undef if ($config{githubUN} eq "..Skipped");
}

sub makeFork{
	
    if (!$config{githubUN}) {print "GitHub account not setup so cannot fork\n";return};
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
	if (!$config{"fork"})   {print "Fork not setup so cannot clone\n";return}; 
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
		 print "Upstream added successfully" ; 
		}
		else{
		 $config{upstream}=0;
		 print "Upstream not added" ; 
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

sub getChallenges{   # extracts week number from index page,
	print "\nGetting challenges\n";
	my $week   = findItem("http://perlweeklychallenge.org",qr/perl-weekly-challenge-(\d+)/m);
	unless ((exists $config{currentweek})&&($config{currentweek} eq $week)){
		$config{currentBranch}=undef;      # undefines current branch
		$config{currentweek}="$week" ;     # sets current week
	    $config{task1}  = stripWrap(       # extracts tasks and stores them
	                      findItem("http://perlweeklychallenge.org/blog/perl-weekly-challenge-$week",
	                      qr/TASK #1<\/h2>([\s\S]*)<h2 id="task-2">/m),60);
	    $config{task2}  = stripWrap(
	                      findItem("http://perlweeklychallenge.org/blog/perl-weekly-challenge-$week",
	                      qr/TASK #2<\/h2>([\s\S]*)<p>Last date /m),60);
    }

	print "\nCurrent week = $config{currentweek}\n\n";
	my $task=prompt ("Select Task to see",["Task 1","Task 2","Skip"]);
	while ($task  =~/^1|2$/){
	   print color('bold green'),"#" x 24,"  Task $task  Week $config{currentweek}  ","#" x 24,"\n",color('reset'),
	        ($task =~/^1/)?comment($config{task1},"#",65):comment($config{task2},"#",65),
	        color('bold green'),"#" x 68,"\n",color('reset');
	   $task=prompt ("\nSelect Task to see",["Task 1","Task 2","Skip"]);
    }
}

sub getBranches{
	print "\n\nGetting branches ";
	my $br=`git branch --remote`;
	my @matches = grep ($_ !~/HEAD|master/,($br =~ /origin\/([^\s\n]+)/mg) );
	print "\nRemote Branches found : -",join ", ",@matches;
	my $abr=`git branch`;
	$abr=~s/\s+/ /gm;
	print "\nBranches found : - $abr\n";
	
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
	print "Now add your responses to folder ".pathToChallenge()."\n";
	prompt ("Get ready to code!!");  
	
	  }

sub readyToCode{
	while (1){
		# Auto generate perl scripts for PWC solutions
		my $language=prompt ("Select Language:-",[qw/Perl Raku Other Skip/]);
		last if $language !~/^1|2|3$/;
		my $dir=pathToChallenge().(("","perl","raku","other")[$language]);
		print "Making directory $dir, if not already present\n";
		mkdir $dir unless -d $dir;
		my $task=prompt ("Select Task to work on:-",["Task 1","Task 2","Skip"]);
		last if $task !~/^1|2$/;
		my $file=$dir.$directorySeparator."ch-$task.".(("","pl","p6","")[$language]);
		my $shebang=(("","#!/usr/env/perl\n","#!perl6 \n","")[$language]);
		if (-e $file){
			browse2 ($file);
		}
		else{
			writeFile($file,"$shebang# Task $task Challenge $config{currentweek} Solution by $config{githubUN}\n".
							 comment($config{"task$task"},"#"));
			browse2 ($file);
		}
	}
}	
    
sub readyToTest{
	prompt ("Get ready to test your code!!\n".
	        "NOTE:- In testing your code will be executed as written\n".
	        "There will be no safety checks so please be satisfied that\n".
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
	my @fileNames=map {/$directorySeparator([^$directorySeparator]+)$/;$1} @scripts;
	while (1){
	    my $response=prompt("Select file to test or 's' to skip",\@fileNames);
	    last if  !$response or $response!~/\d/ or $response>@scripts;
	    testCode($scripts[$response-1]);
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
		     \("This is my first ever submission, I wish to use my Github username",
		       "My PWC user name is different from my github username",
		       "Something else is wrong (raise an issue)") );
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
	$text=~s/\n//gm;           # remove newlines
	$text=~s/<\/p>|<\/h3>/\n/gm;      # replace paragraph ends with newlines
	$text=~s/<[^>]*>//gm;      # remove all other tags
	
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
		print `git commit --author=$config{githubUN} --message="Challenge-$config{currentweek} solutions by $dirName"`;
		print "Pushing results to your github...\n";
		print `git  push -u origin branch-$config{currentweek}`;
		print "Now time to create a pull request.  Browser should open\n".
		      "and you should see a button to create pull request...\n";
		browse2("https://github.com/login?return_to=%2F$config{githubUN}%2Fperlweeklychallenge-club");
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
	}
	print color('bold red')," >>";
	print color('bold yellow');
	chomp(my $response=<>);
	print color('reset');
	return $response;
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
    for (sort keys %config){
		if (defined $config{$_}){
			print $fh " $_  => '$config{$_}',\n";
		}
		else{
			print $fh " $_  => '',\n"
		}
	}
	close $fh;
}

sub loadConfig{
	if (-e "$workingDirectory/Config") { 
		if (%config=do "$workingDirectory/Config" ){   ## crude way to load %config from a file
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
