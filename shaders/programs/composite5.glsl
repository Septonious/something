#define COMPOSITE_5

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#ifdef VL
uniform float viewWidth, viewHeight;

uniform sampler2D colortex1;
#endif

uniform sampler2D colortex0;

// Global Variables //
#ifdef VL
const vec2 vlOffsets[4] = vec2[4](
   vec2(0.21848650099008202, -0.09211370200809937),
   vec2(-0.5866112654782878, 0.32153793477769893),
   vec2(-0.06595078555407359, -0.879656059066481),
   vec2(0.43407555004227927, 0.6502318262968816)
);
#endif

// Includes //
#ifdef VL
#include "/lib/filters/diskBlur.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef VL
	vec3 volumetrics = getDiskBlur8RGB(colortex1, texCoord, 2.0);
	volumetrics = pow8(volumetrics) * 256.0;

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