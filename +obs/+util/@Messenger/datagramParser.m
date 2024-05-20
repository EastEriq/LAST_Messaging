function datagramParser(Msng,~,Data)
% This function is set as callback when a full udp datagram is received
%  It reads the datagram, interprets as command string, and evaluates it
%
% this function could logically be a private method of the Messenger class,
% but that seems not to sit well with the instrument callback mechanism,
% which IIUC evaluates it in the base workspace

    if Msng.StreamResource.BytesAvailable>0
        if Msng.StreamResource.BytesAvailable>=Msng.StreamResource.InputBufferSize
            % flush the whole buffer, because in principle the overwritten
            %  messages in it could contain corrupted commands. In practice,
            %  instead, one finds in it many usable messages and some
            %  truncated ones. We could try to decode each one of them in a
            %  loop instead.
            Msng.reportError('%s input buffer overflow! Flushing it',Msng.Id)
            %  fclose(Msng.StreamResource);
            %  fopen(Msng.StreamResource);
            % flushinput doesn't remove pending callbacks for the terminators
            %  received - the function may be called again several times
            %  while the stream has been emptied.
            flushinput(Msng.StreamResource)
            return
        end
        stream=char(fread(Msng.StreamResource)'); % fread allows longer than 128 bytes, fgetl no
    else
        Msng.reportError('udp input buffer for %s empty, nothing to process',...
            Msng.Id)
        return
    end

    if ~exist('Data','var')
        Data=struct('Data',struct('AbsTime',now,'DatagramAddress','','DatagramPort',[]));
    end

    % reconstruct the incoming Message
    try
        M=obs.util.Message(stream);
        % fill in some fields at reception: with udp objects we have the origin
        %  address only if the function is called as a callback. Perhaps with
        %  udpport objects we would have it more naturally from the result of
        %  read()?
        M.ReceivedTimestamp=datenum(Data.Data.AbsTime);
        if ~isempty('M.ReplyTo.Host') && isempty(Data.Data.DatagramAddress)
            Data.Data.DatagramAddress=M.ReplyTo.Host;
        end
        if ~isempty('M.ReplyTo.Port') && isempty(Data.Data.DatagramPort)
            Data.Data.DatagramPort=M.ReplyTo.Port;
        end
        % diagnostic echo from the message content
        if Msng.Verbose==2 % in truth so far I said that Verbose is a boolean
            Msng.report("received '" + stream + "' from " + ...
                M.ReplyTo.Host + ':' + ...
                num2str(Data.Data.DatagramPort) + " in " +...
                (M.ReceivedTimestamp-M.SentTimestamp)*86400000 +'msec\n')
        end
    catch
        % diagnostic echo
        if Msng.Verbose==2 && nargin==3 % in truth so far I said that Verbose is a boolean
            Msng.report("received '" + stream + "' from " + ...
                Data.Data.DatagramAddress + ':'+...
                num2str(Data.Data.DatagramPort) + " on " +...
                datestr(Data.Data.AbsTime) +'\n')
        end
        Msng.reportError('stream "%s" received is not a valid message!',stream)
        return
    end

    % safeguard filling of M.ReplyTo if by mistake is not provided by the
    %  sender
    if isempty(M.ReplyTo.Host) && nargin==3
        M.ReplyTo.Host = Data.Data.DatagramAddress;
    end
    if isempty(M.ReplyTo.Port) && nargin==3
        M.ReplyTo.Port = Data.Data.DatagramPort;
    end
 
    Msng.executeCommandAndReply(M)

end
