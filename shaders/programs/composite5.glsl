#include "/lib/common.glsl"

#define COMPOSITE_5

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
	vec2( 1.5,  0.5),
	vec2(-0.5,  1.5),
	vec2(-1.5, -0.5),
	vec2( 0.5, -1.5)
);
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef VL
	vec3 volumetrics = texture2D(colortex1, texCoord + vlOffsets[0] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[1] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[2] / vec2(viewWidth, viewHeight)).rgb;
		 volumetrics+= texture2D(colortex1, texCoord + vlOffsets[3] / vec2(viewWidth, viewHeight)).rgb;
	volumetrics *= 0.25;
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