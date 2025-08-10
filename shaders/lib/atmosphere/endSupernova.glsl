float sampleNebulaNoise(vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.50).r;
          noise *= texture2D(noisetex, coord * 0.25).r;
          noise *= texture2D(noisetex, coord * 0.125).r;
    return noise * 4.0;
}

void drawEndSupernova(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS) {
    float baseRing = pow32(pow32(VoS * VoS)) * 10000.0;

    worldPos.x += 14.0;
    worldPos.y -= 4.0;

    vec2 planeCoord0 = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
    planeCoord0.y += baseRing * 0.002 + frameTimeCounter * 0.001;

    vec3 wSunVec = ToWorld(normalize(sunVec * 10000.0));
    worldPos += wSunVec * 8.0;

    vec2 planeCoord1 = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
    planeCoord1.y += baseRing * 0.002 + frameTimeCounter * 0.001;

    float baseNoise = sampleNebulaNoise(planeCoord0);
    float offsetNoise = sampleNebulaNoise(planeCoord1);
    float noiseDiff = min(max(baseNoise - offsetNoise, 0.0) * 4.0, 1.0);

    float nebulaColorMixer = texture2D(noisetex, planeCoord0 * 0.25).r;
          nebulaColorMixer = pow4(nebulaColorMixer) * 6.0;
    float nebulaVisibility = (0.15 - VoS * VoS * VoS * 0.15) + pow24(VoS) * 0.85;
    vec3 nebula = (1.0 + noiseDiff) * mix(vec3(5.6, 2.2, 0.2), vec3(0.1, 2.8, 1.1), nebulaColorMixer) * baseNoise * offsetNoise * nebulaVisibility;
         nebula *= max(1.0 - pow32(VoS) * 1.0, 0.0);
         nebula *= length(nebula) * END_SUPERNOVA_BRIGHTNESS;

    nebula *= 1.0 + baseRing * (32.0 - END_SUPERNOVA_BRIGHTNESS * 4.0);

    color += nebula;

    float hole = pow32(pow32(VoS)) * 8.0;
          hole = clamp(hole, 0.0, 1.0);

    color *= 1.0 - hole;
}