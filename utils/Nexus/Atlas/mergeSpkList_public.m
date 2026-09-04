function spk = mergeSpkList_public(spk_list)
% Concatenate spike-level fields across triggers into a single spk struct.
% Per-unit metadata is unioned so units appearing only in later triggers
% are not dropped. unit_templates / spatial_profiles may have fewer rows
% than unit_ids (KS4 stores templates only for units passing a higher quality
% bar) — position-based indexing with zero-fill handles the mismatch.
    spk = spk_list{1};
    for t = 2:numel(spk_list)
        s = spk_list{t};
        spk.spike_times_s    = [spk.spike_times_s(:);    s.spike_times_s(:)];
        spk.spike_clusters   = [spk.spike_clusters(:);   s.spike_clusters(:)];
        spk.spike_amplitudes = [spk.spike_amplitudes(:); s.spike_amplitudes(:)];
        new_mask = ~ismember(s.unit_ids, spk.unit_ids);
        if any(new_mask)
            new_pos  = find(new_mask);
            spk.unit_ids         = [spk.unit_ids(:);         s.unit_ids(new_mask)];
            spk.unit_locs        = [spk.unit_locs;           s.unit_locs(new_mask, :)];
            spk.unit_quality     = [spk.unit_quality(:);     s.unit_quality(new_mask)];
            spk.unit_root_elecs  = [spk.unit_root_elecs(:);  s.unit_root_elecs(new_mask)];
            valid_t = new_pos(new_pos <= size(s.unit_templates,   1));
            n_fill  = numel(new_pos) - numel(valid_t);
            spk.unit_templates   = cat(1, spk.unit_templates, ...
                s.unit_templates(valid_t, :, :), ...
                zeros(n_fill, size(spk.unit_templates,2),   size(spk.unit_templates,3),   'like', spk.unit_templates));
            valid_s = new_pos(new_pos <= size(s.spatial_profiles, 1));
            n_fill  = numel(new_pos) - numel(valid_s);
            spk.spatial_profiles = [spk.spatial_profiles; ...
                s.spatial_profiles(valid_s, :); ...
                zeros(n_fill, size(spk.spatial_profiles,2), 'like', spk.spatial_profiles)];
        end
    end
end
