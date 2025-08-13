vec3 nvec3(vec4 pos) {
    return pos.xyz / pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.x - 0.5), abs(coord.y - 0.5)) * 1.85;
}

const float errMult = 1.8;

vec4 Raytrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither, out float border, 
			  int refinementSteps, float stepSize, float refMult, float stepLength, int sampleCount) {
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos + normal * (0.075 + min(0.35, length(viewPos) * 0.125));

    vec3 rayIncrement = stepSize * reflect(normalize(viewPos), normalize(normal));
    viewPos += rayIncrement;
	vec3 rayDir = rayIncrement;

    int refinedSamples = 0;

    for (int i = 0; i < sampleCount; i++) {
        pos = nvec3(gbufferProjection * nvec4(viewPos)) * 0.5 + 0.5;
		if (pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex,pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
		dist = length(start - rfragpos);

        float err = length(viewPos - rfragpos);
		float rayLength = length(rayIncrement) * pow(length(rayDir), 0.1) * errMult;
		if (err < rayLength) {
			refinedSamples++;
			if (refinedSamples >= refinementSteps) break;
			rayDir -= rayIncrement;
			rayIncrement *= refMult;
		}
        rayIncrement *= stepLength;
        rayDir += rayIncrement * (0.1 * dither + 0.9);
		viewPos = start + rayDir;
    }

	border = cdist(pos.st);

	return vec4(pos, dist);
}