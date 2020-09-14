#!/bin/bash
# diff-whitespace-only file1 file2

if [[ $# -ne 2 ]]; then
   echo "Usage: diff-whitespace-only file1 file2"
   exit 1
fi

# Using perl to simulate "readlink -f" on mac (to resolve sym links to the temp directory)
# git apply will complain with references via sym links.
# See: https://stackoverflow.com/a/42918/411282
tempfile1=$(perl -MCwd -le 'print Cwd::abs_path(shift)' $(mktemp -t diff-ws))
tempfile2=$(perl -MCwd -le 'print Cwd::abs_path(shift)' $(mktemp -t diff-ws))

cp "$1" "$tempfile1"
cp "$2" "$tempfile2"


# Had trouble in git apply with -p0 (kept the "a/b") and -p1 (stripped the
# leading slash), so stripping paths manually with --directory and -p#
tempdir=$(dirname "$tempfile1")
numslashes=$(dirname "$tempfile1" | sed 's/[^\/]//g' | wc -c | tr -d " ")

# The "git apply" below will delete temp1, and overwrite temp2 with
# temp1 + the patch that has none of the whitespace diffs between the two.
# Derived from: Add only non-whitespace changes
# https://stackoverflow.com/q/3515597/411282

git diff -U0 -w --no-color "$tempfile1" "$tempfile2" \
    | git apply -p"$numslashes"  --directory "$tempdir"  -v --unsafe-paths  --unidiff-zero --ignore-space-change -


# Now diff "old + NON-whitespace diffs" with "new" to get just the
# whitespace diffs.

git diff "$tempfile2" "$2"
