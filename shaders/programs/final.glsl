#include "/lib/common.glsl"

#ifdef FSH

// VSH Data //
in vec2 texCoord;

// Uniforms //
uniform sampler2D colortex1;

uniform float viewWidth, viewHeight;

// Pipeline Options //
const bool shadowHardwareFiltering = false;
const int noiseTextureResolution = 256;
const float shadowDistanceRenderMul = 1.0;
const float wetnessHalflife = 128.0;

/*
const int colortex0Format = R11F_G11F_B10F; //Main scene
const int colortex1Format = RGB8; //Final scene
const int colortex4Format = RGBA16; //Reflections
*/

// Includes //
#if MC_VERSION >= 11200
#include "/lib/post/sharpenFilter.glsl"
#endif

// Main //
void main() {
    vec3 color = texture2D(colortex1, texCoord).rgb;

	#if MC_VERSION >= 11200
	sharpenFilter(color, texCoord);
	#endif

    gl_FragColor.rgb = color;
}

#endif


//**//**//**//**//**//**//**//**//**//**//**//**//**//**//


#ifdef VSH

// VSH Data //
out vec2 texCoord;

// Main //
void main() {
    texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif