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
end