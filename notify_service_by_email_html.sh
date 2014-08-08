#!/bin/bash

##
## By kali
## Build html notification to be piped to mail command
##
##


EMAIL_TARGET=${1:-$NAGIOS_CONTACTEMAIL}

IMG_WIDTH=500
IMG_HEIGHT=200

NAGIOS_BASEURL="https://YOUR_NAGIOS_BASEURL/nagios"
GRAPHITE_BASEURL="https://YOUR_GRAPHITE_BASEURL/render/?width=${IMG_WIDTH}&height=${IMG_HEIGHT}&target="
CURL_OPTIONS_GRAPHITE="-s -u GRAPHITE_HTTP_USER:GRAPHITE_HTTP_PASSWORD"
CURL_OPTIONS_NAGIOS="-s -u YOUR_NAGIOS_HTTP_USER:YOUR_NAGIOS_HTTP_PASSWORD"

declare -A COLORS_SERVICE
COLORS_SERVICE[OK]='#88d066'
COLORS_SERVICE[WARNING]='#ffff00'
COLORS_SERVICE[CRITICAL]='#f88888'
COLORS_SERVICE[UNKNOWN]='#ffbb55'

declare -a COLORS_TABLE
COLORS_TABLE[0]='#f4f4f4'
COLORS_TABLE[1]='#e7e7e7'

MESSAGE_BODY="<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n \
<html><head><title></title></head>\n \
<body style=\"font-family: verdana\">\n \
<br />\n \
<span style=\"background-color: ${COLORS_SERVICE[$NAGIOS_SERVICESTATE]}; padding: 1px 5px; border: 1px solid black;\">${NAGIOS_SERVICESTATE}</span> -\n \
<strong>${NAGIOS_HOSTNAME} ${NAGIOS_SERVICEDESC}</strong>\n \
<br />\n \
<br />\n \
"

#<pre style=\"font-size: 9pt\">${NAGIOS_SERVICEOUTPUT}</pre>\n \
#<br />\n \


if [ -n "$NAGIOS_NOTIFICATIONAUTHOR" -a -n "$NAGIOS_NOTIFICATIONCOMMENT" ] ; then
	MESSAGE_BODY+="<strong>"
	if [ "$NAGIOS_NOTIFICATIONTYPE" == 'ACKNOWLEDGEMENT' ] ; then
		MESSAGE_BODY+="acknowledgement: "
	else
		MESSAGE_BODY+="comment: "
	fi
	MESSAGE_BODY+="${NAGIOS_NOTIFICATIONAUTHOR}:</strong> ${NAGIOS_NOTIFICATIONCOMMENT}\n \
<br />\n \
<br />\n \
"
fi

MESSAGE_BODY+="<table cellpadding=\"2px\" style=\"width: 100%; \">\n \
 <tr style=\"background-color: ${COLORS_TABLE[0]};\"> <td>Notification Type</td><td>${NAGIOS_NOTIFICATIONTYPE}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[1]};\"> <td>Service</td><td>${NAGIOS_SERVICEDESC}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[0]};\"> <td>Host</td><td>${NAGIOS_HOSTALIAS}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[1]};\"> <td>Address</td><td>${NAGIOS_HOSTADDRESS}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[0]};\"> <td>State</td><td>${NAGIOS_SERVICESTATE}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[1]};\"> <td>Date/Time</td><td>${NAGIOS_LONGDATETIME}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[0]};\"> <td>Duration</td><td>${NAGIOS_SERVICEDURATION}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[1]};\"> <td>Notification number</td><td>${NAGIOS_SERVICENOTIFICATIONNUMBER}</td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[0]};\"> <td>Check command</td><td><pre style=\"font-size: 9pt\">${NAGIOS_SERVICECHECKCOMMAND}</pre></td> </tr>\n \
 <tr style=\"background-color: ${COLORS_TABLE[1]};\"> <td>Check output:</td><td><pre style=\"font-size: 9pt\">${NAGIOS_SERVICEOUTPUT}</pre></td> </tr>\n \
</table>\n \
<br />\n \
"

