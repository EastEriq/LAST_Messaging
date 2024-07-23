function resp=query(Msng,command,evalInListener)
% sends a command through the messenger, waits for the reply (blocking)
% evalInListener true means that the command which is sent must be
%  evaluated, in the *destination* messenger, in the workspace of its
%  listener function. This applies only to special commands like
%  whoIsThere. Normally this argument is false.
  
    if ~exist('evalInListener','var')
        evalInListener=false;
    end

    resp=[];
    Msng.LastMessage=[];
    nid=Msng.send(command,Msng.StreamResource.Timeout,evalInListener);

    if ~isempty(Msng.LastError)
        % if send() was problematic, don't expect a reply
        return
    end
    
    % analyze the call chain and find out if we're in a callback. The code
    %  makes sense, but probably we're never really in this case, even in
    %  roundtrips. Why?
    ds=dbstack;
    callchain={ds.name};
    calledFromCallback = any(contains(callchain,{'timercb','instrcb'}));
    
    % poll for an incoming reply within a timeout
    started=now;
    nbytes1=0;
    replyReceived=false;
    M=[];
    while ~replyReceived && (now-started)<Msng.StreamResource.Timeout/3600/24
        if Msng.CallbackRespond && ~calledFromCallback
            % the listener callback fills the content automatically, when
            %  the stream is completed by a terminator
        else
            % If we can't rely on the automatic callback (for instance
            %  because query is already called by a non interruptible
            %  callback, like that of a timer or a notify, let's sit here
            %  and check for incoming bytes (blocking). When the count stops
            %  increasing, call explicitely the listener function, which
            %  fills Msng.LastMessage. We can do that because the i/o
            %  StreamResource is accessible from any context....
            nbytes=Msng.StreamResource.BytesAvailable;
            % rely on that messages burst in quickly. If the number of
            %  bytes in buffer hasn't increased in the last 10ms, there
            %  should be something to process. Fragile.
            if nbytes==nbytes1 && nbytes>0 || nbytes==Msng.StreamResource.InputBufferSize
                Msng.datagramParser()
            end
            nbytes1=nbytes;
        end
        % note that instead of the reply to the query, a command
        %  from somewhere else (i.e. a query from another monitoring
        %  process) could have sneaked in. datagramParser will
        %  treat that, but we are not yet done and must still wait
        %  for our reply. What discriminates is: empty .Command,
        %  .ReplyTo matching this Messenger (we don't contemplate
        %  for the moment messages with a forwarding reply instruction)
        %  and negative .RequestReplyWithin
        M=Msng.LastMessage;
        replyReceived = ~isempty(M) && ...
                        isempty(M.Command) && ~isempty(M.Content) && ...
                        strcmpi(M.ReplyTo.Host,Msng.DestinationHost) && ...
                        M.ReplyTo.Port==Msng.StreamResource.RemotePort;
        pause(0.01)
    end
    
    if ~isempty(M)
        if ~isempty(M.ProgressiveNumber) && ...
            nid ~= M.ProgressiveNumber
            Msng.report('warning: reply #%d received for message #%d\n',...
                M.ProgressiveNumber,nid)
        end
        if ~isempty(M.Content)
            resp=jsondecode(M.Content);
        else
            % typically the result of a query of a command with no return
            %  argument
            resp=[];
        end
        Msng.LastError='';
    else
        if isa(command,'obs.util.Message')
            command=command.Command;
        end
        if isempty(Msng.Id)
            Msng.reportError('%s timed out waiting for a reply to "%s"',...
                Msng.Name, command)
        else
            Msng.reportError('%s timed out waiting for a reply to "%s"',...
                Msng.Id, command)
        end
    end