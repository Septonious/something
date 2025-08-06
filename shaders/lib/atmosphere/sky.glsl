vec3 getAtmosphere(vec3 viewPos) {
    vec3 nViewPos = normalize(viewPos);

    float VoS = dot(nViewPos, sunVec);
    float VoU = dot(nViewPos, upVec);
    float VoSPositive = VoS * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoSClamped = clamp(VoS, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float daySkyDensity = 0.5 + 0.5 * exp(-2.5 * VoUPositive * VoUPositive + 0.5 * timeBrightness);
    float nightSkyDensity = exp(-0.8 * VoUClamped);
    float skyDensity = mix(nightSkyDensity, daySkyDensity, timeBrightnessSqrt);

    //Fake light scattering
    float mieScattering = pow16(VoSClamped);

    float VoUcm = max(VoUClamped + 0.15, 0.0);
    float colorMixer = pow(VoUcm, 0.4 + timeBrightnessSqrt * 0.15);
    vec3 rayleighScattering = mix(vec3(8.8 - timeBrightnessSqrt * 3.8, 1.2, 0.0), vec3(4.25, 5.25, 0.5), colorMixer);
        rayleighScattering = mix(rayleighScattering, lightColSqrt * 4.0, VoUPositive * VoUPositive * 0.5);
        rayleighScattering *= VoUcm * clamp(pow(1.0 - VoUcm, 3.0 - VoSClamped), 0.0, 1.0);
        rayleighScattering *= (0.6 + sunVisibility * 0.4) + (0.6 - sunVisibility * 0.6) * exp(VoSPositive);

    float scatteringMixer = pow2(1.0 - VoUcm) * (0.6 + VoUPositive * 0.6);
    float rlScatteringMixer = scatteringMixer * pow(length(rayleighScattering), 0.33) * (1.0 - wetness * 0.75) * (0.9 - timeBrightness * 0.6);

    vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
    vec3 daySky = mix(nSkyColor, vec3(0.71, 0.48, 0.85), 0.7 - sunVisibility * 0.4 - timeBrightnessSqrt * 0.3);
         daySky = mix(daySky, rayleighScattering * (1.0 + timeBrightnessSqrt + timeBrightness), rlScatteringMixer);
         daySky = mix(daySky, lightColSqrt * (1.0 + mieScattering), 0.5 * mieScattering * pow3(1.0 - VoUcm) * sunVisibility);

    vec3 nightSky = lightNight * 0.65;
    vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
    atmosphere *= 1.0 - wetness * 0.125;
    atmosphere *= skyDensity;

    //Fade atmosphere to dark gray underground
    atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

    return atmosphere;
}