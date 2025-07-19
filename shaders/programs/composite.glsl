#include "/lib/common.glsl"

#define COMPOSITE

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform sampler2D colortex0;

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = pow(color, vec3(2.2));
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