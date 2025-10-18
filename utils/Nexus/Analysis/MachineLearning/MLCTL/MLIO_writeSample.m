function sampleFile =  MLIO_writeSample(FID, DF_smp, sampleAddress, fileType)
    fld_DS=FID.fld_DS;
    conn_index=FID.conn_index;
    files = dir(fld_DS);
    nSamples = sum(~[files.isdir]);   % counts only files    
    switch fileType
        case "csv"

        case "hdf5"         
            % QUERY DATABASE FOR PRE-EXISTING SAMPLE
            sampleFile = MLIO_queryDB(conn_index,sampleAddress,"sampleFIle");
            if isempty(sampleFile)
                sampleFile = sprintf("%0*d.hdf5",10,nSamples+1);
            end           
            sampleFile_full = fullfile(fld_DS,sampleFile);
            MLIO_writeDF2HDF5(DF_smp, sampleFile_full)
            % info = h5info(fileTag);
            % readGroup(info,fileTag)
    end
end