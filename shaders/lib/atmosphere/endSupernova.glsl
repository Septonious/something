float sampleNebulaNoise(vec2 coord) {
    float noise = texture2D(noisetex, coord * 0.50).r;
          noise *= texture2D(noisetex, coord * 0.25).r;
          noise *= texture2D(noisetex, coord * 0.125).r;
    return noise * 4.0;
}

void drawEndSupernova(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS, inout float nebulaFactor) {
    float star = pow32(pow32(VoS * VoS));
    vec3 supernova = star * endLightColSqrt * pulse * 2.0;
         supernova *= pow4(min(1.0, length(supernova))) * 2.0;
    vec3 wSunVec = ToWorld(normalize(sunVec * 10000.0));
    worldPos.x += 14.0;
    worldPos.y -= 4.0;
    vec2 planeCoord0 = worldPos.xz / (worldPos.y + length(worldPos.xyz));
    worldPos += wSunVec * 8.0;
    vec2 planeCoord1 = worldPos.xz / (worldPos.y + length(worldPos.xyz));

    float baseNoise = sampleNebulaNoise(planeCoord0);
    float offsetNoise = sampleNebulaNoise(planeCoord1);
    float noiseDiff = min(max(baseNoise - offsetNoise, 0.0) * 4.0, 1.0);

    float nebulaColorMixer = texture2D(noisetex, planeCoord0 * 0.25).r;
          nebulaColorMixer = pow4(nebulaColorMixer) * 4.0;
    float nebulaVisibility = pow24(VoS);
    vec3 nebula = (1.0 + noiseDiff) * mix(vec3(4.8, 3.0, 0.2) * endLightColSqrt, vec3(0.1, 2.8, 1.1), nebulaColorMixer) * baseNoise * offsetNoise * nebulaVisibility;
         nebula *= 0.1 + length(nebula) * 0.4;
    supernova += nebula;
    color += supernova;
    nebulaFactor += float(length(nebula) > 0.125);
}