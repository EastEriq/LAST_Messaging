function resp=whoIsThere(Msng)
% simple method to get the receiving Messenger's name: issue a query to be
% evaluated in the listener workspace itself
    resp=query(Msng,'Msng.Name',true);