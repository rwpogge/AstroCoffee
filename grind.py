#!/opt/anaconda3/bin/python
#
# Replacement for grind.pl to adapt to changes in the ArXiV's RSS feed
# XML format that manifested on 2024 Feb 1 and broke the old Perl
# script's SAX parser.
#
# Decision was made to retire grind.pl and rewrite in python to take
# advantage of better XML parsing using the requests and BeautifulSoup
# modules.
#
# Author: 
#   R. Pogge (OSU Astronomy)
#   pogge.1@osu.edu
#
# Revision History:
#   2024 Feb 01 - development start [rwp/osu]
#   2024 Feb 02 - modified for CGI [rwp & Matt Rendina, OSU]
#   2024 Feb 03 - removed UTC date trick for the Brew archive, now
#                 using the pubDate item in the XML which is
#                 robust [rwp/osu]
#   2024 Feb 15 - Adjusted author list extraction to avoid empty
#                 pAuth list errors first seen on this day.
#                 [mcr/osu] with extra bits [rwp/osu]
#   2024 Mar 04 - changed behavior if no papers found in the feed
#                 to give the selection form w/o new papers but
#                 allow use of the old/external papers entries [rwp]   
#----------------------------------------------------------------------

import sys
import os
import re
import numpy as np
from datetime import datetime

# XML parsing

import requests
from bs4 import BeautifulSoup

# Setup

versionID = '3.0.5'
versionDate = '2026-03-08'

# ArXiV RSS Feed for astro-ph

rssFeed = 'http://arxiv.org/rss/astro-ph'

# Read the date

now = datetime.now()
calDate = now.strftime('%A %B %e')

# brew log relative URL

brewLog = f'/Coffee/brew.log'

# daily paper database file

coffeePot = '/var/www/CoffeePot'

dbFile = f'{coffeePot}/astro-ph.pdb'
#dbFile = f'./astro-ph.pdb'

# Maximum number of authors to display before using et al.

maxAuth = 10

# Read the arxiv RSS feed

r = requests.get(rssFeed)
soup = BeautifulSoup(r.text,'xml')
papers = soup.find_all('item')

numPapers = len(papers)

# First check - we get anything?  If not, say so and exit

#if numPapers == 0:
#gotNothing = f"""
#Content-type: text/html
#
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
#<HTML>
#<HEAD>
#<TITLE>Astro Coffee - No Papers in the arXiv RSS feed</TITLE>
#<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
#</HEAD>
#<BODY BGCOLOR="#FFFFFF">
#<h2>ERROR: No papers found on arXiv today</h2>
#<p>The arXiv RSS feed channel has no papers
#listed for today.  Note that weekends and some holidays
#have no postings, or the feed was not constructed 
#correctly.  
#<p>
#Please let Rick Pogge know you had problems, and if he is
#around hopefully it might be solved before coffee time.
#If not, be ready to do it by hand the old fashioned way...
#<hr>
#grind.py v{versionID} [{versionDate}]
#</BODY>
#</HTML>
#      """
#    print(gotNothing)
#    sys.exit(1)

# We got at least one paper posted, start parsing the RSS feed for
# the bits we need

# Posting date derived from the pubData element. Use this for
# display on the webpage and as the rootname of the Brew archive entry

pubDate = soup.find_all('pubDate')
pubBits = pubDate[0].text.split(' ')
postingDate = f'{pubBits[3]} {pubBits[2]} {pubBits[1]}'
archiveRoot = f'{pubBits[3]}{pubBits[2]}{pubBits[1]}'

# Temporary lists because of some infelicities in the feed

arxivIDs = []
titles = []
absLinks = []
pdfLinks = []
absNames = []
abstracts = []
authors = []
subTypes = []

