#if defined OVERWORLD
float timeBrightnessSqrt = sqrt(timeBrightness);
float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - pow(1.0 - timeBrightness, 1.5);

vec3 lightSun = mix(mix(mix(lightSunrise, lightMorning, timeBrightnessSqrt), mix(lightEvening, lightSunset, 1.0 - timeBrightnessSqrt), mefade), lightDay, dfade);
vec3 ambientSun = mix(mix(mix(ambientSunrise, ambientMorning, timeBrightnessSqrt), mix(ambientEvening, ambientSunset, 1.0 - timeBrightnessSqrt), mefade), ambientDay, dfade);

vec3 lightColRaw = mix(lightNight, lightSun, sunVisibility);
vec3 lightColSqrt = mix(lightColRaw, dot(lightColRaw, vec3(0.448, 0.880, 0.171)) * weatherCol, wetness * 0.75);
vec3 lightCol = lightColSqrt * lightColSqrt;

vec3 ambientColRaw = mix(ambientNight, ambientSun, sunVisibility);
vec3 ambientColSqrt = mix(ambientColRaw, dot(ambientColRaw, vec3(0.448, 0.880, 0.171)) * weatherCol, wetness * 0.75);
vec3 ambientCol = ambientColSqrt * ambientColSqrt;

//Per-biome weather
//Every biome specified here has a corresponding uniform in the /shaders/shaders.properties file
uniform float isSnowy, isLushCaves, isDesert, isSwamp, isMushroom, isJungle;

//Color for each biome. Format: vec3(biome_color_red, biome_color_green, biome_color_blue) * isBiome
vec3 biomeColor = vec3(0.425, 0.375, 0.150) * isLushCaves +
                  vec3(1.105, 0.705, 0.515) * (1.0 + timeBrightness * 0.5) * isDesert +
                  vec3(0.925, 1.285, 0.785) * isSwamp +
                  vec3(1.115, 0.745, 0.975) * isMushroom +
                  vec3(0.955, 1.085, 0.895) * isJungle;

//This variable toggles per-biome weather when a player enters a specific biome
float isSpecificBiome = isLushCaves + isDesert + isSwamp + isMushroom + isJungle;
#elif defined NETHER
vec3 netherCol = sqrt(normalize(fogColor + 0.00000001));
vec3 netherColSqrt = sqrt(netherCol);
#endif