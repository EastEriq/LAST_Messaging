function disconnect(Msng)
% close the udp stream, but don't delete it from workspace
%  and delete the receiver callback function (policy for both still TBD)
    if isvalid(Msng.StreamResource)
        Msng.StreamResource.DatagramReceivedFcn='';
        fclose(Msng.StreamResource);
    else
        % delete it only if invalid (can happen when recreating
        %  an object, when the old is deleted)
        delete(Msng.StreamResource)
%         Msng.reportError(['invalid udp resource while attempting to ',...
%                           'disconnect messenger %s'], Msng.Id)
    end
end
