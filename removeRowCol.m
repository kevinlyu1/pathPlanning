% removeRowCol.m
% removes either the row or the columns that contain 0

function [rowRemoved1,rowRemoved2,colRemoved1,colRemoved2] = removeRowCol(matrix1, matrix2)

rowRemoved1 = matrix1;
rowRemoved2 = matrix2;
colRemoved1 = matrix1;
colRemoved2 = matrix2;

removeMatrix = [];
[m,n] = size(matrix1);
for i = 1:m
    if ~any(matrix1(i,:))
        removeMatrix(end+1) = i;
    end
end

if ~isempty(removeMatrix)
    rowRemoved1 = matrix1;
    rowRemoved1(removeMatrix,:) = [];
    rowRemoved2 = matrix2;
    rowRemoved2(removeMatrix,:) = [];
end

removeMatrix = [];
for i = 1:n
    if isempty(matrix1(:,i))
        removeMatrix(end+1) = i; %#ok<*AGROW>
    end
end

if ~isempty(removeMatrix)
    colRemoved1 = matrix1;
    colRemoved1(:,removeMatrix) = [];
    colRemoved2 = matrix2;
    colRemoved2(:,removeMatrix) = [];
end


end