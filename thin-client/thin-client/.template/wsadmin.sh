#!/bin/bash
#
# Wrapper script for launching wsadmin using the "thin client" runtime.
#
# The variables that need to be changed when creating a new thin client 
# installation are:
#
#   1. WAS_HOME          - the root directory of the thin client installation
#   2. USER_INSTALL_ROOT - also the root directory of the thin client installation
#   3. wsadminHost       - the default host for a deployment manager
#   4. wsadminConnType   - the default connection type (JSR160RMI is recommended)
#   5. wsadminPort       - the default port to use
#
#   Everything else in this wrapper script can remain unchnaged.
#
#   If you want to turn on trace for wsadmin there are properties to do so.
#   See wsadminTraceString, wsadminTraceFile, wsadminValOut.
#   Keep in mind that the values set here may be overridden by values in
#   a wsadmin.properties in the home directory of the user running this wrapper.
#

# WAS_HOME is thw wsadmin.sh own directory
# WAS_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
setWASHome() {
    if [ "${REPLACE_WAS_HOME:=}" != "" ] && [ -d ${REPLACE_WAS_HOME} ]
    then
        WAS_HOME=${REPLACE_WAS_HOME}
    else
        CUR_DIR=`pwd`
        cd "$(dirname ${0})"
        WAS_HOME=`pwd`
        cd "${CUR_DIR}"
    fi
}
setWASHome
USER_INSTALL_ROOT="${WAS_HOME}"

# You can specify this -host, -conntype, -port on the command line to override
# It is recommended that the user always provide at least one of host or port
# to force thought about what deployment manager is going to be used.
# We set the port to a bogus value to avoid accidentally connecting to a 
# deployment manager or other WAS process running on localhost.
wsadminHost=-Dcom.ibm.ws.scripting.host=localhost
wsadminConnType=-Dcom.ibm.ws.scripting.connectionType=JSR160RMI
wsadminPort=-Dcom.ibm.ws.scripting.port=0
wsadminLang=-Dcom.ibm.ws.scripting.defaultLang=jython

# The following are wsadmin properties for tracing
# The various trace levels are error,warn,info,fine,finer,finest (I think)
# Keep in mind that a wsadmin.properties in the home directory of the user
# running this script will take precedence over the values here.
# wsadminTraceString=-Dcom.ibm.ws.scripting.traceString=*=info
wsadminTraceFile=-Dcom.ibm.ws.scripting.traceFile=${USER_INSTALL_ROOT}/logs/wsadmin.traceout
wsadminValOut=-Dcom.ibm.ws.scripting.validationOutput=${USER_INSTALL_ROOT}/logs/wsadmin.valout

# JAVA_HOME should point to where Java is installed for the thin client
JAVA_HOME="$WAS_HOME/java"

WAS_LOGGING="-Djava.util.logging.manager=com.ibm.ws.bootstrap.WsLogManager"
WAS_LOGGING="$WAS_LOGGING -Djava.util.logging.configureByServer=true"

if [ -f ${JAVA_HOME}/bin/java ]; then
  JAVA_EXE="${JAVA_HOME}/bin/java"
else
  JAVA_EXE="${JAVA_HOME}/jre/bin/java"
fi

# For debugging the utility itself
# WAS_DEBUG=-Djava.compiler="NONE -Xdebug -Xnoagent - Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=7777"

CLIENTSOAP="-Dcom.ibm.SOAP.ConfigURL=file:${USER_INSTALL_ROOT}/properties/soap.client.props"
CLIENTSAS="-Dcom.ibm.CORBA.ConfigURL=file:${USER_INSTALL_ROOT}/properties/sas.client.props"
CLIENTSSL="-Dcom.ibm.SSL.ConfigURL=file:${USER_INSTALL_ROOT}/properties/ssl.client.props"
CLIENTIPC="-Dcom.ibm.IPC.ConfigURL=file:${USER_INSTALL_ROOT}/properties/ipc.client.props"

SHELL=com.ibm.ws.scripting.WasxShell

# If wsadmin properties is set, use it
if [ -n "${WSADMIN_PROPERTIES+V}" ]; then
  WSADMIN_PROPERTIES_PROP="-Dcom.ibm.ws.scripting.wsadminprops=${WSADMIN_PROPERTIES}"
else
  # not set, do not use it
  WSADMIN_PROPERTIES_PROP=
fi

# If config consistency check is set, use it
if [ -n "${CONFIG_CONSISTENCY_CHECK+V}" ]; then
  WORKSPACE_PROPERTIES="-Dconfig_consistency_check=${CONFIG_CONSISTENCY_CHECK}"
else
  # not set, do not use it
  WORKSPACE_PROPERTIES=
fi

# Parse the input arguments
isJavaOption=false
nonJavaOptionCount=1
for option in "$@" ; do
  if [ "$option" = "-javaoption" ]; then
    isJavaOption=true
  else
    if [ "$isJavaOption" = "true" ]; then
      javaOptions="$javaOptions $option"
      isJavaOption=false
    else
      nonJavaOption[$nonJavaOptionCount]="$option"
      nonJavaOptionCount=$((nonJavaOptionCount+1))
    fi
  fi
done

# If the jython.jar isn't explicitly added to the classpath in front of the admin client JAR, then the jython wrapper in
# the client JAR is instantiated and that leads to odd import issues with classes in the jython.jar. 
# The name of the admin client jar changes depending on the version of WAS in use, e.g., 7.0, 8.0 or 8.5 
CP="${WAS_HOME}/properties:${WAS_HOME}/lib/*"

# Platform specific args...
PLATFORM=$(/bin/uname)

case $PLATFORM in
  AIX | Linux)
    CONSOLE_ENCODING=-Dws.output.encoding=console ;;
  OS/390)
    CONSOLE_ENCODING=-Dfile.encoding=ISO8859-1
    EXTRA_X_ARGS="-Xnoargsconversion" ;;
esac

# Set the Java options for performance...

case $PLATFORM in
  AIX)
    PERF_JVM_OPTIONS="-Xms256m -Xmx256m -Xquickstart" ;;
  Linux)
    PERF_JVM_OPTIONS="-Xms256m -Xmx256m -Xj9 -Xquickstart" ;;
  OS/390)
    PERF_JVM_OPTIONS="-Xms256m -Xmx256m" ;;
esac 

if [ -z "${JAASSOAP}" ]; then
  JAASSOAP="-Djaassoap=off"
fi

CMDLINE="${JAVA_EXE} ${PERF_JVM_OPTIONS} ${EXTRA_X_ARGS} -Dws.ext.dirs=$WAS_EXT_DIRS ${WAS_LOGGING} ${javaOptions} ${CONSOLE_ENCODING} ${WAS_DEBUG} ${CLIENTSOAP} ${JAASSOAP} ${CLIENTSAS} ${CLIENTSSL} ${CLIENTIPC} ${WSADMIN_PROPERTIES_PROP} ${WORKSPACE_PROPERTIES} -Duser.root=${WAS_HOME} -Duser.install.root=${USER_INSTALL_ROOT} -Dwas.install.root=${WAS_HOME} -Dcom.ibm.websphere.thinclient=true ${wsadminTraceFile} ${wsadminValOut} ${wsadminTraceString} ${wsadminHost} ${wsadminConnType} ${wsadminPort} ${wsadminLang} -classpath ${CP} ${SHELL} ${nonJavaOption[@]}"

# echo "Executing: $CMDLINE"   # for debug
$CMDLINE
exit $?
