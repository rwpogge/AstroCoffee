# AstroCoffee

**Last Update: 2026 Mar 8 [rwp]**

Software for the OSU AstroCoffee arXiv paper selection and web tools

See [Release Notes](releases.md) for details.

## Overview

This repository contains the CGI scripts for running OSU AstroCoffee. These
are written in python and perl. Two Jupyter notebooks used for code and
RSS feed testing are included.

## AstroCoffee Web Forms

The arXiv posts new papers 5 days a week (Sunday through Thursday) at 8pm
Eastern Time.  In addition to the email announcement and web pages at
[arxiv.org](http://arxiv.org), they also generate an RSS web feed listing
all of the astro-ph papers in XML format.  For astro-ph, the RSS feed
URL is `arxiv.org/rss/astro-ph`.

The AstroCoffee CGI scripts work in 3 steps:

### `grind.py`

This python program reads the current RSS feed, creates a local digest
used by subsequent steps, and creates and displays a paper selection
web form.

When a user clicks on "Submit" on the web form, it triggers the next
script..

### `brew.pl`

This perl script processes the selections from the "grind" webform,
showing the selections, and asking the user to confirm or go back.

If the selections are confirmed, it triggers the final script...

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

Sometimes, the `grind.py` script either finds no papers or has some
other error (like showing a previous day's posting of papers not the
current day's).  These are almost always problems with the source
astro-ph RSS feed at arxiv.orb.  This notebook is provided to check
the current RSS feed and run diagnostics to test if the problem is
indeed on the feed side.

