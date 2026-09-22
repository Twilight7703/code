function carrier = prepare_carrier_image(inputImage)
%PREPARE_CARRIER_IMAGE Convert an image to an 8-bit single-channel carrier.
%   INPUTIMAGE must be a uint8 grayscale or RGB image.

if ~isa(inputImage,'uint8')
    error('Carrier images must be uint8 grayscale or RGB images.');
end
if ismatrix(inputImage)
    carrier = inputImage;
elseif ndims(inputImage) == 3 && size(inputImage,3) == 3
    if isequal(inputImage(:,:,1),inputImage(:,:,2)) && ...
            isequal(inputImage(:,:,1),inputImage(:,:,3))
        carrier = inputImage(:,:,1);
    else
        carrier = rgb2gray(inputImage);
    end
else
    error('Carrier images must be uint8 grayscale or RGB images.');
end
end
