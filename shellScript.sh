#------------------------------
# all required variables
#------------------------------
EXECUTABLE_NAME="memleakFinder"
TRUE=1
FALSE=0
OUTPUT_FILE_SUFFIX="_mem_leaks"
TEMP_FILE=./memleak.temp
TEMP_PID=./memleak.pid
VALGRIND_LOG_FILE=./vlog_bkp

#-----------------------------------
# usage function implementation
#-----------------------------------
function usage() {
        echo -e "
USAGE:
\t\033[1;34m$EXECUTABLE_NAME\033[0m  \033[1;36m-f valgrind_log_file  -s search_strings  [-h]\033[0m
\n\t\t\033[1;36m -f : provide the full path of the valgrind log file which need to be parsed to find the memory leaks
\t\t -s : provide set of search strings in a comma seperated format. i.e. \"search_string1,search_string2,..\"
\t\t -h : help \033[0m\n"
        exit 1
}

#--------------------------------
# parsing command-line arguments
#--------------------------------
while getopts f:s:h option
do
    case "${option}" in
        f) VALGRIND_LOG_FILE_UNTOUCH=${OPTARG};;
        s) search_strings=${OPTARG};;
        h) usage ;;
    esac
done

#------------------------------------
# validating command-line arguments
#------------------------------------
echo -e "\nDEBUG :: validating the command-line arguments"
if [[ -z $VALGRIND_LOG_FILE_UNTOUCH ]]
then
        echo -e "ERROR :: -f option is manditory"
        usage
elif [[ -z $search_strings ]]
then
        echo -e "ERROR :: -s option is manditory"
        usage
fi

if [[ ! -r $VALGRIND_LOG_FILE_UNTOUCH ]]
then
        echo -e "ERROR :: input valgrind log i.e \"$VALGRIND_LOG_FILE\" provided is not present"
        exit 1
fi

#-----------------------------------------------------------
# processing the valgrind log file for finding memory leaks
#-----------------------------------------------------------
echo -e "DEBUG :: input valgrind logfile: \"$VALGRIND_LOG_FILE_UNTOUCH\""
echo -e "DEBUG :: the following are the search strings provided"
search_str_count=0
for search_string in $(echo $search_strings | sed "s/,/ /g")
do
        (( search_str_count ++ ))
        echo -e "\t\t$search_str_count) $search_string"
done

echo -e "DEBUG :: processing the valgrind log file for finding memory leaks"
OUTPUT_FILE=$VALGRIND_LOG_FILE_UNTOUCH$OUTPUT_FILE_SUFFIX
echo " " > $OUTPUT_FILE
grep '==.*== $' $VALGRIND_LOG_FILE_UNTOUCH | sort | uniq | cut -d '=' -f3 > $TEMP_PID
total_pid_count=`wc -l $TEMP_PID | cut -d' ' -f1`
processed_pid_count=0
cat $TEMP_PID | while read pid
do
        (( processed_pid_count ++ ))
        echo -e "DEBUG :: [$processed_pid_count/$total_pid_count] processing the valgrind logs for PID-$pid"
        grep "$pid" $VALGRIND_LOG_FILE_UNTOUCH > $VALGRIND_LOG_FILE
        total_lines=$(wc -l $VALGRIND_LOG_FILE | cut -d ' ' -f1)
        line_no=0

        while read line
        do
                #echo $line
                if [[ "$line" == *"bytes in"* && "$line" == *"definitely lost in"* ]]
                then
                        echo $line > $TEMP_FILE
                        found_start=1
                elif [[ $found_start == 1 ]]
                then
                        echo $line >> $TEMP_FILE

                        IFS=',' read -r -a array <<< "$search_strings"
                        for search_string in "${array[@]}"
                        do
                                if [[ "$line" == *"${search_string}"* ]]
                                then
                                        found_search_str=1
                                fi
                        done
                        if [[ "$line" == "=="*"==" ]]
                        then
                                if [[ $found_search_str == 1 ]]
                                then
                                        cat $TEMP_FILE >> $OUTPUT_FILE
                                fi
                                found_start=0
                                found_search_str=0
                        fi
                fi
                (( line_no ++ ))

        done < $VALGRIND_LOG_FILE
done

echo -e "\n\n\033[1;34mmemory leak file:\033[0m \033[1;36m$OUTPUT_FILE\033[0m \n"

#---------
# CleanUp
#---------
if [[ -f $TEMP_FILE ]]
then
        rm $TEMP_FILE
fi

if [[ -f $TEMP_PID ]]
then
        rm $TEMP_PID
fi

if [[ -f $VALGRIND_LOG_FILE ]]
then
        rm $VALGRIND_LOG_FILE
fi