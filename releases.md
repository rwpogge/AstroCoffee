# AstroCoffee Release Notes

**Last Release: 2026 Mar 8**

## Version 3.0.5 - 2026 Mar 8

Minor code changes required because of a major python update, some things `BeautifulSoup` did before
have been deprecated, method names changed (`findAll()` changed to `find_all()`), and some minor cleanup.

This is the version we migrated onto GitHub for support and curation moving forward.


## Version 3.0.4 - 2024 Mar 4

### `grind.py` 
Changed the behavior if no papers were found in the feed, which can sometimes happen because
the RSS feed was created empty of papers on the arXiv side.  This allows generation of the
selection form without new papers to permit selection of old/external papers using the
appropriate html form entry boxes.

## Version 3.0.3 - 2024 Feb 15

### `grind.py`

Adjusted the author list extraction code to avoid empty `pAuth` list errors that first popped up with 
this day's arXiv posting. Extra bits of code courtesy of Matt Rendina.

## Version 3.0.2 - 2024 Feb 3

### `grind.py` 
Removed the UTC date trick from the old Brew archive, now using the `pubDate` datum in the XML files
which is more robust.  Avoids issues with people getting ahead of paper selection accidentally overwriting
the previous day's selections because the old UTC date had issues if you were on the wrong side of UTC midnight.
This usually worked for perl, not so much for python.  Nothing like users to help you learn how to break things.

## Version 3.0.1 - 2024 Feb 2

### `grind.py`
Migrated from standalone notebook for CGI scripting with help from Matt Rendina

## Version 3.0.0 - 2024 Feb 1

### `grind.py`
Start of development with standalone Jupyter notebook and python codes that ran in
the Linux shell to learn how to parse the new arXiV RSS feeds.

Versions 1 and 2 were written in perl, version 3 was written in python to address changes in the arXiv 
RSS feed XML format that appeared on this date that broke the old perl script's SAX-based parser.  
The decision was made to migrate to python to take advantage of better XML parsing
offered by the `requests` and `BeautifulSoup` python modules.

We only migrated `grind.pl` to python, and python's CGI handling still leaves much to be desired
compared to perl's.  `brew.pl` and `pour.pl` will stay in python.

### `brew.pl`
Unchanged from version 2.5.2 from 2022 Mar 22

### `pour.pl`
Unchanged from version 2.2.0 from 2022 Mar 22

