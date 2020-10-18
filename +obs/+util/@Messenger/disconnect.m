function disconnect(Msng)
% close the serial stream, but don't delete it from workspace
%  and delete the receiver callback function (policy for both still TBD)
   fclose(Msng.StreamResource);
   
   Msng.StreamResource.DatagramReceivedFcn='';
end
