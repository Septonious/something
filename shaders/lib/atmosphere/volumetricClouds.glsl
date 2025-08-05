float texture2DShadow(sampler2D shadowtex, vec3 shadowPos) {
    float shadow = texture2D(shadowtex, shadowPos.xy).r;

    return clamp((shadow - shadowPos.z) * 65536.0, 0.0, 1.0);
}

void getDynamicWeather(inout float speed, inout float amount, inout float frequency, inout float thickness, inout float density, inout float detail, inout float height, inout float scale) {
	#ifdef VC_DYNAMIC_WEATHER
	int day = int((worldDay * 24000 + worldTime) / 24000);
	float dayAmountFactor = abs(day % 7 / 2 - 0.5) * 0.5;
	float dayDensityFactor = abs(day % 9 / 4 - day % 2);
	float dayFrequencyFactor = 1.0 + abs(day % 6 / 4 - day % 2) * 0.4;
    float dayScaleFactor = (day % 5 - day % 8 + day % 3) * 0.5;
	float dayHeightFactor = day % 5 + day % 18 + day % 27 - day % 33 - 10;
	#endif

	amount = mix(amount, 10.50, wetness);

	#ifdef VC_DYNAMIC_WEATHER
	amount -= dayAmountFactor;
	thickness += dayFrequencyFactor - 0.75;
	density += dayDensityFactor;
    scale += dayScaleFactor;
	height += dayHeightFactor;
	#endif
}

void getCloudSample(vec2 rayPos, vec2 wind, float attenuation, float amount, float frequency, float thickness, float density, float detail, inout float noise) {
	rayPos *= 0.0035 * frequency;

	float worleyNoise = (1.0 - texture2D(noisetex, rayPos.xy + wind * 0.5).g) * 0.4 + 0.25;
	float perlinNoise = texture2D(noisetex, rayPos.xy + wind * 0.5).r;
	float noiseBase = perlinNoise * 0.6 + worleyNoise * 0.4;

	float detailZ = floor(attenuation * thickness) * 0.05;
	float noiseDetailA = texture2D(noisetex, rayPos - wind + detailZ).b;
	float noiseDetailB = texture2D(noisetex, rayPos - wind + detailZ + 0.05).b;
	float noiseDetail = mix(noiseDetailA, noiseDetailB, fract(attenuation * thickness));

	float noiseCoverage = abs(attenuation - 0.125) * (attenuation > 0.125 ? 1.1 : 8.0);
		  noiseCoverage *= noiseCoverage * (VC_ATTENUATION + wetness * 1.5);
	
	noise = mix(noiseBase, noiseDetail, detail * 0.05) * 22.0 - noiseCoverage;
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

	if (visibility > 0.0) {
		//Positions
		vec3 viewPos = ToView(vec3(texCoord, z0));
		vec3 nViewPos = normalize(viewPos);
		vec3 nWorldPos = normalize(ToWorld(viewPos));

		float lViewPos = length(viewPos);

		#ifdef DISTANT_HORIZONS
		float dhZ = texture2D(dhDepthTex0, texCoord).r;
		vec4 dhScreenPos = vec4(texCoord, dhZ, 1.0);
		vec4 dhViewPos = dhProjectionInverse * (dhScreenPos * 2.0 - 1.0);
			 dhViewPos /= dhViewPos.w;
		float lDhViewPos = length(dhViewPos.xyz);
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

		float rayLength = thickness * 4.0;
			  rayLength /= nWorldPos.y * nWorldPos.y * 4.0 + 1.0;

		vec3 rayIncrement = nWorldPos * rayLength;
		int sampleCount = min(int(planeDifference / rayLength + 1), 6 + VC_DISTANCE / 1000);

		if (maxDist > 0 && sampleCount > 0) {
			float cloud = 0.0;
			float cloudAlpha = 0.0;
			float cloudLighting = 0.0;

			//Variables
			vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
			float VoU = dot(nViewPos, upVec);
			float VoL = dot(nViewPos, lightVec);
			float halfVoL = mix(abs(VoL), VoL, shadowFade) * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float scattering = pow20(halfVoL);
			float noiseLightFactor = (2.0 - VoL * shadowFade) * density;

			vec3 rayPos = startPos + rayIncrement * dither;
			
			float maxDepth = currentDepth;
			float sampleTotalLength = minDist + rayLength * dither;
			float fogDistance = 10.0 / max(abs(float(height) - 72.0), 56.0);

			vec2 wind = vec2(frameTimeCounter * speed * 0.005, sin(frameTimeCounter * speed * 0.1) * 0.01) * speed * 0.1;

			//Ray marcher
			for (int i = 0; i < sampleCount; i++, rayPos += rayIncrement, sampleTotalLength += rayLength) {
				if (cloudAlpha > 0.99 || (lViewPos < sampleTotalLength && z0 < 1.0)) break;

				#ifdef DISTANT_HORIZONS
				if ((lDhViewPos < sampleTotalLength && dhZ < 1.0)) break;
				#endif

                vec3 worldPos = rayPos - cameraPosition;
				float lWorldPos = length(worldPos.xz);

				if (lWorldPos > distance) break;

				//Indoor leak prevention
				if (eyeBrightnessSmooth.y < 210.0 && cameraPosition.y > height - 50.0 && lWorldPos < shadowDistance) {
					if (texture2DShadow(shadowtex1, ToShadow(worldPos)) <= 0.0) break;
				}

				float noise = 0.0;
				float attenuation = smoothstep(height, cloudTop, rayPos.y);

				getCloudSample(rayPos.xz / scale, wind, attenuation, amount, frequency, thickness, density, detail, noise);

                float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 512.0) * lightningBoltPosition.w * 32.0, 1.0);
				float sampleLighting = pow(attenuation, 1.0 - halfVoLSqr * 0.25);
					  sampleLighting *= 1.0 - pow(noise, noiseLightFactor) * (0.85 - lightning * 0.85) + lightning * 128.0;

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
			cloudLighting = cloudLighting * shadowFade + pow8(1.0 - cloudLighting) * pow(VoS, 5.0 - shadowFade * 4.0) * (1.0 - shadowFade) * 0.75;

			vec3 nSkyColor = normalize(skyColor + 0.0001);
            vec3 cloudAmbientColor = mix(atmosphereColor * atmosphereColor * 0.5, 
									 mix(ambientCol, atmosphereColor * nSkyColor * 0.3, 0.2 + timeBrightnessSqrt * 0.3 + isSpecificBiome * 0.4),
									 sunVisibility * (1.0 - wetness));
            vec3 cloudLightColor = mix(lightCol, lightCol * nSkyColor * 3.0, timeBrightnessSqrt * (0.5 - wetness * 0.5)) * (1.0 + scattering * shadowFade);
			vec3 cloudColor = mix(cloudAmbientColor, cloudLightColor, cloudLighting) * mix(vec3(1.0), biomeColor, isSpecificBiome * sunVisibility);
			    cloudColor = mix(cloudColor, atmosphereColor * length(cloudColor) * 0.5, wetness * 0.6);

			float opacity = clamp(mix(VC_OPACITY, 0.99, (max(0.0, cameraPosition.y) / height)), 0.0, 1.0 - wetness * 0.5);

			#if MC_VERSION >= 12104
			opacity = mix(opacity, opacity * 0.5, isPaleGarden);
			#endif

			vc = vec4(cloudColor, cloudAlpha * opacity) * visibility;
		}
	}
}