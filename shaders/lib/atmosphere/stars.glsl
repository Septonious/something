float getNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void drawStars(inout vec3 color, in vec3 worldPos, in vec3 sunVec, in float VoU, in float VoS, in float caveFactor, in float nebulaFactor, in float occlusion, in float size) {
	#ifdef OVERWORLD
	float visibility = (1.0 - sunVisibility) * (1.0 - wetness) * pow(VoU, 0.5) * caveFactor;
	#else
	float visibility = 0.4 - nebulaFactor * 0.2;
	#endif

	visibility *= 1.0 - occlusion;

	if (0 < visibility) {
		vec2 planeCoord = worldPos.xz / (length(worldPos.y) + length(worldPos.xz));
			 planeCoord *= size;
			 planeCoord += cameraPosition.xz * 0.00001;
			 planeCoord += frameTimeCounter * 0.0005;

		vec2 planeCoord0 = floor(planeCoord * 500.0 * STAR_AMOUNT) / (500.0 * STAR_AMOUNT);
		vec2 planeCoord1 = floor(planeCoord * 1000.0 * STAR_AMOUNT) / (1000.0 * STAR_AMOUNT);

		float stars = getNoise(planeCoord0 + 10.0);
			  stars*= getNoise(planeCoord1 + 14.0);
			  stars = clamp(stars - (0.85 - nebulaFactor * 0.1), 0.0, 1.0);
			  stars *= visibility * STAR_BRIGHTNESS * 21.0;
			  stars *= stars * visibility;

		#ifdef OVERWORLD
		color += stars * lightNight;
		#else
		color += stars * endLightColSqrt * 0.5;
		#endif
	}
}