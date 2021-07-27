function resp=query(Msng,command,evalInListener)
% sends a command through the messenger, waits for the reply (blocking)
% evalInListener true means that the command which is sent must be
%  evaluated, in the *destination* messenger, in the workspace of its
%  listener function. This applies only to special commands like
%  whoIsThere. Normally this argument is false.
  
    if ~exist('evalInListener','var')
        evalInListener=false;
    end

    Msng.LastMessage=[];
    send(Msng,command,true,evalInListener);

    if ~isempty(Msng.LastError)
        % if send() was problematic, don't expect a reply
        return
    end
    
    % poll for an incoming reply within a timeout
    started=now;
    nbytes1=0;
    while isempty(Msng.LastMessage) && (now-started)<Msng.StreamResource.Timeout/3600/24
        if Msng.CallbackRespond
            % the listener callback fills the content automatically, when
            %  the stream is completed by a terminator
        else
            % let's check for incoming bytes. When the count stops
            %  increasing, call explicitely the listener function, which
            %  fills Msng.LastMessage. We can do that because the i/o
            %  StreamResource is accessible from any context....
            nbytes=Msng.StreamResource.BytesAvailable;
            if nbytes==nbytes1 && nbytes>0
                Msng.listener()
            end
            nbytes1=nbytes;
        end
        pause(0.01)
    end
    
    if ~isempty(Msng.LastMessage)
        if ~isempty(Msng.LastMessage.Content)
            resp=jsondecode(Msng.LastMessage.Content);
        else
            % typically the result of a query of a command with no return
            %  argument
            resp=[];
        end
        Msng.LastError='';
    else
        Msng.reportError('Timeout while waiting for a reply message')
        resp=[];
    end