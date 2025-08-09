#ifdef VL
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}
#endif

float get3DNoise(vec3 rayPos) {
	rayPos += vec3(frameTimeCounter, 0.0, 0.0);
	rayPos.xz /= 512.0;

	float yResolution = 3.0;
	float yOffsetScale = 0.35;
	float yLow  = floor(rayPos.y / yResolution) * yOffsetScale;
	float yHigh = yLow + yOffsetScale;
	float yBlend = fract(rayPos.y / yResolution);

	float noiseLow  = texture2D(noisetex, rayPos.xz + yLow).r;
	float noiseHigh = texture2D(noisetex, rayPos.xz + yHigh).r;

	float noise = mix(noiseLow, noiseHigh, yBlend);
	noise = sin(noise * 28.0 + frameTimeCounter * 4.0) * 0.25 + 0.5;

	return noise;
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
    float vlIntensity = 0.0;

    #ifdef VL
	#ifdef OVERWORLD
        float VoLm = pow(VoLClamped, 2.0 + sunVisibility);
        vlIntensity = sunVisibility * (1.0 - VL_STRENGTH_RATIO) * (1.0 - timeBrightness) + VL_STRENGTH_RATIO * VoLm;
        vlIntensity = mix(0.5 + VoLm, vlIntensity, eBS);
        vlIntensity *= mix(VL_NIGHT, mix(VL_MORNING_EVENING, VL_DAY, timeBrightness), sunVisibility) * (3.0 - eBS * 2.0);
        #if !defined VC_SHADOWS
        vlIntensity *= max(pow6(1.0 - VoUClamped * (1.0 - timeBrightness) * sunVisibility), float(isEyeInWater == 1));
        #else
        vlIntensity = mix(vlIntensity, eBS * (0.5 + timeBrightnessSqrt * 0.5), float(isEyeInWater == 1));
        #endif
        vlIntensity *= caveFactor * shadowFade;
       vec3 nSkyColor = normalize(skyColor + 0.000001) * mix(vec3(1.0), biomeColor, sunVisibility * isSpecificBiome);
       vec3 vlCol = mix(lightCol, nSkyColor, timeBrightness * 0.75);
	#else
       float dragonBattle = 1.0;
       #if MC_VERSION <= 12104
            dragonBattle = gl_Fog.start / far;
       #endif
       float endBlackHolePos = pow2(clamp(dot(nViewPos, sunVec), 0.0, 1.0));
       float visibilityNormal = endBlackHolePos * 0.25;
       float visibilityDragon = 0.25 + endBlackHolePos * 0.5;
       vlIntensity = float(0.56 < z0) * mix(visibilityDragon, visibilityNormal, clamp(dragonBattle, 0.0, 1.0)) * 0.25;

       vec3 vlCol = endLightColSqrt;
	#endif

    vlIntensity *= VL_STRENGTH;
    #endif

    //LPV Fog Variables
    float lpvFogIntensity = LPV_FOG_STRENGTH * (16.0 - float(isEyeInWater == 1) * 15.0);
          lpvFogIntensity *= 1.0 - eBS * timeBrightnessSqrt;

    if (totalVisibility > 0.0) {
        //Crepuscular rays parameters
        #if defined VC_SHADOWS && defined VL
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;

        getDynamicWeather(speed, amount, frequency, thickness, density, height, scale);

        float cloudTop = height + thickness * scale - 50.0;
        vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;
        #endif

        //Ray marcher parameters
        int sampleCount = VL_SAMPLES;

        float maxDist = shadowDistance;
        #ifdef VC_SHADOWS
            maxDist += 128.0;
        #endif
            maxDist /= 1.0 + float(isEyeInWater == 1) * 5.0;

        float rayLength = (maxDist / (sampleCount + 1.0)) * 0.05;

        maxDist *= viewFactor;
        rayLength *= viewFactor;

        float maxCurrentDist = min(maxDist, linearDepth1);

        //Ray marching
        for (int i = 0; i < sampleCount; i++) {
            float currentDist = pow(exp2(i + dither), 1.5) * rayLength;

            if (currentDist > maxCurrentDist) break;

            vec3 worldPos = ToWorld(ToView(vec3(texCoord, getLogarithmicDepth(currentDist))));
            float lWorldPos = length(worldPos);

            if (lWorldPos > maxDist) break;

            float currentSampleIntensity = pow(currentDist / maxDist, 1.5) / sampleCount;

            vec3 rayPos = worldPos + cameraPosition;

            //Volumetric lighting
            vec3 vlSample = vec3(0.0);

            #ifdef VL
            if (vlIntensity > 0.0) {
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

                vlSample = clamp(shadow1 * shadowCol * shadowCol * 2.0 + shadow0 * vlCol * float(isEyeInWater == 0), 0.0, 1.0);

                //Crepuscular rays
                #ifdef VC_SHADOWS
                if (rayPos.y < cloudTop) {
                    vec3 cloudShadowPos = rayPos + (worldSunVec / max(abs(worldSunVec.y), 0.0)) * max(cloudTop - rayPos.y, 0.0);

                    float noise = 0.0;
                    getCloudShadow(cloudShadowPos.xz / scale, wind, amount, frequency, density, noise);
                    vlSample *= noise * shadowFade;
                }
                vlSample *= 1.0 - min((rayPos.y - thickness) * (1.0 / cloudTop), 1.0);
                #endif
            }
            #endif

            //LPV Fog
            vec3 lpvFogSample = vec3(0.0);

            #ifdef LPV_FOG
            if (lpvFogIntensity > 0.0) {
                vec3 voxelPos = worldToVoxel(worldPos);
                     voxelPos /= voxelVolumeSize;
                     voxelPos = clamp(voxelPos, 0.0, 1.0);

                if (isInsideVoxelVolume(voxelPos)) {
                    float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
                        floodfillFade = clamp(floodfillFade, 0.0, 1.0);

                    vec4 lightVolume = vec4(0.0);
                    if ((frameCounter & 1) == 0) {
                        lightVolume = texture(floodfillSamplerCopy, voxelPos);
                    } else {
                        lightVolume = texture(floodfillSampler, voxelPos);
                    }

                    lpvFogSample = pow(lightVolume.rgb, vec3(1.0 / FLOODFILL_RADIUS)) * (1.0 - floodfillFade * floodfillFade);

                    #ifdef LPV_CLOUDY_FOG
                    vec3 noisePos = rayPos * 3.0;
                    float n3da = texture2D(noisetex, noisePos.xz * 0.0025 + floor(noisePos.y * 0.25) * 0.25).r;
                    float n3db = texture2D(noisetex, noisePos.xz * 0.0025 + floor(noisePos.y * 0.25 + 1.0) * 0.25).r;

                    float cloudyNoise = mix(n3da, n3db, fract(noisePos.y * 0.25));
                        cloudyNoise = max(cloudyNoise * cloudyNoise * cloudyNoise, 0.0);
                    lpvFogSample *= cloudyNoise;
                    #endif
                }
            }
            #endif

            //Translucency Blending
            if (linearDepth0 < currentDist) {
                vlSample *= translucent;
                lpvFogSample *= translucent;
            }

            //Accumulate samples
            vl += vlSample * currentSampleIntensity * vlIntensity;
            vl += lpvFogSample * currentSampleIntensity * lpvFogIntensity;
        }
        vl *= totalVisibility * 2;
    }
}