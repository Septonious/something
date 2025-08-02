vec3 getAtmosphere(vec3 viewPos, vec3 worldPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);
    float VoSPositive = VoS * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoSClamped = clamp(VoS, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float daySkyDensity = 0.5 + 0.5 * exp(-2.5 * VoUPositive * VoUPositive + 0.5 * timeBrightness);
    float nightSkyDensity = exp(-0.7 * VoUClamped);
    float skyDensity = mix(nightSkyDensity, daySkyDensity, timeBrightnessSqrt);

    //Fake light scattering
    float mieScattering = pow10(VoSClamped);

    float VoUcm = max(VoUClamped + 0.15, 0.0);
    float rayleighScatteringMixer = pow(VoUcm, 0.4);
    vec3 rayleighScattering = mix(vec3(8.8 - timeBrightnessSqrt * 3.4, 1.2, 0.0), vec3(4.25, 5.25, 0.5), rayleighScatteringMixer);
        rayleighScattering = mix(rayleighScattering, lightColSqrt * 4.0, VoUPositive * VoUPositive * 0.5);
        rayleighScattering *= VoUcm * pow3(1.0 - VoUcm);
        rayleighScattering *= (0.6 + sunVisibility * 0.4) + (0.6 - sunVisibility * 0.6) * exp(VoSPositive);

    float sunScattering = pow2(1.0 - VoUClamped) * (0.25 + VoUPositive * 0.5) * (1.0 - timeBrightnessSqrt * 0.5);

    vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
    vec3 daySky = mix(nSkyColor, vec3(0.47, 0.42, 0.55), 0.6 - timeBrightnessSqrt * 0.6);
         daySky = mix(daySky, rayleighScattering * (1.0 + timeBrightnessSqrt * 2.0), sunScattering * sqrt(length(rayleighScattering)));
         daySky = mix(daySky, lightColSqrt * 1.3, sunScattering * VoSClamped * VoSClamped * 0.5);

    vec3 nightSky = lightNight * 0.65;
    vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
    atmosphere *= 1.0 - wetness * 0.125;
    atmosphere *= skyDensity;

    //Fade atmosphere to dark gray underground
    atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

    return atmosphere;
}