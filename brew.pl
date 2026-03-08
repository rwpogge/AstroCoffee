#!/usr/bin/perl
#
# brew.pl -- make coffee web page and script to print them out.
#
# This script is invoked by the "grind.pl" script in which the user
# selects astro-ph abstracts to be extracted from arXiv.org This script
# lets the user review the choices from "grind.pl" before committing
# them to print.  It also generates the printout pages for each selected
# abstract and the Daily Brew edition.
#
# When the "Print Them!" button is pressed, the selection review form
# triggers the "pour.pl" script which does the printing, archiving, and
# other tasks associated with putting up the lastest edition of the
# Daily Brew.
#
# This version uses the new paper database file created by grind.pl from
# the current RSS feed from arXiv.org, bypassing the old code that read
# the daily email.
#
# R. Pogge, OSU Astronomy Dept.
# pogge@astronomy.ohio-state.edu
# 2001 Sept 5
#
# Based on a script by David Weinberg & Alberto Conti, but modified extensively
# since it was stolen sometime in 2001.
#
# Modification History:
#   2001 Sept 27: Added logic to replace >, <, and & by their HTML
#                 equivalents whenever they appear in output text from
#                 the astro-ph lising (e.g., "z>4" in the title) [rwp]
#   2002 Jan 17: minor tweaks for the new web server/firewall stuff [rwp]
#   2002 Dec 15: ported to Linux for the new apache web server [rwp]
#   2002 Dec 27: added hooks for archiving the Daily Brew [rwp]
#   2003 May 27: added select button for alternative printers [rwp]
#   2005 Sep 22: added links to the new Coffee Agenda pages/tools [rwp]
#   2005 Sep 26: added handling of new Categories: line [rwp]
#   2007 Apr 03: new arXiv format [rwp]
#   2007 Jul 05: ability to add papers by number from outside astroph [rwp]
#   2008 Jun 24: Major Revision - uses XML feed instead of daily email [rwp]
#   2011 Jun 07: Fixes for the new webserver [rwp]
#   2013 Feb 27: Added direct PDF link to the Daily Brew [rwp/osu]
#   2014 Oct 20: Added MathJax support for LaTeX markup [rwp/osu]
#   2022 Feb 22: Better way to add old arXiv and other papers [rwp/osu]
#
###########################################################################

$versionID = "brew.pl Version 2.5.2" ;
$versionDate = "2022-03-22" ;

# We do some HTML parsing for "other" papers entered by hand

use HTML::Parser;
use LWP::Simple;

# Date - because some people run it the night before, we have to finesse and use UTC
#        BEWARE!  We only get away with this because of our local timezone (US Eastern)

$date=`date -u +"%A %Y %B %e"` ;
chomp($date) ;

# Year and Month for archiving

$archiveYear = `date -u +"%Y"` ;  # Year in CCYY format
chomp($archiveYear) ;

$archiveMon = `date -u +"%b"` ;   # 3-letter month code (in locale language)
chomp($archiveMon) ;

$archiveMonth = `date -u +"%B"` ; # full month name (in locale language)
chomp($archiveMonth) ;

# Full path to the Astro Coffee web directory (no terminal /)

$coffeeDir = "/var/www/Coffee" ;
$coffeeURL = "/Coffee" ;
$archiveDir = "$coffeeDir/Archive/" ;
$cgiPath = "/cgi-bin/Coffee" ;

# Full path to the outside-the-server-domain data & working files

$dataDir = "/var/www/CoffeePot" ;

# Full path and name of the html2ps converter

$html2ps = "/usr/bin/html2ps" ;

# Full path and name of the webquery perl script

$webGrab = "/var/www/CoffeePot/webquery.pl" ;

# Default printer and unix print commmand to use

$usePrinter= "libraryd" ;

# start the HTML page for brew.pl

&print_HTTP_header;
&print_head;

# Process the info from grind.pl

