function send(Msng,command,requestReply,evalInListener)
% send a message through the Messenger channel
% 
% command: a string, containing a Matlab command, or
%          a Message object, containing all fields.
% requestReply: boolean, if a reply is demanded (default false if omitted)
% evalInListener: boolean, true for the special case of queries about the
%                 Receiver (default false if omitted)
    if ~exist('requestReply','var')
        requestReply=false;
    end

    if ~exist('evalInListener','var')
        evalInListener=false;
    end

    if ischar(command)
        M=obs.util.Message(command);
    elseif isa(command,'obs.util.Message')
        M=command;
    else
        Msng.reportError('%s: wrong type of message to send',Msng.Name)
        return
    end

   % fill all the other fields of the message
   localhostname=char(java.net.InetAddress.getLocalHost.getHostName);
   % consider evolving .From into a structure
   M.From=sprintf('%s:%d',localhostname,Msng.LocalPort);
   M.SentTimestamp=now;
   M.RequestReply=requestReply;
   M.EvalInListener=evalInListener;
   
   Msng.MessagesSent=Msng.MessagesSent+1;
   M.ProgressiveNumber=Msng.MessagesSent;
   
   % flatten it and dispatch it
   try
       flat=jsonTruncate(Msng,M);
       fwrite(Msng.StreamResource,flat);
       Msng.LastError='';
   catch
       Msng.reportError(['message datagram could not be written '...
                                 'to udp resource %s'],Msng.Name)
   end