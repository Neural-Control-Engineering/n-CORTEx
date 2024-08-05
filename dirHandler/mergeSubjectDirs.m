function mergeSubjectDirs(expDir_local, expDir_cloud)
    subjectList_local = string(categorize(fullfile(expDir_local,"Subjects"),"isDir"));
    subjectList_cloud = string(categorize(fullfile(expDir_cloud,"Subjects"),"isDir"));
    subjectList_local = subjectList_local(~ismember(subjectList_local, subjectList_cloud));
    for i = 1:length(subjectList_local)
        subj = subjectList_local(i);
        mkdir(fullfile(expDir_cloud,"Subjects",subj));
    end
end