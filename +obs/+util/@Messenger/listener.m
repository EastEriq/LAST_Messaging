function listener(Msng,Type,Data)
% This function is set as callback when a full udp datagram is received
%  It reads the datagram, interprets as command string, and evaluates it
%
% this function could logically be a private method of the Messenger class,
% but that seems not to sit well with the instrument callback mechanism,
% which IIUC evaluates it in the base workspace
   cmd=char(fread(Msng.StreamResource)'); % fread allows longer than 128 bytes
   % diagnostic echo
   Msng.report("received '" + cmd + "' from " + Data.Data.DatagramAddress + ':'+...
       num2str(Data.Data.DatagramPort) + " on " + datestr(Data.Data.AbsTime) +'\n')
   
   % try to interpret cmd, which could be either a simple char string or
   %  a json cast of a cell, mappable onto a Message
   M=obs.util.Message(cmd);
   % fill in some fields at reception
   M.From=[Data.Data.DatagramAddress ':' Data.Data.DatagramPort];
   M.ReceivedTimestamp=datenum(Data.Data.AbsTime);
   % try to execute the command (in which context? base?)
   try
       output=eval(M.Command);
       if M.RequestReply
           % send back a message with output in .Content and empty .Command
       end
   catch
       Msng.reportError('illegal command received');
   end
end