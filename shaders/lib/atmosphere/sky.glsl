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
     float mieScattering = 0.25 * exp(pow3(VoSClamped));
     VoUClamped = max(VoUClamped - (0.15 - VoSPositive * 0.15) * (1.0 - sunVisibility), 0.0);
     float rayleighScatteringMixer = pow(VoUClamped, 0.35);
     vec3 rayleighScattering = mix(vec3(8.8, 1.2, 0.0), vec3(4.0, 5.0, 1.0), rayleighScatteringMixer);
          rayleighScattering = mix(rayleighScattering, lightColSqrt * 2.0, VoUPositive * VoUPositive);
          rayleighScattering *= pow(VoUClamped, 1.3 - VoSPositive * 0.4) * pow2(1.0 - VoUClamped);
          rayleighScattering *= (0.6 - sunVisibility * 0.3) * exp(VoSPositive);

     float sunScattering = sunVisibility * pow(1.0 - VoUClamped, 5.0 - VoSClamped * 3.0) * (0.4 + VoSClamped * VoSClamped * 0.25);

     vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
     vec3 daySky = mix(nSkyColor, vec3(0.85, 0.75, 1.05), 0.4 - timeBrightnessSqrt * 0.4);
          //daySky *= 1.0 + mieScattering;
          daySky += rayleighScattering * (0.6 - timeBrightness * 0.3) * (1.0 - wetness);
          daySky = mix(daySky, lightColSqrt, sunScattering);

     vec3 nightSky = lightNight * 0.65;
     vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
          atmosphere *= 1.0 - wetness * 0.125;
          atmosphere *= skyDensity;

     //Fade atmosphere to dark gray underground
     atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

     return atmosphere;
}