#include "/lib/common.glsl"

#define COMPOSITE15

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform int frameCounter;

#if defined FXAA || defined TAA
uniform float viewWidth, viewHeight;
uniform float aspectRatio;
#endif

uniform sampler2D depthtex1;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

#if defined MOTION_BLUR || defined TAA
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView, gbufferModelViewInverse;
#endif

uniform mat4 gbufferProjectionInverse;

// Pipeline Constants //
const bool colortex1MipmapEnabled = true;

// Includes //
#ifdef MOTION_BLUR
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/motionBlur.glsl"
#endif

#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef TAA
#include "/lib/util/reprojection.glsl"
#include "/lib/antialiasing/taa.glsl"
#endif

// Main //
void main() {
	vec2 newTexCoord = texCoord;

	#if defined MOTION_BLUR || defined TAA
	float z1 = texture2D(depthtex1, newTexCoord).r;
	#endif

    vec3 color = texture2DLod(colortex1, newTexCoord, 0).rgb;
	#ifdef FXAA
		 color = FXAA311(color);	
	#endif

	#ifdef MOTION_BLUR
		 color = getMotionBlur(color, z1);
	#endif

	vec4 previousColor = vec4(texture2D(colortex2, newTexCoord).r, 0.0, 0.0, 0.0);
	#ifdef TAA
	     previousColor = TemporalAA(color, previousColor.r, z1);
	#endif

    /* DRAWBUFFERS:12 */
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(previousColor);
}

#endif

//**//**//**//**//**//**//**//**//**//**//**//**//**//**//

#ifdef VSH

// VSH Data //
out vec2 texCoord;

void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}

#endif