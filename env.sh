#!/bin/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure Java project environment with environment variables, project files
# and functions supporting the project build process:
# \\
# Environment variables:
#  - CLASSPATH, MODULEPATH      ; used by Java compiler and JVM
#  - JDK_JAVAC_OPTIONS          ; flags for the Java compiler
#  - JDK_JAVADOC_OPTIONS        ; flags for the Javadoc compiler
#  - JAR_PACKAGE_LIBS           ; libraries to package with jar-file
#  - JUNIT_CLASSPATH            ; CLASSPATH used by the JUnit test runner
#  - JUNIT_OPTIONS              ; flags for the JUnit test runner
#  - JACOCO_AGENT_OPTIONS       ; JVM jacoco agent options (code coverage)
# \\
# Project files created for VSCode and eclipse IDE, 'libs' link:
#  - libs -> <path-to-libs>     ; link created to 'libs' directory
#  - .classpath, .project       ; used to set up the VSCode Java extension
#  - .vscode/launch-coderunner  ; VS Code Java Code Runner launch file
# 
# Executable functions:
# \\
#  - show cmd [args] cmd [args] ...         ; show commands
# 
#  - mk [--show] cmd [args] cmd [args] ...  ; execute commands
# 
#  - wipe [--all|-a]            ; unset project env variables and functions
#                               ; --all|-a: including project files
# Commands:
#  - build                      ; perform the build process with stages:
#                               ; - clean compile compile-tests run-tests package
#  - clean                      ; remove files created during the build process
#  - compile, compile-tests     ; compile sources, unit tests
#  - run, run-tests             ; run the program, run unit tests
#  - coverage, coverage-report  ; record code coverage, create coverage report
#  - package|jar [--package-libs|--fat-jar] ; package compiled code into .jar
#  - run-jar                    ; run the packaged .jar
#  - javadoc|javadocs|docs|doc  ; create Javadoc
#  - delombok                   ; delombok 'src/main' to 'target/delombok'
# 
# Usage:
#  - source env.sh [-v] [-e]    ; -v verbose show discovered assets
#                               ; -e show values of environment variables
#  - mk --version               ; show version
#  - mk --help                  ; show help
# 
# Tests:
#  - mk build; cat target/resources/META-INF/MANIFEST.MF; mk package --package-libs
#  - mk run run-jar run; mk javadoc coverage coverage-report run
#  - cat target/resources/META-INF/MANIFEST.MF; ls -la target; mk run run-jar
# 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Revision information:
# @version: 1.4.0
# @author: sgraupner
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ISSUES:
# - (#001) 'realpath' is not available on Mac -> install 'brew' and 'coreutils'
#   see: https://formulae.brew.sh/formula/coreutils.
# 
# - (#002) 'realpath' does not support flag '--relative-to' on Mac -> absorbed
#   flag in realpath_ function, alternatively remove use of flag.
# 
# - (#003) lombok does not work with 'com.fasterxml.jackson' modules, remove
#   dependency from 'module-info.java' for 'mk delombok', must also delete all
#   'com.fasterxml.jackson' imports, e.g. from 'ContactsSplitterImpl.java'.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Disables zsh to output ANSI escape characters in sub-processes: $(find ...)
# and disable 'no matches found:' message with 'setopt no_match' in zsh.
[ "$(type setopt 2>/dev/null)" ] && is_zsh=true && setopt no_nomatch

declare -gA P=(
    # general assets
    [version]="1.4.0"           # version number
    [pdir]="."                  # relative path to project directory
    [src]="src/main"            # Java source code, probed for existence
    [tests]="src/tests"         # Java unit tests, probed for existence
    [res]="src/resources"       # none-Java sources, config files etc., probed for existence
    [manifest]="META-INF/MANIFEST.MF"
    [libs]="libs"               # located and created, if not exists
    [libs-search]=".. ../.. ../../.. branches ../branches"
    [module]=""                 # module name from 'module-info.java'
    [module-info]="src/main/module-info.java"
    [module-path]=""            # modules found in 'libs'
    [main]="application.Application"    # default main class to run
    # 
    # defined assets
    [target]="target"           # compiled, copied and generated code
    [target-cls]="target/classes"           # compiled code (.class-files)
    [target-tests]="target/test-classes"    # compiled test classes
    [target-res]="target/resources"         # none-Java source assets copied from P[res]
    [target-jar]="target/application-1.0.0-SNAPSHOT.jar"    # packaged application as fat .jar
    # 
    [logs]="logs"               # directory to store log files
    [delombok]="target/delombok"            # target for code de-lomboked from 'src/main'
    [docs]="target/javadoc"     # directory the javadoc compiler stores javadocs
    [cov]="target/coverage"                 # directory for jacoco.agent to store coverage files
    [cov-file]="target/coverage/jacoco.exec"    # file created by the jacoco.agent
    [cov-report]="target/coverage-report"       # output directory for coverage report (HTML)
    # 
    # discovered assets
    [libs-rp]=""                # libs relative real path (traced links)
    [libs-rpup]=""              # libs relative real path one level up (trimmed '/libs')
    [libs-abs]=""               # libs absolute path
    [cov-agent]=""              # jacoco code coverage agent, e.g. 'libs/jacoco/jacocoagent.jar'
    [cov-report-gen]=""         # jacoco report generator, e.g. 'libs/jacoco/jacococli.jar'
    [jars]=""                   # .jar files found in libs, used by CLASSPATH
    [junit-jars]=""             # .jar files from libs for JUnit testing, used by JUNIT_CLASSPATH
    [junit-runner]=""           # .jar file found in libs for the JUnit test runner
    [lombok-jar]=""             # .jar for lombok code injection, e.g. 'libs/lombok/lombok-1.18.38.jar'
    # 
    [script]="${BASH_SOURCE[0]}"    # name of this script file
    [is-zsh]="$is_zsh"          # empty if executing shell is not zsh
    [is-win]=$([[ "$(uname)" =~ (CYGWIN|MINGW) ]] && echo true)
    [sep]=":"                   # seperator used in CLASSPATH, MODULEPATH
    [ra-opt]="-ra"              # zsh: read -rA arr <<< $str vs. -ra (bash)
    [has-realpath]=$(type realpath 1>/dev/null 2>/dev/null; [ $? -eq 0 ] && echo true)
    [has-cygpath]=$(type cygpath 1>/dev/null 2>/dev/null; [ $? -eq 0 ] && echo true)
)
if [ "$is_zsh" ]; then
    P[script]="./${(%):-%x}"    # obtain name of this script and overwrite P[script]
    P[script-path]="${${P[script]}%/*}"
    P[ra-opt]="-rA"
