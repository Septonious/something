float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, inout vec3 atmosphereColor, in vec3 worldPos, in float VoU, in float VoS, in float caveFactor, in float nebulaFactor, in float occlusion, in float size) {
	#ifdef OVERWORLD
	float visibility = moonVisibility * (1.0 - wetness) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 1.0;
	#endif

	visibility *= 1.0 - occlusion;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xyz));
			 planeCoord *= size;
			 #ifdef END_SUPERNOVA
			 float baseRing = pow10(pow32(VoS));

			 planeCoord *= clamp(1.0 - baseRing * 4.0, 0.0, 1.0);
			 planeCoord += baseRing;
			 #endif
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.001;
		const float amount = STAR_AMOUNT;
		vec2 planeCoord0 = floor(planeCoord * 500.0 * amount) / (500.0 * amount);
		vec2 planeCoord1 = floor(planeCoord * 1000.0 * amount) / (1000.0 * amount);

		float stars = getNoise(planeCoord0 + 10.0);
			  stars*= getNoise(planeCoord1 + 14.0);
			  stars = clamp(stars - (0.85 - nebulaFactor * 0.1), 0.0, 1.0);
			  stars *= stars * 64.0;
			  stars = clamp(stars, 0.0, 1.0);

		#ifdef OVERWORLD
		if (moonVisibility > 0.0) {
			color *= 1.0 + texture2D(noisetex, planeCoord * 0.25).r * VoU * pow4(moonVisibility);
		}
		color += stars * lightNight * visibility * STAR_BRIGHTNESS;
		#else
		vec3 coloredStars = vec3(0.3, 0.3, 0.3) * stars;
			 coloredStars += vec3(1.0, 0.4, 0.7) * pow32(stars);
		color += coloredStars * (1.0 - nebulaFactor * 0.85) * visibility * END_STAR_BRIGHTNESS;
		#endif
	}
}