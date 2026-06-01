function [h, p, t] = qw_statTest(x,y)
% statistical test using either t-test or Mann-Whitney U test based on if x/y are from normal distribution
% t=1, t-test
% t=2, Mann-Whitney U test

[H1,P1] = kstest((x-mean(x)));
[H2,P2] = kstest((y-mean(y)));


if H1 == 0 & H2 == 0
    [h p] = ttest2(x, y);
    t = 1; % student's t test
else
    [p h] = ranksum(x,y);
    t = 2;
end
