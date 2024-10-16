function success=connect(Msng)
% open the udp stream associated to the messenger and
%  setup a callback function for the receiver. Terminator is left as LF
% This method only prepares the local side of the messenger for
%  communication; it doesn't attempt to check if at the pointed end there is
%  a corresponding messenger. For that, the method .areYouThere can be
%  used.
   success = 0;

    try
        if strcmp(Msng.StreamResource.status,'closed')
            fopen(Msng.StreamResource);
        end
        success = true;
    catch
        Msng.reportError('udp stream on %s:%d cannot be opened',...
            Msng.DestinationHost,Msng.DestinationPort);
    end
    
    % setup the receiver callback, if so required
    Msng.CallbackRespond=Msng.CallbackRespond;

end
