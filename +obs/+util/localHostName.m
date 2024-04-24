function localhostname=localHostName()
    % java trick to get the hostname, from matlabcentral. This is a one
    %  liner, but returns a name which is not understood out of the
    %  observatory domain
    % localhostname=char(java.net.InetAddress.getLocalHost.getHostName);
    % LAST machines don't have a DNS and know only about their names or
    % tere IPs. IPs should be useful also for connecting with WIS machines.
    % Using IP may be an option, but I'm not sure that udp ports from a
    % last machine to an IP address can be opened in matlab without some
    % proxy setting.
    [~,sysoutput]=system('hostname -I');
    % cope with mutiple lines, produced by previous output on stdout,
    %  wronlgy redirected: take only the last line terminated by \n
    outlines=split(sysoutput,newline);
    localhostname=strtok(strtrim(outlines{end-1})); % strtok to filter only the first address
    % OTOH, java.net.InetAddress.getLocalHost.getHostAddress returns only
    %  127.0.0.1
