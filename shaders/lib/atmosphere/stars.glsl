float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in float VoU, in float caveFactor, in float nebulaFactor, in float occlusion, in float size) {
	#ifdef OVERWORLD
	float visibility = moonVisibility * (1.0 - wetness) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 1.0;
	#endif

	visibility *= 1.0 - occlusion;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord *= size;
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.0005;
		float amount = STAR_AMOUNT * (1.0 + nebulaFactor);
		vec2 planeCoord0 = floor(planeCoord * 500.0 * amount) / (500.0 * amount);
		vec2 planeCoord1 = floor(planeCoord * 1000.0 * amount) / (1000.0 * amount);

		float stars = getNoise(planeCoord0 + 10.0);
			  stars*= getNoise(planeCoord1 + 14.0);
			  stars = clamp(stars - 0.85, 0.0, 1.0);
			  stars *= visibility * STAR_BRIGHTNESS * 21.0;
			  stars *= stars * visibility;

		#ifdef OVERWORLD
		if (moonVisibility > 0.0) {
			color *= 1.0 + texture2D(noisetex, planeCoord * 0.25).r * VoU * pow4(moonVisibility);
		}
		color += stars * lightNight;
		#else
		color += endLightColSqrt * vec3(pow3(stars) * 0.025, endLightColSqrt.g * 0.75, stars * 0.25) * stars * 0.75;
		#endif
	}
}