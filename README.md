TYPO3 Copyright Header
======================

Objective
---------

This bash script makes a mass-update on all .php files of a TYPO3 CMS source directory and replaces the existing copyright header with a new one.

Installation
------------

1. Create a new folder, for example `copyright`
2. Copy the following two files into this directory: `copyright.sh` and `copyright-php-files.txt`
3. Ensure, the script file is executable: `chmod u+x copyright.sh`
4. Clone (Git) the latest TYPO3 CMS source files into the directory `copyright`, e.g. `copyright/typo3_src.git`

Usage
-----

Change into the `copyright` directory and execute the script `copyright.sh`:

```
cd copyright
./copyright.sh typo3_src.git
```

This will search for *.php files in `typo3_src.git` and replace the copyright header with the content of file `copyright-php-files.txt`.

Author
------

Michael Schams
[schams.net](http://schams.net)

