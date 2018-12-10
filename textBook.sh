#!/bin/bash
#=======================================
#   script to create a journal for my 
#   job as a high school Maths teacher
#=======================================
#============ Global files ==========
workingDir=$( cd "$(dirname "$0")" ; pwd -P )
tmpfile="$workingDir/.tmp.tex"
theBookDir="$workingDir/theBook"
RESOURCES="$workingDir/resources"
LOGFILE="$theBookDir/logfile"
#======================================
if ! [ -f "$LOGFILE" ] ; then
    touch "$LOGFILE"
fi
#==================== create a file for each classe
data="$(cat "$RESOURCES/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
IFS=$'\r\n' classes=($(echo "$data"))
for (( i1 = 0 ; i1 < ${#classes[@]} ; i1++ )) ; do
    if ! [ -f "$theBookDir/${classes[$i1]}.tex" ] ; then
      touch "$theBookDir/${classes[$i1]}.tex"
    fi
done
#=============  Global variables ===========
declare -A str=()
declare -A cmdhist=()
line_index=0
number_of_periods=$(cat "$RESOURCES/tableau"|grep ^`date '+%a'`|awk '{print NF-1 }')
periods_of_today=$(cat "$RESOURCES/tableau"|grep ^`date '+%a'`|awk '{$1="";print $0 }')
#===========================================

# $1 the line
# $2  a/e
function addline(){
      str[$line_index]='\indent '"$1"
      cmdhist[$line_index]="$2"
      line_index=$((line_index+1))
}

# $1 class
# $2 period
# $3 period num
function headerA(){
    entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')
    local periodNum=$3

    str[$line_index]='\par'
    line_index=$((line_index+1))

    str[$line_index]='\noindent\makebox[\linewidth]{\rule{\paperwidth}{0.4pt}}'
    line_index=$((line_index+1))

    str[$line_index]=' \\'
    line_index=$((line_index+1))

    # %N begin
    str[$line_index]="%%:$entryDATE:$periodNum:begin"
    line_index=$((line_index+1))

    export LC_ALL=ar_MA.utf8
    local line="$(cat "$RESOURCES/dateA") : $(date --date "-$MINUSDAYS days" +'%A %d %B %Y') \\\\"
    export LC_ALL=en_US.utf8

    str[$line_index]="$line"
    line_index=$((line_index+1))

    line="$(cat "$RESOURCES/classA") : $1 \\\\"
    str[$line_index]="$line"

    line_index=$((line_index+1))
    line="$(cat "$RESOURCES/periodA") : $2 \\\\"

    str[$line_index]=" \\  "
    line_index=$((line_index+1))

    str[$line_index]="$line"
    line_index=$((line_index+1))

}

# $1 name of holyday
# $2 first day 
# $3 last day
function headerB(){
  entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')

  str[$line_index]='\par'
  line_index=$((line_index+1))

  str[$line_index]='\noindent\makebox[\linewidth]{\rule{\paperwidth}{0.4pt}}'
  line_index=$((line_index+1))

  str[$line_index]=' \\'
  line_index=$((line_index+1))

  # %N begin
  str[$line_index]="%%:$entryDATE:begin"
  line_index=$((line_index+1))

  if [ -z "$3" ] 
      then
          str[$line_index]="$2 : $1"
          line_index=$((line_index+1))
      else
          str[$line_index]="$(cat "$RESOURCES/from") $2 $(cat "$RESOURCES/to") $3"
          line_index=$((line_index+1))
          str[$line_index]='\newline'
          line_index=$((line_index+1))
          str[$line_index]='\indent'
          line_index=$((line_index+1))
          str[$line_index]="$1"
          line_index=$((line_index+1))
  fi
}


# $1 debug
function printLines(){
  echo 
  #printf "\033[1;5;31m"	
  #echo "$(cat "$RESOURCES/period-num")$entryDATE   "
  #printf "\033[0m"	
  for ((k2=3;k2<$line_index;k2++)) ; do
    if (($k2>7)) && [[ "$1" == "debug" ]]; then 
      printf "\033[1;30m$k2:\033[0m  "
    fi
    echo ${str[$k2]}
  done
}

#  $1 index for str[]
function editAline(){
      local index="$1"
      echo "${str[$index]}" >| "$tmpfile"
      if [[ ${cmdhist[$index]} == a ]] 
          then 
              gedit "$tmpfile" && \
              local line=$(cat "$tmpfile" ) \
              && str[$index]="$line"
          else
              vim "$tmpfile"
              local line=$(cat "$tmpfile" )
              str[$index]="$line"
      fi
}

# $1 period number 
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
      for ((k3=0;k3<$line_index;k3++)) ; do
          echo "${str[$k3]}" >> "$theBookDir/$class.tex"
      done
      entryDATE=$(date --date "-$MINUSDAYS days" +'%d-%m-%Y')
      echo "%%:$entryDATE:$periodNum:end" >> "$theBookDir/$class.tex"
      local lnumber=$( awk -v v="$var:unsaved" 'match($0,v){print NR}' "$LOGFILE" )
      if [[  "$lnumber" != "" ]] ; then
        sed   --in-place -e "${lnumber} s/.*/$var:saved/" "$LOGFILE"
      fi
      str=()
      cmdhist=()
      line_index=0
}

function showMenu(){
  local mm=$(printf '  %s\n' "$1"|sed 's/(/\\033\[1;32m(/g'|sed 's/)/)\\033\[0m/g')
  printf "$mm"
  echo
}

#  $1 period number or "" for ext-period
#  $2 y for automatic save
function editing(){
    local periodNum=$1
    while true ; do
        tput reset
        if [[ "$2" != "y" ]] 
            then  printLines debug
                  echo
            else
                  echo
                  echo -ne "\t saving... $entryDATE"\\r 
        fi
        if [[ "$2" != "y" ]] 
            then
                printf "\033[1;33m"
                menu11="(a)arabic text (e)equation/latin text (n)newline (f)insert pdf  "
                menu12="(1-9)edit (h)edit header (s)save (p)print (x) exit "
                menu21="(aa)arabic text (ee)equation/text (nn)newline (ff)insert pdf"
                menu22="(10-19)edit (ss)save (pp)print (xx) exit "
                if (( $line_index <= 10 )) 
                    then 
                          echo "=============================================================="
                          showMenu "$menu11" 
                          showMenu "$menu12" 
                          echo "=============================================================="
                          echo
                          IFS= read -rN 1 -p " : " choice
                    else 
                          echo "=============================================================="
                          showMenu "$menu21" 
                          showMenu "$menu22" 
                          echo "=============================================================="
                          echo
                          IFS= read -rN 2 -p " : " choice
                fi
                printf "\033[0m\n"
            else choice=s
        fi
        case "$choice" in
              a|aa)  gedit "$tmpfile" && local line=$(cat "$tmpfile" ) && addline "$line" a ;;
              e|ee)  vim "$tmpfile"
                  local line=$(cat "$tmpfile" )
                  addline "$line \\  \\" e ;;
              [6-9]) editAline "$choice" ;;
              1[0-9]) editAline "$choice" ;;
              n|nn) addline '\newline' e ;;
              f|ff) 
                file1="$(find "$HOME" -type f -iname "*.pdf" 2>/dev/null |fzf)"
                cp "$file1" "$theBookDir/pdf-`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`.pdf"
                addline "\\includepdf[pages={1}]{pdf-`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`.pdf}" e ;;
              s|ss) SaveTheFile "$periodNum"  ; break ;;
              p|pp) makeIT ;;
              x|xx) exit ;;
        esac
    done
}

