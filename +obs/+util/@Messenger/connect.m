function success=connect(Msng)
% create a tcpip object on the specified host:port, open the stream and
%  setup a callback function for the receiver
   success = 0;

    try
        delete(instrfind('RemoteHost',Msng.Address{1})) % and 'Port',Msng.Address{2}, check
    catch
        Msng.LastError=['cannot delete tcpip object ' Msng.Address{1}  ':' ...
                         num2str(Msng.Address{2}) ];
    end

    try
        Msng.StreamResource=tcpip(Msng.Address{1},Msng.Address{2},'Name',Msng.Name);
    catch
        Msng.LastError=['cannot create tcpip object ' Msng.Address{1}  ':' ...
                         num2str(Msng.Address{2}) ];
    end

    try
        if strcmp(Msng.StreamResource.status,'closed')
            fopen(Msng.StreamResource);
        end
        success = true;
    catch
        Msng.LastError=['tcp stream on ' Msng.Address{1}  ':' ...
                         num2str(Msng.Address{2}) ' cannot be opened'];
    end
    
    % setup the receiver callback
end
