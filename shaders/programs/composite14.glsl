#include "/lib/common.glsl"

#define COMPOSITE14

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
#ifdef BLOOM
uniform float viewWidth, viewHeight;
#endif

uniform sampler2D colortex0;
uniform sampler2D colortex2;

#ifdef BLOOM
uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex1;

uniform mat4 gbufferProjectionInverse;
#endif

// Pipeline Options //
const bool colortex0MipmapEnabled = true;
const bool colortex1MipmapEnabled = true;
const bool colortex2Clear = false;

// Includes //
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

// Main //
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	vec3 temporalColor = vec3(0.0);
	#ifdef TAA
		 temporalColor = texture2D(colortex2, texCoord).gba;
	#endif

	float temporalData = 0.0;

	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	color = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS) / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD));
	color = pow(color, vec3(1.0 / 2.2));
	colorSaturation(color);
	color += (Bayer8(gl_FragCoord.xy) - 0.25) / 128.0;

	/* DRAWBUFFERS:12 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(temporalData, temporalColor);
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