function goOn=datagramParser(Msng)
% Variation of the Messenger callback function, here called instead
%  explicitely when a full udp datagram is received
%  It reads the datagram, interprets as command string, and evaluates it
%
% this function could logically be a private method of the Messenger class,
% but that seems not to sit well with the instrument callback mechanism,
% which IIUC evaluates it in the base workspace
    goOn=true; % will become false if 'return' is received

    if Msng.StreamResource.BytesAvailable>0
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
        % diagnostic echo
        if Msng.Verbose==2 % in truth so far I said that Verbose is a boolean
            Msng.report("received '" + stream + "' from " + ...
                M.From.Host + ':' + M.From.Port + " on " +...
                datestr(M.ReceivedTimestamp) +'\n')
        end
    catch
        Msng.reportError('stream "%s"received is not a valid message!',stream)
        return
    end

    % Store the message received, so that the process can access it.
    %  E.g. to check for a reply to a query
    Msng.LastMessage=M;

    if isempty(M.ReplyTo.Host)
        M.ReplyTo.Host=M.From.Host;
    end
    if isempty(M.ReplyTo.Port)
        M.ReplyTo.Port=M.From.Port;
    end

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
            if strcmp(M.Command,'return')
                goOn=false; % will be used as harness to break the loop
            end
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
        end
    catch
        Msng.reportError('illegal messenger command "%s" received from %s:%d',...
            M.Command,M.From.Host,M.From.Port);
    end

    try
        if M.RequestReply
            % change Msng properties according to the origin of the message
            Msng.DestinationHost=M.ReplyTo.Host;
            Msng.DestinationPort=M.ReplyTo.Port;
            % send back a message with output in .Content and empty .Command
            Msng.reply(jsonencode(out,'ConvertInfAndNaN',false));
            % note: found a corner case for which jsonencode is erroneously
            %       verbose: unitCS.connect whith an unreachable focuser,
            %       tries to read the public focuser properties despite
            %       not requested. Go figure which bug.
        end
    catch
        Msng.reportError('problem encoding in json the result of command "%s"',...
            M.Command);
        if M.RequestReply
            % send back a message with Error! in .Content and empty .Command
            Msng.reply('"Error!"'); % double quotes for json
        end
    end
end
