function localhostIP=localHostIP()
    % java trick to get the hostname, from matlabcentral. This is a one
    %  liner, but returns a name which is not understood out of the
    %  observatory domain
    % localhostname=char(java.net.InetAddress.getLocalHost.getHostName);
    % LAST machines don't have a DNS and know only about their names or
    % tere IPs. IPs should be useful also for connecting with WIS machines.
    % Using IP may be an option, but I'm not sure that udp ports from a
    % last machine to an IP address can be opened in matlab without some
    % proxy setting.
    % idea to clear stdout from https://www.mathworks.com/support/bugreports/1400063
    %  strange that this system call intercepts whatever is on left on stdout, even
    %  if on another host.
    [~,r]=system('');
    [~,sysoutput]=system('hostname -I');
    % cope with mutiple lines, produced by previous output on stdout,
    %  wronlgy redirected: take only the last line terminated by \n
    outlines=split(sysoutput,newline);
    localhostIP=strtok(strtrim(outlines{end-1})); % strtok to filter only the first address
    % OTOH, resolvehost(java.net.InetAddress.getLocalHost.getHostAddress,'address') returns only
    %  127.0.0.1
