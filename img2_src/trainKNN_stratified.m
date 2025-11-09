function [mdl, bestK, bestDist, bestCvLoss, valAcc, gridTbl] = trainKNN_stratified(rootDir, targetSize, kList, distList)
%TRAINKNN_STRATIFIED  Load .mat files per class under rootDir, preprocess to targetSize,
% extract features, perform stratified 75/25 split, 5-fold CV for (k, distance),
% train final model, evaluate on validation split, and visualize confusion.
%
% Additionally returns a table (gridTbl) with one row per hyperparameter
% candidate including CV loss and validation accuracy.
    if nargin<2 || isempty(targetSize), targetSize=[28 28]; end
    if nargin<3 || isempty(kList), kList = [1 3 5 7 9 11]; end
    if nargin<4 || isempty(distList), distList = {'euclidean','cityblock','cosine'}; end

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

    % Stratified 75/25 split
    rng(0);
    trainMask = false(size(Y)); testMask = false(size(Y));
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

    % Hyperparameter CV + per-candidate validation
    rows = {};
    bestCvLoss = inf; bestK = kList(1); bestDist = distList{1};
    for di = 1:numel(distList)
        for ki = 1:numel(kList)
            try
                kVal = kList(ki);
                distVal = distList{di};

                tmdl = fitcknn(Xtr, Ytr, ...
                    'NumNeighbors', kVal, ...
                    'Distance', distVal, ...
                    'Standardize', true, ...
                    'Prior','uniform');
                cvmdl = crossval(tmdl, 'KFold', 5);
                los = kfoldLoss(cvmdl);

                candMdl = fitcknn(Xtr, Ytr, 'NumNeighbors', kVal, 'Distance', distVal, ...
                                  'Standardize', true, 'Prior','uniform');
                if ~isempty(Xte)
                    Yhat_c = predict(candMdl, Xte);
                    valAcc_c = mean(Yhat_c==Yte);
                else
                    valAcc_c = NaN;
                end

                rows(end+1,:) = {targetSize(1), kVal, distVal, los, valAcc_c}; %#ok<AGROW>

                if los < bestCvLoss
                    bestCvLoss = los; bestK = kVal; bestDist = distVal;
                end
            catch
            end
        end
    end
    gridTbl = cell2table(rows, 'VariableNames', {'targetSize','k','distance','cvLoss','valAcc'});

    fprintf('[kNN] targetSize=%dx%d | best k=%d, distance=%s, cvLoss=%.4f\n', ...
        targetSize(1), targetSize(2), bestK, bestDist, bestCvLoss);

    % Train final model + validation for the best setting
    mdl = fitcknn(Xtr, Ytr, 'NumNeighbors', bestK, 'Distance', bestDist, ...
                  'Standardize', true, 'Prior','uniform');
    if ~isempty(Xte)
        Yhat = predict(mdl, Xte);
        valAcc = mean(Yhat==Yte);
        fprintf('[kNN] Validation Accuracy: %.2f%% (%d/%d)\n', 100*valAcc, sum(Yhat==Yte), numel(Yte));
        try
            figure('Name',sprintf('kNN Confusion (%dx%d)',targetSize(1),targetSize(2)),'Color','w');
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
        fprintf('[kNN] No test set (some classes may be too small). Skip validation.\n');
    end
end
