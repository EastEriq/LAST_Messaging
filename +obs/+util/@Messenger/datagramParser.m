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

    % Store the message received, so that the process can access it.
    %  E.g. to check for a reply to a query
    Msng.LastMessage=M;

    % try to execute the command. Could use evalc() instead of eval to retrieve
    %  an eventual output in some way. Out=eval() alone would error on
    %  for instance assignments. OTOH, with evalc() the screen output will have to be
    %  parsed in order to get information out of it.
    % And, there is the issue of in which context to evaluate, which ultimately
    %  forces the use of evalin().
    try
        out='';
        if ~isempty(M.Command)
            % this is an expensive way of dealing with either one output or none
            Msng.ExecutingCommand=M.Command;
            try
                if M.EvalInListener
                    out=eval(M.Command);
                else
                    out=evalin('base',M.Command);
                end
            catch
                if M.EvalInListener
                    eval(M.Command);
                else
                    evalin('base',M.Command);
                end
            end
            Msng.ExecutingCommand='';
        end
    catch ME
        try
            Msng.reportError('illegal messenger command "%s" received from %s:%d\n  %s',...
                M.Command, M.ReplyTo.Host, M.ReplyTo.Port, ME.message);
            Msng.ExecutingCommand='';
            % attempt to command .reportError back in the caller. Beware of
            %  possible side effects (for example, quotes in ME.message itself
            %  can cause problems).
            % Errors in this command may cause infinite loops
            quotexpanded=replace(ME.message,'''','''''');
            quotexpanded=replace(quotexpanded,newline,' ');
            R=obs.util.Message(sprintf('Msng.reportError(''%%s receiver reports: %s'',Msng.Id)',...
                quotexpanded));
            R.ProgressiveNumber=M.ProgressiveNumber;
            R.RequestReplyWithin=-1;
            R.EvalInListener=true;
            % change Msng.StreamResource properties (*not* Msng default
            %  destination) according to the origin of the message
            Msng.StreamResource.RemoteHost=M.ReplyTo.Host;
            Msng.StreamResource.RemotePort=M.ReplyTo.Port;
            Msng.send(R);
        catch
            % with overflown buffer, I've seen reaching here with 
            %  M.Command= a truncated json message, and empty M.Host
            Msng.reportError('cannot report back to the sender what is wrong with the message received, giving up')
        end
        % a simpler solution is to set out=ME, and return the ME structure
        %  as result. But the above .send bypasses sending the reply below?
        out=ME;
    end

    try
        if (now-M.SentTimestamp)*86400 < M.RequestReplyWithin
            % change Msng.StreamResource properties (*not* Msng default
            %  destination) according to the origin of the message
            Msng.StreamResource.RemoteHost=M.ReplyTo.Host;
            Msng.StreamResource.RemotePort=M.ReplyTo.Port;
            % send back a message with output in .Content and empty .Command
            Msng.reply(jsonencode(out,'ConvertInfAndNaN',false),M.ProgressiveNumber);
            % note: found a corner case for which jsonencode is erroneously
            %       verbose: unitCS.connect with an unreachable focuser,
            %       tries to read the public focuser properties despite
            %       not requested. Go figure which bug.
        end
    catch ME
        Msng.reportError('problem sending the json encoded result of command "%s"',...
            M.Command);
        if (now-M.SentTimestamp)*86400 < M.RequestReplyWithin
            % send back a message with Error! in .Content and empty .Command
            Msng.reply(jsonencode(ME.message),M.ProgressiveNumber); % double quotes for json
            % TODO a bit more sophystication, like adding a field .Status
            %  to the message, or sending back a command .reportError
            %  for the receiving messenger (might become cumbersome)
        end
    end
end
