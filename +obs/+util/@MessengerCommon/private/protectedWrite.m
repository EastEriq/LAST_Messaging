function protectedWrite(Msng,flat)
% fwrite to Messenger.StreamResource, with checks about the its validity
    sr=Msng.StreamResource;
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
