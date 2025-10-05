# gitmodule-env.sh
Gitmodule with file [*env.sh*](env.sh) to *"source"* a Java project.
*"Sourcing"* a project means to create the environment in the executing
shell process with:

- environment variables,

- functions and commands and

- project files.

Check-out this *git module* into sub-directory `.env` with:

```sh
git submodule add -f -- https://github.com/sgra64/gitmodule-env.sh.git .env

ls -la .env                 # show content of .env folder holding the git module
```
```
total 61
drwxr-xr-x 1 svgr2 Kein     0 Oct  5 22:28 .
drwxr-xr-x 1 svgr2 Kein     0 Oct  5 22:28 ..
-rw-r--r-- 1 svgr2 Kein    29 Oct  5 22:28 .git
-rwxr-xr-x 1 svgr2 Kein 42156 Oct  5 22:28 env.sh       <-- sourcing script
-rw-r--r-- 1 svgr2 Kein  8894 Oct  5 22:28 README.md
```

In addition, git has created a `.gitmodules` file in the project directory
and added the new gitmodule:

```sh
cat .gitmodules             # show .gitmodules file
```

Output shows the new git module registered with the project:

```
[submodule ".env"]
        path = .env
        url = https://github.com/sgra64/gitmodule-env.sh.git
```

```sh
git submodule                       # list git submodules registered with the project
git submodule foreach git status    # show status of each registered submodule
```
```
d197ffc742fccc0e427b5b847041f94a0a11d911 .env (heads/main)

Entering '.env'
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```


&nbsp;

## Project Scaffold

"*Sourcing*" assumes a certain structure ("*scaffold*") of the project.
The layout below shows a typical structure of a Java project with sub-directories:

- `src` - for all project source code,

- `target` - for all generated (compiled) content,

- `libs` - for external packages and libraries used in the project,

- `.git` - the local *git* repository,

- `.vscode` - project settings for the *VSCode* IDE and

- `.env` - the folder with the sourcing script `env.sh`.


Make sure you have this structure in the project directory:

```sh
--<project-directory>:                  # project directory
 |
 | # directory with script 'env.sh' to source the project
 +--<.env>
 |   +-- env.sh
 |
 | # VSCode IDE project settings
 +--<.vscode>
 |   +-- settings.json                  # project-specific VSCode settings
 |   +-- launch.json                    # Java/Debug launch settings
 |   +-- launch_terminal.sh             # terminal launch settings
 |
 +--<.git>                              # local git repository
 +-- .gitignore                         # file with patterns to ignore by git
 +-- .gimodules                         # git modules added to the project
 |
 +--<libs>          # directory of link to libraries folder
 |
 +--<src>           # all project source code is under 'src'
 |   |
 |   +--<main>                      # application source code
 |   |   +-- module-info.java           # module defintion file
 |   |   +--<application>               # Java package 'application'
 |   |       +-- package-info.java      # package description for javadoc
 |   |       +-- Application.java       # program with main() function
 |   |
 |   +--<resources>                 # none-Java source code, configuration files
 |   |   +-- application.properties     # application configuration file
 |   |   +-- logging.properties         # logging configuration file
 |   |   +--<META-INF>                  # jar-packaging information
 |   |       +-- MANIFEST.MF            # manifest with Main-Class, Class-Path
 |   |
 |   +--<tests>                     # Unit-test source code separated from src/main
 |      +--<application>               # mirrored package structure
 |          +-- Application_0_always_pass_Tests.java   # initial JUnit-test
 |
 +--<target>        # compiled classes and generated artefacts are under 'target'
 |   |
 |   |
 |   +-- application-1.0.0-SNAPSHOT.jar # .jar file as result of build process
 |   |
 |   +--<classes>                       # compiled Java classes (.class files)
 |   |   +-- module-info.class          # compiled module-info class
 |   |   +--<application>               # compiled 'application' package
 |   |       +-- package-info.class
 |   |       +-- Application.class
 |   |
 |   +--<resources>                     # copied resource files
 |   |   +-- application.properties, logging.properties
 |   |   +--<META-INF>                  # jar-packaging information
 |   |       +-- MANIFEST.MF            # manifest with Main-Class, Class-Path
 |   |
 |   +--<test-classes>                  # compiled test classes
 |       +--<application>
 |           +-- Application_0_always_pass_Tests.class
 |
```


&nbsp;

## "*Sourcing*" the Project

The expression *"sourcing"* the environment comes from the shell command
`source` that is used to execute the file and make it effective in the
*executing shell process*, not in a sub-process such as when executed as
a script.

