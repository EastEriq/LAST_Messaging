function send(Msng,command)
% send a message through the Messenger channel
% 
% command: a string, containing a Matlab command, or
%          a Message object, containing all fields
    if ischar(command)
        M=obs.util.Message(command);
    elseif isa(command,'obs.util.Message')
        M=command;
    else
        Msng.reportError('wrong type of message to send')
        return
    end

   % fill all the other fields of the message
   
   % flatten it and dispatch it
   fwrite(Msng.StreamResource,jsonencode(M));