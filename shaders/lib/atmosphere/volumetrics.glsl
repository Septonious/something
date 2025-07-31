#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

void computeVolumetrics(inout vec4 result, in vec3 translucent, in float dither) {
    //Stuff which we're doing
    vec3 volumetricLighting = vec3(0.0);
    vec3 cloudyFog = vec3(0.0);
    vec3 lpvFog = vec3(0.0);
    float fireflies = 0.0;
    float currentDepth = 0;
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
    float linearDepth0 = getLinearDepth2(z0);
    float linearDepth1 = getLinearDepth2(z1);

	//Positions & Common variables
	vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
	vec3 viewPos = ToView(vec3(texCoord.xy, z0));
	vec3 nViewPos = normalize(viewPos);
    vec3 worldPos = ToWorld(viewPos);
    vec3 nWorldPos = normalize(worldPos);
    float lViewPos = length(viewPos);

    float VoL = dot(nViewPos, lightVec);
    float VoU = dot(nViewPos, upVec);
    float VoLPositive = VoL * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoLClamped = clamp(VoL, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float water = texture2D(colortex3, texCoord).b;
    float totalVisibility = float(z0 > 0.56);

	#if MC_VERSION >= 11900
	totalVisibility *= 1.0 - darknessFactor;
	#endif

	totalVisibility *= 1.0 - blindFactor;

    //Ray Marcher Parameters
    int sampleCount = VL_SAMPLES;

    float rayLength = distance(gbufferModelViewInverse[3].xyz, worldPos) / VL_SAMPLES;
    float sampleTotalLength = rayLength * dither;

    vec3 rayIncrement = nWorldPos * rayLength;
    vec3 rayPos = cameraPosition + rayIncrement * dither;

    //Volumetric Lighting Variables
    #ifdef VL
	#ifdef OVERWORLD
        float VoLm = pow(VoLClamped, 3.0 + sunVisibility * 2.0);
        float vlVisibility = sunVisibility * (1.0 - VL_STRENGTH_RATIO) * (1.0 - timeBrightness) + VL_STRENGTH_RATIO * VoLm;
              vlVisibility *= mix(VL_NIGHT, mix(VL_MORNING_EVENING, VL_DAY, timeBrightness), sunVisibility);
          #if !defined VC_SHADOWS
            vlVisibility *= max(pow6(1.0 - VoUClamped * (1.0 - timeBrightness) * sunVisibility), float(isEyeInWater == 1));
          #endif
            vlVisibility *= caveFactor * shadowFade;

       vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
       vec3 vlCol = mix(lightCol, lightCol * nSkyColor, timeBrightnessSqrt);
	#else
       float dragonBattle = 1.0;
       #if MC_VERSION <= 12104
            dragonBattle = gl_Fog.start / far;
       #endif
       float endBlackHolePos = pow2(clamp(dot(nViewPos, sunVec), 0.0, 1.0));
       float visibilityNormal = endBlackHolePos * 0.25;
       float visibilityDragon = 0.25 + endBlackHolePos * 0.5;
       float vlVisibility = float(0.56 < z0) * mix(visibilityDragon, visibilityNormal, clamp(dragonBattle, 0.0, 1.0)) * 0.25;

       vec3 vlCol = endLightColSqrt;
	#endif

    vlVisibility /= sampleCount;
    vlVisibility *= min(lViewPos * 0.001 * (1.0 + timeBrightness * 6.0) * (7.0 - sunVisibility * 6.0), 1.0);
    vlVisibility *= VL_STRENGTH;
    #endif

    //Ray Marching
    for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
       if (lViewPos < sampleTotalLength && z0 < 1.0) break;

       vec3 worldPos = rayPos - cameraPosition;
       float lWorldPos = length(worldPos);
       float lWorldPosXZ = length(worldPos.xz);

       //VL calculations
       #ifdef VL
       if (vlVisibility > 0.0) {
          vec3 shadowCol = vec3(0.0);

          float shadow0 = 1.0;
          float shadow1 = 0.0;

          if (length(worldPos.xz) <= shadowDistance) {
             vec3 shadowPos = ToShadow(worldPos);
             shadow0 = texture2DShadow(shadowtex0, shadowPos);

             #ifdef SHADOW_COLOR
             if (shadow0 < 1.0) {
                shadow1 = texture2DShadow(shadowtex1, shadowPos);
                if (shadow1 > 0.0) {
                    shadowCol = texture2D(shadowcolor0, shadowPos.xy).rgb;
                }
             }
             #endif
          }

          volumetricLighting = clamp(shadow1 * shadowCol * shadowCol * 4.0 + shadow0 * vlCol * float(isEyeInWater == 0), 0.0, 1.0);
          volumetricLighting *= vlVisibility;
       }
       #endif

       //Accumulate samples
       result.rgb += volumetricLighting;
    }
    result *= totalVisibility;
}