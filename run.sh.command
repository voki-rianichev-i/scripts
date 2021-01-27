#!/usr/bin/env bash
is_build_project=false
make_pull=false
run_cmake=true
execute=true
binary_name=""
scheme_name=""
pull_branch=""

check_update(){
    if [[ $(git -C $(dirname $0) rev-parse HEAD) != $(git -C $(dirname $0) rev-parse @{u}) ]]
    then
        printf "\e[1;32m\nNew version of script is available,you can update it by running:\n\ngit -C $(dirname $0) pull\n\n\e[0m"
    fi
}
print_help(){
    echo -e "\nUsage: ./run.sh.command [options] <path_to_dir>
    Options:
    -h, --help\t\t: Print this manual
    -b, --build\t\t: Run cmake/mac.sh.command and build project with XCode
    -p, --pull\t\t: Pull current repo branch and update submodules
    --no-cmake\t\t: Don't run CMake before building
    --no-exec\t\t: Don't execute binary
    \nExample: './run.sh.command -b -p ./repos/MM'\n
    This will pull curent branch of './repos/MM' , update submodules,
    run 'cmake/mac.sh.command',build project with XCode and execute the binary.\n"
    check_update
}

identify_project(){
    project_origin=$(git --git-dir=$PROJECT_DIR/.git remote get-url origin)
    if [[ $project_origin == *"mystery-garden"* ]]
    then
        binary_name="MysteryGarden-Dev"
        scheme_name="MysteryGarden-Dev"
    elif [[ $project_origin == *"manor-matters"* ]]
    then
        binary_name="ManorMatters-Dev"
        scheme_name="Mansion-Dev"
    else
        echo "'$PROJECT_DIR' doesn't contain Manor-Matters or Mystery-Garden project\n"
        exit
    fi
}

pull_repo(){
    cd $PROJECT_DIR
    pull_branch=$(git branch --show-current)
    echo -e "Pulling origin '$pull_branch' ...\n"
    git pull origin "$pull_branch";
    if [[ $? -eq 0 ]]
    then
        echo -e "\nBranch '$pull_branch' pulled succesfully\n"
        echo "Updating submodules"
        git submodule update --init --recursive;
        if [ $? -eq 0 ]
        then
            echo -e "\nSubmodules succesfully updated\n"
        else
            echo -e "\nUpdating submodules failed\n" 
            exit   
        fi
    else
        echo -e "\nPull '$pull_branch' failed\n"
        exit
    fi

}

build_project(){
    if $run_cmake
    then
        bash $PROJECT_DIR/cmake/mac.sh.command
    fi

    if [ $? -eq 0 ]
    then
        build_dir="$PROJECT_DIR/build/mac"
        if [ -d $build_dir ]
        then
            cd $build_dir
            xcodebuild -showBuildTimingSummary -jobs $(sysctl -n hw.ncpu) -scheme $scheme_name build
            if ! [ $? -eq 0 ]
            then
                echo -e "\nBuild failed\n"
                exit
            fi
        else
            echo -e "Build directory '$build_dir' doesn't exist"
            exit
        fi
    else
        echo -e "\nCMake error\n"
        exit
    fi
}

execute_binary(){
    echo "Looking for binary..."
    binary_path=$(find $PROJECT_DIR -path "*/Contents/MacOS/$binary_name")
    if [ $? -eq 0 ] && ! [ -z "$binary_path" ]
    then 
        Echo "Binary found"
        run_command="$binary_path --baseDir=$PROJECT_DIR --resolution iPad"
        echo -e "\n\nRunning '$run_command'\n\n"
        $run_command
    else
        echo -e "Binary '$binary_name' doesn't exist"
    fi
}

# START
if [ $# -eq 0 ]
then
    echo "No arguments provided"
    exit
fi

for arg in "$@"
do
    case $arg in
        --help|-h)
            print_help
            exit
            ;;
        --build|-b)
            echo BUILD
            is_build_project=true
            ;;
        --pull|-p)
            echo PULL
            make_pull=true
            ;;
        --no-cmake)
            echo NO_CMAKE
            run_cmake=false
            ;;
        --no-exec)
            echo NO_EXECUTION
            execute=false
            ;;
        *)
            if ! [ -d $arg ]
            then
                echo "Invalid argument: '$arg'"
                exit
            else
                cd $arg
                PROJECT_DIR=$(pwd)
                echo "Directory '$PROJECT_DIR'"
            fi
            ;;
    esac

done

identify_project

if $make_pull
then
    pull_repo
fi

if $is_build_project
then
    start=`date +%s`
    build_project
    end=`date +%s`
    printf "\e[1;32m\nBuild took $(( ($end - $start) / 60 ))  minutes.\n\e[0m"
fi

if $execute
then
    execute_binary
fi

check_update
