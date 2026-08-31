function nexAtlas_annotateChannels(nexon, subjectID, atlas)
% Inject atlas MAP region and probability into the nexon channel registry.
%
%   nexon      Nexon handle object
%   subjectID  key as used in registry.SUBJ (e.g. "subj_20115_20250407")
%   atlas      struct from nexAtlas_load
%
% Writes into nexon.console.BASE.registry.SUBJ.(subjectID).atlasAnnotation:
%   .channel_indices  (n_ch,)  — Neuropixels channel indices
%   .channel_depths   (n_ch,)  — µm from probe tip
%   .regionMAP        (n_ch,)  string — MAP region from posterior
%   .region_prob      (n_ch,)  float  — posterior probability of MAP label
%
% The annotation is the lookup table for nexAtlas_lookupChannels.
% CLR bus gains "ax--regionMAP" and "ax--region_prob" once the channel DF
% axes are augmented to include these fields (see nexAtlas_lookupChannels).

    post    = atlas.posteriors.canonical;         % (n_ch × n_reg)
    regions = atlas.prior.region_acronyms(:)';  % (1 × n_reg) string

    [prob, regIdx] = max(post, [], 2);           % MAP label index + prob per channel

    annotation.channel_indices = atlas.prior.channel_indices;
    annotation.channel_depths  = atlas.prior.channel_depths;
    annotation.regionMAP       = regions(regIdx);   % (n_ch,) string
    annotation.region_prob     = prob;               % (n_ch,) double

    nexon.console.BASE.registry.SUBJ.(char(subjectID)).atlasAnnotation = annotation;
end
