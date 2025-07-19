#include "/lib/common.glsl"

#define SHADOW

#ifdef FSH

// VSH Data //
flat in int mat;
in vec2 texCoord;
in vec4 color;

// Uniforms //
uniform sampler2D tex;

// Main //
void main() {
    vec4 albedo = texture2D(tex, texCoord) * color;

	float glass = float(mat == 3);

	if (albedo.a < 0.01) discard;

    #ifdef SHADOW_COLOR
	albedo.rgb = mix(vec3(1.0), albedo.rgb, 1.0 - pow(1.0 - albedo.a, 1.5));
	albedo.rgb *= albedo.rgb;
	albedo.rgb *= 1.0 - pow32(albedo.a);

	if (glass > 0.5 && albedo.a < 0.35) discard;
	#endif
	
	gl_FragData[0] = albedo;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

// VSH Data //
flat out int mat;
out vec2 texCoord;
out vec4 color;

// Uniforms //
uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

// Attributes //
attribute vec4 mc_Entity;

// Main //
void main() {
	texCoord = gl_MultiTexCoord0.xy;

	mat = int(mc_Entity.x);
	
	//Color & Position
	color = gl_Color;

	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();

	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif