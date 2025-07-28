else if (material == 12) {
    emission = pow3(lAlbedo) * float(lAlbedo > 0.7);

    if (emission > 0.0) {
        vec2 pos = (worldPos.xz + cameraPosition.xz) * 0.5 + (worldPos.xy + cameraPosition.xy) * 0.5 + (worldPos.zy + cameraPosition.zy) * 0.5;
        float lavaNoise = texture2D(noisetex, (pos + frameTimeCounter * 0.1) * 0.025).r;
        albedo.rgb = vec3(LAVA_R, LAVA_G, LAVA_B) * LAVA_I * pow4(lavaNoise) * 3.0;
    }
}