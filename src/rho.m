function rho_s = rho(s,soil,crop)
    eta = crop.ET_p/(soil.phi*crop.Zr);
    m = soil.ks*10 / (soil.phi * crop.Zr * (exp(soil.betha*(1-soil.s_fc))-1));
    if (s <= soil.s_h)
        rho_s = 0;
    elseif (s <= soil.s_star)
        rho_s = (eta * (s-soil.s_h)/(soil.s_star-soil.s_h));
    elseif (s <= soil.s_fc)
        rho_s = eta;
    else
        rho_s = eta + m * (exp(soil.betha*(s-soil.s_fc))-1);
    end
end


