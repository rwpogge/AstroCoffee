#!/usr/bin/perl
#
# pour.pl -- final step - copy the freshly brewed abstract index into
#            the public web page and archive the old abstract index
#
# This script is invoked by the "brew.pl" script, which has as set of
# selected papers for the new edition of "The Daily Brew" (the master
# list of the day's selected papers).
#
# pour.pl is the "do it" script.  It creates the public version of the
# Daily Brew webpage from the temporary copy and updates the Daily
# Brew Archives.
#
# The original versions from 2002 until 2022 would also print paper
# copies of the Daily Brew and selected papers, but we went paperless
# in 2022.
#
# R. Pogge, OSU Astronomy Dept.
# pogge@astronomy.ohio-state.edu
# 2001 Sept 5
#
# Modification History:
#   2002 Dec 15: minor mods for the new linux apache server [rwp]
#   2002 Dec 27: added hooks for maintaining a Brew archive [rwp]
#   2003 May 27: printer option now passed from the brew.pl script [rwp]
#   2008 Jun 24: change of version for RSS feed-based retrieval [rwp]
#   2011 Jun 07: minor changes for the new webserver [rwp]
#   2013 Feb 27: added direct PDF link [rwp]
#   2022 Mar 22: disabled printing [rwp]
#
###########################################################################

$versionID = "pour.pl Version 2.2.0" ;
$versionDate = "2022-03-22" ;

# when and where...

$date=`date -u +"%A %B %e"` ;
$wd=`pwd` ;
chomp($wd) ;
chomp($date) ;

# process the info passed by brew.pl

if ($ENV{'REQUEST_METHOD'} eq 'POST'){
  # POST method dictates that we get the form input from
  #  standard input
  read(STDIN,$buffer,$ENV{'CONTENT_LENGTH'});

} elsif ($ENV{'REQUEST_METHOD'}=~ /^(GET|HEAD)$/) {
  $buffer = $ENV{'QUERY_STRING'};

}

# Split the name-value pairs on '&'

@pairs = split(/&/,$buffer);

# Go through the pairs and determine the name and value for each variable.   

foreach $pair (@pairs) {
   ($name,$value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $FORM{$name} = $value;
}

# Step 1: Copy temppage to webpage

$newBrew = $FORM{webpage};

rename("$FORM{temppage}","$newBrew");

# Step 2: Copy the current edition into the archive

$archiveYear  = $FORM{ArchYear} ;
$archiveMonth = $FORM{ArchMonth} ;
$archiveMon   = $FORM{ArchMon} ;
$archiveName  = $FORM{ArchiveName} ;

$archiveDir = "$FORM{CoffeeDir}/Archive" ;

# Make certain that the archive directories exist.  If not, create them with
# reasonably secure permissions.

if (-e "$archiveDir/$archiveYear") {
  if (-e "$archiveDir/$archiveYear/$archiveMonth/") {
    # good !
  } else {
    mkdir("$archiveDir/$archiveYear/$archiveMonth/",0755) ;
  }
} else {
  mkdir("$archiveDir/$archiveYear",0755) ;
  mkdir("$archiveDir/$archiveYear/$archiveMonth/",0755) ;
}

# now, copy the current "Daily Brew" into the archive directory

$archiveFile = "$archiveDir/$archiveYear/$archiveMonth/$archiveName" ;

system("cp $newBrew $archiveFile") ;

# create/update the HTML index in the archive month directory

chdir("$archiveDir/$archiveYear/$archiveMonth") ;
system("$FORM{DataDir}/mkarchindex $archiveYear $archiveMon $archiveMonth") ;

# Step 3: Mop up and let them know what we've done...

&print_HTTP_header;
&print_head;

print "<h2>All Done!</h2>\n" ;

print "<p>The picks of the day are in \n";
print "<a href=\"$FORM{weblink}/coffee.html\"><i>The Daily Brew</i></a>\n";

print "<p><b>Note:</b> We no longer print hardcopies of abstracts or the brew.\n";

print "<p>The current edition of the <cite>Daily Brew</cite> has been\n" ;
print "added to the archive for\n" ;
print "<a href=\"$FORM{weblink}/Archive/$archiveYear/$archiveMonth/\">$archiveMonth \n" ;
print "$archiveYear</a>.\n" ;

&print_tail;

exit;

# -------------------- Print the HTTP header --------------------

sub print_HTTP_header {
        print "Content-type: text/html\n\n";
}

# -------------------- Print the generic page heading --------------------

sub print_head {
        print <<END;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Astro Coffee - Step 3: Pour...</title>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
</head>
<body bgcolor="#ffffff">

END
}

# -------------------- Print the web page tail --------------------

sub print_tail {
        print <<END;

<p>
<hr>
<p>
Return to the <a href="/Coffee/index.html">Astro Coffee Home Page</a>

<p>
<hr>
$versionID [$versionDate]
</BODY>
</HTML>
END
}
