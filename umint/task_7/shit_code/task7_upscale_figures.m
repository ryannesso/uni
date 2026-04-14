function out = task7_upscale_figures(figDir, scale, outDir)
%TASK7_UPSCALE_FIGURES Upscale existing PNG figures (no retraining needed).
%   out = task7_upscale_figures(figDir, scale, outDir)
%   - figDir: path to folder with *.png
%   - scale: e.g., 2 (default)
%   - outDir: output folder (default: sibling "figures_hires")
%
% Note: this increases pixel dimensions via interpolation; it does NOT
% recreate extra detail like a true re-export at higher DPI.

if nargin < 1 || isempty(figDir)
    error('figDir is required');
end
if nargin < 2 || isempty(scale)
    scale = 2;
end
if nargin < 3 || isempty(outDir)
    outDir = fullfile(fileparts(figDir), 'figures_hires');
end

figDir = char(figDir);
outDir = char(outDir);

if ~exist(figDir, 'dir')
    error('Folder does not exist: %s', figDir);
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

files = dir(fullfile(figDir, '*.png'));
out = struct();
out.inDir = figDir;
out.outDir = outDir;
out.scale = scale;
out.count = numel(files);

for i = 1:numel(files)
    inPath = fullfile(figDir, files(i).name);
    I = imread(inPath);

    if scale ~= 1
        I2 = imresize(I, scale, 'bicubic');
    else
        I2 = I;
    end

    outPath = fullfile(outDir, files(i).name);
    imwrite(I2, outPath);
end

fprintf('Upscaled %d PNG(s) from %s -> %s (x%.2f)\n', out.count, figDir, outDir, scale);
end
