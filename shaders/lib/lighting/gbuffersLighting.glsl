void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, inout vec3 shadow, in vec2 lightmap, 
                      in float NoU, in float NoL, in float NoE,
                      in float subsurface, in float emission, in float smoothness, in float parallaxShadow) {
    //Variables
    float lViewPos = length(viewPos.xz);
    float lAlbedo = length(albedo.rgb);
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

    //Floodfill Lighting. Works only on Iris
    #if !defined GBUFFERS_BASIC && !defined GBUFFERS_WATER && !defined GBUFFERS_TEXTURED && !defined DH_TERRAIN && !defined DH_WATER && defined VX_SUPPORT
    vec3 voxelPos = worldToVoxel(worldPos);

    float floodfillFade = maxOf(abs(worldPos) / (voxelVolumeSize * 0.5));
          floodfillFade = clamp(floodfillFade, 0.0, 1.0);

    vec3 voxelLighting = vec3(0.0);

    if (isInsideVoxelVolume(voxelPos) && emission == 0.0) {
        vec3 voxelSamplePos = voxelPos + worldNormal;
             voxelSamplePos /= voxelVolumeSize;
             voxelSamplePos = clamp(voxelSamplePos, 0.0, 1.0);

        vec3 lightVolume = vec3(0.0);
        if ((frameCounter & 1) == 0) {
            lightVolume = texture3D(floodfillSamplerCopy, voxelSamplePos).rgb;
        } else {
            lightVolume = texture3D(floodfillSampler, voxelSamplePos).rgb;
        }
        voxelLighting = pow(lightVolume, vec3(1.0 / FLOODFILL_RADIUS));

        #ifdef GBUFFERS_ENTITIES
        voxelLighting += pow16(lightmap.x) * blockLightCol;
        #endif

        float mixFactor = 1.0 - floodfillFade * floodfillFade;

        blockLighting = mix(blockLighting, voxelLighting * FLOODFILL_BRIGHTNESS, mixFactor * 0.95);
    }
    #endif

    //Shadow Calculations
    //Some code made by Emin and gri573
    float shadowLightingFade = maxOf(abs(worldPos) / (vec3(shadowDistance, shadowDistance + 64.0, shadowDistance)));
          shadowLightingFade = clamp(shadowLightingFade, 0.0, 1.0);
          shadowLightingFade = 1.0 - pow3(shadowLightingFade);

    //Subsurface scattering
    float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
    float sss = 0.0;

    if (subsurface > 0.0) {
        sss = pow8(VoL) * shadowFade * (1.0 - wetness * 0.5);
        NoL += subsurface * shadowLightingFade;
        NoL = mix(NoL, 1.0, sss * subsurface);
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
                  distanceBias = 0.1 + 0.0004 * distanceBias * (1.0 - float(subsurface > 0.0));
            vec3 bias = worldNormal * distanceBias * (2.0 - 0.95 * max(NoL, 0.0));

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
        float fade = clamp(lViewPos * 0.01, 0.0, 1.0);
        float offset = 0.00075 - shadowMapResolution * 0.0000001; 
              offset *= 1.0 + subsurface * (3.0 - 3.5 * fade);

        shadow = computeShadow(shadowPos, offset, subsurface, lightmap.y, 1.0 - fade);
    }
    vec3 realShadow = shadow;
    vec3 fakeShadow = getFakeShadow(lightmap.y);

    shadow = mix(fakeShadow, shadow, vec3(shadowLightingFade)) * clamp(NoL * 1.01 - 0.01, 0.0, 1.0);
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

    //Lightning Flash
    float lightning = min(lightningFlashEffect(worldPos, lightningBoltPosition.xyz, 256.0) * lightningBoltPosition.w * 4.0, 1.0);
    vec3 lightningFlash = vec3(lightning) * (clamp(dot(lightningBoltPosition.xyz, worldNormal), 0.0, 1.0) * 0.9 + 0.1) * lightmap.y;

    //Specular Highlight
    vec3 specularHighlight = vec3(0.0);

    #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK) && !defined NETHER
    if (emission < 0.01 && lightmap.y > 0.0) {
        vec3 baseReflectance = vec3(0.1);

        float smoothnessF = 0.2 + lAlbedo * 0.2 + NoL * 0.2;
        #if defined DH_TERRAIN && defined END
              smoothnessF += 0.15;
        #endif
              smoothnessF = mix(smoothnessF, 0.95, smoothness);

        #ifdef OVERWORLD
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, lightCol, shadow * vanillaDiffuse, color.a);
        #else
        specularHighlight = getSpecularHighlight(normal, viewPos, smoothnessF, baseReflectance, endLightCol * 0.25, shadow * vanillaDiffuse, color.a);
        #endif

        specularHighlight = clamp(specularHighlight * 4.0, vec3(0.0), vec3(8.0));
    }
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
    albedo.rgb *= sceneLighting + blockLighting + emission + specularHighlight + lightningFlash;
    albedo.rgb *= vanillaDiffuse;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}