#!/bin/bash
string=$1
string="$(echo "$string"| sed 's@\\\\@@g' )"
string="$(echo "$string"| sed 's@\\noindent\\makebox\[\\linewidth\]{\\rule{\\paperwidth}{0.4pt}}@@g' )"
string="$(echo "$string"| sed 's@\\par@@g' )"
string="$(echo "$string"| sed 's@\\noindent@@g' )"
string="$(echo "$string"| sed 's@%%:.*$@@g' )"
string="$(echo "$string"| sed '/^$/d' )"
echo "$string"
