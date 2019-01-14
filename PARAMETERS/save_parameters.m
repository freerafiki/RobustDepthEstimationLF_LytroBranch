function save_parameters(folder_path, ...
    path, superpixels_size, window_size, alpha_DFD, alpha_DFC, gamma_DFD_s1, ...
    gamma_DFD_s2, beta_DFD, gamma_DFC_s1, gamma_DFC_s2, beta_DFC, sp_type, wsPP)

nameFile = 'parameters.txt';
fileID = fopen(strcat(folder_path, nameFile),'w');
fprintf(fileID,'PARAMETERS\n\n');
fprintf(fileID,'Using Lytro image read using LFToolbox;\nUsing the image at: ');
fprintf(fileID,path);

fprintf(fileID,'Superpixel technique=');
if sp_type == 1
    fprintf(fileID,'vl_slic from MATLAB, superpixels size = %d\n',superpixels_size);
else
    fprintf(fileID,'slicmex from EPFL, number of sp = 500, compactness = 20\n');
end
fprintf(fileID,'window_size=%d, window_size_post-proc=%d\n', window_size, wsPP);
fprintf(fileID,'\nDEFOCUS\n');
fprintf(fileID,'alphaDFD=%1.3f, gammaDFD_s1=%1.3f, gammaDFD_s2=%1.3f, betaDFD=%1.3f\n', alpha_DFD, gamma_DFD_s1, gamma_DFD_s2, beta_DFD);
fprintf(fileID,'\nCORRESPONDENCES\n');
fprintf(fileID,'alphaDFC=%1.3f, gammaDFC_s1=%1.3f, gammaDFC_s2=%1.3f, betaDFC=%1.3f\n', alpha_DFC, gamma_DFC_s1, gamma_DFC_s2, beta_DFC);

%fprintf(fileID,'\nCalculated on image at ');
%fprintf(fileID,path);
