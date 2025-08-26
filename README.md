# gitmodule-env.sh
Gitmodule with file env.sh to source a Java project.

Script [*env.sh*](env.sh) sets up the environment for a Java project.

The [*source*](https://superuser.com/questions/46139/what-does-source-do)
command is used to execute the script. Environment variables defined by the
script become effective in the executing *shell*. Since the command used is
called *"source"*, the action of executing the script is also called
*"sourcing"*.

```sh
echo $CLASSPATH                 # CLASSPATH variable is undefined before 'sourcing'

source env.sh                   # 'sourcing' the script
```

Output shows *environment variables* defined by the script, *created files*
and *functions* that are available after *"sourcing"* :

```
- created environment variables:
   - PROJECT_PATH: "/c/Sven1/svgr2/tmp/svgr/workspaces/new/klausur"
   - CLASSPATH
   - JUNIT_CLASSPATH
   - MODULEPATH
   - JDK_JAVAC_OPTIONS
   - JDK_JAVADOC_OPTIONS
   - JUNIT_OPTIONS
   - JACOCO_AGENT
- created files:
   - .classpath
   - .vscode/.classpath
   - .vscode/.modulepath
   - .vscode/.sources
   - .project
- created functions:
   - show [cmd1, cmd2...]
   - mk [cmd1, cmd2...] [args]
   - wipe [--all|-a|-la]
```

The *CLASSPATH* variable is now defined (and so are the other environment
variables):

```sh
echo $CLASSPATH                 # show value of CLASSPATH environment variable after 'sourcing'
```

Output shows the value of the *CLASSPATH* environment variable after *"sourcing"*:

```
bin/classes;bin/resources;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/jackson/jackson-annotations-2.19.0.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/jackson/jackson-core-2.19.0.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/jackson/jackson-databind-2.19.0.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/junit/junit-jupiter-api-5.12.2.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/logging/log4j-api-2.24.3.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/logging/log4j-core-2.24.3.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/logging/log4j-slf4j2-impl-2.24.3.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/logging/slf4j-api-2.0.17.jar;C:/Sven1/svgr2/tmp/svgr/workspaces/new/libs/lombok/lombok-1.18.38.jar
```


&nbsp;

Synopsis of script [*env.sh*](env.sh):

```java
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup a Java project environment with environment variables, project files
# and functions supporting the project build process:
# \\
# Environment variables:
#  - PROJECT_PATH               ; path to git project (to wipe after cd-out)
#  - CLASSPATH, MODULEPATH      ; used by Java compiler and JVM
#  - JDK_JAVAC_OPTIONS          ; used by the Java compiler
#  - JDK_JAVADOC_OPTIONS        ; used by the Javadoc compiler
#  - JUNIT_CLASSPATH            ; used by the JUnit test runner
#  - JUNIT_OPTIONS              ; used by the JUnit test runner
#  - JACOCO_AGENT               ; JVM jacoco agent option for code coverage
# \\
# Project files for VSCode and eclipse IDE:
#  - .classpath, .project       ; used to set up the VSCode Java extension
#  - in .vscode: .classpath, .modulepath, .sources  ; for Java Code Runner
# 
# Executable functions:
# \\
#  - show [cmd1, cmd2...]       ; show build commands
# 
#  - mk [cmd1, cmd2...] [args]  ; execute build commands
# 
#  - wipe [--all|-a|-la]        ; unset project env variables and functions
#                               ; --all|-a: including project files
#                               ; -la: project files and 'libs' link or folder
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# VSCode commands:
#  - build: Ctrl-Shift-B
#  - run:   Ctrl-Alt-N
#  - clean Java Language Server Workspace: Ctrl-Shift-P
# 
# VSCode project cache:
#  - Windows: C:/Users/<USER>/AppData/Roaming/Code/User/workspaceStorage
#  - MacOS:   ~/Library/Application Support/Code/User/workspaceStorage
# 
# VSCode installation paths:
#  - Windows: C:/Users/<User>/AppData/Local/Programs/Microsoft\ VS\ Code/bin
#  - MacOS:   /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Revision information:
# @version: 1.0.8
# @author: sgraupner
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```