for paper in papers:
    titles.append(paper.find('title').text)
    link = paper.find('link').text
    
    # pick apart the link into the bits we need
    
    protocol,url = link.split('//')
    urlBits = url.split('/')
    paperID = urlBits[-1]
    arxivIDs.append(paperID)
    absLinks.append(f'{protocol}//arxiv.org/abs/{paperID}')
    pdfLinks.append(f'{protocol}//arxiv.org/pdf/{paperID}.pdf')
    absNames.append(f'arXiv:{paperID}')
    
    # submission type
    
    subTypes.append(paper.find('arxiv:announce_type').text.upper())

    # paper abstract
    
    abstracts.append(paper.find('description').text)

    # authors are in dc:creator, which can be a mess as arXiv user inputs
    # are not rigorously filtered. The extra processing below addresses
    # common issues we've encountered [mcr/osu & rwp/osu]
        
    rawAuth = paper.find('dc:creator')
    pAuth = rawAuth.text.split('\n')[1:-1]
    pAuth = re.sub(r"<\\/?dc:creator>", "", rawAuth.text).split(',')
    if len(pAuth) <= maxAuth:
        for auth in pAuth:
            auth = auth.replace(",","")
            if auth == pAuth[0]:
                authList = auth.strip()
            else:
                authList = f'{authList}, {auth.strip()}'
    else:
        authList = f'{pAuth[0].replace(",","").strip()}'
        for i in range(1,maxAuth):
            authList = f'{authList}, {pAuth[i].replace(",","").strip()}'
        authList = f'{authList}, et al. [{len(pAuth)-1} co-authors]'

    authors.append(authList)

# numpy arrays of our primary data

paperID = np.array(arxivIDs)
absURL = np.array(absLinks)
pdfURL = np.array(pdfLinks)
paperName = np.array(absNames)
paperType = np.array(subTypes)
paperTitle = np.array(titles)
paperAuths = np.array(authors)
paperAbst = np.array(abstracts)

# Number of new submissions

iNew = np.where(paperType=='NEW')[0]
numNew = len(iNew)

# Number of cross-posted papers

iCross = np.where(paperType=='CROSS')[0]
numCross = len(iCross)

# Number of replacements

iUpdated = np.where((paperType=='REPLACE') | (paperType=='REPLACE-CROSS'))[0]
numUpdated = len(iUpdated)

# Last step before we built the HTML pages is to delete the
# old database file and rebuild it with today's entries.

if os.path.exists(dbFile):
    os.unlink(dbFile)

pbd = open(dbFile,'w')
for i in iNew:
    dbStr = f'{paperID[i]}|astro-ph|{absURL[i]}|{pdfURL[i]}|{paperName[i]}|{paperType[i]}|{paperTitle[i]}|{paperAuths[i]}|{paperAbst[i]}'
    pbd.write(f'{dbStr}\n')
for i in iCross:    
    dbStr = f'{paperID[i]}|astro-ph|{absURL[i]}|{pdfURL[i]}|{paperName[i]}|{paperType[i]}|{paperTitle[i]}|{paperAuths[i]}|{paperAbst[i]}'
    pbd.write(f'{dbStr}\n')
for i in iUpdated:
    dbStr = f'{paperID[i]}|astro-ph|{absURL[i]}|{pdfURL[i]}|{paperName[i]}|{paperType[i]}|{paperTitle[i]}|{paperAuths[i]}|{paperAbst[i]}'
    pbd.write(f'{dbStr}\n')

pbd.close()

# Build the "Daily Grind" webform

# HTML compliant header and page title 
#   note the required space after the MIME-type specification
#   required by the webserver CGI interaction

htmlHead = """Content-type: text/html

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML>
<HEAD>
<TITLE>Astro Coffee Step 1: Grind...</TITLE>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<p>
<center><h1><cite>The Daily Grind</cite></h1></center>
"""
print(htmlHead)

# Instructions

instructions = f"""<h2>Instructions</h2>
<p>This set of web forms is used to select a subset of the most recent
astro-ph abstracts for discussion at Astro Coffee. The procedure is as follows: 
<dl> 
<p><dd><b>Step 1</b>: Select astro-ph papers using the form below. 
<p><dd><b>Step 2</b>: Review your selections. 
<p><dd><b>Step 3</b>: Post today's edition of the <a href="/Coffee/coffee.html"><i>Daily Brew</i></a>, 
and update the <a href="/Coffee/Archive/">AstroCoffee Archive</a>. 
</dl> 

<p>
<hr>

<h2>Step 1: Select Papers</h2> 

<p>Abstracts from the lastest arXiv.org posting for astro-ph are below.
Note that if there was a problem with today's abstract
RSS feed, you may have to select abstracts by 
hand the old-fashioned way! 
"""

