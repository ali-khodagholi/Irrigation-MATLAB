function st = soilmoisture(s0,soil,crop)
    st = s0;
    a = 10*st;
    while (abs(st-a)>st*0.1)
        a = st;
        st = s0-rho((st+s0)/2,soil,crop);
    end
end

