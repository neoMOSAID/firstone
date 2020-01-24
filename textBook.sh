#!/bin/bash
#=======================================
#   script to create a journal for my
#   job as a high school Maths teacher
#=======================================
#============ Global files ==========
workingDir=$( cd "$(dirname "$0")" ; pwd -P )
tmpfile="/tmp/textBook_tmp.tex"
theBookDir="$workingDir/theBook"
RESOURCES="$workingDir/resources"
LOGFILE="$theBookDir/logfile"
removeLatex="$workingDir/removeLatex.sh"
#======================================
if ! [ -f "$LOGFILE" ] ; then
    touch "$LOGFILE"
fi
#==================== create a file for each classe
data="$(cat "$workingDir/files/tableau"|
        awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|
        cut -d= -f1|sort|uniq)"
IFS=$'\r\n' classes=($(echo "$data"))
for (( i1 = 0 ; i1 < ${#classes[@]} ; i1++ )) ; do
    if ! [[ -f "$theBookDir/${classes[$i1]}.tex" ]] ; then
      touch "$theBookDir/${classes[$i1]}.tex"
    fi
    if ! [[ -f "$theBookDir/${classes[$i1]}-list" ]] ; then
        touch "$theBookDir/${classes[$i1]}-list"
    fi
done
#==============================
str=""
yearStart='2019-09-09'
#==============================

# $1 class
# $2 period
# $3 period num
function headerA(){
    entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')
    local periodNum=$3

    str=$'\n''\par'
    str="$str"$'\n''\noindent\makebox[\linewidth]{\rule{\paperwidth}{0.4pt}}'

    str="$str"$'\n'' \\'

    # %N begin
    str="$str"$'\n'"%%:$entryDATE:$periodNum:begin"

    export LC_ALL=ar_MA.utf8
    local line="$(cat "$RESOURCES/dateA") : $(date --date "-$MINUSDAYS days" +'%A %d %B %Y') \\\\"
    export LC_ALL=en_US.utf8

    str="$str"$'\n'"$line"

    line="$(cat "$RESOURCES/classA") : $1 \\\\"
    str="$str"$'\n'"$line"

    line="$(cat "$RESOURCES/periodA") : $2 \\\\"

    str="$str"$'\n'"$line"

    str="$str"$'\n'" \\\\  "

}

# $1 name of holyday
# $2 first day
# $3 last day
function headerB(){
  entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')

  str="$str"$'\n''\par'
  str="$str"$'\n''\noindent\makebox[\linewidth]{\rule{\paperwidth}{0.4pt}}'

  str="$str"$'\n'' \\'

  # %N begin
  str="$str"$'\n'"%%:$entryDATE:begin"

  if [ -z "$3" ]
      then
          str="$str"$'\n'"$2 : $1"
      else
          str="$str"$'\n'"$(cat "$RESOURCES/from") $2 $(cat "$RESOURCES/to") $3"
          str="$str"$'\n''\newline'
          str="$str"$'\n''\indent'
          str="$str"$'\n'"$1"
  fi
}




# $1 period number
# $2 y for auto saving
function SaveTheFile(){
      local periodNum=$1
      local today=`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`
      local class=$(echo "$periods_of_today"|awk -v var="$periodNum" '{print $var}')
      class="${class%=*}"
      var="$today:$class:period$periodNum"
      if `grep "$var:saved" "$LOGFILE" >/dev/null` ; then
        printf "\033[1;31m already saved\033[0m\n"
        return
      fi
      echo "$str" >> "$theBookDir/$class.tex"
      entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')
      echo "%%:$entryDATE:$periodNum:end" >> "$theBookDir/$class.tex"
      local lnumber=$( awk -v v="$var:unsaved" 'match($0,v){print NR}' "$LOGFILE" )
      if [[  "$lnumber" != "" ]] ; then
        if [[ "$2" == y ]]
            then
                sed   --in-place -e "${lnumber} s/.*/$var:saved:auto/" "$LOGFILE"
            else
                sed   --in-place -e "${lnumber} s/.*/$var:saved/" "$LOGFILE"
        fi
      fi
}

function showMenu(){
  local mm=$(printf '  %s\n' "$1"|sed 's/(/\\033\[1;32m(/g'|sed 's/)/)\\033\[0m/g')
  printf "$mm"
  echo
}

#  $1 period number or "" for ext-period
#  $2 y for automatic saving
function editing(){
    local periodNum=$1
    while true ; do
        tput reset
        if [[ "$2" != "y" ]]
            then
                 "$removeLatex" "$str"
                  echo
            else
                  echo
                  echo -ne "\t saving... $entryDATE"\\r
        fi
        if [[ "$2" != "y" ]]
            then
                menu="(a)arabic text (e)equation/latin text (f)insert pdf/image \n"
                menu+="  (s)save & exit (x)quit w/o saving "
                printf "\033[1;33m"
                echo "=============================================================="
                printf "\033[0m"
                showMenu "$menu"
                printf "\033[1;33m"
                echo "=============================================================="
                echo
                IFS= read -rN 1 -p " : " choice
                printf "\033[0m\n"
            else choice=s
        fi
        case "$choice" in
              a)    echo "$str" >| "$tmpfile"
                    xkb-switch -s ar
                    gedit "$tmpfile" && str="$(cat "$tmpfile" )"
                    xkb-switch -s fr ;;
              e)    echo "$str" >| "$tmpfile"
                    vim "$tmpfile"
                    str="$(cat "$tmpfile" ) \\\\"  ;;
              f)
                    file1="$(find "$HOME" -type f \
                    \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.pdf" \) \
                    2>/dev/null |fzf)"
                    ext=${file1##*.}
                    cp "$file1" "$theBookDir/file-`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`.$ext"
                    str+=$'\n'"\\includepdf[pages={1}]"
                    str+="{pdf-`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`.$ext}" ;;
              s)    SaveTheFile "$periodNum" "$2"
                    if [[ "$2" != "y" ]] ;
                        then exit
                        else return
                    fi ;;
              x)    exit ;;
        esac
    done
}

