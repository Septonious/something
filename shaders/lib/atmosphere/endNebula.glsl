void sampleNebulaNoise(vec2 coord, inout float colorMixer, inout float noise) {
    colorMixer = texture2D(noisetex, coord * 0.25).r;
    noise = texture2D(noisetex, coord * 0.50).r;
    noise *= colorMixer;
    noise *= texture2D(noisetex, coord * 0.125).r;
    noise *= 4.0;
}

float getSpiralWarping(vec2 coord){
	float whirl = -10.0;
	float arms = 10.0;

    coord = vec2(atan(coord.y, coord.x) + frameTimeCounter * 0.1, sqrt(coord.x * coord.x + coord.y * coord.y));
    float center = pow8(1.0 - coord.y) * 2.0;
    float spiral = sin((coord.x + sqrt(coord.y) * whirl) * arms) + center - coord.y;

    return clamp(spiral * 0.1, 0.0, 1.0);
}

void drawEndNebula(inout vec3 color, in vec3 worldPos, in float VoU, in float VoS) {
    float hole = pow(pow4(pow32(VoS)), END_BLACK_HOLE_SIZE);
    float gravityLens = hole;
    hole *= hole;
    hole *= hole;

    vec3 sunVec = mat3(gbufferModelViewInverse) * sunVec;
    vec2 sunCoord = sunVec.xz / (sunVec.y + length(sunVec));
    vec2 planeCoord = worldPos.xz / (length(worldPos) + worldPos.y) - sunCoord;
    float warping = getSpiralWarping(planeCoord);
         planeCoord.x *= 0.75 - abs(VoU) * 0.25;
         planeCoord.y *= 4.0;

    vec2 planeCoord0 = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz)) + warping * gravityLens;

    float nebulaNoise = 0.0;
    float nebulaColorMixer = 0.0;
    sampleNebulaNoise(planeCoord0, nebulaColorMixer, nebulaNoise);
          nebulaColorMixer = pow4(nebulaColorMixer) * 6.0;

    float nebulaVisibility = (0.2 - VoS * VoS * VoS * 0.2) + pow24(VoS) * 0.8;
    vec3 nebula =  mix(vec3(5.6, 2.2, 0.2), vec3(0.1, 2.8, 1.1), nebulaColorMixer) * nebulaNoise * nebulaNoise * nebulaVisibility;
         nebula *= max(1.0 - pow32(VoS) * 1.0, 0.0);
         nebula *= length(nebula) * END_NEBULA_BRIGHTNESS;

    float torus = 1.0 - clamp(length(planeCoord), 0.0, 1.0);
          torus = pow(pow16(torus * torus), END_BLACK_HOLE_SIZE);

    color += nebula;

    //Black Hole
    const vec3 blackHoleColor = vec3(5.6, 2.2, 0.2);

    float innerRing = pow2(hole * 3.0);
          innerRing *= float(innerRing > 0.2) * 8.0 * (1.0 - 6.0 * hole) * 8.0;
          innerRing = max(innerRing, 0.0);
          hole = clamp(hole * 8.0, 0.0, 1.0);

    float torusNoise = texture2D(noisetex, vec2(planeCoord.x * 4.0 + frameTimeCounter * 0.05, planeCoord.y)).r;

    color += mix(blackHoleColor, vec3(4.0), hole) * hole * hole * 2.0;
    color *= 1.0 - hole;
    color += vec3(1.0) * innerRing;
    color += mix(blackHoleColor, vec3(4.0), sqrt(torus)) * torus * 2.0 * torusNoise;

}