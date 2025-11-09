clear; clc; close all;

% ========================= Main Pipeline =========================
% Steps 1-8 as required.

% ========================= Step 1: Read & show original =========================
img = read_charact('charact1.txt');
figure('Name','Step1: Original','Color','w');
imagesc(img); axis image off; colormap(gray(32)); caxis([0 31]); colorbar;
title('Original (0..31 grayscale)');

% ========================= Step 2: Thresholding =========================
T = 1;  % simple fixed threshold
bw = binarize_image(img, T);
figure('Name','Step2: Binary','Color','w');
subplot(1,2,1);
histogram(double(img(:)), 32); grid on;
xlabel('Gray level (0..31)'); ylabel('Count'); title('Histogram');
xline(T,'r--','LineWidth',1.2,'Label',sprintf('T=%d',T));
subplot(1,2,2); imshow(bw); title(sprintf('Binary (T=%d)', T));

% ========================= Step 3: One-pixel thinning =========================
thin_img = thin_zhangsuen(bw);
figure('Name','Step3: One-pixel Thin','Color','w');
subplot(1,2,1); imshow(bw);       title('Binary (input)');
subplot(1,2,2); imshow(thin_img); title('One-pixel Thin');

% ========================= Step 4: Outlines =========================
outline = outline_erode(bw);
figure('Name','Step4: Outlines','Color','w'); imshow(outline); title('Outlines');

% ========================= Step 5: Segment, label, crop (pad+resize) =========================
targetSizeDisp = [28 28];
[crops, keepOrder, S] = segment_and_crop(bw, targetSizeDisp, true);

% ========================= Step 6: Arrange as AB123C =========================
wordImg = arrange_AB123C(crops, keepOrder, S);
figure('Name','Step6: Arrange AB123C','Color','w');
imshow(wordImg); title('Arranged as AB123C');

% ========================= Step 7: Rotate 30 degrees about the center =========================
rotImg = rotate_about_center(wordImg, 30, 1);
figure('Name','Step7: Rotated 30^o','Color','w');
imshow(rotImg, 'InitialMagnification','fit'); axis image off;
title('Rotated by 30° about center');

% ========================= Step 8: Train classifiers + experiments =========================
rootDir = fullfile(pwd,'p_dataset_26');
assert(isfolder(rootDir), 'Training dataset folder not found: %s', rootDir);

targetSizes = [24 28 32];    % sizes to test (padding/resizing)
fprintf('\n========== [kNN Experiments: targetSize + hyperparameters] ==========\n');
kList    = [1 3 5 7 9 11];
distList = {'euclidean','cityblock','cosine'};
knnResults = table; knnGridAll = table;
for ts = targetSizes
    [mdlK, bestK, bestDist, cvLoss, valAcc, knnGrid] = trainKNN_stratified(rootDir, [ts ts], kList, distList);
    knnResults = [knnResults; 
        table(ts, bestK, string(bestDist), cvLoss, valAcc, 'VariableNames', ...
        {'targetSize','bestK','bestDistance','cvLoss','valAcc'})];
    knnGridAll = [knnGridAll; knnGrid];
end
disp(knnResults);
% Per-hyperparameter results (kNN):
try, disp(sortrows(knnGridAll, {'targetSize','cvLoss'})); end

fprintf('\n========== [SVM(RBF) Experiments: targetSize + hyperparameters] ==========\n');
CList = [0.1 1 10];
kernelScaleList = {'auto',1,2,4};
svmResults = table; svmGridAll = table;
for ts = targetSizes
    [mdlS, bestC, bestKS, cvLoss, valAcc, svmGrid] = trainSVM_stratified(rootDir, [ts ts], CList, kernelScaleList);
    svmResults = [svmResults; 
        table(ts, bestC, string(bestKS), cvLoss, valAcc, 'VariableNames', ...
        {'targetSize','bestC','bestKernelScale','cvLoss','valAcc'})];
    svmGridAll = [svmGridAll; svmGrid];
end
disp(svmResults);
% Per-hyperparameter results (SVM):
try, disp(sortrows(svmGridAll, {'targetSize','cvLoss'})); end

% Demo: kNN on arranged AB123C with 28x28 preprocessing
[mdlK_demo, ~, ~, ~, ~] = trainKNN_stratified(rootDir, [28 28], kList, distList);
figure('Name','Step8: kNN Prediction on AB123C (28x28)','Color','w');
gts = ["A","B","1","2","3","C"];
for i = 1:6
    I28 = preprocessGlyph(wordImg(:,(i-1)*28+1:i*28)>0, [28 28]);
    feat = extractFeat(I28);
    pred = string(predict(mdlK_demo, feat));
    subplot(1,6,i); imshow(I28>0);
    title(sprintf('Pred:%s | GT:%s', regexprep(pred,'^Sample',''), gts(i)));
end

fprintf('\nDone. Steps (1–8) completed. Included per-hyperparameter tables.\n');