# $1 status
# $2 y for automatic saving
function allsaved1(){
  if [[ "$1" == "status" ]] ; then return ; fi
  if [[ "$2" == "y" ]] ; then return ; fi
  printf "\033[1;35m All saved\033[1;31m\n"
  while true ; do
    IFS= read -rN 1 -p " (p) print (x) exit ?: " answer
    printf "\033[0m\n"
    case "$answer" in
      p) makeIT ;;
      x) exit ;;
    esac
  done
}

# $1 status
# $2 y for automatic saving
function allsaved0(){
  local today=`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`
  local today_periods_from_log=$(grep ^"$today" "$LOGFILE")
  local periods_of_today=$(cat "$workingDir/files/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{$1="";print $0 }')
  while read -u 3 -r line ; do
      if `echo "$line" |grep unsaved >/dev/null ` ; then
            local periodNum=$(echo "$line" | awk -F: '{print $3}'|tr -dc '0-9' )
            local class=$(echo "$periods_of_today" | awk -v var="$periodNum" '{print $var}')
            if [[ "$1" == "status" ]] ; then
                  speriode=" $(cat "$RESOURCES/periodA" ) "
                  sunsaved=" $( cat "$RESOURCES/h-unsaved" ) "
                  sclass=" ${class%=*} "
                  tmp="${class#*=}"
                  stmp=" ${tmp/-/ - } "
                  printf '\033[1;31m%-10s' "$stmp"
                  printf '\033[1;31m%-10s' "$sclass"
                  printf '\033[1;31m%-10s' "$sunsaved"
                  printf '\033[0m\n'
            fi
            msg="${class%=*} ** `echo ${class#*=} |sed 's/-/ - /'`"
            if [[ "$2" != "y" ]]
                then
                    if [[ "$1" != "status" ]] ; then
                        IFS= read -rN 1 -p " $msg  $(cat "$RESOURCES/h-saveOne" ) (Y/n)?" answer
                        echo
                    fi
                else answer="y"
            fi
            if [[ "$answer" == "y" || "$answer" == "Y" ]] ; then
                  headerA  ${class%=*}  "`echo ${class#*=} |sed 's/-/ - /'`" "$periodNum"
                  editing  $periodNum  "$2"
            fi
      fi
  done 3<<< "$today_periods_from_log"
}

# $1 status
# $2 y for automatic saving
function savePeriods(){
   if (( allsaved == 1 ))
      then allsaved1 "$1" "$2"
      else allsaved0 "$1" "$2"
   fi
}

function convertAndGetDate(){
  local converted=$(echo "$1"|awk -F- '{printf("%s-%s-%s",$3,$2,$1)}')
  export LC_ALL=ar_MA.utf8
  echo `date -d "$converted +$2 days" +'%A %d %B %Y'`
  export LC_ALL=en_US.utf8
}

function handleBreakDays(){
    str=""
    local today=`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`
    today_is_a_breakday=0
    if `grep "$today" "$workingDir/files/breakdays" >/dev/null` ; then
        today_is_a_breakday=1
        if `grep "$today:saved" "$LOGFILE" >/dev/null` ; then
             return
        fi
        local name=$(grep "$today" "$workingDir/files/breakdays"|awk -F: '{print $2}')
        local today=$(grep "$today" "$workingDir/files/breakdays"|awk -F: '{print $1}')
        if `echo "$today" |grep '\*' >/dev/null`
            then
                local nbrDays=$(echo $today |cut -d* -f2)
                local cleaned="$(echo $today |cut -d* -f1)"
                echo
                question="$(cat "$RESOURCES/Q-is") $( convertAndGetDate "$cleaned" 0 ) "
                question+="$(cat "$RESOURCES/is") $name  $(cat "$RESOURCES/Q-mark") "
                diff=0
                diff=$((oldKK-kk))
                if (( $diff >7 && $diff != $kk )) ; then
                    Oldchoice=""
                fi
                if [[ "$Oldchoice" == 'y' ]]
                    then
                        choice=n
                    else
                        echo "$question"
                        echo
                        IFS= read -rN 1 -p " (y/n) : " choice
                        Oldchoice=$choice
                        oldKK=$kk
                        echo
                fi
                case "$choice" in
                   y|Y)
                        local is_muslim_holiday=1
                        local FIRSTONE=$( convertAndGetDate "$cleaned" 0 )
                        local LASTONE=$( convertAndGetDate "$cleaned" "$nbrDays")
                        ;;
                     *)
                        today_is_a_breakday=0
                        return ;;
                esac
            else
                local firstOne=$(grep "$name" "$workingDir/files/breakdays"|awk -F: '{print $1}'|head -1)
                local FIRSTONE="$( convertAndGetDate "$firstOne" 0 )"
                local lastOne=$(grep "$name" "$workingDir/files/breakdays"|awk -F: '{print $1}'|tail -1)
                local LASTONE="$( convertAndGetDate "$lastOne" 0 )"
        fi
        if [[ "$FIRSTONE" != "$LASTONE" ]]
            then
                  headerB  "$name" "$FIRSTONE" "$LASTONE"
                  local allOfThem=$(grep "$name" "$workingDir/files/breakdays"|awk -F: '{print $1}')
                  while read -r line ; do
                        echo $line:saved:$name >> "$LOGFILE"
                  done <<< "$allOfThem"
            else
                headerB  "$name" "$FIRSTONE"
                echo $firstOne:saved:$name >> "$LOGFILE"
        fi
        data="$(cat "$workingDir/files/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
        IFS=$'\r\n' classes=($(echo "$data"))
        for (( i1 = 0 ; i1 < ${#classes[@]} ; i1 ++)) ; do
                  echo "$str" >> "$theBookDir/${classes[$i1]}.tex"
        done
        str=""
    fi
}

function startup(){
    handleBreakDays

    if (( $today_is_a_breakday == 1 )) ; then return ; fi
    local today=`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`
    if [[ `date --date "-$MINUSDAYS days" +'%a'` == 'Sun' ]] ; then
      if ! `grep "$today" "$LOGFILE" >/dev/null` ; then
          echo "$today:Sunday" >> "$LOGFILE"
      fi
      return
    fi
    local today_periods_from_log=$(grep ^"$today" "$LOGFILE")
    local number_of_periods=$(cat "$workingDir/files/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{print NF-1 }')
    local periods_of_today=$(cat "$workingDir/files/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{$1="";print $0 }')
    [[ -z "$number_of_periods" ]] && return
    if [[ "$today_periods_from_log" == "" ]]
        then
            for (( k4=1 ;k4<=$number_of_periods;k4++)) ; do
              local class=$(echo "$periods_of_today" | awk -v var="$k4" '{print $var}')
              class="${class%=*}"
              echo "$today:$class:period$k4:unsaved" >> "$LOGFILE"
            done
            allsaved=0
        else
            if ! `echo "$today_periods_from_log" | grep unsaved >/dev/null`
                then allsaved=1
                else allsaved=0
            fi
    fi
}

# $1 paragraph text
# $2 paragraph date
function EditIT(){
      text2="$1"
      local EditedEntryDATE="$2"
      while true ; do
            tput reset
            echo
            "$removeLatex" "$text2"
            echo
            menu="(a)arabic text (e)equation/text\n"
            menu+="  (f)insert pdf/image (x) save & exit"
            printf "\033[1;33m"
            echo "=============================================================="
            showMenu "$menu"
            printf "\033[1;33m"
            echo "=============================================================="
            echo
            IFS= read -rN 1 -p " : " choice
            echo
            case "$choice" in
                  a)   echo "$text2" >| "$tmpfile"
                       xkb-switch -s ar
                       gedit "$tmpfile" && text2=$(cat "$tmpfile" )
                       xkb-switch -s fr ;;
                  e)   echo "$text2" >| "$tmpfile"
                       vim "$tmpfile"
                       text2=$(cat "$tmpfile" ) ;;
                  f)
                       file1="$(find "$HOME" -type f \
                       \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.pdf" \) \
                       2>/dev/null |fzf)"
                       ext=${file1##*.}
                       cp "$file1" "$theBookDir/file-$EditedEntryDATE.$ext"
                       text2+=$'\n'"\\includepdf[pages={1}]{file-$EditedEntryDATE.$ext}"
                       ;;
                  x) return ;;
             esac
       done
}

