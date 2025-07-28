else if (material >= 7 && material < 12 && material != 10 || material == 31) {
    emission = lAlbedo * lAlbedo * 0.5;
    if (material == 11) smoothness = (0.3 + lAlbedo) * (1.0 - emission);
}