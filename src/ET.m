function evapt = ET(s,soil,crop)
    if (s <= soil.s_h)
        evapt = 0;
    elseif (s < soil.s_star)
        evapt = crop.ET_p * (s - soil.s_h)/(soil.s_star - soil.s_h);
    else
        evapt = crop.ET_p;
    end
end

