else if (material2 == 309) {//Quartz blocks
    smoothness = clamp(pow4(length(pow(albedo.rgb, vec3(7.0)))) * 0.7, 0.0, 1.0);
}