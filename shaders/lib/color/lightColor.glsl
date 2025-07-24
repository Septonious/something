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