print(instructions)

# Build the selection form

formHeader = f"""<p>
<h3>astro-ph abstracts for {calDate}</h3>

<form action="/cgi-bin/Coffee/brew.pl" method="POST">"""

print(formHeader)

# New papers

if numNew == 0:
    newHeader = f"""
<h3>No New Papers found</h3>

An arXiv RSS feed was found but contained no papers.
<p>
This could be a glitch at arXiv or it could be one of the occasional
arXiv holidays. Before sending out an email asking for help with the
local coffee scripts, please check the 
<a href='https://info.arxiv.org/help/availability.html'>arXiv 
Availability of submissions webpage</a> to check on possible issues
at arXiv proper.
<p>
<table border=0>"""

else:
    newHeader = f"""
<h3>New Papers ({numNew}):</h3>
<table border=0>"""

print(newHeader)

for i in iNew:
    entryStr = f"""<tr>
<td><td valign=top><input type="checkbox" name="abstract" value="{paperID[i]}"></td>
<td><b>{paperTitle[i]}</b><br>
{paperAuths[i]}<br>
<a href="{absURL[i]}">{paperName[i]}</a>
</td>
</tr>
<tr><td>&nbsp;</td><td>&nbsp;</td></tr>"""
    print(entryStr)

if numNew > 0:
    print("</table>")

# Cross-listings

if numCross > 0:
    newHeader = f"""
<h3>Cross Listings ({numCross}):</h3>
<table border=0>"""

    print(newHeader)

    for i in iCross:
        entryStr = f"""<tr>
<td><td valign=top><input type="checkbox" name="abstract" value="{paperID[i]}"></td>
<td><b>{paperTitle[i]}</b><br>
{paperAuths[i]}<br>
<a href="{absURL[i]}">{paperName[i]}</a>
</td>
</tr>
<tr><td>&nbsp;</td><td>&nbsp;</td></tr>"""
        print(entryStr)
    print("</table>")

# updated papers

if numUpdated > 0:
    newHeader = f"""
<h3>Replacements ({numUpdated}):</h3>
<table border=0>"""

    print(newHeader)

    for i in iUpdated:
        entryStr = f"""<tr>
<td><td valign=top><input type="checkbox" name="abstract" value="{paperID[i]}"></td>
<td><b>{paperTitle[i]}</b><br>
{paperAuths[i]}<br>
<a href="{absURL[i]}">{paperName[i]}</a>
</td>
</tr>
<tr><td>&nbsp;</td><td>&nbsp;</td></tr>"""
        print(entryStr)
    print("</table>")

# Add the hidden keywords that pass along information needed by subsequent forms

hiddenKeys = f"""
<input type="hidden" name="NumAbstracts" value="{numPapers}">
<input type="hidden" name="AbstListing" value="{dbFile}">
<input type="hidden" name="ArchiveName" value="{archiveRoot}.html">
<input type="hidden" name="PostingDate" value="{postingDate}">
"""
print(hiddenKeys)


# HTML bottom of the page
#
# Provide entry widgets for users to add previous arxiv papers by arXiv number
# and by full URL links to papers outside arxiv.
#
# Then add the submit/reset buttons closing the form and close out the
# HTML file

bottomMatter = f"""
<h3>Previous arXiv Papers</h3>
Add links to previous arXiv papers by arXiv number (e.g., 2202.04273v2)
<b>one arXiv number line</b><br>
<textarea name="OldPapers" cols=24 rows=4></textarea>

<h3>Other Papers/Links</h3>
Add links by full URL (e.g., https://www.nature.com/articles/d41586-022-00425-8)
<b>one URL per line</b><br>
<textarea name="OtherPapers" cols=24 rows=4></textarea>

<input type="hidden" name="Printer" value="NONE">

<p>
<input type="SUBMIT" value="Submit Choices">  &nbsp; or &nbsp; 
<input type="RESET" value="Clear Choices">

</form>
<hr>
grind.py v{versionID} [{versionDate}]
</BODY>
</HTML>
"""

print(bottomMatter)

# All done, bye bye!

sys.exit(0)