else
    script_=${P[script]}
    P[script-path]="${script_%/*}"
fi
# 
# return codes from functions
RC_HELP_MSG=100                 # parse_args found -h, --help flag to print help message
RC_NOTHING_CREATED=200          # configure_env found that nothing was created
# 
# arrays to log created assets
created_vars=(); created_files=(); created_funcs=()


function discover_env() {
    [ "${P[is-win]}" ] && P[sep]=';'
    # 
    # [ $(is_project_directory $p) ] && \
    #     echo "must run in project directory" && \
    #     return 1
    # 
    for p in ${P[script-path]} ${P[script-path]}/.. ; do
        [ $(is_project_directory $p) ] && P[pdir]="$(realpath_ --relative-to=. $p)" && break
    done
    # 
    # define offset path 'pd' if script runs from other than project folder
    [ "${P[pdir]}" = "." ] && P[pdir]="" || local pd="${P[pdir]}/"
    # 
    # locate 'libs' directory and attempt to link into project directory
    if [ ! -e "$pd${P[libs]}" ]; then
        local libs_path=$(locate_libs)
        if [ "$libs_path" ]; then
            # MinGW (GitBash) requires MSYS setting for symlinks
            # https://www.joshkel.com/2018/01/18/symlinks-in-windows/
            [ "${P[is-win]}" ] && export MSYS="winsymlinks:nativestrict"
            # 
            ln -s "$libs_path" "$pd${P[libs]}"
            created_files+=("ln -s $libs_path $pd${P[libs]}")
        fi
    fi
    # 
    local main="${P[main]}"
    main=${main//./\//}".java"       # replace '.' with '/' in main class
    # 
    [ ! -d "$pd${P[src]}" ] && P[src]=""
    [ ! -f "$pd${P[src]}/$main" ] && P[main]=""
    [ ! -d "$pd${P[tests]}" ] && P[tests]=""
    [ ! -d "$pd${P[res]}" ] && P[res]="" && P[target-res]=""
    [ ! -f "$pd${P[res]}/${P[manifest]}" ] && P[manifest]=""
    # 
    # parse module name from file 'module-info.java'
    [ -f "$pd${P[module-info]}" ] && \
        P[module]=$(parse_module_name $pd${P[module-info]}) || P[module-info]=""
    # 
    if [ -d "$pd${P[libs]}" ]; then
        # 
        # determine absolute path to 'libs' tracing links
        [ "${P[is-win]}" ] && P[libs-abs]=$(cygpath_ -wa "$pd${P[libs]}") || P[libs-abs]=$(realpath_ "$pd${P[libs]}")
        # 
        # determine relative path to 'libs' tracing links
        [ "$pd" ] && local locd="$pd" || local locd="."
        P[libs-rp]=$(realpath_ --relative-to="$locd" "$pd${P[libs]}")
        # 
        # determine relative path to 'libs' one level up ('/libs' removed)
        # rlibs=${rlibs%libs}; rlibs=${rlibs%/}   # remove trailing 'libs' and then '/' (two steps for 'libs')
        # [ -z "$rlibs" ] && rlibs="."
        local libs_up=$(dirname "${P[libs-rp]}")
        P[libs-rpup]="$libs_up"
        # 
        local sep1=""; local sep2=""; local sep3=""
        [ "${P[module]}" ] && P[module-path]="${P[target-cls]}"; local has_mod=""
        # 
        P[pckg-libs]=""
        IFS=$'\n' dirs=($([ "$pd" ] && builtin cd "$pd"; find "${P[libs-rp]}" -type d -not -path "*.git*"))
        for dir in "${dirs[@]}"; do
            jars=($(ls $dir/*.jar 2>/dev/null))
            for jar in "${jars[@]}"; do
                case "$jar" in
                */junit-platform-console-standalone*.jar) P[junit-runner]="$jar"; local addjunitjar="true" ;;
                */jacocoagent*.jar) [ "${P[tests]}" ] && P[cov-agent]="$jar"; local addjunitjar="true" ;;
                */jacococli*.jar) P[cov-report-gen]="$jar"; local addjunitjar="true" ;;
                */lombok*.jar) P[lombok-jar]="$jar"; local addjar="true" ;;
                */junit/junit-jupiter-api*) local addjar2="true" ;;
                */junit/*) ;;
                */jacoco/*) local addjunitjar="true"; has_mod="true" ;;
                *) local addjar="true" ;;
                esac
                # 
                # ${jar:${#libs_up}+1}
                if [ "$addjar" -o "$addjar2" ]; then
                    P[jars]+="$sep1$jar" && sep1="${P[sep]}" && has_mod="true"
                    if [ "$libs_up" = "." ]; then 
                        P[pckg-libs]+="$sep3-C $libs_up $jar" && sep3=" "
                    else
                        P[pckg-libs]+="$sep3-C $libs_up ${jar:${#libs_up}+1}" && sep3=" "
                    fi
                fi
                # 
                [ "$addjar" -o "$addjunitjar" ] &&
                    P[junit-jars]+="$sep2$jar" && sep2="${P[sep]}"
                # 
                addjar=""; addjar2=""; addjunitjar=""
            done
            # 
            [ "${P[module]}" -a "$has_mod" ] && P[module-path]+="${P[sep]}$dir"; has_mod=""
            # 
        done; unset IFS
        # 
    else
        echo "cannot find \"${P[libs]}\" directory"
    fi
    return 0
}

function configure_env() {
    [ "${P[pdir]}" ] && local pd="${P[pdir]}/"
    local sep="${P[sep]}"
    # 
    if [ -z "$CLASSPATH" ]; then
        local cp="${P[target-cls]}"
        # iterate over ${P[sep]}-separated string that works for bash and zsh
        IFS='|'; for jar in ${P[target-res]} $(tr "${P[sep]}" '|' <<< ${P[jars]}); do
            cp+="$sep$jar"
        done; unset IFS
        export CLASSPATH="$cp"; created_vars+=(CLASSPATH)
    fi
    if [ -z "$MODULEPATH" -a "${P[module-path]}" ]; then
        export MODULEPATH="${P[module-path]}"; created_vars+=(MODULEPATH)
    fi
    if [ -z "$JDK_JAVAC_OPTIONS" ]; then
        # set '-Xlint:-options' to suppress message "Annotation processing is enabled"
        local javac_opts="-Xlint:-options"
        # 
        [ "${P[module]}" ] && javac_opts+=" -Xlint:-module --module-path \"$MODULEPATH\""
        # 
        export JDK_JAVAC_OPTIONS="$javac_opts"; created_vars+=(JDK_JAVAC_OPTIONS)
    fi
    if [ -z "$JDK_JAVADOC_OPTIONS" ]; then
        local javadoc_opts=""
        [ "${P[module]}" ] && javadoc_opts="--module-path \"\$MODULEPATH\" "
        javadoc_opts+="-version -author -Xdoclint:-missing"
        export JDK_JAVADOC_OPTIONS="$javadoc_opts"; created_vars+=(JDK_JAVADOC_OPTIONS)
    fi
    if [ -z "$JAR_PACKAGE_LIBS" -a "${P[pckg-libs]}" ]; then
        # in addition to libs, add files in resources, except the META-INF folder
        if [ "${P[res]}" ]; then
            [ "${P[pckg-libs]}" ] && local sp=" "
            for res in $(find "${P[res]}" -type f -not -path '*/META-INF/*'); do
                res=${res/src\//}   # 'src/resources/...' -> 'resources/...'
                P[pckg-libs]+="$sp-C . $res"; sp=" "
            done
        fi
        export JAR_PACKAGE_LIBS="${P[pckg-libs]}"; created_vars+=(JAR_PACKAGE_LIBS)
    fi
    # remove P[pckg-libs] from output with -v option
    [ "${P[is-zsh]}" ] && P[pckg-libs]="" || unset P[pckg-libs]
    # 
    if [ "${P[tests]}" ]; then
        if [ -z "$JUNIT_CLASSPATH" ]; then
            local cp="${P[target-cls]}"
            # iterate over ${P[sep]}-separated string that works for bash and zsh
            IFS='|'; for jar in ${P[target-tests]} ${P[target-res]} $(tr "${P[sep]}" '|' <<< ${P[junit-jars]}); do
                cp+="$sep$jar"
            done; unset IFS
            export JUNIT_CLASSPATH="$cp"; created_vars+=(JUNIT_CLASSPATH)
        fi
        [ -z "$JUNIT_OPTIONS" ] && \
            export JUNIT_OPTIONS="--details-theme=unicode" && created_vars+=(JUNIT_OPTIONS)
    fi
    if [ "${P[cov-agent]}" -a -z "$JACOCO_AGENT_OPTIONS" ]; then
        local jacopts="-javaagent:${P[cov-agent]}=output=file,destfile=${P[cov-file]}"
        export JACOCO_AGENT_OPTIONS="$jacopts" && created_vars+=(JACOCO_AGENT_OPTIONS)
    fi
    # 
    if [ ! -f "$pd.classpath" ]; then
        # 
        local sp="[[:space:]]"
        [ -z "${P[res]}" ]   &&   local del_res="-e /^#$sp---$sp.classpath.res$/,/^#$sp---$/d"
        [ -z "${P[tests]}" ] && local del_tests="-e /^#$sp---$sp.classpath.tests$/,/^#$sp---$/d"
        # 
        if [ "${P[module]}" ]; then
            # extract '.classpath-entry.mod' section and replace '<space>' with '*' and '\n' with '%'
            # to preserve structure after flattening in variable cp_entry
            local cp_entry=$(sed -e '1,/^# -- .classpath-entry.mod$/d' -e '/^# --$/,$d' -e 's/ /*/g' -e 's/$/%/' < "${P[script]}")
            local del_jre="-e /^#$sp---$sp.classpath-jre$/,/^#$sp---$/d"         # del no-module section
        else
            local cp_entry=$(sed -e '1,/^# -- .classpath-entry$/d' -e '/^# --$/,$d' -e 's/ /*/g' -e 's/$/%/' < "${P[script]}")
            local del_jre="-e /^#$sp---$sp.classpath-jre.mod$/,/^#$sp---$/d"     # del with-module section
        fi
        cp_entry=${cp_entry//[[:space:]]/}      # squeeze remaining spaces from cp_entry
        (   # extract first section from .classpath template and delete
            # parts that are not present in project (tests, resources)
            sed -e '1,/^# -- .classpath-start$/d' \
                -e '/^# --$/,$d' $del_res $del_tests $del_jre \
                -e '/^# --/d' < "${P[script]}"
            # 
            # extract second part for injecting ${P[jars]} libraries
            local jars=(); IFS="${P[sep]}" read ${P[ra-opt]} jars <<< "${P[jars]}"; unset IFS
            # 
            # iterate over ${P[jars]} and expand '@jar' variable in $cp_entry
            for jar in ${jars[@]}; do
                jar="${P[libs-abs]}/"${jar//*libs\//}  # replace local 'libs'-path with absolute path for .classpath
                # revert '%' for '\n' and '*' for '<space>' substitutions in cp_entry
                echo -n -E ${cp_entry/@jar/$jar} | tr '%*' '\n '
            done
            # extract third part closing .classpath file or use shortcut
            # sed -e '1,/^# -- .classpath-end$/d' -e '/^# --$/,$d' < "${P[script]}"
            echo "</classpath>"     # use (faster) shortcut
        # 
        ) | sed -e 's/^# //' \
                -e 's!@src!'${P[src]}'!g' \
                -e 's!@target!'${P[target]}'!g' \
                -e 's!@classes!'${P[target-cls]}'!g' \
                -e 's!@res-out!'${P[target-res]}'!g' \
                -e 's!@res!'${P[res]}'!g' \
                -e 's!@tests!'${P[tests]}'!g' \
                -e 's!@test-classes!'${P[target-tests]}'!g' \
                > $pd.classpath; created_files+=("$pd.classpath")
    fi
    if [ ! -f "$pd.project" ]; then
        sed -e '1,/^# -- .project$/d' \
            -e '/^# --$/,$d' \
            -e 's/^# //' < "${P[script]}" > $pd.project; created_files+=("$pd.project")
    fi
    if [ -d .vscode -a ! -f $pd.vscode/launch-coderunner ]; then
        # create code runner java @.vscode/launch-coderunner file
        [ -z "${P[module]}" ] &&
            echo -e "-cp \"$CLASSPATH\"\\n    ${P[main]}" > $pd.vscode/launch-coderunner ||
            echo -e "-cp \"$CLASSPATH\"\\n -p \"$MODULEPATH\"\\n -m ${P[module]}/${P[main]}" \
            > $pd.vscode/launch-coderunner
        # 
        created_files+=("$pd.vscode/launch-coderunner")
    fi
    # return 0 if anything was created, otherwise return marker $RC_NOTHING_CREATED
    # to print "project environment has been set up"
    local anything_created="${created_vars[@]}${created_files[@]}${created_funcs[@]}"
    # 
    [ ${#anything_created} -eq 0 ] && return $RC_NOTHING_CREATED || return 0
}

function parse_args() {
    for arg in $@; do
        case $arg in
        -h|-he|-eh|-hv|-vh|-hev|-hve|-ehv|-vhe|-evh|-veh|--help) return $RC_HELP_MSG ;;
        -v|--verbose) local arg_verbose=true ;;
        -e|--environment) local arg_env=true ;;
        -ev|-ve) local arg_verbose=true; local arg_env=true ;;
        --post) local post=true ;;
        esac
    done
    if [ "$post" -a "$arg_verbose" ]; then
        # show array P[] of discovered project
        echo "----------------------------"
        declare -p P | sed -e 's/\[/\n  [/g'
    fi
    if [ "$post" -a "$arg_env" ]; then
        [ "$arg_verbose" ] && echo "----" || echo "----------------------------"
        echo "- CLASSPATH:;$CLASSPATH" | sed -e 's/;/\n  + /g'; echo
        echo "- JUNIT_CLASSPATH:;$JUNIT_CLASSPATH" | sed -e 's/;/\n  + /g'; echo
        echo "- MODULEPATH:;$MODULEPATH" | sed -e 's/;/\n  + /g'; echo
        echo "- JUNIT_OPTIONS: $JUNIT_OPTIONS"; echo
        echo "- JDK_JAVAC_OPTIONS: $JDK_JAVAC_OPTIONS"; echo
        echo "- JDK_JAVADOC_OPTIONS: $JDK_JAVADOC_OPTIONS"; echo
        echo "- JAR_PACKAGE_LIBS: $JAR_PACKAGE_LIBS"
    fi
    [ "$post" ] && [ "$arg_verbose" -o "$arg_env" ] && echo "----------------------------"
    return 0
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Output set of instructions to execute the command passed as argument.
# Usage:
#   command [command] [--coverage] [--package-libs|--fat-jar]
# 
# Commands:
#  - build                      ; perform the build process with stages:
#                               ; - clean compile compile-tests run-tests package
#  - clean                      ; remove files created during the build process
#  - compile, compile-tests     ; compile sources, unit tests
#  - run, run-tests             ; run the program, run unit tests
#  - coverage, coverage-report  ; record code coverage, create coverage reports
#  - package|jar [--package-libs|--fat-jar] ; package compiled code into .jar
#  - run-jar                    ; run the packaged .jar
#  - javadoc|javadocs|docs|doc  ; create Javadoc
# 
# @Return instructions to execute commands
# 
function command() {
    local cmd="$1"; shift; local args=(); local sp=""
    for arg in $@; do
        case "$arg" in
        --coverage) [ "$JACOCO_AGENT_OPTIONS" ] && local cov_opts="$JACOCO_AGENT_OPTIONS" ;;
        --package-libs|--fat-jar) local include_jars="--include-libs" ;;
        *) args+="$sp$arg"; sp=" " ;;
        esac
    done

    case "$cmd" in

    build)
        echo "mk clean compile compile-tests run-tests package"
        ;;

    clean)
        local to_clean=""   # target, logs, docs*, cov* (* part of target)
        [ -d "${P[target]}" ] && to_clean+="${P[target]} "
        [ -d "${P[logs]}" ] && to_clean+="${P[logs]} "
        [ "$to_clean" ] && echo "rm -rf $to_clean" || echo ": nothing to clean"
        ;;

    compile)
        [ -d "${P[res]}" -a ! -f "${P[target-res]}/${P[manifest]}" ] && local addOn=" &&"
        # 
        echo "javac \$(find ${P[src]} -name '*.java') -d ${P[target-cls]}$sp${args[@]}$addOn"
        [ "$addOn" ] && echo "mkdir -p ${P[target-res]} && cp -R ${P[res]} ${P[target-res]}/.."
        ;;

    compile-tests)
        [ -d "${P[tests]}" ] &&
            echo "javac -cp \$JUNIT_CLASSPATH \$(find ${P[tests]} -name '*.java') \\" &&
            echo "  -d ${P[target-tests]} ${args[@]}" ||
            echo "echo no tests present"
        ;;

    run)
        if [ "${P[main]}" ]; then
            [ "${P[module]}" ] &&
                echo "java -p \$MODULEPATH -m \"${P[module]}/${P[main]}\" ${args[@]}" ||
                echo "java \"${P[main]}\" ${args[@]}"
        else
            echo "echo no main class to execute"
        fi ;;

    run-tests)
        if [ -d "${P[tests]}" ]; then
            echo "java -cp \$JUNIT_CLASSPATH \\"
            [ "$cov_opts" ] && echo "  $cov_opts \\"
            echo "  org.junit.platform.console.ConsoleLauncher \$JUNIT_OPTIONS \\"
            # [ ${#args[@]} -gt 0 ] && echo "  ${args[@]}" || echo "  --scan-class-path"
            [ ${#args[@]} -gt 0 ] && echo "  $args" || echo "  --scan-class-path"
            # [ ${#args[@]} -gt 0 ] && echo "  -c application.Application_0_always_pass_Tests" || echo "  --scan-class-path"
        else
            echo "echo no tests present"
        fi ;;

    coverage)
        # coverage agent, see: https://www.jacoco.org/jacoco/trunk/doc/agent.html
        [ -d "${P[cov]}" ] && echo "rm -rf ${P[cov]} &&"
        command run-tests --coverage ${args[@]}
        echo "&& echo coverage events recorded in: ${P[cov-file]}"
        ;;

    coverage-report)
        # coverage report generation, see: https://www.jacoco.org/jacoco/trunk/doc/cli.html
        echo "java -jar ${P[cov-report-gen]} report ${P[cov-file]} \\"
        echo "  --sourcefiles ${P[src]} \\"
        echo "  --classfiles ${P[target-cls]} \\"
        echo "  --html ${P[cov-report]}"    # --csv coverage.cvs, --xml coverage.xml
        echo "&& echo coverage report created in: ${P[cov-report]}/index.html"
        ;;

    package|jar)
        [ "$include_jars" ] && local sp=" "
        local manifest=$(prepare_manifest $include_jars)
        # 
        echo "jar -c -v -f \"${P[target-jar]}\" \\"
        [ "$manifest" ] && echo "  --manifest=$manifest \\"
        echo "  -C ${P[target-cls]} . \$(packaged_content$sp$include_jars) &&"
        echo "  [ -f \${P[target-jar]} ] &&"
        echo "    echo -e \"-->\\\ncreated: ${P[target-jar]}\" ||"
        echo "    echo -e \"-->\\\nno compiled classes or manifest, no .jar created\""
        ;;

    run-jar)
        echo "java -jar \"${P[target-jar]}\" ${args[@]}"
        ;;

    lombok|delombok|de-lombok)
        if [ "${P[lombok-jar]}" -a -d "${P[src]}" ]; then
            echo "rm -rf ${P[delombok]} &&"
            # 
            # [BUG] delombok is not Working with Modules #2829 (2021)
            # https://github.com/projectlombok/lombok/issues/2829
            # FIX: hide 'module-info.java' for 'delombok'
            [ -f "${P[module-info]}" ] &&
                local moduleinfo="${P[module-info]}" &&
                echo "mv $moduleinfo $moduleinfo.BAK &&" &&
            # 
            echo "java -jar ${P[lombok-jar]} delombok \\"
            echo "  ${P[src]} -d ${P[delombok]} --format=pretty --encoding=\"UTF-8\" \\"
            [ "${P[module]}" ] && echo "  --module-path=\"\$MODULEPATH\" \\"
            echo "  --classpath=\"\$CLASSPATH\" 2>&1 | head -30 >/dev/tty;"
            # 
            # restore 'module-info.java' from 'module-info.java.BAK'
            echo "[ -f $moduleinfo.BAK ] &&"
            echo "  mv $moduleinfo.BAK $moduleinfo;"
            # 
            echo "echo \"de-lomboked '"${P[src]}"' to '"${P[delombok]}"'\""
            # 
        else
            echo "echo no .jar: \"libs/lombok/lombok-{version}.jar\" or no \"${P[src]}\" to de-lombok"
        fi
        ;;

    javadoc|javadocs|docs|doc)
        # pick source to javadoc, either 'src/main' or 'target/src-delomboked'
        [ -d "${P[delombok]}" ] && local src="${P[delombok]}" || local src="${P[src]}"
        # 
        if [ -d "$src" ]; then
            # collect packages to javadoc, e.g.: "application datamodel.customer" and set up
            # 'noqualifier' flag, e.g. "java.*:application.*:datamodel.*"
            local p=$(builtin cd $src && find * -type d | tr '/\n' '. ')
            local packages=${p%"${p##*[![:space:]]}"}   # trim trailing spaces
            local noqualifiers=$(builtin cd $src && find * -maxdepth 0 -type d | sed -e 's!.*!:&.*!' | tr -d '\n')
            # 
            echo "rm -rf ${P[docs]} &&"
            echo "javadoc --source-path $src -d ${P[docs]} \\"
            echo "  $(eval echo \$JDK_JAVADOC_OPTIONS) \\"
            echo "  -noqualifier \"java.*$noqualifiers\" \\"
            echo "  $packages &&"
            echo "  echo -e \"-->\\\ncreated javadoc in: '"${P[docs]}/index.html"'\""
        else
            echo "echo no source files present for javadoc"
        fi ;;
    esac
}

