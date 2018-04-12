function maskBin = maskBinary(mask)
    [h, w] = size(mask);
    maskBin=mask;
    for i=1:h
        for j=1:w
            if mask(i,j)>150
                maskBin(i,j)=1;
            else
                maskBin(i,j)=0;
            end
        end 
    end 
end