function resp=query(Msng,command,evalInListener)
% sends a command through the messenger, waits for the reply (blocking)
  
    if ~exist('evalInListener','var')
        evalInListener=false;
    end

    Msng.LastMessage=[];
    send(Msng,command,true,evalInListener);
    
    % poll for an incoming reply within a timeout
    started=now;
    while isempty(Msng.LastMessage) && (now-started)<Msng.StreamResource.Timeout/3600/24
        pause(0.01)
    end
    
    if ~isempty(Msng.LastMessage)
        resp=jsondecode(Msng.LastMessage.Content);
    else
        Msng.reportError('Timeout while waiting for a reply message')
        resp=[];
    end