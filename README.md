# ME5405 Machine Vision Project

This repository contains coursework for  NUS ME5405, focusing on "Machine Vision" techniques. The project demonstrates essential machine vision pipelines: image preprocessing, feature extraction, segmentation, and classification. Code is mainly written in Matlab, covering binarization, thinning, connected component analysis, contour extraction, character segmentation and normalization, feature calculation (HOG & zoning), kNN classification experiments, and consistent visualization for comprehensible reporting.

## Directory Structure

- `img1_src/`: Processing pipeline for `chromo.txt` images. Includes thinning algorithms, contour extraction, connected component analysis, statistics, and visualization.
- `img2_src/`: Complete pipeline for `charact1.txt` character images: binarization → thinning → contour extraction → segmentation/sorting → feature extraction → classification experiments.
- `img1_src/chromo.txt`: Source grayscale image (64x64), encoded by letters (A–V) and digits (0–9) to represent 32 grayscale levels.
- `img2_src/charact1.txt`: Another source image for the workflow above.

## Main Functionalities

### img1_src (Character Counting & Annotation)

1. **Grayscale image loading & decoding**: Converts txt file encoding to 32-level grayscale image and displays it.
2. **One-pixel thinning (Zhang-Suen)**: `zhangsuen_thin.m` implements the thinning algorithm for skeletonization.
3. **Outline extraction**: Uses Sobel operator and morphological erosion for contour detection.
4. **Connected component labeling & region attributes**: 8-connected labeling, region property computation with `my_regionprops.m` (centroid & bounding box).
5. **Broken link repair**: Morphological direction-based repair for broken strokes.

### img2_src (Character Segmentation & Recognition Pipeline)

1. **Gray txt loading & visualization**: Custom loader to display the source character image.
2. **Binarization with visualization**: Interactive histogram, fixed thresholding.
3. **Skeletonization**: Thinning for binary images.
4. **Contour extraction**: Morphological erosion for outline.
5. **Automatic character segmentation & normalization**: Connected component segmentation, noise filtering, padding, and scale normalization (`segment_and_crop.m`).
6. **Reordering**: Sorts and arranges segmented characters into the AB123C structure.
7. **Affine rotation experiments**: Rotates results around center for robustness demonstration.
8. **Feature extraction & classification**: Extracts HOG or 4x4 zoning features, performs kNN classification with grid search on parameters, reporting experiment tables.

## Key Implementations

- **zhangsuen_thin.m**: Matlab implementation of the Zhang-Suen thinning algorithm for skeletal extraction.
- **segment_and_crop.m**: Connected component segmentation, robust filtering, and normalization.
- **extractFeat.m**: HOG feature extraction with automatic fallback to zoning features.
- **preprocessGlyph.m**: Adaptive padding, noise removal, flexible normalization for consistent input.
- **kNN & SVM classification pipeline**: Multiple hyperparameters and distance metrics tested and benchmarked.

## Requirements

- Matlab R2020 or later (built-in functions `extractHOGFeatures` required for HOG features).
- Data files included with the source; no separate download needed.

## How to Run

Run the main scripts in each folder:

```matlab
cd img1_src; img1_main
cd ../img2_src; img2_main
```

## Visualization

Each core step provides interactive visual windows, showing intermediate results, classification predictions, and experiment tables—ideal for teaching and reporting purposes.

---

For further details, please refer directly to the `.m` files and code comments.
