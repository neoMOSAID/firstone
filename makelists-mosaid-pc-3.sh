#!/bin/bash
workingDir=$( cd "$(dirname "$0")" ; pwd -P )
theBookDir="$workingDir/theBook"
RESOURCES="$workingDir/resources"
FILE="$workingDir/theBook/lists.tex"

echo '\documentclass[12pt,a4paper]{article}
\usepackage[left=1.00cm, right=1.00cm, top=0.60cm, bottom=2.50cm]{geometry}
\usepackage{amsmath,amsfonts,amssymb}
\usepackage{tabu,multirow}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{fancyhdr}

\usepackage{fontspec}
\usepackage{polyglossia}
\setmainlanguage{arabic}
\setotherlanguage{english}
%\setmainfont{Amiri}
\setdefaultlanguage[calendar=gregorian,numerals=maghrib]{arabic}
\newfontfamily\arabicfont[Script=Arabic, Scale=1.0]{Amiri}

\usepackage{atbegshi}% http://ctan.org/pkg/atbegshi
\AtBeginDocument{\AtBeginShipoutNext{\AtBeginShipoutDiscard}}

\pagestyle{fancy}
\fancyhead{}
\fancyfoot{}
\fancyfoot[R]{السنة الدراسية : 2019-2020}
\fancyfoot[L]{الأستاذ : رضوان مساعد}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

\setlength{\extrarowheight}{4.5pt}
\begin{document}
\begin{center}
' > "$FILE"

data="$(cat "$workingDir/files/tableau"|
awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|
cut -d= -f1|sort|uniq)"
IFS=$'\r\n' classes=($(echo "$data"))
for (( i1 = 0 ; i1 < ${#classes[@]} ; i1 ++)) ; do
str1='\begin{table}[]
\caption{'"${classes[$i1]}"'}
\centering
\resizebox{\textwidth}{!}{%
\begin{tabu}{|c|c|[2pt]c|c|c|c|[2pt]c|c|c|c|[2pt]c|}
\hline
'
str1+='  &   & \multicolumn{4}{c|}{'" $(cat "$RESOURCES/semester")"' 1} '
str1+='     & \multicolumn{4}{c|}{'" $(cat "$RESOURCES/semester")"' 2} '
str1+='     &  '"$(cat "$RESOURCES/ng")"' \\ \hline
'
str1+="No & $(cat "$RESOURCES/name") "
str2=''
for k in {1..4} ; do
    str2+="&   $(cat "$RESOURCES/ds") $k "
done

str1+="$str2 $str2"
str1+='  &  \\ \hline
'

ll=1
while read -r name ; do
    str1+=" $ll & $name"
    for k in {1..8} ; do
        str1+=' & '
    done
    str1+=' & \\ \hline'$'\n'
    ll=$((ll+1))
done < "$theBookDir/${classes[$i1]}-list"

str1+='
\end{tabu}%
}
\end{table}

'
echo "$str1" >> "$FILE"
done
echo '
\end{center}
\end{document}
' >> "$FILE"

xelatex "$FILE"

