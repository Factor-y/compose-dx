#!/usr/bin/env bash
# ref https://www.ibm.com/support/knowledgecenter/en/SSAW57_9.0.5/com.ibm.websphere.nd.multiplatform.doc/ae/txml_adminclient.html
#########################

clean() {
    if [ -d $TMP ]; then 
        echo "Clean: removing $TMP"
        rm -R $TMP
    else
        echo "Clean: nothing to clean"
    fi
}
make() {
    echo "Making: creating $TMP"
    cp -r "$STPL" "$TMP"
    mkdir -p "$TMP"/{"etc","lib","properties","logs","optionalLibraries"}

    # this include the jar for the latest version of Jython (Jython27)
    # to include older version of Jython include com.ibm.ws.admin.client.forJython21_*.jar 
    # commenting out the following
    # cp $WAS_HOME/runtimes/com.ibm.ws.admin.client.forJython21_*.jar  "$TMP/lib"
    cp $WAS_HOME/runtimes/com.ibm.ws.admin.client_*.jar "$TMP/lib"
    cp $WAS_HOME/plugins/com.ibm.ws.security.crypto.jar "$TMP/lib"
    # undocumented, contains jyhton jar ()
    cp -r $WAS_HOME/optionalLibraries/jython $TMP/optionalLibraries/

    cp -r $WAS_HOME/properties/messages $TMP/properties/

    cp $PROFILE/properties/ipc.client.props $TMP/properties/
    cp $PROFILE/properties/soap.client.props $TMP/properties/
    cp $PROFILE/properties/sas.client.props $TMP/properties/
    cp $PROFILE/properties/ssl.client.props $TMP/properties/
    cp $PROFILE/properties/wsjaas_client.conf $TMP/properties/

    [ -f "$PROFILE/etc/key.p12" ] && {
        cp "$PROFILE/etc/key.p12" "$TMP/etc/"
    } || {
        echo "Warning: could not find $PROFILE/etc/key.p12"
        echo "         if security is enabled, please provide key store in the etc folder"
    }
    [ -f "$PROFILE/etc/trust.p12" ] && { 
        cp "$PROFILE/etc/trust.p12" "$TMP/etc/" 
    } || {
        echo "Warning: could not find $PROFILE/etc/trust.p12"
        echo "         if security is enabled, please provide trust store in the etc folder"
    }

    if [ -n "$JAVA" ]; then
        echo "Making: resolved java from $JAVA"
        cp -r "$JAVA" "$TMP/java"
    else
        if [ -f "$WAS_HOME/java/bin/java" ]; then 
            echo "Making: resolved java from $WAS_HOME/java"
            cp -r "$WAS_HOME/java" "$TMP/"
        else
            makeJava && {
                echo "Making: resolved java from $FOUND_JAVA"
            } || {
                sep
                echo "| Warning: unable to find java runtime, you must provide it in the java folder |"
                sep
            }
        fi
    fi
}
makeJava() {
    FOUND_JAVA=
    for _dir in "${WAS_HOME}/java/"*; do
        echo "Making: check java in ${_dir}"
        [ -f "${_dir}/bin/java" ] && FOUND_JAVA="${_dir}" && break
    done

    if [ -n "$FOUND_JAVA" ]; then
        cp -r "$FOUND_JAVA" "$TMP/java"
        return 0
    fi

    return 1
}
doZip() {
    if ! [ -x "$(command -v zip)" ]; then
        echo "No zip command found, skipping zip to $OUT"
        echo "Final thin-client unpacked is saved to $TMP"
        return 0
    fi

    cd $TMP && zip -rq $OUT ./* & pid=$! # Process Id of the previous running command

    local spin[0]="-"
    local spin[1]="\\"
    local spin[2]="|"
    local spin[3]="/"

    sep
    echo -n "Zipping: $OUT    ${spin[0]}"
    while kill -0 $pid 2>/dev/null; do
        for i in "${spin[@]}"; do
            echo -ne "\b$i"
            sleep 0.1
        done
    done
    echo ""
    echo ""
    return 0
}
help() {
    echo ""
    echo "Sample use:"
    echo ""
    echo "./generateThinClient.sh \\"
    echo "    -w /opt/IBM/WebSphere/AppServer \\"
    echo "    -p /opt/IBM/WebSphere/wp_profile \\"
    echo "    -o somefile.zip"
    echo ""
    echo "Where"
    echo "     -w [path to app_server_root] specify app_server_root path, default is"
    echo "        $WAS_HOME"
    echo "     -p [path to profile] specify profile_root path, connections configurations"
    echo "        will be pre-configured as for that profile, dafault is"
    echo "        $DEF_PROFILE"
    echo "     -o [path or filename] zip file were the client will be generated"
    echo "     -j [path to java] used to specify the java runtime to include in the thin client"
    echo "        If don't pecified then java will be searched in"
    echo "        $WAS_HOME/java/ and direct subfolders"
    echo "     -t flag that indicates to use the profile template as source"
    echo "        for configurations, will ignore -p flag, the profile template path is"
    echo "        $WAS_HOME/$DEF_PROFILE_TPL"
    echo ""
}
head() {
    echo "================================================================================"
}
sep() {
    echo "--------------------------------------------------------------------------------"
}
considerations() {
    sep
    echo "|                                                                              |"
    echo "| The property 'user.root' is overridden inside the wsadmin script for client  |"
    echo "| portability, if you need to change it just remove the override and modify    |"
    echo "| its value in the file 'properties/ssl.client.props'                          |"
    echo "|                                                                              |"
    sep
    echo "|                                                                              |"
    echo "| Use wsadmin.sh providing                                                     |"
    echo "|     -port <SOAP-port> -user <wpsadmin> -password <wpsadminpwd>               |"
    echo "|                                                                              |"
    sep
    echo ""
}
printenv() {
    echo "Variables for reference:"
    echo "  WAS_HOME=$WAS_HOME"
    echo "  PROFILE=$PROFILE"
    echo "  TMP=$TMP"
    echo "  OUT=$OUT"
    sep
}
check() {
    [ ! -d $WAS_HOME ] && {
        echo "Error: $WAS_HOME doesn't exist! Provide it with the -w argument"
        exit 1
    }
    [ ! -d $PROFILE ] && {
        echo "Error: $PROFILE doesn't exist! Provide it with the -p argument"
        exit 1
    }
}

# Vars to be specified, default values
WAS_HOME="/opt/IBM/WebSphere/AppServer"
OUT="ThinClient.zip"

# Build directories
RUN_DIR=`pwd`
TMP="$RUN_DIR/target"
# Script directory
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
STPL="${SDIR}/.template"

DEF_PROFILE_TPL="profileTemplates/default/documents"
DEF_PROFILE="/opt/IBM/WebSphere/AppServer/profiles/cw_profile"

head
while getopts "w:o:p:j:th" optchar; do
    case "${optchar}" in
        h)
            JUSTPRINT="1"
            help
            sep
            ;;
        w) WAS_HOME="${OPTARG}";;
        o) OUT="${OPTARG}";;
        p) PROFILE="${OPTARG}";;
        j)
            JAVA="${OPTARG}"
            [ ! -f "$JAVA/bin/java" ] && {
                echo "Error: java path '$JAVA' not valid (doesn't have bin/java file)"
                echo "    please provide a valid path"
                exit 1
            }
            ;;
        t)
            # use profile template
            sep
            echo "| You have specified to use the profile template as source for configuration,  |"
            echo "| the -p flag is ignored and the client will not include trust and key stores  |"
            echo "| you need to provide them inside the etc folder as 'trust.p12' and 'key.p12'  |"
            sep
            USE_PROFILE_TPL="1"
            ;;
        *) 
            help
            exit 1
            ;;
    esac
done

# get full name of out file
OUT=$(cd $(dirname "$OUT") && pwd -P)/$(basename "$OUT")

[ -z "$PROFILE" ] && PROFILE="$DEF_PROFILE"
[ -n "$USE_PROFILE_TPL" ] && PROFILE="$WAS_HOME/$DEF_PROFILE_TPL"
[ -n "$JUSTPRINT" ] && {
    echo ""
    printenv
    echo "Nothing has been done"
    echo ""
    exit 0
}
printenv
check
clean
make
doZip
considerations