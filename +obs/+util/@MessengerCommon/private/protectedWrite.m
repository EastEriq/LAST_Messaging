function protectedWrite(Msng,flat)
% fwrite to Messenger.StreamResource, with checks about the its validity
    sr=Msng.StreamResource;
        % I've seen this failing on startup of a blind slave, which is
        %  already interrogated by a monitor - maybe because the
        %  Streamresource is not yet set?
        % ???? access once to avoid that Msng.DestinationHost becomes
        % something nonsenical as 'MasterResponder.send' or 
        %  '{obs.util.Listener}' if running in a headless slave ???
    if isempty(sr.RemoteHost)
        Msng.reportError(sr.RemoteHost)
    end
    if isa(sr,'udp') && isvalid(sr) && strcmp(sr.Status,'open')
        fwrite(Msng.StreamResource,flat);
    else
        if isa(sr,'udp')
            if isvalid('sr')
                Msng.reportError('.StreamResource is of class udp but invalid')
            else
                Msng.reportError('.StreamResource is %s',sr.Status)
            end
        else
            Msng.reportError('.StreamResource is of invalid class %s',class(sr))
        end
    end