# $1 status
# $2 y for automatic saving
function allsaved1(){
  if [[ "$1" == "status" ]] ; then exit ; fi
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
  local periods_of_today=$(cat "$RESOURCES/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{$1="";print $0 }')
  while read -u 3 -r line ; do
      if `echo "$line" |grep unsaved >/dev/null ` ; then
            local periodNum=$(echo "$line" | awk -F: '{print $3}'|tr -dc '0-9' )
            local class=$(echo "$periods_of_today" | awk -v var="$periodNum" '{print $var}')
            if [[ "$1" == "status" ]] ; then
                  printf "\033[1;31m"
                  echo "${class%=*} at `echo ${class#*=} |sed 's/-/ - /'` unsaved"
                  printf "\033[0m"
            fi
            msg="${class%=*} ** `echo ${class#*=} |sed 's/-/ - /'`"
            if [[ "$2" != "y" ]]
                then
                    if [[ "$1" != "status" ]] ; then
                        IFS= read -rN 1 -p "Save entry for $msg (Y/n)?" answer
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
    str=()
    cmdhist=()
    line_index=0
    local today=`date --date "-$MINUSDAYS days" +'%d-%m-%Y'`
    today_is_a_breakday=0
    if `grep "$today" "$RESOURCES/breakdays" >/dev/null` ; then
        today_is_a_breakday=1
        if `grep "$today:saved" "$LOGFILE" >/dev/null` ; then
             return
        fi
        local name=$(grep "$today" "$RESOURCES/breakdays"|awk -F: '{print $2}')
        local today=$(grep "$today" "$RESOURCES/breakdays"|awk -F: '{print $1}')
        if `echo "$today" |grep '\*' >/dev/null` 
            then
                local nbrDays=$(echo $today |cut -d* -f2)
                local cleaned="$(echo $today |cut -d* -f1)"
                echo
                question="$(cat "$RESOURCES/Q-is") $( convertAndGetDate "$cleaned" 0 ) "
                question+="$(cat "$RESOURCES/is") $name  $(cat "$RESOURCES/Q-mark") "
                echo "$question"
                echo 
                IFS= read -rN 1 -p " : " choice
                echo 
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
                local firstOne=$(grep "$name" "$RESOURCES/breakdays"|awk -F: '{print $1}'|head -1)
                local FIRSTONE="$( convertAndGetDate "$firstOne" 0 )"
                local lastOne=$(grep "$name" "$RESOURCES/breakdays"|awk -F: '{print $1}'|tail -1)
                local LASTONE="$( convertAndGetDate "$lastOne" 0 )"
        fi
        if [[ "$FIRSTONE" != "$LASTONE" ]] 
            then 
                  headerB  "$name" "$FIRSTONE" "$LASTONE"
                  local allOfThem=$(grep "$name" "$RESOURCES/breakdays"|awk -F: '{print $1}')
                  while read -r line ; do
                        echo $line:saved:$name >> "$LOGFILE"
                  done <<< "$allOfThem"
            else  headerB  "$name" "$FIRSTONE"
        fi
        data="$(cat "$RESOURCES/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
        IFS=$'\r\n' classes=($(echo "$data"))
        for (( i1 = 0 ; i1 < ${#classes[@]} ; i1 ++)) ; do
              for (( j1=0;j1<$line_index;j1++)) ; do
                  echo "${str[$j1]}" >> "$theBookDir/${classes[$i1]}.tex"
              done
        done
        str=()
        cmdhist=()
        line_index=0
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
    local number_of_periods=$(cat "$RESOURCES/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{print NF-1 }')
    local periods_of_today=$(cat "$RESOURCES/tableau"|grep ^`date --date "-$MINUSDAYS days" +'%a'`|awk '{$1="";print $0 }')
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
            echo "$text2"
            echo
            menu="(a)arabic text (e)equation/text (f)insert pdf (x) save & exit"
            echo "=============================================================="
            showMenu "$menu" 
            echo "=============================================================="
            echo
            IFS= read -rN 1 -p " : " choice
            echo
            case "$choice" in
                  a)   echo "$text2" >| "$tmpfile"
                       gedit "$tmpfile" && text2=$(cat "$tmpfile" ) ;;
                  e)   echo "$text2" >| "$tmpfile"
                       vim "$tmpfile"
                       text2=$(cat "$tmpfile" ) ;;
                  f) 
                       file1="$(find "$HOME" -type f -iname "*.pdf" 2>/dev/null |fzf)"
                       cp "$file1" "$theBookDir/pdf-$EditedEntryDATE.pdf"
                       text2+="$text2 \\\\"$'\n'"\\includepdf[pages={1}]{pdf-$EditedEntryDATE.pdf}"
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
      if [ -z "$theBookDir/$theBook" ] ; then 
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
}

# $1 v for verbose
function makeIT(){
    cat "$theBookDir/header" >| "$theBookDir/product.tex"
    data="$(cat "$RESOURCES/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
    IFS=$'\r\n' classes=($(echo "$data"))
    for (( i1 = 0 ; i1 < ${#classes[@]} ; i1 ++)) ; do
        cat "$theBookDir/classeheader" |sed "s/insertClassHere/${classes[$i1]}/" >> "$theBookDir/product.tex"
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
  data="$(cat "$RESOURCES/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
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
  if [ -z "$lastSavedDay" ] 
      then lastSavedDay='2018-09-04'
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
              if [[ "$1" == "status" ]] ; then
                  exit
              fi
      fi
  done
}

function openIT(){
    data="$(cat "$RESOURCES/tableau"|awk '{$1=""; for(i=2;i<=NF;i++)printf("%s\n",$i);}'|cut -d= -f1|sort|uniq)"
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
  if (( `date '+%m'` >= 9 )) 
      then  local backupDir="$workingDir/backup/$year-$((year+1))"
      else  local backupDir="$workingDir/backup/$((year-1))-$year"
  fi
  if ! [ -d "$backupDir" ] ; then
      mkdir -p "$backupDir"
  fi
  rsync -aq "$RESOURCES" "$backupDir" --exclude backup
  rsync -aq "$theBookDir" "$backupDir" --exclude backup
}

function _printhelp () {
  printf '\033[1;33m  %-22s\t\033[1;37m%s\n' "$1" "$2"
}

function SYear(){
  local year="$(date '+%Y')"
  if (( `date '+%m'` >= 9 )) 
        then  echo "$year-$((year+1))"
        else  echo "$((year-1))-$year"
  fi
}

function printhelp () {
  _printhelp  "" "$(cat "$RESOURCES/h-save" )"
  _printhelp  "h,H,help" "$(cat "$RESOURCES/h-help" )"
  _printhelp  "a,A,add" "$(cat "$RESOURCES/h-add" )"
  _printhelp  "e,E,edit [d-m-Y] [#N]" "$(cat "$RESOURCES/h-edit" )"
  _printhelp  "p,P,print" "$(cat "$RESOURCES/h-print" )"
  _printhelp  "s,S,status" "$(cat "$RESOURCES/h-status" )"
  _printhelp  "o,O,open" "$(cat "$RESOURCES/h-open" )"
  _printhelp  "oo" "$(cat "$RESOURCES/h-oopen" )"
  _printhelp  "b,B,backup" "$(cat "$RESOURCES/h-backup" ) $( SYear ) "
}

#save entries for all unsaved days before today
#abscence/pc not powered up/...
checkIfAllsaved "$1"

case "$1" in 
             "")    savePeriods ;;
       edit|e|E)    editEntry $2 $3 ;;
        add|a|A)    addPeriod ;;
      print|p|P)    makeIT $2 ;;
     status|s|S)    savePeriods "status" ;;
       open|o|O)    openIT ;;
             oo)    gedit  "$theBookDir/product.tex" & ;;
       view|v|V)    okular "$theBookDir/product.pdf" 2>&1 2>/dev/null & ;;
       help|h|H)    printhelp ;;
     backup|b|B)    backUP ;;
esac




