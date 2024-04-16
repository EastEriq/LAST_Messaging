function nid=send(Msng,command,requestReply,evalInListener)
% send a message through the Messenger channel
% 
% command: a string, containing a Matlab command, or
%          a Message object, containing all fields.
% requestReply: boolean, if a reply is demanded (default false if omitted)
% evalInListener: boolean, true for the special case of queries about the
%                 Receiver (default false if omitted)
% Optionally, the number of the sent message is returned, so that it can be
%  compared to the answer received when queried, to make sure that there is
%  no answer pileup
    
    % update counter here so it is available if only the command string is
    %  passed
    Msng.MessagesSent=Msng.MessagesSent+1;

    if ischar(command)
        M=obs.util.Message(command);
        M.ProgressiveNumber=Msng.MessagesSent;
        if ~exist('requestReply','var')
            requestReply=false;
        end
        if ~exist('evalInListener','var')
            evalInListener=false;
        end
        M.RequestReply=requestReply;
        M.EvalInListener=evalInListener;
        % fallback, for queries it will cause a mismatch warning at the receiver
    elseif isa(command,'obs.util.Message')
        M=command;
    else
        Msng.reportError('%s: wrong type of message to send',Msng.Name)
        nid=[];
        return
    end

   % fill all the other fields of the message
   % for now; decide a policy for supplying a different ReplyTo later
   if isempty(M.ReplyTo.Host)
       M.ReplyTo.Host=Msng.localHostName;
   end
   if isempty(M.ReplyTo.Port)
       M.ReplyTo.Port=Msng.LocalPort;
   end
   M.SentTimestamp=now;
   
   nid=M.ProgressiveNumber;
   
   % flatten it and dispatch it
   try
       flat=jsonTruncate(Msng,M);
       fwrite(Msng.StreamResource,flat);
       Msng.LastError='';
   catch
       Msng.reportError(['message datagram could not be written '...
                                 'to udp resource %s'],Msng.Name)
   end
