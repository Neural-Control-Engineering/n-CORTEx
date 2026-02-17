function [h, p, t] = qw_statPairedTest(x,y)
% statistical test using either paired t-test or Wilcoxon signed rank test based on if x/y are from normal distribution
% t=1, t-test
% t=2, Wilcoxon signed rank test

[H1,P1] = kstest((x-mean(x)));
[H2,P2] = kstest((y-mean(y)));

if H1 == 0 & H2 == 0
    [h p] = ttest(x, y);
    t = 1;
else
    [p h] = signrank(x,y);
    t=2;
end
