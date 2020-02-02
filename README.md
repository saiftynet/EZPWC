# EZPWC -Easy Perl Weekly Challenges Script

This is a script that hopefully eases the interactions between the Chellenge participant and GitHub.  It tries to automate much of the instruction provided on the [readme](https://github.com/manwar/perlweeklychallenge-club) in manwars GitHub page for the challenges.

* It creates a PerlChallenges folder (by default in user's home folder)
* It sets up a github user if needed
* It forks, and then creates a local clone if it hasn't already been done
* It adds/ fetches upstream
* It extracts the latest week's challenges
* It creates a new branch for current week if not already created
* It then allows user to make changes, and finally adds to branch, commits and pushes
* It then takes user to GitHub ot create a pull request. 