if ! typeset -f show >/dev/null; then
    # 
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Output set of instructions to execute for the commands passed as arguments.
    # Usage:
    #   show [commands]
    # 
    function show() {
        [ "$1" = "--help" ] && echo "show cmd [args] cmd [args] ..." && return 0 ||
            mk --show $@
    }
    created_funcs+=("show cmd [args] cmd [args] ...;")
fi

if ! typeset -f mk >/dev/null; then
    # 
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Show [--show] or execute commands passed as arguments.
    # Usage:
    #   mk [--show] [commands]
    # 
    function mk() {
        local args=(); local sp=""
        # 
        for arg in $@; do case "$arg" in
        --show) local show_only=true ;;
        --version) echo "mk version ${P[version]}"; return 0 ;;
        --help) echo "mk [--show|--version] { cmd [args] }*"; return 0 ;;
        *) args+=($sp$arg); sp=" " ;;
        esac; done
        # 
        if [ ${#args[@]} -eq 0 ]; then
            mk --show build compile compile-tests run run-tests package run-jar javadoc clean
        else
            args+=("STOP")
            local num=${#args[@]}; local cmd=""; local execute=""
            # 
            local cmd_args=();  # per-command args[]
            for arg in ${args[@]}; do num=$((num - 1)); local cmd_sp=""
                arg=${arg/ /}       # remove leading ' ' appearing in zsh
                case "$arg" in
                # commands separate commands from arguments
                build|clean|compile|compile-tests|run|run-tests|coverage|coverage-report|package|jar|run-jar|lombok|de-lombok|javadoc|javadocs|docs|doc)
                    [ -z "$cmd" ] && cmd="$arg" || execute=true ;;
                # 
                # collect per-command arguments
                *) [ "$arg" != "STOP" ] && cmd_args+=("$arg") ;;
                # 
                esac
                [[ $num -eq 0 ]] && execute="true"
                # 
                if [ "$execute" ]; then         # always show command
                    [ ${#cmd_args[@]} -gt 0 ] && local c_args=" [$(echo ${cmd_args[@]})]" || local c_args=""
                    # 
                    echo "$cmd:$c_args"
                    # 
                    command $cmd ${cmd_args[@]} | sed -e 's/.*/  &/'  # indent commands by 2 spaces
                    # 
                    # print seperator "---" for commands producing longer output, else newline except for last line
                    [ "$show_only" ] && [ $num -gt 0 ] && echo ||
                        case "$cmd" in
                        build|clean|compile|compile-tests) ;;
                        *) echo "---" ;;
                        esac
                    # 
                    if [ -z "$show_only" ]; then            # execute command with ${cmd_args[@]}, if provided
                        # 
                        # fetch command which may contain unresolved substitutions, e.g. "$(find ... )"
                        local exec_cmd="$(command $cmd ${cmd_args[@]})"
                        [ "$cmd" = "build" ] && echo ""     # output line after 'mk build'
                        # 
                        # flatten command into single-line for zsh, remove " \" from single-line command
                        exec_cmd=${exec_cmd// \\/}          # ; echo "-->" [$exec_cmd]
                        [ "${P[is-zsh]}" ] && exec_cmd=$(tr -d '\n' <<< $exec_cmd)
                        # 
                        eval $exec_cmd                      # execute flattened, single-line command
                        # 
                        # print newline for executed run-commands, except for "run-tests", which issues newline
                        if [ $? -eq 0 ]; then
                            [ $num -gt 0 -a "$cmd" != "run-tests" ] && echo
                        else
                            return 1                        # exit processing-loop on failure
                        fi
                    fi
                    cmd="$arg"; cmd_args=(); execute=""
                fi
            done
        fi; return 0
    }
    created_funcs+=("mk [--show] cmd [args] cmd [args] ...;")
fi

if ! typeset -f wipe >/dev/null; then
    # 
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Wipe the project environment, remove all files, environment variables and
    # functions created during sourcing.
    # Usage:
    #   wipe [-a|--all]
    # 
    function wipe() {
        for arg in $@; do case "$arg" in
        --all|-a) local all=true ;;
        --help) echo "wipe [--all|-a]"; return 0 ;;
        -*) echo "unknown flag: [$arg], use: $(wipe --help)"; return 1 ;;
        *) echo "unknown argument: [$arg], use: $(wipe --help)"; return 1 ;;
        esac; done
        # 
        local wipe_vars=( \
            CLASSPATH MODULEPATH JUNIT_CLASSPATH JUNIT_OPTIONS JDK_JAVAC_OPTIONS \
            JDK_JAVADOC_OPTIONS JAR_PACKAGE_LIBS JACOCO_AGENT_OPTIONS \
        )
        local wipe_files=(.classpath .project .vscode/launch-coderunner)
        local wipe_funcs=(command show mk wipe prepare_manifest packaged_content)
        # 
        local rm_vars=(); local rm_files=(); local rm_funcs=()
        # 
        # collect environment variables, files and functions to wipe
        for var in "${wipe_vars[@]}"; do
            [ "$(eval echo '$'$var)" ] && rm_vars+=($var) && local print_wiping=true
        done
        # 
        for file in $(show clean | sed -e '/rm -rf/!d' -e 's/[[:space:]]*rm -rf//'); do
            file=${file//[[:space:]]/}  # trim spaces from file name
            [ -e "$file" ] && rm_files+=($file) && local print_wiping=true
        done
        # 
        [ "$all" ] && for file in "${wipe_files[@]}"; do
            file=${file//[[:space:]]/}  # trim spaces from file name
            [ -e "$file" ] && rm_files+=($file) && local print_wiping=true
        done
        # 
        [ "$all" ] && for func in "${wipe_funcs[@]}"; do
            func=${func//[[:space:]]/}  # trim spaces from function name
            # keep 'wipe' function, remove with 'wipe -a'
            [ "$func" = "wipe" -a -z "$all" ] && continue
            if typeset -f $func >/dev/null; then
                rm_funcs+=($func)
                local print_wiping=true
            fi
        done
        # 
        [ "$print_wiping" ] && echo "wiping:"
        # 
        if [ "${rm_vars[@]:0:1}" ]; then
            local cmd="unset ${rm_vars[@]}"
            local line=" - unset"; local sp=" "
            # 
            for v in "${rm_vars[@]}"; do
                local line_added="$line$sp$v"
                if [ ${#line_added} -gt 78 ]; then
                    echo "$line,"; line="   $v"
                else
                    line+="$sp$v"; sp=", "
                fi
            done; [ "$line" ] && echo "$line"
            eval $cmd   # execute unset command
        fi
        # 
        [ "${rm_files[@]:0:1}" ] && \
            local cmd="rm -rf ${rm_files[@]}" && echo " - $cmd" && eval $cmd
        # 
        [ "${rm_funcs[@]:0:1}" ] && \
            local cmd="unset -f ${rm_funcs[@]}" && echo " - $cmd" && eval $cmd
        # 
        return 0
    }
    created_funcs+=("wipe [--all|-a]")
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prepares 'target/resources/META-INF/MANIFEST.MF' by adding lines:
#   Main-Class: application.Application
#   Class-Path: resources 
#     resources/application.properties
#     resources/application.yaml
#     resources/application.yml
#     libs/jackson/jackson-annotations-2.19.0.jar (with --include-libs)
#     libs/jackson/jackson-core-2.19.0.jar
#     libs/jackson/jackson-databind-2.19.0.jar
# Usage:
#   prepare_manifest [--include-libs]
# @Return path to MANIFEST.MF used from 'src/resources' or 'target/resources'
# Function is needed after configuration to package .jar files, do not unset.
# 
function prepare_manifest() {
    if [ "${P[manifest]}" ]; then
        rm -rf "${P[target-res]}"
        # fresh copy of "${P[res]}" to "${P[target-res]}" (entire folder)
        mkdir -p "${P[target-res]}" && cp -R "${P[res]}" "${P[target-res]}/.."
        local manifest="${P[target-res]}/${P[manifest]}"
        # add 'Main-Class:' and 'Class-Path:' entries, if not present
        # remove empty lines, -e '$a\Main-Class: '"${P[main]}"
        sed -e '/^[[:space:]]*$/d' < "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
        # 
        if [ "${P[main]}" -a -z "$(grep 'Main-Class:' $manifest)" ]; then
            echo "Main-Class: ${P[main]}" >> "$manifest"
        fi
        if [ -z "$(grep 'Class-Path:' $manifest)" ]; then
            # add resources and libs from $JAR_PACKAGE_LIBS, if present (keep space after "${P[res]} ")
            echo "Class-Path: resources " >> "$manifest"
        fi
            # [ "$1" = "--include-libs" ] && local filter="cat" || local filter="grep -v '.jar'"
            filter="cat"    # always include libs in 'target/resources/META-INF/MANIFEST.MF/Class-Path:'
            sed -e 's/-C[[:space:]][a-zA-Z0-9_./\-]*[[:space:]]//g' \
                -e 's/[[:space:]]/\n    /g' \
                -e 's/^/    /' <<< $JAR_PACKAGE_LIBS | eval $filter >> "$manifest"
        # fi
        echo $manifest
    fi; return 0
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Return content added to .jar as expected by the .jar command with adjusted
# paths for libs and resources matching the internal path.
# Usage:
#   packaged_content [--include-libs]
# @Return:
#  -C . libs/jackson/jackson-annotations-2.19.0.jar
#  -C . libs/jackson/jackson-core-2.19.0.jar ...
#  -C target resources/application.properties ...
# 
# @Return path to MANIFEST.MF used from 'src/resources' or 'target/resources'
# Function is needed after configuration to package .jar files, do not unset.
# 
function packaged_content() {
    [ -d "${P[target-res]}" ] && local res="${P[target-res]}" || local res="${P[res]}"
    res=${res%resources}    # remove trailing 'resources' (for just 'resources')
    res=${res%/}            # remove trailing '/' (for '/resources')
    # 
    # extract files from "-C <path> <file>" entries in $JAR_PACKAGE_LIBS
    # sed -n '0~3p' prints every 3rd line
    for c in $(tr ' ' '\n' <<< $JAR_PACKAGE_LIBS | sed -n '0~3p'); do
        case "$c" in
        *.jar)  [ "$1" = "--include-libs" ] && echo "-C ${P[libs-rpup]} $c" ;;
        *)      echo "-C $res $c" ;;
        esac
    done; return 0
}

function locate_libs() {
    [ "${P[pdir]}" ] && local pd="${P[pdir]}/"  # local project directory
    local libs="${P[libs]}"
    # 
    # read 'P[libs-search]' space-separated paths into libs_paths array
    IFS=' ' read ${P[ra-opt]} libs_paths <<< "${P[libs-search]}"; unset IFS
    for p in ${libs_paths[@]}; do
        local lp="$p/$libs"
        echo -n "probing for 'libs'" > /dev/tty
        [ -d "$pd$lp" ] && echo "$lp" && echo ", found at:" $lp > /dev/tty && return 0 || \
            echo ", none." > /dev/tty
    done; return -1
}

function parse_module_name() {
    [ "$1" ] && local minfo="$1" || local minfo="${P[module-info]}"
    # 
    if [ -f "$minfo" ]; then
        # read file 'module-info.java' and strip comments
        local mod=" "$(sed -e 's|//.*||' -e 's|/\*.*||' -e 's|^[[:space:]]*\*.*||' -e '/^[[:space:]]*$/d' < "$minfo")
        # 
        mod=${mod/?*module/}    # remove from remaining text everything including 'module'
        mod=${mod/'{'?*/}       # remove everything after '{' leaving module name in the middle
        mod=${mod#"${mod%%[![:space:]]*}"}      # strip leading whitespaces
        mod=${mod%"${mod##*[![:space:]]}"}      # strip trailing whitespaces
        echo ${mod}
    fi; return 0
}

function is_project_directory() {
    [ "$1" ] && local path="$1" || local path="."
    [ ! -d "$path/.git" -o ! -d "$path/${P[src]}" ] && return 1
    echo true; return 0
}

function realpath_() {
    # disable '--relative-to' for Mac since realpath on Mac does not support it
    case "$1" in
    --relative-to*) [ "${P[is-zsh]}" ] && shift ;;  # absorb flag '--relative-to' for zsh
    esac
    if [ "${P[has-realpath]}" ]; then
        realpath $@     # output the real filesystem path with links traced
    else
        # [ "${P[is-zsh]}" ] && local last_arg=${@:$#} || local last_arg="${!#}"
        echo $@         # output unchanged path
    fi
}

function cygpath_() {
    if [ "${P[has-cygpath]}" ]; then
        /usr/bin/cygpath $@ | sed -e 's|\\|/|g'         # invoke cygpath, if present
    else
        # emulate cygpath behavior, if not present, obtain last arg in $@ arguments
        [ "${P[is-zsh]}" ] && local last_arg=${@:$#} || local last_arg="${!#}"
        if [ "$1" = "-w" ]; then
            # emulate 'cygpath -w <path>' -> convert to absolute Windows path C:\Users\...
            local rp=$(realpath_ "$last_arg")               # rp="/cygdrive/d/home/svgr"
            local rp2=$(sed -e 's|.*/[a-zA-Z]/||' <<< $rp)  # separate '/cygdrive/c' (rp1) from '/home/svgr' (rp2)
            local rp1=${rp%"$rp2"}                          # echo -E "rp1: [$rp1]", echo -E "rp2: [$rp2]"
            if [ "$rp1" ]; then
                # last char of rp1 is drive letter 'c' -> convert to uppercase 'C'
                local drv=${rp1: -2: -1}
                [ "${P[is-zsh]}" ] && drv="${drv:u}:" || drv="${drv^^}:"
            fi
            echo -E $drv$rp     # output Windows-path 'C:\User\...', -E avoids interpretation of '\t' in zsh
        else
           echo $last_arg       # with no option, output path provided as last argument
        fi
    fi
}

function print_created_assets() {
    # 
    [ "${created_vars[@]:0:1}" ] && echo " - created environment variables:" &&
        IFS=';' && for var in ${created_vars[@]}; do
            # remove all spaces for zsh and bash:
            var=${var// /}
            [ -z "$var" ] && continue
            echo "    -" $var
        done
    # 
    [ "${created_files[@]:0:1}" ] && echo " - created files:" &&
        IFS=';' && for file in ${created_files[@]}; do
            echo "    -" $file
        done
    # 
    [ "${created_funcs[@]:0:1}" ] && echo " - created functions:" &&
        IFS=';' && for func in ${created_funcs[@]}; do
            [ "$func" ] && echo "    -" $func
        done
    # 
    [ "$IFS" ] && unset IFS
    return 0
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Perform project discovery and configuration with the creation of files,
# environment variables and functions.
# 
discover_env &&
        parse_args $@ &&
        configure_env &&
        echo "----------------------------" &&
        print_created_assets &&
        echo "----------------------------" &&
        echo '-->' success &&
        parse_args --post $@ \
    || case $? in
        $RC_HELP_MSG)
            echo "configure Java project"
            echo "- ${P[script]} [-evh] [--verbose] [--environment] [--help]"
            ;;
        $RC_NOTHING_CREATED)
            echo "project environment has been set up"
            parse_args --post $@
            ;;
        *)  echo '-->' failure
            ;;
    esac

# Cleanup variables and functions that are no longer needed after setup.
# Keep P[] array and functions used as commands: show, mk, wipe, command.
unset is_zsh script_ RC_HELP_MSG RC_NOTHING_CREATED \
        created_vars created_files created_funcs
# 
# keep functions: show, mk, wipe, command
# keep functions: prepare_manifest, packaged_content since they are
# needed after configuration for packaging .jar files
unset -f discover_env configure_env parse_args locate_libs parse_module_name \
        is_project_directory realpath_ cygpath_ print_created_assets
# 
return 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Template sections extracted by the template() function separated between
# markers: # '^# -- section-indicator$' and '^# --$'. @vars are included in
# output for substitution with actual values.
# 
# The .classpath file has the following sections:
# - .classpath.start        ; @target, @src, @classes
# - .classpath.res          ; @resources, @resources-output
# - .classpath.tests        ; @tests, @test-classes
# - .classpath.jre          ; 
# - .classpath.jre.mod      ; 
# - .classpath-entry        ; @jar
# - .classpath-entry.mod    ; @jar
# - .classpath.end
# - - - - - - - - - - - - - - - - - - -
# 
# .classpath file, first section
# -- .classpath-start
# <?xml version="1.0" encoding="UTF-8"?>
# <classpath>
#   <classpathentry kind="output" path="@target"/>
#   <classpathentry kind="src" path="@src" output="@classes"/>
# --- .classpath.res
#   <classpathentry kind="src" path="@res" output="@res-out" including="**/*.properties|**/*.yaml|**/*.yml"/>
# ---
# --- .classpath.tests
#   <classpathentry kind="src" path="@tests" output="@test-classes">
#     <attributes>
#       <attribute name="test" value="true"/>
#     </attributes>
#   </classpathentry>
# ---
# --- .classpath-jre
#   <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
#   <classpathentry kind="con" path="org.eclipse.jdt.junit.JUNIT_CONTAINER/5"/>
# ---
# --- .classpath-jre.mod
#   <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER">
#     <attributes>
#        <attribute name="module" value="true"/>
#     </attributes>
#   </classpathentry>
#   <classpathentry kind="con" path="org.eclipse.jdt.junit.JUNIT_CONTAINER/5">
#     <attributes>
#        <attribute name="module" value="true"/>
#     </attributes>
#   </classpathentry>
# ---
# --

# .classpath file, second section
# -- .classpath-entry
#   <classpathentry kind="lib" path="@jar"/>
# --
# -- .classpath-entry.mod
#   <classpathentry kind="lib" path="@jar">
#     <attributes>
#       <attribute name="module" value="true"/>
#     </attributes>
#   </classpathentry>
# --

# .classpath file, third section
# -- .classpath-end
# </classpath>
# --

# -- .project
# <?xml version="1.0" encoding="UTF-8"?>
# <projectDescription>
#   <name>$name</name>
#   <comment></comment>
#   <projects>
#   </projects>
#   <buildSpec>
#     <buildCommand>
#       <name>org.eclipse.jdt.core.javabuilder</name>
#       <arguments></arguments>
#     </buildCommand>
#   </buildSpec>
#   <natures>
#     <nature>org.eclipse.jdt.core.javanature</nature>
#   </natures>
# </projectDescription>
# --

# -- CLASSPATH-entries (not used)
# bin/classes
# bin/resources
# libs/jackson/jackson-annotations-2.19.0.jar
# libs/jackson/jackson-core-2.19.0.jar
# libs/jackson/jackson-databind-2.19.0.jar
# libs/junit/junit-jupiter-api-5.12.2.jar
# libs/logging/log4j-api-2.24.3.jar
# libs/logging/log4j-core-2.24.3.jar
# libs/logging/log4j-slf4j2-impl-2.24.3.jar
# libs/logging/slf4j-api-2.0.17.jar
# libs/lombok/lombok-1.18.38.jar
# --
# -- JUNIT_CLASSPATH-entries (not used)
# bin/classes
# bin/test-classes
# bin/resources
# libs/jackson/jackson-annotations-2.19.0.jar
# libs/jackson/jackson-core-2.19.0.jar
# libs/jackson/jackson-databind-2.19.0.jar
# libs/jacoco/jacocoagent.jar
# libs/jacoco/jacococli.jar
# libs/junit-platform-console-standalone-1.9.2.jar
# libs/logging/log4j-api-2.24.3.jar
# libs/logging/log4j-core-2.24.3.jar
# libs/logging/log4j-slf4j2-impl-2.24.3.jar
# libs/logging/slf4j-api-2.0.17.jar
# libs/lombok/lombok-1.18.38.jar
# --
