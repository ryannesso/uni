function labels = mnistReadLabels(filename)
%MNISTREADLABELS Read MNIST IDX1 label file.
%   labels = mnistReadLabels(filename) returns a row vector (1 x N) double
%   with labels in {0..9}.

fid = fopen(filename, 'rb');
if fid == -1
    error('mnistReadLabels:FileOpen', 'Cannot open file: %s', filename);
end
cleaner = onCleanup(@() fclose(fid));

magic = fread(fid, 1, 'int32', 0, 'ieee-be');
if isempty(magic) || magic ~= 2049
    error('mnistReadLabels:BadMagic', 'Bad magic number in %s (expected 2049).', filename);
end

numLabels = fread(fid, 1, 'int32', 0, 'ieee-be');
raw = fread(fid, double(numLabels), 'uint8=>double');
if numel(raw) ~= numLabels
    error('mnistReadLabels:UnexpectedEOF', 'Unexpected EOF in %s.', filename);
end

labels = reshape(raw, 1, []);
end
