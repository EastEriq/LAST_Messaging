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
    catch ME
        try
            Msng.reportError('illegal messenger command "%s" received from %s:%d\n  %s',...
                M.Command, M.ReplyTo.Host, M.ReplyTo.Port, ME.message);
            % attempt to command .reportError back in the caller. Beware of
            %  possible side effects (for example, quotes in ME.message itself
            %  can cause problems).
            % Errors in this command may cause infinite loops
            quotexpanded=replace(ME.message,'''','''''');
            R=obs.util.Message(sprintf('Msng.reportError(''receiver reports: %s'')',...
                quotexpanded));
            R.ProgressiveNumber=M.ProgressiveNumber;
            R.RequestReply=false;
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
        if M.RequestReply
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
        if M.RequestReply
            % send back a message with Error! in .Content and empty .Command
            Msng.reply(jsonencode(ME.message),M.ProgressiveNumber); % double quotes for json
            % TODO a bit more sophystication, like adding a field .Status
            %  to the message, or sending back a command .reportError
            %  for the receiving messenger (might become cumbersome)
        end
    end
end
