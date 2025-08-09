const vec2 roughReflectionOffsets[4] = vec2[4](
   vec2(0.21848650099008202, -0.09211370200809937),
   vec2(-0.5866112654782878, 0.32153793477769893),
   vec2(-0.06595078555407359, -0.879656059066481),
   vec2(0.43407555004227927, 0.6502318262968816)
);

void getReflection(inout vec4 color, in vec3 viewPos, in vec3 normal, in float fresnel, in float smoothness) {
	float border = 0.0;
	float blueNoiseDither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;

	#ifdef TAA
	blueNoiseDither = fract(blueNoiseDither + 1.61803398875 * mod(float(frameCounter), 3600.0));
	#endif

	#ifndef OVERWORLD
	int sampleCount = 30;
	#else
	int sampleCount = int(30 - eBS * 15);
	#endif

	sampleCount = int(sampleCount * (0.5 + smoothness * 0.5));

	vec4 reflectPos = Raytrace(depthtex1, viewPos, normal, blueNoiseDither, border, 3, 0.5, 0.2, 1.5, sampleCount);

	border = clamp(2.0 * (1.0 - border), 0.0, 1.0);

	float zThreshold = 1.0 + 1e-5;
	vec4 reflection = vec4(0.0);
	if (reflectPos.z < zThreshold) {
		float fovScale = gbufferProjection[1][1] / 1.37;
		float dist =  0.125 * pow2(1.0 - smoothness) * reflectPos.a * fovScale;
		float lod = log2(viewHeight * dist);

		for (int i = -2; i <= 2; i++) {
			for (int j = -2; j <= 2; j++) {
				vec2 offset = vec2(i, j) * exp2(lod - 1.0) / vec2(viewWidth, viewHeight);
				reflection += texture2DLod(colortex0, reflectPos.xy + offset, max(lod - 1, 0.0));
			}
		}

		reflection /= 25.0;
		reflection.rgb *= float(reflection.a > 0.0);
		reflection.a *= border;
	}

	#ifdef OVERWORLD
	vec3 falloff = color.rgb;
	#elif defined NETHER
	vec3 falloff = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 falloff = endLightCol * 0.15;
	#endif

	if (reflection.a < 1.0 && isEyeInWater == 0) {
		if (eBS > 0.0) {
			#ifdef OVERWORLD
			vec3 viewPosRef = reflect(normalize(viewPos), normal);
			vec3 reflectedAtmosphere = getAtmosphere(viewPosRef);
			reflectedAtmosphere = pow(reflectedAtmosphere, vec3(2.2));
			falloff = mix(falloff, reflectedAtmosphere, eBS);
			#endif
		}

		#if MC_VERSION >= 11900
		falloff *= 1.0 - darknessFactor;
		#endif

		falloff *= 1.0 - blindFactor;
	}

	vec3 finalReflection = max(mix(falloff, reflection.rgb, reflection.a), vec3(0.0));

	#ifdef GENERATED_SPECULAR
	smoothness = pow(smoothness, max(1.0, 1.5 - smoothness)); //Prevents crazy strong reflections on rough surfaces
	#endif

	color.rgb = mix(color.rgb, finalReflection, pow(fresnel, 1.5) * smoothness);
}