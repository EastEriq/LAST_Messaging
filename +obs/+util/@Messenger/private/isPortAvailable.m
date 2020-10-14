function avail=isPortAvailable(M)
% Check if the serial or tcpip resource assigned to the messenger object is
%  still known to the system, and delete if it disappeared.
    %tic   

    % hopefully 1 ping is enough - eventually fine tune. However, only
    %  su can ping more frequently than every 0.2sec, so more than one
    %  repetition would add multiples of 200ms + ping time.
    % self-note: see using ss instead, should allow checking the
    %  specific port
    if unix(['ping -c 1 -i 0.2 -w 2 ' M.Address{1} '>/dev/null'])
        portlist='';
    else
        portlist=M.Address{1};
    end
    
    avail=any(contains(portlist,M.Port));
    if ~avail
        M.report("Tcpip "+ M.Address{1}+':'+M.Address{2}+...
                  ' disappeared from system, closing it\n')
        try
            delete(instrfind('RemoteHost',M.Address{1}))
        catch
            M.LastError=['cannot delete tcpip object ' M.Address{1} ':' M.Address{2}];
        end
    end
    
    % fprintf('availability check: %.1fms\n',toc*1000);