# $1 date
# $2 period num
function editEntry(){
      entryDATE=$1
      if [ -z "$entryDATE" ] ; then return ; fi
      if [ -z $2 ]
            then entryNUM=1
            else entryNUM=$2
      fi
      theBook="$(grep  "$entryDATE" "$LOGFILE"|grep "period$entryNUM")"
      if [ -z "$theBook" ] ; then
          echo not found !
          exit
      fi

      theBook="$(echo "$theBook" | awk -F: '{print $2}').tex"

      local pattern1="%%:$entryDATE:$entryNUM:begin"
      local pattern2="%%:$entryDATE:$entryNUM:end"
      local theEntryDate="$entryDATE-$entryNUM"

      d1=$(grep -n "$pattern1" "$theBookDir/$theBook" | cut -d: -f 1)
      if [ -z "$d1" ] ; then
          echo d1 not found !
          return
      fi
      d1=$((d1+1))
      d2=$(grep -n "$pattern2" "$theBookDir/$theBook" | cut -d: -f 1)
      if [ -z "$d2" ] ; then
          echo d2 not found !
          return
      fi

      d2=$((d2-1))
      local text1=$(sed  -n "$d1,$d2"p "$theBookDir/$theBook")
      EditIT "$text1"  "$theEntryDate"

      printf '%s\n' "/$pattern1/+1,/$pattern2/-1d" "/$pattern1/a" "$text2" . wq | ed -s "$theBookDir/$theBook"
      sed -i '/^$/d' "$theBookDir/$theBook"

      lnumber=$( grep -n "$entryDATE" "$LOGFILE" | grep "period$entryNUM"| cut -d: -f1 )
      sed   --in-place -e "${lnumber} s/:auto//" "$LOGFILE"
}

