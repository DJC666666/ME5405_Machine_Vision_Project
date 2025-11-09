function [mdl, bestC, bestKS, bestCvLoss, valAcc, gridTbl] = trainSVM_stratified(rootDir, targetSize, CList, kernelScaleList)
%TRAINSVM_STRATIFIED  Multi-class SVM (RBF) via ECOC with stratified split.
% Searches hyperparameters C and KernelScale; logs per-candidate CV loss and
% validation accuracy (trained with that candidate) into gridTbl.
%
% Returns:
%   mdl        - trained ECOC SVM model
%   bestC      - best BoxConstraint (C)
%   bestKS     - best KernelScale (numeric or 'auto')
%   bestCvLoss - best CV loss (5-fold on training split)
%   valAcc     - validation accuracy of the final best model
%   gridTbl    - table with rows: [targetSize, C, KernelScale, cvLoss, valAcc]

    if nargin<2 || isempty(targetSize), targetSize=[28 28]; end
    if nargin<3 || isempty(CList), CList = [0.1 1 10]; end
    if nargin<4 || isempty(kernelScaleList), kernelScaleList = {'auto',1,2,4}; end

    % -------- Load dataset and extract features --------
    D = dir(rootDir); D = D([D.isdir]);
    classes = string(setdiff({D.name},{'.','..'}));
    assert(~isempty(classes), 'No class subfolders found under: %s', rootDir);

    X = []; Y = strings(0,1);
    perClassIdx = struct();
    for ci = 1:numel(classes)
        cls = classes(ci);
        files = dir(fullfile(rootDir, cls, '*.mat'));
        feats_cls = [];
        for k = 1:numel(files)
            S  = load(fullfile(files(k).folder, files(k).name));
            fn = fieldnames(S); if isempty(fn), continue; end
            I  = S.(fn{1});
            Ipp  = preprocessGlyph(I, targetSize);
            feat = extractFeat(Ipp);
            feats_cls = [feats_cls; feat]; %#ok<AGROW>
        end
        if isempty(feats_cls), continue; end
        X = [X; feats_cls]; %#ok<AGROW>
        Y = [Y; repmat(cls, size(feats_cls,1), 1)]; %#ok<AGROW>
        perClassIdx.(cls) = (numel(Y)-size(feats_cls,1)+1) : numel(Y);
    end
    assert(~isempty(X),'No training samples loaded from dataset.');

    % -------- Stratified 75/25 split --------
    rng(0);
    trainMask = false(size(Y)); 
    testMask  = false(size(Y));
    for ci = 1:numel(classes)
        if ~isfield(perClassIdx, classes(ci)), continue; end
        idx = perClassIdx.(classes(ci));
        idx = idx(randperm(numel(idx)));
        nTr = max(1, round(0.75*numel(idx)));
        trainMask(idx(1:nTr)) = true;
        testMask( idx(nTr+1:end)) = true;
    end
    Xtr = X(trainMask,:); Ytr = Y(trainMask);
    Xte = X(testMask,:);  Yte = Y(testMask);

    % -------- Hyperparameter search with CV + per-candidate validation --------
    rows = {};
    bestCvLoss = inf; 
    bestC  = CList(1); 
    bestKS = kernelScaleList{1};

    for ciC = 1:numel(CList)
        for ciKS = 1:numel(kernelScaleList)
            ks = kernelScaleList{ciKS};
            try
                t = templateSVM('KernelFunction','rbf', ...
                                'KernelScale', ks, ...
                                'Standardize', true, ...
                                'BoxConstraint', CList(ciC));
                % 5-fold CV on training set
                cvmdl = crossval(fitcecoc(Xtr,Ytr, 'Learners',t,'Coding','onevsone','Prior','uniform'), ...
                                 'KFold',5);
                los = kfoldLoss(cvmdl);

                % Train candidate on training set and evaluate on validation set
                md_c = fitcecoc(Xtr,Ytr, 'Learners',t,'Coding','onevsone','Prior','uniform');
                if ~isempty(Xte)
                    Yhat_c = predict(md_c, Xte);
                    valAcc_c = mean(Yhat_c==Yte);
                else
                    valAcc_c = NaN;
                end

                rows(end+1,:) = {targetSize(1), CList(ciC), ks, los, valAcc_c}; %#ok<AGROW>

                if los < bestCvLoss
                    bestCvLoss = los; bestC = CList(ciC); bestKS = ks;
                end
            catch
                % Skip invalid combos (if any)
            end
        end
    end
    gridTbl = cell2table(rows, 'VariableNames', {'targetSize','C','KernelScale','cvLoss','valAcc'});

    fprintf('[SVM] targetSize=%dx%d | best C=%g, KernelScale=%s, cvLoss=%.4f\n', ...
        targetSize(1), targetSize(2), bestC, mat2str(bestKS), bestCvLoss);

    % -------- Train final model + validation for the best setting --------
    tFinal = templateSVM('KernelFunction','rbf', ...
                         'KernelScale', bestKS, ...
                         'Standardize', true, ...
                         'BoxConstraint', bestC);
    mdl = fitcecoc(Xtr, Ytr, 'Learners',tFinal,'Coding','onevsone','Prior','uniform');

    if ~isempty(Xte)
        Yhat = predict(mdl, Xte);
        valAcc = mean(Yhat==Yte);
        fprintf('[SVM] Validation Accuracy: %.2f%% (%d/%d)\n', 100*valAcc, sum(Yhat==Yte), numel(Yte));
        try
            figure('Name',sprintf('SVM Confusion (%dx%d)',targetSize(1),targetSize(2)),'Color','w');
            confusionchart(categorical(Yte), categorical(Yhat), ...
                'RowSummary','row-normalized','ColumnSummary','column-normalized');
            cc = confusionchart(categorical(Yte), categorical(Yhat), ...
                'RowSummary','row-normalized','ColumnSummary','column-normalized');

             % Force English axis labels
            cc.XLabel = 'Predicted Class';
            cc.YLabel = 'True Class';
        catch
        end
    else
        valAcc = NaN;
        fprintf('[SVM] No test set (some classes may be too small). Skip validation.\n');
    end
end