if [[ $NAGIOS_SERVICECHECKCOMMAND == check_graphite_metric* ]] ; then
	# if alert comes from a graphite-monitored service, insert the graph and links
	GRAPHITE_METRIC=`sed -r "s/^.*-m '(.*)'.*/\1/" <<< ${NAGIOS_SERVICECHECKCOMMAND} | sed "s/%HOST%/$NAGIOS_HOSTNAME/g"`
	GRAPH_BASE64=$(/usr/bin/curl ${CURL_OPTIONS_GRAPHITE} "${GRAPHITE_BASEURL}${GRAPHITE_METRIC}&from=-6hours" | /usr/bin/base64 -w0)
	MESSAGE_BODY+="<div style=\"font-size: 10pt; font-family: monospace; text-align: center\">\n \
		Have a look at the graph for the service in the last 6 hours:<br />\n \
		<img src=\"data:image/png; base64,${GRAPH_BASE64}\" width=\"${IMG_WIDTH}\" height=\"${IMG_HEIGHT}\">\n \
		<br />\n \
		<br />\n \
		Check service graphs for longer times: <br />\n \
		<a href='${GRAPHITE_BASEURL}${GRAPHITE_METRIC}&from=-1day'>Last day</a><br />\n \
		<a href='${GRAPHITE_BASEURL}${GRAPHITE_METRIC}&from=-1week'>Last week</a><br />\n \
		<a href='${GRAPHITE_BASEURL}${GRAPHITE_METRIC}&from=-1month'>Last month</a><br />\n \
		<a href='${GRAPHITE_BASEURL}${GRAPHITE_METRIC}&from=-1year'>Last year</a><br />\n \
		</div><br />\n \
		"
else
	# else insert the service trend from nagios
	GRAPH_BASE64=$(/usr/bin/curl ${CURL_OPTIONS_NAGIOS} "${NAGIOS_BASEURL}/cgi-bin/trends.cgi?createimage&host=${NAGIOS_HOSTNAME}&service=${NAGIOS_SERVICEDESC}" | /usr/bin/base64 -w0)
	MESSAGE_BODY+="<div style=\"font-size: 10pt; font-family: monospace; text-align: center\">\n \
		Have a look at the state history for the service:<br />\n \
		<img src=\"data:image/png; base64,${GRAPH_BASE64}\">\n \
		</div><br />\n \
		"
fi

MESSAGE_BODY+="<div style=\"font-size: 9pt; font-family: monospace;\">\n \
<ul>\n \
<li><a href=\"${NAGIOS_BASEURL}\">${NAGIOS_BASEURL}</li>\n \
<li><a href=\"${NAGIOS_BASEURL}/cgi-bin/extinfo.cgi?type=2&host=${NAGIOS_HOSTNAME}&service=${NAGIOS_SERVICEDESC}\">Alert Status Page</a> - all unhandled nagios alerts</li>\n \
<li><a href=\"${NAGIOS_BASEURL}/cgi-bin/cmd.cgi?cmd_typ=34&host=${NAGIOS_HOSTNAME}&service=${NAGIOS_SERVICEDESC}\">Acknowledge Alert</a> - acknowledge this service</li>\n \
</ul>\n \
${NAGIOS_LONGDATETIME}\n \
</div>
</body>
</html>
"

MESSAGE_SUBJECT="** ${NAGIOS_NOTIFICATIONTYPE} Service Alert: ${NAGIOS_HOSTALIAS}/${NAGIOS_SERVICEDESC} is ${NAGIOS_SERVICESTATE} **"

echo -e $MESSAGE_BODY | /usr/bin/mail.mailutils -a "Content-Type: text/html" -s "${MESSAGE_SUBJECT}" ${EMAIL_TARGET}
