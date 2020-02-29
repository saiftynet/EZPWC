# EZPWC -Easy Perl Weekly Challenges Script

This is a script that hopefully eases the interactions between the Chellenge participant and GitHub.  It tries to automate much of the instruction provided on the [readme](https://github.com/manwar/perlweeklychallenge-club) in manwars GitHub page for the challenges.

* It creates a PerlChallenges folder (by default in user's home folder)
* It sets up a github user if needed
* It forks, and then creates a local clone if it hasn't already been done
* It adds/ fetches upstream
* It extracts the latest week's challenges
* It creates a new branch for current week if not already created.
* It interactively creates a solutions folder and files to edit if these do not already exist
* It automatically initiates an editor on the newly created file, or if the file exists already, opens it for editing
* It then allows user to test the code prior to submission
* It finally adds to branch, commits and pushes
* It then takes user to GitHub to create a pull request. 
* Interactions include a bit of colourisation for readability.


## Installation: -
Prerequisites: Uses the modules LWP::Simple, Cwd, Scalar::Util, Term::ANSI (color)

Simply Copy file to a suitable location and make it executable, or execute it using perl EZPWC.pl.
The file may be editted to allow change in location of the git clone...by default it is in a working directory  in the home folder.  Changing the following line can change the target folder.

`$workingDirectory="$ENV{HOME}/PerlChallenges"`;

## Instructions: -
Execute the file and prompts will follow. At some points, the default browser may open, allowing you to create or login to your github account. At certain points, e.g. when pushing changes to master, you may be asked to enter your github user name and password.  Your password itself is not stored in any file.

A working directory is created, a clone is stored within this directory, and also withing this director is a Config file that is created to store settings and preferences.

## To Do:-
* Have a better menu system...maybe migrate to Curses, or GUI e.g. Tk, Win32 or Gtk
* Allow testing of scripts before submitting
* Allow exploring of previous challenges
* Perhaps check for updates
Allow statistical analysis


## Screenshot

![Screenshot](https://github.com/saiftynet/EZPWC/blob/master/EZPWC.png)

![Screenshot2](https://github.com/saiftynet/EZPWC/blob/master/EZPWC%20colorised.png)

![Screenshot2](https://github.com/saiftynet/EZPWC/blob/master/EZPWC%20editing%20code.png)

