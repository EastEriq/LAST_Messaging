function start(L)
% start the listener, opening the port and entering into an infinite loop
%  the loop will end if the keyword 'return' is received as command

% trimming of Messenger.connect:
    % open the udp stream associated to the messenger and
    %  setup a callback function for the receiver. Terminator is left as LF
   success = 0;

    try
        if strcmp(L.StreamResource.status,'closed')
            fopen(L.StreamResource);
            flushinput(L.StreamResource);
            L.report('flushed, destination host=%s\n',L.StreamResource.RemoteHost)
        end
        success = true;
    catch
        L.reportError('udp stream on %s:%d cannot be opened',...
            L.DestinationHost,L.DestinationPort);
    end
    
    
% infinite listener loop 
    goOn=true;
    while success && goOn
        pause(0.01)
        if L.StreamResource.BytesAvailable>0
            % udp messages should be contained in a single packet, no? So
            % we can assume that if there are bytes, it is a complete
            % message.
            goOn=L.datagramParser;
        end
    end

% trimming of Messenger.disconnect:
    % close the udp stream, but don't delete it from workspace
    %  and delete the receiver callback function (policy for both still TBD)
    if isvalid(L.StreamResource)
         fclose(L.StreamResource);
    else
        % delete it only if invalid (can happen when recreating
        %  an object, when the old is deleted)
        delete(L.StreamResource)
        %         Msng.reportError(['invalid udp resource while attempting to ',...
        %                           'disconnect messenger %s'], L.Id)
    end

end