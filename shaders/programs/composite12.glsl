#define COMPOSITE_12

// Settings //
#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#ifdef GI
uniform float far, near;
uniform float viewWidth, viewHeight;

uniform sampler2D depthtex0;

uniform sampler2D colortex3;
uniform sampler2D colortex6;
#endif

uniform sampler2D colortex0;

// Pipelone Options //
const bool colortex6MipmapEnabled = true;
const bool colortex6Clear = false;

// Includes //
#ifdef GI
#include "/lib/util/encode.glsl"
#include "/lib/filters/ssptDenoiser.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	#ifdef GI
    vec3 gi = denoiseSSPT(colortex6, texCoord);

    /* DRAWBUFFERS:06 */
	gl_FragData[0].rgb = color;
    gl_FragData[1].rgb = gi;
    #else
    /* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = color;
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