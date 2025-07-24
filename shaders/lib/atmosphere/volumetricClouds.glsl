float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height, inout float scale) {
	int worldDayInterpolated = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(worldDayInterpolated % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(worldDayInterpolated % 9 / 4 - worldDayInterpolated % 2);
	float dayFrequencyFactor = 1.0 + abs(worldDayInterpolated % 6 / 4 - worldDayInterpolated % 2) * 0.4;
    int dayScaleFactor = int(abs(worldDayInterpolated % 8 - worldDayInterpolated % 3) * 0.5);

	amount = mix(amount, 11.25, wetness) - dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
	frequency *= dayFrequencyFactor;
    scale += dayScaleFactor;
}

void getCloudSample(vec2 rayPos, vec2 wind, float attenuation, float amount, float frequency, float thickness, float density, float detail, inout float noise) {
	rayPos *= 0.0025 * frequency;

	float deformNoise = clamp(texture2D(noisetex, rayPos.xy * 0.125 + wind * 0.25).r * 2.0, 0.0, 1.0);
	float noiseSample = texture2D(noisetex, rayPos.xy + wind * 0.5).g;
	float noiseBase = (1.0 - noiseSample) * 0.35 + 0.25 + wetness * 0.1;

	amount *= 0.75 + deformNoise * 0.3;
	density *= 2.0 - pow3(deformNoise);
	detail *= 0.75 + deformNoise * 0.25;

	float detailZ = floor(attenuation * thickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * thickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.1 : 8.0);
		  noiseCoverage *= noiseCoverage * (VC_ATTENUATION + wetness * 1.5);
	
	noise = mix(noiseBase, noiseDetail, detail * mix(0.05, 0.025, min(cameraPosition.y * 0.0025, 1.0)) * int(noiseBase > 0.0)) * 22.0 - noiseCoverage;
	noise = max(noise - amount, 0.0) * (density * 0.25);
	noise /= sqrt(noise * noise + 0.25);
}

void computeVolumetricClouds(inout vec4 vc, in vec3 atmosphereColor, float z0, float dither, inout float currentDepth) {
	//Total visibility
	float visibility = caveFactor * int(0.56 < z0);

	#if MC_VERSION >= 11900
	visibility *= 1.0 - darknessFactor;
	#endif

	visibility *= 1.0 - blindFactor;

	if (0 < visibility) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		#endif

		//Cloud parameters
		float speed = VC_SPEED;
		float amount = VC_AMOUNT;
		float frequency = VC_FREQUENCY;
		float thickness = VC_THICKNESS;
		float density = VC_DENSITY;
		float detail = VC_DETAIL;
		float height = VC_HEIGHT;
        float scale = VC_SCALE;
        float distance = VC_DISTANCE;

		getDynamicWeather(speed, amount, frequency, thickness, density, detail, height, scale);

        #ifdef DISTANT_HORIZONS
        distance *= 2.0;
        #endif

		//Setting the ray marcher
		float cloudTop = height + thickness * scale;
		float lowerPlane = (height - cameraPosition.y) / nWorldPos.y;
		float upperPlane = (cloudTop - cameraPosition.y) / nWorldPos.y;
		float minDist = max(min(lowerPlane, upperPlane), 0.0);
		float maxDist = max(lowerPlane, upperPlane);

		float planeDifference = maxDist - minDist;
		vec3 startPos = cameraPosition + minDist * nWorldPos;

		float rayLength = thickness * 5.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 5.0 + 1.0;

		vec3 sampleStep = nWorldPos * rayLength;
		int sampleCount = int(min(planeDifference / rayLength, 20) + 1);

        float fogDistance = 10.0 / max(abs(float(height) - 72.0), 56.0);

		if (maxDist > 0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Scattering variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, lightVec);
			float halfVoL = mix(abs(VoL), VoL, shadowFade) * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float scattering = pow20(halfVoL) * 2.0;
			float noiseLightFactor = (2.0 - VoL * shadowFade) * density;

			vec3 rayPos = startPos + sampleStep * dither;
			
			float maxDepth = currentDepth;
			float sampleTotalLength = minDist + rayLength * dither;

			vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += sampleStep, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (length(viewPos) < sampleTotalLength && z0 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((length(dhViewPos.xyz) < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;
				float lWorldPos = length(worldPos.xz);

				if (lWorldPos > distance) break;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 220.0 && length(worldPos) < shadowDistance) {
					if (texture2DShadow(shadowtex1, ToShadow(worldPos)) <= 0.0) break;
				}

				float noise = 0.0;
				float attenuation = smoothstep(height, cloudTop, rayPos.y);

				getCloudSample(rayPos.xz / scale, wind, attenuation, amount, frequency, thickness, density, detail, noise);

                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 512.0) * lightningBoltPosition.w * 32.0, 1.0);
				float sampleLighting = pow(attenuation, 1.0 - halfVoLSqr * 0.25);
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor) * (0.9 - lightning * 0.9) + 0.1 + lightning * 128.0;

				cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
				cloud = mix(cloud, 1.0, noise);
				noise *= pow6(smoothstep(mix(distance * 0.1, 300, wetness), 16.0, lWorldPos * fogDistance));
				cloudAlpha = mix(cloudAlpha, 1.0, noise);

				//gbuffers_water cloud discard check
				if (currentDepth == maxDepth && cloud > 0.5) {
					currentDepth = sampleTotalLength;
				}
			}

			//Final color calculations
			float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
			cloudLighting = cloudLighting * shadowFade + pow8(1.0 - cloudLighting) * pow4(VoS) * (1.0 - shadowFade);
            float morningEveningFactor = 1.0 - 0.2 * sqrt(sunVisibility) * (1.0 - timeBrightnessSqrt);

            vec3 cloudAmbientColor = mix(ambientCol, atmosphereColor * atmosphereColor, 0.4 + timeBrightness * 0.2) * 0.6;
            vec3 cloudLightColor = mix(lightCol, normalize(skyColor + 0.0001) * 2.0, timeBrightness * (0.75 - wetness * 0.75)) * (1.0 + scattering * shadowFade);
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting);

			float opacity = clamp(mix(VC_OPACITY, 0.99, (max(0.0, cameraPosition.y) / height)), 0.0, 1.0 - wetness * 0.5);

			#if MC_VERSION >= 12104
			opacity = mix(opacity, opacity * 0.5, isPaleGarden);
			#endif

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}