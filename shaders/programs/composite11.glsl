#define COMPOSITE_12

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int frameCounter;

uniform float viewWidth, viewHeight;

#ifdef DH_SCREENSPACE_SHADOWS
uniform float timeAngle;
uniform float near, far;
uniform float dhNearPlane, dhFarPlane;

uniform vec3 sunPosition;

uniform sampler2D dhDepthTex1;
#endif

uniform sampler2D noisetex, depthtex1;
uniform sampler2D colortex0;

#ifdef GI
uniform sampler2D colortex3;
uniform sampler2D shadowcolor0, shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 shadowModelView, shadowProjection;
#endif

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

#ifdef DH_SCREENSPACE_SHADOWS
uniform mat4 dhProjection, dhProjectionInverse;
#endif

// Global Variables //
#ifdef DH_SCREENSPACE_SHADOWS
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
float caveFactor = mix(clamp((cameraPosition.y - 56.0) / 16.0, float(sign(isEyeInWater)), 1.0), 1.0, eBS);
float sunVisibility = clamp((dot( sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.15) * 3.0, 0.0, 1.0);
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#endif

// Includes //
#if defined GI || defined DH_SCREENSPACE_SHADOWS
#include "/lib/util/transformMacros.glsl"
#include "/lib/util/ToScreen.glsl"
#include "/lib/util/ToView.glsl"
#include "/lib/util/ToWorld.glsl"
#endif

#ifdef GI
#include "/lib/util/encode.glsl"
#include "/lib/lighting/rsm.glsl"
#endif

#ifdef DH_SCREENSPACE_SHADOWS
#include "/lib/util/ToViewDH.glsl"
#include "/lib/lighting/screenSpaceDHShadows.glsl"
#endif

// Main //
void main() {
	vec4 color = texture2D(colortex0, texCoord);

    #if defined GI || defined DH_SCREENSPACE_SHADOWS
	vec3 gi = vec3(0.0);
	float shadow = 0.0;

    float z1 = texture2D(depthtex1, texCoord).r;

    vec3 screenPos = vec3(texCoord, z1);
    vec3 viewPos = ToView(screenPos);
    vec3 worldPos = ToWorld(viewPos);
    #endif

	#ifdef DH_SCREENSPACE_SHADOWS
	float dhZ1 = texture2D(dhDepthTex1, texCoord).r;

	shadow = screenSpaceDHShadows(z1, dhZ1);
	#endif

	#ifdef GI
    vec3 gbuffersData = texture2D(colortex3, texCoord).rgb;
    vec3 normal = normalize(decodeNormal(gbuffersData.rg));
    vec3 worldNormal = normalize(ToWorld(normal * 100000.0));

	gi = computeRSM(worldNormal, worldPos, viewPos, z1);
	#endif

    #if defined GI || defined DH_SCREENSPACE_SHADOWS
        /* DRAWBUFFERS:06 */
        gl_FragData[0] = color;
        gl_FragData[1].rgb = gi;
    #else
        /* DRAWBUFFERS:0 */
        gl_FragData[0] = color;
    #endif
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif