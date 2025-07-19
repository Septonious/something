void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, inout vec3 shadow, in vec2 lightmap, 
                      in float NoU, in float NoL, in float NoE,
                      in float subsurface, in float emission) {
    //Variables
    float NoLm = NoL;
    float lViewPos = length(viewPos.xz);
    float ao = color.a * color.a;
    vec3 worldNormal = normalize(ToWorld(normal * 100000000.0));

    //Vanilla Directional Lighting
    float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;

    #ifdef GBUFFERS_TERRAIN
    NoL = pow(NoL, 1.0 + float(subsurface > 0.5) * 0.5);
    #endif

    //Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 2.0 + max(lightmap.x - 0.05, 0.0);
          blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - min(emission, 1.0));
    #ifdef OVERWORLD
         blockLighting *= 1.0 - pow4(lightmap.y) * 0.75;
    #endif

    //Shadow Calculations
    //Some code made by Emin and gri573
    float shadowLightingFade = maxOf(abs(worldPos) / (vec3(shadowDistance, shadowDistance + 64.0, shadowDistance)));
          shadowLightingFade = clamp(shadowLightingFade, 0.0, 1.0);
          shadowLightingFade = 1.0 - pow3(shadowLightingFade);

    //Subsurface scattering
    float sss = 0.0;

    if (subsurface > 0.0) {
        float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
        sss = pow8(VoL) * shadowFade * (1.0 - wetness * 0.5);
        if (subsurface > 0.49 && subsurface < 0.51) {
            NoL += 0.3 * shadowLightingFade * (1.0 + sss * 0.5);
        } else if (subsurface > 0.39 && subsurface < 0.41) {
            NoL += 0.1;
        } else if (subsurface > 0.09 && subsurface < 0.11) {
            NoL += 0.25;
        } else {
            NoL += 0.3 * shadowLightingFade;
            NoL = mix(NoL, 1.0, 0.75 * min(sss * 2.0, 1.0) * shadowLightingFade);
        }
    }

    //Scene Lighting
    #ifndef NETHER
    if (NoL > 0.0001 && shadowLightingFade > 0.0) {
        float lightmapS = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);

        vec3 worldPosM = worldPos;

        #ifdef GBUFFERS_TEXTURED
            vec3 centerWorldPos = floor(worldPos + cameraPosition) - cameraPosition + 0.5;
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmapS);
        #else
            //Shadow bias without peter-panning
            float distanceBias = pow(dot(worldPos, worldPos), 0.75);
                  distanceBias = 0.12 + 0.0008 * distanceBias;
            vec3 bias = worldNormal * distanceBias * (2.0 - 0.95 * max(NoLm, 0.0));

            //Fix light leaking in caves
            if (lightmapS < 0.999) {
                #ifdef GBUFFERS_HAND
                    worldPosM = mix(vec3(0.0), worldPosM, 0.2 + 0.8 * lightmapS);
                #else
                    vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));

                    #ifdef GBUFFERS_WATER
                        bias *= 0.7;
                        worldPosM += (1.0 - lightmapS) * edgeFactor;
                    #endif

                    worldPosM += (1.0 - pow2(pow2(max(color.a, lightmapS)))) * edgeFactor;
                #endif
            }

            worldPosM += bias;
        #endif

        vec3 shadowPos = ToShadow(worldPosM);
        float offset = 0.001 - shadowMapResolution * 0.0000001;
        float vpsFade = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);

        shadow = computeShadow(shadowPos, offset, subsurface, lightmap.y, vpsFade);
    }
    vec3 realShadow = shadow;
    vec3 fakeShadow = getFakeShadow(lightmap.y);

    shadow = mix(fakeShadow, shadow, vec3(shadowLightingFade)) * clamp(NoLm * 1.01 - 0.01, 0.0, 1.0);
    #endif

    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;

    vec3 sceneLighting = mix(ambientCol * lightmap.y, lightCol, shadow * rainFactor * shadowFade);
         sceneLighting *= 1.0 + sss * shadow;
    #elif defined END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, shadow) * 0.25;
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.035;
    #endif

    //Minimal Lighting
    #if defined OVERWORLD || defined END
    sceneLighting += minLightCol * (1.0 - lightmap.y);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.2, 0.3, 0.2);

    //Vanilla AO
    float aoMixer = (1.0 - ao) * (1.0 - pow6(lightmap.x));
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, aoMixer);

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= sceneLighting + blockLighting + emission;
    albedo.rgb *= vanillaDiffuse;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}