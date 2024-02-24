function connectionChangedFcn_photon(Q)
    send(Q.pq, 'connectionChanged:photon');      
    send(Q.q, 1);    
end