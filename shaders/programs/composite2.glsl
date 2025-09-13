#define COMPOSITE_2

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#if defined VL || defined LPV_FOG
uniform float viewWidth, viewHeight;

uniform sampler2D colortex1;
#endif

uniform sampler2D colortex0;

// Includes //
#if defined VL || defined LPV_FOG
#include "/lib/filters/diskBlur.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#if defined VL || defined LPV_FOG
	vec3 volumetrics = getDiskBlur8RGB(colortex1, texCoord, 2.0);
	     volumetrics *= volumetrics;

	color += volumetrics;
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
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