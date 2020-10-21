function send(Msng,command,requestReply,evalInListener)
% send a message through the Messenger channel
% 
% command: a string, containing a Matlab command, or
%          a Message object, containing all fields.
% requestReply: boolean, if a reply is demanded (default true if omitted)
% evalInListener: boolean, true for the special case of queries about the
%                 Receiver (default false if omitted)
    if ~exist('requestReply','var')
        requestReply=true;
    end

    if ~exist('evalInListener','var')
        evalInListener=false;
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
   M.From=Msng.Name;
   M.SentTimestamp=now;
   M.RequestReply=requestReply;
   M.EvalInListener=evalInListener;
   
   Msng.MessagesSent=Msng.MessagesSent+1;
   M.ProgressiveNumber=Msng.MessagesSent;
   
   % flatten it and dispatch it
   flat=jsonTruncate(Msng,M);
   fwrite(Msng.StreamResource,flat);
