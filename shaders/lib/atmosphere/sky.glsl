vec3 getAtmosphere(vec3 viewPos, vec3 worldPos) {
     vec3 nViewPos = normalize(viewPos);

     float VoSRaw = dot(nViewPos, sunVec);
     float VoURaw = dot(nViewPos, upVec);
     float VoUClamped = clamp(VoURaw, 0.0, 1.0);
     float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
           VoSClamped = pow(VoSClamped, 1.25);

     float skyDensity = exp((-0.75 + timeBrightness * 0.15) * abs(VoURaw));
     float baseScatteringHeight = pow6(1.0 - VoUClamped + 0.04);

     //Fake light scattering
     vec3 scattering = mix(mix(vec3(2.9, 3.4, 0.2), lightColSqrt, sunVisibility), vec3(1.9, 0.8, 0.0), pow2(1.0 - VoUClamped));
          scattering *= pow(1.0 - abs(VoURaw), 4.0 - VoSClamped);
          scattering *= 0.5 * timeBrightnessSqrt + 0.5 * exp(VoSRaw * 0.5);

     vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, isSpecificBiome);
     vec3 daySky = mix(nSkyColor, vec3(0.6, 0.5, 0.5), 0.5 - timeBrightnessSqrt * 0.5);
          daySky += scattering * max(0.0, 0.5 - timeBrightnessSqrt) * (1.0 - wetness);
          daySky = mix(daySky, lightColSqrt, baseScatteringHeight * mix(0.4 + VoSClamped * 0.6, 1.0, timeBrightnessSqrt) * (0.5 - timeBrightnessSqrt * 0.3));
     vec3 nightSky = lightNight * 0.75;
     vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
          atmosphere *= 1.0 - wetness * 0.125;
          atmosphere *= skyDensity;

     //Fade atmosphere to dark gray underground
     atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

     return atmosphere;
}