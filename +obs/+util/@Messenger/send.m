function send(Msng,command,requestReply)
% send a message through the Messenger channel
% 
% command: a string, containing a Matlab command, or
%          a Message object, containing all fields.
% reply: boolean, if a reply is demanded (default true if omitted)
    if ~exist('reply','var')
        requestReply=true;
    end

    if ischar(command)
        M=obs.util.Message(command);
    elseif isa(command,'obs.util.Message')
        M=command;
    else
        Msng.reportError('wrong type of message to send')
        return
    end

   % fill all the other fields of the message
   M.From=resolvehost('localhost','address');
   M.SentTimestamp=now;
   M.RequestReply=requestReply;
   
   % flatten it and dispatch it
   fwrite(Msng.StreamResource,jsonencode(M));