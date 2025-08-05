else if (material2 == 317) { // red bricks
    smoothness = 0.15 - clamp(pow3(lAlbedo) * 0.25, 0.0, 0.15);
}