if ($ENV{'REQUEST_METHOD'} eq 'POST'){
  # POST method dictates that we get the form input from
  #  standard input
  read(STDIN,$buffer,$ENV{'CONTENT_LENGTH'});
}
elsif ($ENV{'REQUEST_METHOD'}=~ /^(GET|HEAD)$/) {
  $buffer = $ENV{'QUERY_STRING'};
}

# Split the name-value pairs on '&'

@pairs = split(/&/,$buffer);

# Go through the pairs and determine the name and value for each variable.

#print "<p>Data received from grind.pl:\n" ;
#print "<p><dl>\n" ;

$numPairs = 0;
$numPapers = 0;
@abstractID = "";  # array with selected abstract ID numbers

foreach $pair (@pairs) {
   ($name,$value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   if ($name eq "NumAbstracts") {
     $NumAbstracts = $value ;

   } elsif ($name eq "AbstListing") {
     $dbFile = $value ;

   } elsif ($name eq "PostingDate") {
     $postingDate = $value ;

   } elsif ($name eq "ArchiveName") {
     $ArchName = $value ;

   } elsif ($name eq "abstract") {
     $abstractID[$numPapers] = $value;
     $numPapers++ ;

   } elsif ($name eq "Printer") {
     $usePrinter = $value ;

   } elsif ($name eq "OldPapers") {
     $oldPapers = $value;

   } elsif ($name eq "OtherPapers") {
     $otherPapers = $value;

   }
   #print "<dd>$name = $value\n" ;
   $numPairs ++ ;
}
#print "</dl>\n" ;

# Read in the abstract database file created by grind and create the
# hash tables we need later, or squawk if the database file is absent.


if (-r $dbFile) {
  open(PDB,$dbFile);
  while (<PDB>)  {
    $newline = $_;
    chomp($newline);
    @line = split('\|',$newline);
    $paperID = $line[0];
    $paperArchive{$paperID} = $line[1];
    $paperURL{$paperID} = $line[2];
    $paperPDF{$paperID} = $line[3];
    $paperName{$paperID} = $line[4];
    $paperType{$paperID} = $line[5];
    $paperTitle{$paperID} = $line[6];
    $paperAuthors{$paperID} = $line[7];
    $paperAbstract{$paperID} = $line[8];
  }
  close(PDB);
} else {
  print "<h2>Error: No astro-ph listing database file found.</h2>\n" ;
  print "\nThe file $dbFile was not found on this server.\n" ;
  print "\n<p>If you are sure there should be an archive update for\n" ;
  print "today, please let Rick Pogge know you had problems, and if he's\n" ;
  print "around hopefully it will be solved before coffee time.\n" ;
  print "If not, be ready to do it by hand the old fashioned way...\n" ;
  &print_tail;
  exit;
}

print "<h2>Step 2: Review your selections</h2>\n" ;

print "You have selected the following $numPapers new abstracts for printing:\n" ;
print "<p><ol>\n" ;
for ($i=0;$i<$numPapers;$i++) {
  print "<li><a href=\"$paperURL{$abstractID[$i]}\">$paperName{$abstractID[$i]}</a>\n" ;
}
print "</ol>\n" ;

# Construct the links to the old arXiv papers, and hope they exist

$slen = length($oldPapers);
chomp($oldPapers);
if ($slen > 0) {
  $oldPapers =~ s/([\012\015])/ /g;
  @old = split(' ',$oldPapers);
  $numOld = 1 + $#old;
  #print "<p>Debug: $oldPapers\n";
  if ($numOld > 0) {
    print "<p>Previous arXiv papers:\n";
    print "<ol>\n";
    for ($i=0;$i<$numOld;$i++) {
      print "<li><a href=\"http://arXiv.org/abs/$old[$i]\">arXiv:$old[$i]</a>\n";
    }
    print "</ol>\n";
  }
}

$slen = length($otherPapers);
chomp($otherPapers);
if ($slen > 0) {
  $otherPapers =~ s/([\012\015])/ /g;
  @other = split(' ',$otherPapers);
  $numOther = 1 + $#other;
  #print "<p>Debug: $otherPapers\n";
  if ($numOther > 0) {
    print "<p>Non-arXiv papers/links:\n";
    print "<ol>\n";
    for ($i=0;$i<$numOther;$i++) {
      print "<li><a href=\"$other[$i]\">$other[$i]</a>\n";
    }
    print "</ol>\n";
  }
}

print "<p>You now have two choices:\n" ;
print "<ol>\n" ;
print "<li>Use the <b>Back</b> button on the browser to go back and\n" ;
print "    revise/amend your selections from among today's abstracts.\n" ;
print "<p>\n<li>Hit the <b>Commit</b> button below which will\n" ;
print "<p><ol>\n" ;
#print "<li>Retrieve the abstracts from the astro-ph archive.\n" ;
#print "<p><li>Start a batch job to print the abstracts plus 5 copies of\n" ;
#print "    the <cite>Daily Brew</cite> on $usePrinter.\n";
print "<p><li>Update the current edition of the\n" ;
print "   <a href=\"$coffeeURL/coffee.html\"><cite>Daily Brew</cite></a>\n" ;
print "   on the department web server.\n" ;
print "<p><li>Update the\n" ;
print "<a href=\"$coffeeURL/Archive/\"><cite>Daily Brew</cite> archives</a>.\n" ;
print "</ol>\n" ;
print "<p><b>Please make sure this is what you want to\n";
print "to do before hitting the <b>Commit</b> button!</b>\n" ;
print "</ol>\n" ;

print "<p>\n" ;
print "<form action=\"$cgiPath/pour.pl\" method=\"POST\">\n" ;
print "<input type=\"hidden\" name=\"CoffeeDir\" value=\"$coffeeDir\">\n" ;
print "<input type=\"hidden\" name=\"DataDir\" value=\"$dataDir\">\n" ;
print "<input type=\"hidden\" name=\"temppage\" value=\"$dataDir/temp.html\">\n" ;
print "<input type=\"hidden\" name=\"webpage\" value=\"$coffeeDir/coffee.html\">\n" ;
print "<input type=\"hidden\" name=\"weblink\" value=\"$coffeeURL\">\n" ;
print "<input type=\"hidden\" name=\"printscript\" value=\"$dataDir/print.sh\">\n" ;
print "<input type=\"hidden\" name=\"Printer\" value=\"$usePrinter\">\n" ;

# archive information

print "<input type=\"hidden\" name=\"ArchYear\" value=\"$archiveYear\">\n" ;
print "<input type=\"hidden\" name=\"ArchMonth\" value=\"$archiveMonth\">\n" ;
print "<input type=\"hidden\" name=\"ArchMon\" value=\"$archiveMon\">\n" ;
print "<input type=\"hidden\" name=\"ArchiveName\" value=\"$ArchName\">\n" ;

print "<p>\n<hr>\n" ;
print "<h2>Step 3: Create the <cite>Daily Brew</cite> and update the webpages</h2>\n" ;
#print "   update the web pages.</h2>\n" ;
print "<blockquote>\n" ;
print "<p><input type=\"SUBMIT\" VALUE=\"Commit\">\n" ;
print "</blockquote>\n" ;
print "</form>\n" ;

&print_tail;

# open the temporary file in $dataDir/ to hold the index of the day's
# choice abstracts.  This keeps it off the server until we're ready to "pour"

open(OUTFILE,">$dataDir/temp.html");

# open the printing script - muy insecure, but does the job, also keep
# in $dataDir.

#open(SCRIPT,">$dataDir/print.sh");

#print SCRIPT "#!/bin/sh\n" ;
#print SCRIPT "#\n" ;

#print SCRIPT "echo \"------------------------------\" >> $coffeeDir/brew.log\n" ;
#print SCRIPT "echo \"Coffee abstract downloading/printing started `date`\" >> $coffeeDir/brew.log \n" ;

#
# Start building "The Daily Brew" webpage of the Abstracts of the Day
#
# 2014 Oct: Adding MathJax support so we can render embedded LaTeX
#           markup For now we call upon the MathJax CDN instead of
#           keeping a local copy. [rwp/osu]
#

select(OUTFILE);   # direct print to here instead of STDOUT for now

print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n" ;
print "<html>\n<head>\n<title>AstroCoffee Abstracts of the Day</title>\n" ;
print "<meta http-equiv=\"content-type\" content=\"text/html;charset=iso-8859-1\">\n" ;
print "<script type=\"text/x-mathjax-config\">\n";
print "   MathJax.Hub.Config({\n";
print "      tex2jax: {inlineMath: [['\$','\$'], ['\\\\(','\\\\)']]}\n";
print "   });\n";
print "</script>\n";
print "<script type=\"text/javascript\" src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML\">\n";
print "</script>\n";
print "</head>\n";
print "<body bgcolor=\"#ffffff\">\n" ;
print "<p><CENTER>\n<h1><cite>The Daily Brew</cite></h1>\n" ;
print "<big>Selected astro-ph abstracts for $date</big>\n" ;
print "<hr>\n";
print "</center>\n";

# Set the printing command

$printCommand = "/usr/bin/lpr -h -P$usePrinter" ;

# Process the abstract listing for today

print "<ul>\n" ;

for($i=0;$i<$numPapers;$i++) {

  # Show this to the user on their browser page...

  $key = $abstractID[$i];
  print "<li><b>$paperTitle{$key}</b><br>\n";
  print "$paperAuthors{$key}<br>\n";
  print "[ <a href=\"$paperURL{$key}\">$paperName{$key}</a>";
  print " | ";
  print "<a href=\"$paperPDF{$key}\" target=\"_blank\">PDF File</a> ]";
  if ($paperType{$key} eq "CROSS") {
    print " [Cross-Listed from $paperArchive{$key}]\n";
  }
  elsif ($paperType{$key} eq "UPDATED") {
    print " [Replacment]\n";
  }
  else {
    print "\n";
  }
  print "<p>\n";

  # ... and put this into the printing script ...

  $abstFile = "$dataDir/$key.html";
#  print SCRIPT "#\n" ;
#  print SCRIPT "$webGrab url=/abs/$key host=arXiv.org file=$dataDir/$key.html\n" ;
#  print SCRIPT "$html2ps $abstFile | $printCommand\n" ;
#  print SCRIPT "'rm' -f $abstFile\n";

  # ... and finally make the standalone abstract page for printing

  if ($usePrinter ne "NONE") {
     open(ABST,">$abstFile");
     print ABST "<html>\n";
     print ABST "<head>\n";
     print ABST "<script type=\"text/x-mathjax-config\">\n";
     print ABST "   MathJax.Hub.Config({\n";
     print ABST "      tex2jax: {inlineMath: [['\$','\$'], ['\\\\(','\\\\)']]}\n";
     print ABST "   });\n";
     print ABST "</script>\n";
     print ABST "<script type=\"text/javascript\" src=\"https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML\">\n";
     print ABST "</script>\n";
     print ABST "</head>\n";
     print ABST "<body>\n";
     print ABST "<center><h2><em>The Daily Brew</em> - $date</h2></center>\n";
     print ABST "<hr>\n";
     print ABST "<h2>$paperName{$key}</h2>\n";
     print ABST "<h1>$paperTitle{$key}</h1>\n";
     print ABST "<big>$paperAuthors{$key}</big>\n";
     print ABST "<dl>\n<dd><big>$paperAbstract{$key}</big>\n</dl>\n";
     if ($paperType{$key} eq "CROSS") {
       print ABST "<p>Cross-Listed from $paperArchive{$key}\n";
     }
     elsif ($paperType{$key} eq "UPDATED") {
       print ABST "<p>Note: This paper is a replacment.\n";
     }
     else {
       print ABST "<p>Posted to $paperArchive{$key}\n";
     }
     print ABST "<hr>\n";
     print ABST "$versionID [$versionDate]\n";
     print ABST "</body>\n";
     print ABST "</html>\n";
     close(ABST);
  }
}
print "</ul>\n" ;

# Now setup to grab any additional papers requested.  Since we don't
# have the current XML feed, we have to grab these from arXiv proper,
# with all the formatting problems that incurs with html2ps's inability
# to handle CSS formatting.

if ($numOld > 0) {
  print "<big>Other arXiv Papers:</big>\n";
  print "<ul>\n";
  for ($i=0;$i<$numOld;$i++) {
    print "<li><a href=\"http://arXiv.org/abs/$old[$i]\">arXiv:$old[$i]</a>\n";
  }
  print "</ul>\n";
}

# Put in other links as-is, no attempt to validate syntax

if ($numOther > 0) {
  print "<big>Other Links:</big>\n";
  print "<ul>\n";
  for ($i=0;$i<$numOther;$i++) {
    print "<li><a href=\"$other[$i]\">$other[$i]</a>\n";
  }
  print "</ul>\n";
}

# All done, print the tail...

&print_tail;

select(STDOUT) ;

# close the abstracts of the day page

close(OUTFILE) ;

# put the final bits in the printing script

#print SCRIPT "#\n";
#print SCRIPT "# ---------- Daily Brew Generation ----------\n";
#print SCRIPT "#\n";
#print SCRIPT "$html2ps -o $coffeeDir/coffee.ps $coffeeDir/coffee.html \n" ;

# print 5 copies of the daily brew (coffee.ps).  On some printers we
# need to print 5 times for efficiency - test your printer and decide

#print SCRIPT "$printCommand -# 5 $coffeeDir/coffee.ps \n" ;

#for ($i==0; $i<5; $i++) {
#  print SCRIPT "$printCommand $coffeeDir/coffee.ps \n" ;
#}

# remove the coffee.ps file

#print SCRIPT "'rm' -f $coffeeDir/coffee.ps \n" ;

# including an update to the printing lot to make sure it did its thing

#print SCRIPT "#\n" ;
#print SCRIPT "echo \"Coffee abstract downloading/printing done at `date`\" >> $coffeeDir/brew.log \n";

# make the script executable and close it

#chmod(0755,"$dataDir/print.sh");

#close(SCRIPT) ;

# all done!

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
<title>Astro Coffee - Step 2: Brew...</title>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
</head>
<body bgcolor="#ffffff">

END
}

# -------------------- Print the error page heading --------------------

sub print_err_head {
        print <<END;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Astro Coffee - Missing astro-ph listing</title>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
</head>
<body bgcolor="#ffffff">

END
}

# -------------------- Print the web page tail --------------------

sub print_tail {
        print <<END;

<hr>
$versionID [$versionDate]
</BODY>
</HTML>
END
}

#---------------------------------------------------------------------------

# handler for the HTML parser

sub start_HTML_handler  {
  return if shift ne "title";
  my $self = shift;
  $self->handler(text => sub { $title .= shift; }, "dtext");
  $self->handler(end  => sub { shift->eof if shift eq "title"; },
		 "tagname,self");
}

# Get the file from the document URL

sub get_HTML_title {
  my ($docurl) = @_;
  $title = "";
  my $p = HTML::Parser->new(api_version => 3);
  $p->handler( start => \&start_HTML_handler, "tagname,self");
  my $content = get("$docurl");
  if (defined $content) {
    $p->parse($content);
  }
  else {
    print "Could not get document from $docurl\n";
  }
  $p->eof;
}
