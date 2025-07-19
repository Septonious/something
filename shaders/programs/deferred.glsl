#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int isEyeInWater;

#ifdef OVERWORLD
uniform int moonPhase;
uniform float timeAngle, timeBrightness, wetness;
#endif

uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

// Pipeline Options //
const bool colortex4Clear = false;

// Global Variables //
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
vec3 eastVec = normalize(gbufferModelView[0].xyz);

#ifdef OVERWORLD
float eBS = eyeBrightnessSmooth.y / 240.0;
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp((dot( sunVec, upVec) + 0.25) * 2.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.25) * 2.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"

#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/sunMoon.glsl"

#ifdef STARS
#include "/lib/atmosphere/stars.glsl"
#endif
#endif

// Main //
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

    float z0 = texture2D(depthtex0, texCoord).r;
	vec3 viewPos = ToView(vec3(texCoord, z0));
	vec3 worldPos = ToWorld(viewPos);

    #if defined OVERWORLD
    vec3 atmosphereColor = getAtmosphere(viewPos);
	#elif defined NETHER
	vec3 atmosphereColor = netherColSqrt.rgb * 0.25;
	#elif defined END
	vec3 atmosphereColor = endLightCol * 0.15;
	#endif

	#if defined OVERWORLD || defined END
	vec3 nViewPos = normalize(viewPos);

	float VoU = dot(nViewPos, upVec);
	float VoS = clamp(dot(nViewPos, sunVec), 0.0, 1.0);
	float VoM = clamp(dot(nViewPos, -sunVec), 0.0, 1.0);
	#endif

    if (z0 == 1.0) {
        color = atmosphereColor * (1.0 + Bayer8(gl_FragCoord.xy) / 32.0 - 0.25);

		float occlusion = 0.0;

		#ifdef OVERWORLD
		drawSunMoon(color, worldPos, nViewPos, VoU, VoS, VoM, caveFactor, occlusion);
		#endif

		if (VoU > 0.0) {
			float nebulaFactor = 0.0;

			#ifdef STARS
			drawStars(color, worldPos, sunVec, VoU, VoS, caveFactor, nebulaFactor, occlusion, 0.6);
			#endif
		}

		color *= 1.0 - blindFactor;
		#if MC_VERSION >= 11900
		color *= 1.0 - darknessFactor;
		#endif
    }

    /* DRAWBUFFERS:04 */
    gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, 1.0);
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif