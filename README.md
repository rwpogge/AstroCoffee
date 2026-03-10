# AstroCoffee

**Last Update: 2026 Mar 8 [rwp]**

Software for the OSU AstroCoffee arXiv paper selection and web tools

See [Release Notes](releases.md) for details.

## Overview

This repository contains CGI scripts written in perl and python used
for running OSU AstroCoffee, and two Jupyter notebooks used for code
development and RSS feed testing.

## AstroCoffee Web Forms

arXiv posts new astrophysics papers on astro-ph 5 days a week (Sunday
through Thursday) at 8pm Eastern Time.  In addition to the email
announcement and web pages at [arxiv.org](http://arxiv.org), they also
generate an RSS web feed with the most recent posting. For astro-ph,
the RSS feed URL is `arxiv.org/rss/astro-ph`.

The AstroCoffee CGI scripts work in 3 steps:

### `grind.py`

This python script reads the current RSS feed, creates a local digest
used by subsequent steps, and creates and displays a paper selection
web form titled "The Daily Grind". This script uses the python
`requests` and `BeautifulSoup` modules for RSS feed retrieval and
parsing.

The selection web form lists all papers from that day sorted into new
papers, cross-listings, and replacement posting as a checkbox
selection form. Two textbox entry widgets following the current paper
selection: one to allow the user to add links to previous arXiv papers
not in the current feed, and a second to add links to non-arXiv papers
(e.g., from journals or press releases).

When the user clicks on the `Submit Choices` button at the bottom of
the selection form, it triggers the next script..

### `brew.pl`

This perl script processes the data from the "grind" webform, displays
the selections as links to the arXiv abstract pages for each paper,
and then asks the user to review their selections and either commit or
go back.

If the user clicks on the `Commit` button, it triggers the final
script...

### `pour.pl`

This perl script processes the final selections from the "brew" script
and performs the following actions:
 * Creates the *Daily Brew* web page listing the paper selections
 * Copies the old *Daily Brew* into the local archive of old selections

## Diagnostic Notebooks

Two Jupyter notebooks are provided

### `grind.ipynb`

This is the sandbox used to develop the `grind.py` script and test changes
needed before deploying a new version on the web server.

### `checkFeed.ipynb`

Sometimes the `grind.py` script either finds no papers or has some
other error (like showing a previous day's posting of papers not the
current day's).  These are almost always problems with the source
astro-ph RSS feed at arxiv.orb.  This notebook is provided to check
the current RSS feed and run diagnostics to test if the problem is
indeed on the feed side.

