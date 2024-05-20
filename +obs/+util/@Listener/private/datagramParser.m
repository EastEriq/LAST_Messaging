function goOn=datagramParser(Msng)
% Variation of the Messenger callback function, here called instead
%  explicitely when a full udp datagram is received
%  It reads the datagram, interprets as command string, and evaluates it
% Differently than the Messenger.datagramParser counterpart, here we don't
%  have a Data argument, and Msng.StreamResource.DatagramAddress and Port
%  are empty (matlab bug or feature?). In order to identify the provenance,
%  we have to rely on the correctness of .ReplyTo fields in the incoming
%  stream

    goOn=true; % will become false if 'return' is received

    if Msng.StreamResource.BytesAvailable>0
        if Msng.StreamResource.BytesAvailable>=Msng.StreamResource.InputBufferSize
            Msng.reportError('%s input buffer overflow!',Msng.Id)
        end
        stream=char(fread(Msng.StreamResource)'); % fread allows longer than 128 bytes, fgetl no
    else
        Msng.reportError('udp input buffer for %s empty, nothing to process',...
            Msng.Id)
        return
    end

    % reconstruct the incoming Message
    try
        M=obs.util.Message(stream);
        % fake the Data which would have been passed if callback
        M.ReceivedTimestamp=now;
        % diagnostic echo. This works if the stream is sane and allows to
        %  reconstruct a sane Message, i.e. not if there is buffer overflow
        if Msng.Verbose==2 % in truth so far I said that Verbose is a boolean
            Msng.report("received '" + stream + "' from " + ...
                M.ReplyTo.Host + ':' + ...
                num2str(M.ReplyTo.Port) + " in " +...
                (M.ReceivedTimestamp-M.SentTimestamp)*86400000 +'msec\n')
        end
    catch
        % diagnostic echo
        if Msng.Verbose==2 % in truth so far I said that Verbose is a boolean
            Msng.report("received '" + stream + " on " +...
                datestr(now) +'\n')
        end
        Msng.reportError('stream "%s" received is not a valid message!',stream)
        return
    end

    if strcmp(M.Command,'return')
        goOn=false; % will be used as harness to break the Listener loop
        return
    end
    
    executeCommandAndReply(Msng,M)
    
end
