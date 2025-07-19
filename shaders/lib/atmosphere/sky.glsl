vec3 getAtmosphere(vec3 viewPos) {
     vec3 nViewPos = normalize(viewPos);

     float VoSRaw = dot(nViewPos, sunVec);
     float VoURaw = dot(nViewPos, upVec);
     float VoUClamped = clamp(VoURaw, 0.0, 1.0);
     float VoSClamped = clamp(VoSRaw, 0.0, 1.0);
           VoSClamped = pow(VoSClamped, 1.25);

     float skyDensity = exp((-0.75 + timeBrightness * 0.15) * abs(VoURaw));
     float baseScatteringHeight = pow6(1.0 - VoUClamped + 0.04);

     vec3 scattering = mix(mix(vec3(1.2, 2.6, 0.1), lightColSqrt, sunVisibility * VoSClamped), vec3(1.9, 0.8, 0.0), pow2(1.0 - VoUClamped));
          scattering *= pow4(1.0 - abs(VoURaw));
          scattering *= 0.4 * timeBrightnessSqrt + 0.6 * exp(VoSRaw * 0.5);

     vec3 daySky = mix(normalize(pow(skyColor, vec3(1.5)) + 0.00001), vec3(0.62, 0.69, 1.00), 0.5 - timeBrightness * 0.25);
          daySky += scattering * (0.75 - timeBrightness * 0.75) * (1.0 - wetness);
          daySky = mix(daySky, lightColSqrt, baseScatteringHeight * (0.4 - timeBrightness * 0.1));
     vec3 nightSky = lightNight * 0.75;
     vec3 atmosphere = mix(nightSky, daySky, sunVisibility);
          atmosphere *= 1.0 - wetness * 0.4;
          atmosphere *= skyDensity;

     //Fade atmosphere to dark gray
     atmosphere = mix(caveMinLightCol, atmosphere, caveFactor);

     return atmosphere;
}