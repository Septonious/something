#define COMPOSITE_4

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// Varyings //
in vec2 texCoord;

// Uniforms //
#if defined WATER_FOG || defined REFRACTION
uniform int isEyeInWater;
#endif

#ifdef WATER_FOG
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float blindFactor;
uniform float timeBrightness, timeAngle, wetness, shadowFade;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 fogColor;
#endif

uniform sampler2D colortex0;

#ifdef REFRACTION
uniform float aspectRatio;
uniform float frameTimeCounter;

uniform sampler2D colortex3;

uniform mat4 gbufferProjection;
#endif

#if defined WATER_FOG || defined REFRACTION
uniform sampler2D depthtex0, depthtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
#endif

// Global Variables //
#ifdef WATER_FOG
#if defined OVERWORLD
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
float fractTimeAngle = fract(timeAngle - 0.25);
float ang = (fractTimeAngle + (cos(fractTimeAngle * 3.14159265358979) * -0.5 + 0.5 - fractTimeAngle) / 3.0) * 6.28318530717959;
vec3 sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
#elif defined END
const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
vec3 sunVec = normalize((gbufferModelView * vec4(1.0, sunRotationData * 2000.0, 1.0)).xyz);
#else
vec3 sunVec = vec3(0.0);
#endif

vec3 upVec = normalize(gbufferModelView[1].xyz);

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.1, 0.0, 0.25) * 4.0;
#endif

// Includes //
#if defined WATER_FOG || defined REFRACTION
#include "/lib/util/ToView.glsl"

#ifdef REFRACTION
#include "/lib/util/encode.glsl"
#include "/lib/post/chromaticAberration.glsl"
#endif

#ifdef WATER_FOG
#ifdef DYNAMIC_HANDLIGHT
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/lighting/handlight.glsl"
#endif

#include "/lib/water/waterFog.glsl"
#endif
#endif

// Main //
void main() {
	vec2 newTexCoord = texCoord;
	vec3 color = texture2D(colortex0, newTexCoord).rgb;

	#if defined WATER_FOG || defined REFRACTION
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	
	vec3 screenPos = vec3(texCoord, z0);
	vec3 viewPos = ToView(screenPos);
	#endif

	#ifdef REFRACTION
	if (z1 > z0) {
		vec3 distort = texture2D(colortex3, texCoord).rgb;

		if (distort.xy != vec2(0.0)) {
			float fovScale = gbufferProjection[1][1] / 1.37;

			distort = decodeNormal(distort.xy) * REFRACTION_STRENGTH;
			distort.xy *= vec2(1.0 / aspectRatio, 1.0) * fovScale / max(length(viewPos.xyz), 8.0);

			vec2 newCoord = clamp(texCoord + distort.xy, 0.0, 1.0);

			float distortMask = texture2D(colortex3, newCoord).b;
			float water = float(distortMask > 0.79 && distortMask < 0.81);
			//float glass = float(distortMask > 0.39 && distortMask < 0.41);

			if (water > 0.0 && z0 > 0.56) {
				z0 = texture2D(depthtex0, newCoord).r;
				z1 = texture2D(depthtex1, newCoord).r;
				color.rgb = texture2D(colortex0, newCoord).rgb;
				if (water > 0.5) {
					getWaterChromaticAberration(colortex0, color.rgb, newCoord, distort.xy * float(distortMask > 0.0));
				}
			}

			screenPos = vec3(newCoord.xy, z0);
			viewPos = ToView(screenPos);
		}
	}
	#endif

	#ifdef WATER_FOG
	if (isEyeInWater == 1){
		vec4 waterFog = getWaterFog(viewPos);
		color = mix(sqrt(color), sqrt(waterFog.rgb), waterFog.a);
		color *= color;
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// Varyings //
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif