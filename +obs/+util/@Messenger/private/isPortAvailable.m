function avail=isPortAvailable(M)
% This function should check if the udp resource assigned to the messenger 
%  object is still known to the system, and delete if it disappeared.
%  For now just ping the host, should in future check specifically for an
%   udp port
    %tic   

    % hopefully 1 ping is enough - eventually fine tune. However, only
    %  su can ping more frequently than every 0.2sec, so more than one
    %  repetition would add multiples of 200ms + ping time.
    % self-note: see using ss instead, should allow checking the
    %  specific port (but ss is only local?) or nmap (but that is not
    %  usually installed)
    if unix(['ping -c 1 -i 0.2 -w 2 ' M.DestinationHost '>/dev/null'])
        portlist='';
    else
        portlist=M.DestinationHost;
    end
    
    avail=any(contains(portlist,M.DestinationHost));
    if ~avail
        M.report("Udp "+ M.DestinationHost+':'+M.DestinationPort+...
                  ' disappeared from system, closing it\n')
        try
            delete(instrfind('RemoteHost',M.DestinationHost))
        catch
            M.LastError=['cannot delete udp object ' M.DestinationHost ':' M.DestinationPort];
        end
    end
    
    % fprintf('availability check: %.1fms\n',toc*1000);
