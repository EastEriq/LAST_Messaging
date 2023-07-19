function datagramParser(Msng,~,Data)
% This function is set as callback when a full udp datagram is received
%  It reads the datagram, interprets as command string, and evaluates it
%
% this function could logically be a private method of the Messenger class,
% but that seems not to sit well with the instrument callback mechanism,
% which IIUC evaluates it in the base workspace
    if Msng.StreamResource.BytesAvailable>0
        stream=char(fread(Msng.StreamResource)'); % fread allows longer than 128 bytes, fgetl no
    else
        Msng.reportError('udp input buffer for %s empty, nothing to process',...
                          Msng.Id)
        return
    end
   % diagnostic echo
   if Msng.Verbose==2 && nargin==3 % in truth so far I said that Verbose is a boolean
       Msng.report("received '" + stream + "' from " + ...
                    Data.Data.DatagramAddress + ':'+...
                    num2str(Data.Data.DatagramPort) + " on " +...
                    datestr(Data.Data.AbsTime) +'\n')
   end
   get(Msng.StreamResource)
   
   % reconstruct the incoming Message
   M=obs.util.Message(stream);
   % fill in some fields at reception: with udp objects we have the origin
   %  address only if the function is called as a callback. Perhaps with
   %  udpport objects we would have it more naturally from the result of
   %  read()?
   if nargin==3
       M.From=[Data.Data.DatagramAddress ':' num2str(Data.Data.DatagramPort)];
       M.ReceivedTimestamp=datenum(Data.Data.AbsTime);
   end
   
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
           % this is an expensive way of dealing with either one output or none
           try
               if M.EvalInListener
                   out=eval(M.Command);
               else
                   out=evalin('base',M.Command);
               end
           catch
               if M.EvalInListener
                   eval(M.Command);
               else
                   evalin('base',M.Command);
               end
            end
       end
   catch
       Msng.reportError('illegal messenger command "%s" received from %s',...
                                M.Command,M.From);
   end
   try
       if M.RequestReply
           % change Msng properties according to the origin of the message
           [Msng.RemoteHost,remain]=strtok(M.From,':');
           Msng.RemotePort=num2str(strrep(remain,':',''));
           % send back a message with output in .Content and empty .Command
           Msng.reply(jsonencode(out,'ConvertInfAndNaN',false));
           % note: found a corner case for which jsonencode is erroneously
           %       verbose: unitCS.connect whith an unreachable focuser,
           %       tries to read the public focuser properties despite
           %       not requested. Go figure which bug.
       end
   catch
       Msng.reportError('problem encoding in json the result of command "%s"',...
                                M.Command);
       if M.RequestReply
           % send back a message with Error! in .Content and empty .Command
           Msng.reply('"Error!"'); % double quotes for json
       end
   end
end
