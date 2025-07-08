function idx_row = nex_searchRowAddress(DTS,rowAddress)
   if ~isempty(DTS)
       dtsCols = DTS.Properties.VariableNames;        
   else
       idx_row = [];
   end
end