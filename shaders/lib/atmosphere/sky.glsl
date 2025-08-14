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
    vec3 scattering1 = mix(vec3(8.8 - timeBrightnessSqrt * 3.8, 1.2, 0.0), vec3(4.25, 5.25, 0.5), colorMixer);
         scattering1 = mix(scattering1, lightColSqrt * 4.0, VoUPositive * VoUPositive * 0.5);
         scattering1 *= VoUcm * clamp(pow(1.0 - VoUcm, 3.0 - VoSClamped), 0.0, 1.0);
         scattering1 *= (0.6 + sunVisibility * 0.4) + (0.6 - sunVisibility * 0.6) * exp(VoSPositive);

    float scatteringMixer = pow2(1.0 - VoUcm) * (0.6 + VoUPositive * 0.6);
    float scattering1Mixer = scatteringMixer * pow(length(scattering1), 0.33) * (1.0 - wetness * 0.75) * (0.9 - timeBrightness * 0.6);
    float scattering2Mixer = sunVisibility * VoSPositive * pow3(scatteringMixer) * (0.75 - timeBrightnessSqrt * 0.75);

    vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
    vec3 daySky = mix(nSkyColor, vec3(0.71, 0.48, 0.85), 0.7 - sunVisibility * 0.4 - timeBrightnessSqrt * 0.3);
         daySky = mix(daySky, scattering1 * (1.0 + timeBrightnessSqrt + timeBrightness), scattering1Mixer);
         daySky = mix(daySky, lightCol * (2.0 + mieScattering), scattering2Mixer);

    vec3 nightSky = lightNight * 0.65;
    vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
         atmosphere *= 1.0 - wetness * 0.125;
         atmosphere *= skyDensity;

    //Fade atmosphere to dark gray underground
    atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

    return atmosphere;
}