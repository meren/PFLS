# set some initial directories
raw_data_target="/Users/meren/Downloads/PFLS-DATA-PACKAGE/EXC-004/RAW-DATA"
raw_data_source="/Users/meren/Downloads/EXC-004-RAW-DATA"
exc_004_path="/Users/meren/Downloads/PFLS-DATA-PACKAGE/EXC-004"
repositories_path="/Users/meren/Downloads/PFLS-DATA-PACKAGE/REPOSITORIES"
output_dir="$exc_004_path/COMBINED-DATA"

for username in $(cat github-usernames.txt)
do
    echo -e "\n⚙️ Working on \033[4m$username\033[0m:"

    if [ -e "$repositories_path/$username/PFLS" ]
    then
        echo -e "   >>> Updating the local repository ..."
        cd $repositories_path/$username/PFLS
        git pull > /dev/null 2>&1
    else
        repo_url="https://github.com/$username/PFLS.git"
        echo -e "   >>> Cloning a copy of $repo_url ..."
        mkdir -p $repositories_path/$username
        cd $repositories_path/$username
        git clone $repo_url > /dev/null 2>&1
    fi

    cd $exc_004_path
    rm -rf $raw_data_target

    cp -r $raw_data_source $raw_data_target

    script_file="$repositories_path/$username/PFLS/EXC-004/generate-combined-data.sh"

    # check submission
    echo -e "   >>> Making sure the EXC-004/generate-combined-data.sh is in place ..."
    if [ ! -e $script_file ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: The generate-combined-data.sh is not there 😞"
        continue
    else
        echo -e "   >>> The script is at \"$script_file\" ..."
    fi

    rm -rf $output_dir

    echo -n "   >>> Running generate-combined-data.sh ... "
    bash $script_file > /dev/null 2>&1
    echo " Done 🎉 Testing output now."

    if [ ! -e $output_dir ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: The generate-combined-data.sh failed to generate the output dir 😞"
        continue
    fi

    num_files=$(ls $output_dir | wc -l)

    if [ ! $num_files -eq "194" ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: The total number of files in the output directory is not correct 😞"
        continue
    fi

    if [ ! -e "$output_dir/CO64-GTDB-TAX.txt" ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: One of the files ('CO64-GTDB-TAX.txt') is missing 😞"
        continue
    fi

    if [ ! -e "$output_dir/CO64_MAG_001.fa" ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: One of the output files ('CO64_MAG_001.fa') is missing 😞"
        continue
    fi

    culture_updated_defline=$(head -n 1 $output_dir/CO64_MAG_001.fa | grep CO64)
    if [ -z "$culture_updated_defline" ]
    then
        echo -e "   >>> ❌ \033[4m$username\033[0m: The FASTA deflines are not asssociated with the culture 😞"
        continue
    fi


    echo -e "   >>> ✅ \033[4m$username\033[0m: The output is correct! 😊"
done


