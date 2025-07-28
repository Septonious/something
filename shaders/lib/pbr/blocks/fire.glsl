else if (material == 15 || material == 16) {
    vec2 pos = worldPos.zy + cameraPosition.zy + worldPos.xy + cameraPosition.xy;
    pos.y *= 0.25;
    float fireNoise = texture2D(noisetex, (pos + vec2(0.0, -frameTimeCounter * 2.0)) * 0.05).r;

    albedo.rgb = length(albedo.rgb) * vec3(TLCF_R, TLCF_G, TLCF_B) * TLCF_I * pow4(fireNoise) * 4.0;
}