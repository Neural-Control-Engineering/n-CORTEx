function betaPeak = returnBetaPeak(periodic_params, paramIdx)
    betaRange = [13,30];
    betaCond = (periodic_params(:,1)>betaRange(1)&periodic_params(:,1)<betaRange(2));
    betaPeak = periodic_params(betaCond==1,paramIdx);
    if ~isempty(betaPeak)
        betaPeak = betaPeak(1);
    else
        betaPeak = 0;
    end
end