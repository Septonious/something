#define GBUFFERS_TERRAIN

#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec4 color;
in vec3 normal;
in vec2 texCoord, lmCoord;
flat in int mat;

// Uniforms //
uniform int isEyeInWater;
uniform int frameCounter;

#ifdef VC_SHADOWS
uniform int worldDay, worldTime;
#endif

uniform float frameTimeCounter;
uniform float viewWidth, viewHeight;
uniform float blindFactor, nightVision;
#if MC_VERSION >= 11900
uniform float darknessFactor;
#endif

#ifdef OVERWORLD
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
#endif

uniform ivec2 eyeBrightnessSmooth;
uniform vec3 cameraPosition;
uniform vec4 lightningBoltPosition;

uniform sampler2D texture, noisetex;

#ifdef VX_SUPPORT
uniform sampler3D floodfillSampler, floodfillSamplerCopy;
uniform usampler3D voxelSampler;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

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
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#include "/lib/util/encode.glsl"
#include "/lib/util/bayerDithering.glsl"
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToNDC.glsl"
#include "/lib/util/ToWorld.glsl"
#include "/lib/util/ToShadow.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/pbr/ggx.glsl"

#ifdef VX_SUPPORT
#include "/lib/vx/blocklightColor.glsl"
#include "/lib/vx/voxelization.glsl"
#endif

#include "/lib/lighting/lightning.glsl"
#include "/lib/lighting/shadows.glsl"

#ifdef VC_SHADOWS
#include "/lib/lighting/cloudShadows.glsl"
#endif

#include "/lib/lighting/gbuffersLighting.glsl"

#ifdef GENERATED_EMISSION
#include "/lib/pbr/generatedPBR.glsl"
#endif

// Main //
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;

    vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
    vec3 newNormal = normal;
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = ToNDC(screenPos);
    vec3 worldPos = ToWorld(viewPos);

	float leaves = float(mat == 10314);
	float saplings = float(mat == 10317);
	float foliage = float(mat >= 10304 && mat <= 10319 || mat >= 10035 && mat <= 10040) * (1.0 - leaves) * (1.0 - saplings);
	float subsurface = leaves + foliage * 0.6 + saplings * 0.4;
    float emission = 0.0, smoothness = 0.0, metalness = 0.0, parallaxShadow = 0.0;
    
	if (foliage > 0.5) {
		float foliageNormalDistance = min(1.0, length(viewPos.xz) / shadowDistance);
		newNormal = normalize(upVec) * (1.0 - foliageNormalDistance * 0.4 * timeBrightness);
	}

	float NoU = clamp(dot(newNormal, upVec), -1.0, 1.0);
	float NoL = clamp(dot(newNormal, lightVec), 0.0, 1.0);
	float NoE = clamp(dot(newNormal, eastVec), -1.0, 1.0);

	#ifdef GENERATED_EMISSION
	generateIPBR(albedo, worldPos, viewPos, lightmap, NoU, emission, smoothness, metalness, subsurface);
	#endif

    vec3 shadow = vec3(0.0);
    gbuffersLighting(albedo, screenPos, viewPos, worldPos, newNormal, shadow, lightmap, NoU, NoL, NoE, subsurface, emission, smoothness, parallaxShadow);

	/* DRAWBUFFERS:03 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(encodeNormal(newNormal), 0.0, clamp(mix(smoothness, 1.0, metalness * metalness), 0.0, 0.95));
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec4 color;
out vec3 normal;
out vec2 texCoord, lmCoord;
flat out int mat;

// Uniforms //
#ifdef TAA
uniform float viewWidth, viewHeight;
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Attributes //
attribute vec4 mc_Entity;

#if defined WAVING_PLANTS || defined WAVING_LEAVES
attribute vec4 mc_midTexCoord;
#endif

// Includes //
#ifdef TAA
#include "/lib/antialiasing/jitter.glsl"
#endif

#if defined WAVING_LEAVES || defined WAVING_PLANTS
#include "/lib/pbr/waving.glsl"
#endif

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
    color = gl_Color;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    mat = int(mc_Entity.x + 0.5);

	//Position
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	#if defined WAVING_PLANTS || defined WAVING_LEAVES
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = getWavingBlocks(position.xyz, istopv, lmCoord.y);
	#endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

	//TAA jittering
    #ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif
}

#endif