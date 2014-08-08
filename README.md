nagios_plugins
==============

Custom nagios plugins
----------------------

  * check_graphite_metric
Check metrics provided by a graphite installation. Useful if you have a running
graphite monitoring system in place and want to set alerts through nagios
without duplication of scripts running locally, and setting nrpe or ssh checks.

Requires running graphite. Allows https interfaces with user authentication.
Allows lo/hi thresholds for alerts.

Set a service check similar to this:

```
define command{
        command_name    check_graphite_metric
        command_line    $USER1$/check_graphite_metric -H $HOSTNAME$ $ARG1$
}

define service{
	use			generic-service
	service_description	your_check
	check_command		check_graphite_metric!-W TH_W_HI -C TH_C_HI -w TH_W_LO -c TH_C_LO -m '%HOST%.your.metric.name'
}
```



Custom nagios notifications
---------------------------

  * notify_service_by_email_html.sh
Send service notifications in html format, with extended information. If the
service checked is a graphite_metric then include the graph image and links to
wider time frames for extra information, as well as links to nagios reports and
acknowledge functions. For non-grahite checks include nagios' native graph of
status history. Requires nagios to pass environment variables to scripts, with
enable_environment_macros=1 on nagios.cfg

Set the notification like:

```
define command{
        command_name    notify-service-by-email
        command_line    $USER1$/notify_service_by_email_html.sh $CONTACTEMAIL$
}
```
