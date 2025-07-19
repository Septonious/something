vec3 getReflection(vec3 viewPos, vec3 normal, vec3 reflectionFade) {
	vec3 reflectedVector = reflect(normalize(viewPos), normal) * 64.0;
	vec3 reflectedScreenPos = ToScreen(viewPos + reflectedVector);
	vec4 reflection = vec4(0.0);

    bool outsideScreen = !(any(lessThan(reflectedScreenPos.xy, vec2(0.0))) || any(greaterThan(reflectedScreenPos.xy, vec2(1.0))));
    if (outsideScreen){
        reflection = texture2D(gaux1, reflectedScreenPos.xy);
		reflection.rgb = pow8(reflection.rgb * 2.0);
    }

    return mix(reflectionFade, reflection.rgb, reflection.a);
}