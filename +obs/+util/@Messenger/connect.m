function success=connect(Msng)
% open the udp stream associated to the messenger and
%  setup a callback function for the receiver. Terminator is left as LF
   success = 0;

    try
        if strcmp(Msng.StreamResource.status,'closed')
            fopen(Msng.StreamResource);
        end
        success = true;
    catch
        Msng.LastError=['udp stream on ' Msng.DestinationHost  ':' ...
                         num2str(Msng.DestinationPort) ' cannot be opened'];
    end
    
    % setup the receiver callback
end
