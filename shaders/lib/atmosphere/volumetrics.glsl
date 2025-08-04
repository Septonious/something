#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

float smoothstep1(float x) {
    return x * x * (3.0 - 2.0 * x);
}

void computeVolumetricLight(inout vec3 vl, in vec3 translucent, in float dither) {
	//Depths
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
    float linearDepth0 = getLinearDepth2(z0);
    float linearDepth1 = getLinearDepth2(z1);

	//Positions & Common variables
    #ifdef VC_SHADOWS
	vec3 worldSunVec = mat3(gbufferModelViewInverse) * lightVec;
    #endif

	vec3 viewPos = ToView(vec3(texCoord.xy, z1));
	vec3 nViewPos = normalize(viewPos);
    vec3 worldPos = ToWorld(viewPos);
    vec3 nWorldPos = normalize(worldPos);
    float lViewPos = length(viewPos);
    float viewFactor = 1.0 - 0.7 * pow2(dot(nViewPos.xy, nViewPos.xy));

    float VoL = dot(nViewPos, lightVec);
    float VoU = dot(nViewPos, upVec);
    float VoLPositive = VoL * 0.5 + 0.5;
    float VoUPositive = VoU * 0.5 + 0.5;
    float VoLClamped = clamp(VoL, 0.0, 1.0);
    float VoUClamped = clamp(VoU, 0.0, 1.0);

    float totalVisibility = float(z0 > 0.56);

	#if MC_VERSION >= 11900
	totalVisibility *= 1.0 - darknessFactor;
	#endif

	totalVisibility *= 1.0 - blindFactor;

    //Volumetric Lighting Variables
	#ifdef OVERWORLD
        float VoLm = pow(VoLClamped, 2.0 + sunVisibility);
        float vlVisibility = sunVisibility * (1.0 - VL_STRENGTH_RATIO) * (1.0 - timeBrightness) + VL_STRENGTH_RATIO * VoLm;
              vlVisibility *= mix(VL_NIGHT, mix(VL_MORNING_EVENING, VL_DAY * (3.0 - eBS * 2.0), timeBrightness), sunVisibility);
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

    vlVisibility *= VL_STRENGTH;

    if (totalVisibility * vlVisibility > 0.0) {
        //Crepuscular rays parameters
        #ifdef VC_SHADOWS
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;
        float cloudTop = VC_HEIGHT + VC_THICKNESS * scale - 50.0;

        getDynamicWeather(speed, amount, frequency, thickness, density, height, scale);

        vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
        #endif

        //Ray marcher parameters
        int sampleCount = VL_SAMPLES;

        float maxDist = shadowDistance;
        #ifdef VC_SHADOWS
            maxDist += 128.0;
        #endif
            maxDist /= 1.0 + float(isEyeInWater == 1) * 3.0;

        float rayLength = (maxDist / (sampleCount + 1.0)) * 0.5;

        maxDist *= viewFactor;
        rayLength *= viewFactor;

        float maxCurrentDist = min(maxDist, linearDepth1);

        //Ray marching
        for (int i = 0; i < sampleCount; i++) {
            float currentDist = (i + dither) * rayLength;

            if (currentDist > maxCurrentDist) break;

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));
            float lWorldPos = length(worldPos);

            if (lWorldPos > maxDist) break;

            float currentSampleIntensity = (currentDist / maxDist) / sampleCount;

            vec3 rayPos = worldPos + cameraPosition;

            vec3 shadowCol = vec3(0.0);
            float shadow0 = 1.0;
            float shadow1 = 0.0;

            if (lWorldPos <= shadowDistance) {
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

            vec3 vlSample = clamp(shadow1 * shadowCol + shadow0 * vlCol * float(isEyeInWater == 0), 0.0, 1.0);

            //Crepuscular rays
            #ifdef VC_SHADOWS
            if (rayPos.y < cloudTop) {
                vec3 cloudShadowPos = rayPos + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max(cloudTop - rayPos.y, 0.0);

                float noise = 0.0;
                getCloudShadow(cloudShadowPos.xz / scale, wind, amount, frequency, density, noise);
                vlSample *= noise;
            }
            vlSample *= 1.0 - min((rayPos.y - thickness) * (1.0 / cloudTop), 1.0);
            #endif

            //Translucency Blending
            if (linearDepth0 < currentDist) {
                vlSample *= translucent;
            }

            //Accumulate samples
            vl += vlSample * currentSampleIntensity;
        }
        vl *= vlVisibility * totalVisibility;
    }
}