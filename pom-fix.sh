#!/bin/bash
tmp="$1.tmp"
awk '/<source>/{print "<forceJavacCompilerUse>true</forceJavacCompilerUse>";print;next}1' $1 > $tmp && mv $tmp $1
f2="$(<$2)" && awk -vf2="$f2" '/<\/profiles>/{print f2;print;next}1' $1 > $tmp && mv $tmp $1