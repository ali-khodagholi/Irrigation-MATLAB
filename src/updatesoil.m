function soil = updatesoil(soil,soilchar)
    allsoil = {'Sand'    ''    'Loamy Sand'    ''    'Sandy Loam'    ''    'Loam'    ''    'Clay' };
    row = find(strcmp(allsoil,soil.type));
    soil.s_fc = soilchar(row,1);
    soil.s_star = soilchar(row,2);
    soil.s_w = soilchar(row,3);
    soil.s_h = soilchar(row,4);
    soil.betha = soilchar(row,5);
    soil.ks = soilchar(row,6);        %cm/day
    soil.phi = soilchar(row,7);
end

