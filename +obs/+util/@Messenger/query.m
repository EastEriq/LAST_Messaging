function resp=query(Msng,command)
% sends a command through the messenger, waits for the reply (blocking)
  Msng.LastMessage=[];
  send(Msng,command,true);
  
  % poll for an incoming reply within a timeout
  started=now;
  while isempty(Msng.LastMessage) && (now-started)<Msng.StreamResource.Timeout
      pause(0.01)
  end
  
  if ~isempty(Msng.LastMessage)
      resp=jsondecode(Msng.LastMessage.Content);
  else
      Msng.reportError('Timeout while waiting for a reply message')
      resp=[];
  end