One must be in the project directory to source the project.

```sh
cd <...>                        # cd into the project directory

source env.sh                   # sourcing the file 'env.sh'
source .env/env.sh              # or from sub-directory '.env'

```

Output shows the created assets:

```
----------------------------
 - created environment variables:
    - CLASSPATH
    - MODULEPATH
    - JDK_JAVAC_OPTIONS
    - JDK_JAVADOC_OPTIONS
    - JAR_PACKAGE_LIBS
    - JUNIT_CLASSPATH
    - JUNIT_OPTIONS
    - JACOCO_AGENT_OPTIONS
 - created files:
    - .classpath
    - .project
    - .coderunner_launch
 - created functions:
    - show cmd [args] cmd [args] ...
    - mk [--show] cmd [args] cmd [args] ...
    - wipe [--all|-a]
----------------------------
--> success
```

Environment variables can be inspected:

```sh
echo $CLASSPATH                 # show value of the CLASSPATH environment variable
```

Outpur shows the value of the CLASSPATH variable used by the Java compiler `javac`
or Java VM `java`:

```
target/classes;target/resources;libs/jackson/jackson-annotations-2.19.0.jar;libs/jackson/jackson-core-2.19.0.jar;libs/jackson/jackson-databind-2.19.0.jar;libs/junit/junit-jupiter-api-5.12.2.jar;libs/logging/log4j-api-2.24.3.jar;libs/logging/log4j-core-2.24.3.jar;libs/logging/log4j-slf4j2-impl-2.24.3.jar;libs/logging/slf4j-api-2.0.17.jar;libs/lombok/lombok-1.18.38.jar
```

Created project files can be inspected as well such as file `.classpath`:

```sh
cat .classpath                  # show content of project files '.classpath'
```

Outpur shows the value of the CLASSPATH variable used by the Java compiler `javac`
or Java VM `java` (content may vary):

```
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
  <classpathentry kind="output" path="target"/>
  <classpathentry kind="src" path="src/main" output="target/classes"/>
  <classpathentry kind="src" path="src/resources" output="target/resources" including="**/*.properties|**/*.yaml|**/*.yml"/>
  <classpathentry kind="src" path="src/tests" output="target/tests">
    <attributes>
      <attribute name="test" value="true"/>
    </attributes>
  </classpathentry>
  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
  <classpathentry kind="con" path="org.eclipse.jdt.junit.JUNIT_CONTAINER/5"/>
  <classpathentry kind="lib" path="libs/jackson/jackson-annotations-2.19.0.jar"/>
  <classpathentry kind="lib" path="libs/jackson/jackson-core-2.19.0.jar"/>
  <classpathentry kind="lib" path="libs/jackson/jackson-databind-2.19.0.jar"/>
  <classpathentry kind="lib" path="libs/junit/junit-jupiter-api-5.12.2.jar"/>
  <classpathentry kind="lib" path="libs/logging/log4j-api-2.24.3.jar"/>
  <classpathentry kind="lib" path="libs/logging/log4j-core-2.24.3.jar"/>
  <classpathentry kind="lib" path="libs/logging/log4j-slf4j2-impl-2.24.3.jar"/>
  <classpathentry kind="lib" path="libs/logging/slf4j-api-2.0.17.jar"/>
  <classpathentry kind="lib" path="libs/lombok/lombok-1.18.38.jar"/>
</classpath>
```

"*Sourcing*" also created functions that can be used as commands:

```sh
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
# 
# Usage:
#  - source env.sh [-v] [-e]    ; -v verbose show discovered assets
#                               ; -e show values of environment variables
```

For example, function `mk` ("*make*") can be used to compile Java source code
by invoking the `javac` compiler with proper arguments:

```sh
mk compile                      # compile java source code
```
```
$ mk compile
compile:
  javac $(find src/main -name '*.java') -d target/classes &&
  mkdir -p target/resources && cp -R src/resources target/resources/..
```

Compiled classes can be inspected in the `target` folder:

```sh
find target                     # list content of the 'target' folder
```

Output shows compiled `.class` files application code and tests and also
copied content from the `resources` folder:

```
target/
target/classes
target/classes/application
target/classes/application/Application.class
target/classes/application/package-info.class
target/classes/application/package_info.class
target/classes/module-info.class
target/resources
target/resources/application.properties
target/resources/META-INF
target/resources/META-INF/MANIFEST.MF
target/tests
target/tests/application
target/tests/application/Application_0_always_pass_Tests.class
```
