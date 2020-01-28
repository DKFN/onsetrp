AddRemoteEvent("damage:bleed:tickeffect", function(amount)
    InvokeDamageFX(amount)
end)

AddRemoteEvent("damage:bleed:toggleeffect", function(active)
    if tonumber(active) == 1 then
        SetPostEffect("Global", "Saturation", 0.2, 0.2, 0.2)
        SetPostEffect("ImageEffects", "VignetteIntensity", 0.7)
        SetPostEffect("Chromatic", "Intensity", 4.0)
        SetPostEffect("Chromatic", "StartOffset", 0.1)
    else
        SetPostEffect("Global", "Saturation", 1, 1, 1)
        SetPostEffect("ImageEffects", "VignetteIntensity", 0.0)
        SetPostEffect("Chromatic", "Intensity", 0.0)
    end
end)
