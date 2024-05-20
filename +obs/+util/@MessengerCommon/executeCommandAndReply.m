function executeCommandAndReply(Msng,M)
% execute the command received by the Messenger inside M.Command, trapping
%  eventual errors, and issue the result in a reply, if the incoming message
%  asked for it.
% Common code called by both Messenger.datagramParser and
%  Listener.datagramParser. Even though it is an ancillary, I think it
%  cannot be private, to be seen by the descendents.

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
            Msng.ExecutingCommand=M.Command;
            if M.RequestReplyWithin>=0 && ...
                (now-M.SentTimestamp)*86400 < M.RequestReplyWithin
            % check whether it is possible to get one output from the
            %  command only if a reply is required (and the time is not
            %  expired, with a harness for desynchronized clocks)
                % The following is an expensive way of dealing with either
                %  one output or none: try first assuming that there is a
                %  result
                try
                    if M.EvalInListener
                        out=eval(M.Command);
                    else
                        out=evalin('base',M.Command);
                    end
                catch OutputError
                % If the above gave a lhs assignment error, evaluate without
                %  asking for a result. We need to be specific, otherwise a
                %  a command which does provide an output but errors during
                %  its execution would be executed twice.
                % TODO, make sure that this traps all the relevant cases
                %  correctly
                % OutputError.identifier
                    thisStack=dbstack;
                    if any(strcmp(OutputError.identifier,...
                       {'MATLAB:maxlhs','MATLAB:m_invalid_lhs_of_assignment'})) && ...
                            strcmp(OutputError.stack(1).name, thisStack(1).name)
                        if M.EvalInListener
                            eval(M.Command);
                        else
                            evalin('base',M.Command);
                        end
                    else
                        throw(OutputError)
                    end
                end
            else
                % no reply asked for sure
                if M.EvalInListener
                    eval(M.Command);
                else
                    evalin('base',M.Command);
                end
            end
            Msng.ExecutingCommand='';
        end
    catch CommandError
        try
            Msng.reportError('illegal messenger command "%s" received from %s:%d\n  %s',...
                M.Command, M.ReplyTo.Host, M.ReplyTo.Port, CommandError.message);
            Msng.ExecutingCommand='';
            % attempt to command .reportError back in the caller. Beware of
            %  possible side effects (for example, quotes in ME.message itself
            %  can cause problems).
            % Errors in this command may cause infinite loops
            quotexpanded=replace(CommandError.message,'''','''''');
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
        out=CommandError;
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
    catch ReplyError
        Msng.reportError('problem sending the json encoded result of command "%s"',...
            M.Command);
        if (now-M.SentTimestamp)*86400 < M.RequestReplyWithin
            % send back a message with Error! in .Content and empty .Command
            Msng.reply(jsonencode(ReplyError.message),M.ProgressiveNumber); % double quotes for json
            % TODO a bit more sophystication, like adding a field .Status
            %  to the message, or sending back a command .reportError
            %  for the receiving messenger (might become cumbersome)
        end
    end
