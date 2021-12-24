function disconnect(Msng)
% close the serial stream, but don't delete it from workspace
%  and delete the receiver callback function (policy for both still TBD)
    if isvalid(Msng.StreamResource)
        Msng.StreamResource.DatagramReceivedFcn='';
        fclose(Msng.StreamResource);
    else
        Msng.reportError(['invalid udp resource while attempting to ',...
                          'disconnect messenger %s'], Msng.Id)
    end
end