# $1 : class name
function makeTable(){
str1='
\begin{table}[]
\caption{'"$1"'}
\centering
\setlength{\extrarowheight}{4pt}
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
done < "$theBookDir/$1-list"

str1+='

\end{tabu}%
}
\end{table}

\clearpage
\thispagestyle{empty}
\clearpage\mbox{}\clearpage

'
echo "$str1"
}

# $1 v for verbose
function makeIT(){
    >| "$theBookDir/product.tex"
    if [[ $yearStart == '2019-09-09' ]] ; then
        cat "$theBookDir/header" \
        | sed "s/insertNAMEhere/$(cat "$workingDir/files/name")/g" \
        | sed "s/insertSYEARhere/$(SYear)/g" \
        >| "$theBookDir/product.tex"
    fi
    data="$(cat "$workingDir/files/tableau"|
            awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|
            cut -d= -f1|sort|uniq)"
    IFS=$'\r\n' classes=($(echo "$data"))
    for (( i1 = 0 ; i1 < ${#classes[@]} ; i1 ++)) ; do
        if [[ $yearStart == '2019-09-09' ]] ; then
            cat "$theBookDir/classeheader" |
            sed "s/insertClassHere/${classes[$i1]}/" >> "$theBookDir/product.tex"
            listLength=$(cat "$theBookDir/${classes[$i1]}-list"|wc -l )
            if (( $listLength > 3 ))
                then
                    makeTable "${classes[$i1]}" >>  "$theBookDir/product.tex"
                else
                    printf '\033[1;33m warrning : class %s list file empty \033[1;0m\n' \
                    "${classes[$i1]}"
            fi
        fi
        cat "$theBookDir/${classes[$i1]}.tex" >> "$theBookDir/product.tex"
    done
    echo "\\vfill" >> "$theBookDir/product.tex"
    echo "\\end{document}" >> "$theBookDir/product.tex"
    cd "$theBookDir/"
    if [[ "$1" == "v" ]] ; then
        xelatex "product.tex"
        return
    fi
    if `xelatex "product.tex" |grep "Output written on" >/dev/null`
        then
            printf "\033[1;32m success\n"
            rm *.log *.aux
        else
            printf "\033[1;31m errors occured ! no pdf was produced\n"
    fi
}

function addPeriod(){
  str=""
  data="$(cat "$workingDir/files/tableau" \
      |awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}' \
      |cut -d= -f1|sort|uniq)"
  IFS=$'\r\n' classes=($(echo "$data"))
  printf "\033[1;32m\n"
  echo "   $(cat "$RESOURCES/add-menu")   "
  echo
  for ((k1=0;k1<${#classes[@]};k1++)) ; do
    echo " $((k1+1))) ${classes[$k1]}"
  done
  echo " x) exit"
  echo
  IFS= read -rN 1 -p " : " choice
  printf "\033[0m\n"
  if ! [[ "$choice" =~ ^[0-9] ]] ; then exit ; fi
  choice=$((choice-1))
  if (( $choice >= ${#classes[@]} )) ; then return ; fi
  if (( $choice < 0 )) ; then return ; fi
  headerA  "${classes[$choice]}" "$(cat "$RESOURCES/ext-period")"
  editing
}

# $1 can be status
function checkIfAllsaved(){
  local today=`date '+%Y-%m-%d'`
  local lastSavedDay=$(cat "$LOGFILE"|grep -w saved |tail -1|cut -d: -f1)
  if [[ -z "$lastSavedDay" ]]
      then lastSavedDay="$yearStart"
      else lastSavedDay=$(echo "$lastSavedDay"|awk -F- '{printf("%s-%s-%s",$3,$2,$1)}')
  fi
  nn="`date -d $today +%s` - `date -d $lastSavedDay +%s`"
  nn=$(( nn / (24*3600) ))
  for (( kk=$nn; kk >= 0 ; kk-- )) ; do
      MINUSDAYS=$kk
      startup
      if (( $kk > 0 ))
          then savePeriods  "s" "y"
          else
              savePeriods "status"
              if [[ "$1" == "status" ]]
                  then exit
              fi
      fi
  done
}

function openIT(){
    data="$(cat "$workingDir/files/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
    IFS=$'\r\n' classes=($(echo "$data"))
    printf "\033[1;32m\n"
    echo "   $(cat "$RESOURCES/open-class")   "
    echo
    for ((k1=0;k1<${#classes[@]};k1++)) ; do
      echo " $((k1+1))) ${classes[$k1]}"
    done
    echo " x) exit"
    echo
    IFS= read -rN 1 -p " : " choice
    printf "\033[0m\n"
    if ! [[ "$choice" =~ ^[0-9] ]] ; then exit ; fi
    choice=$((choice-1))
    if (( $choice >= ${#classes[@]} )) ; then return ; fi
    if (( $choice < 0 )) ; then return ; fi
    gedit "$theBookDir/${classes[$choice]}.tex" &
}

function backUP(){
  local year="$(date '+%Y')"
  local backupDir="$workingDir/backup/$(SYear)/`date '+%d-%m'`"
  if ! [ -d "$backupDir" ] ; then
      mkdir -p "$backupDir"
  fi
  rsync -aq "$theBookDir" "$backupDir" --exclude backup
  printf "\033[1;32m success\n"
}

function _printhelp () {
  printf '\033[1;33m  %-22s\t\033[1;37m%s\n' "$1" "$2"
}

function SYear(){
  local year=$(date '+%Y')
  local dd=$(date '+%m')
  dd=$(echo $dd | sed 's/^0*//')
  if (( $dd >= 9 ))
        then  echo "$year-$((year+1))"
        else  echo "$((year-1))-$year"
  fi
}

function getUnsaved(){
    data=$(
        echo
        printf '\t'
        echo "$(cat "$RESOURCES/unsaved" )"
        echo
        grep auto "$LOGFILE"  \
        | awk -F: '{print $1,$3," ",$2}' \
        | sed 's/^/\t/;s/period//g' \
        | grep --color=never "$1" \
        | cat -n
        echo
    )
    if [[ -z "$1" ]] ; then
        echo "$data"
        return
    fi
    number='^[0-9]+$'
    if ! [[ "$1" =~ $number ]] && [[ -z "$2" ]] ; then
        echo "$data"
        return
    fi
    if [[ "$1" =~ $number ]]  && [[ -z "$2" ]] ; then
        n=$1
    fi
    if [[ "$2" =~ $number ]] ; then n=$2 ; fi
    n=$((n+3))
    periode1=$( echo "$data" \
                | sed -n "$n"p \
                | awk '{print $2}'
            )
    periode2=$( echo "$data" \
                | sed -n "$n"p \
                | awk '{print $3}'
            )
    bash "$0" e $periode1 $periode2
}

function printhelp () {
   echo
  _printhelp  "h,H,help" "$(cat "$RESOURCES/h-help" )"
  _printhelp  "" "$(cat "$RESOURCES/h-save" )"
  _printhelp  "a,A,add" "$(cat "$RESOURCES/h-add" )"
  _printhelp  "e,E,edit [d-m-Y] [#N]" "$(cat "$RESOURCES/h-edit" )"
  _printhelp  "p,P,print" "$(cat "$RESOURCES/h-print" )"
  _printhelp  "s,S,status" "$(cat "$RESOURCES/h-status" )"
  _printhelp  "o,O,open" "$(cat "$RESOURCES/h-open" )"
  _printhelp  "b,B,backup" "$(cat "$RESOURCES/h-backup" ) $( SYear ) "
  _printhelp  "u,U,unsaved" "$(cat "$RESOURCES/h-auto" )"
  echo
}

function removeFiles(){
    read -r -p "confirm (yes/NO) : " ans
    if [[ "$ans" != "yes" ]] ; then
        echo nothing was deleted
        exit
    fi
    echo deleting files
    rm  "$LOGFILE"  2>/dev/null
    rm  "$theBookDir/product.pdf"  2>/dev/null
    cd  "$theBookDir"
    rm  *.tex  2>/dev/null
}

#save entries for all unsaved days before today
#abscence/pc not powered up/...
checkIfAllsaved "$1"

case "$1" in
             "")    savePeriods ;;
       edit|e|E)    editEntry $2 $3 ;;
        add|a|A)    addPeriod ;;
      print|p|P)    makeIT $2 ;;
     status|s|S)    exit;;       #savePeriods "status" ;;
       open|o|O)    openIT ;;
       view|v|V)    evince "$theBookDir/product.pdf" >/dev/null 2>&1 & ;;
       help|h|H)    printhelp ;;
    unsaved|u|U)    getUnsaved "$2" "$3" ;;
     backup|b|B)    backUP ;;
     remove|r|R)    removeFiles ;;
esac




