function images = mnistReadImages(filename)
%MNISTREADIMAGES Read MNIST IDX3 image file.
%   images = mnistReadImages(filename) returns a 3-D array
%   [numRows x numCols x numImages] of type single in range [0, 1].

fid = fopen(filename, 'rb');
if fid == -1
    error('mnistReadImages:FileOpen', 'Cannot open file: %s', filename);
end
cleaner = onCleanup(@() fclose(fid));

magic = fread(fid, 1, 'int32', 0, 'ieee-be');
if isempty(magic) || magic ~= 2051
    error('mnistReadImages:BadMagic', 'Bad magic number in %s (expected 2051).', filename);
end

numImages = fread(fid, 1, 'int32', 0, 'ieee-be');
numRows   = fread(fid, 1, 'int32', 0, 'ieee-be');
numCols   = fread(fid, 1, 'int32', 0, 'ieee-be');

numPixels = double(numImages) * double(numRows) * double(numCols);
pixels = fread(fid, numPixels, 'uint8=>single');
if numel(pixels) ~= numPixels
    error('mnistReadImages:UnexpectedEOF', 'Unexpected EOF in %s.', filename);
end

% IDX stores images row-major. MATLAB is column-major.
% Reshape to [cols x rows x N] then permute to [rows x cols x N].
pixels = reshape(pixels, [numCols, numRows, numImages]);
images = permute(pixels, [2 1 3]) ./ 255;
end
