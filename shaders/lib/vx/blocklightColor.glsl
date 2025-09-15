vec3 getBlocklightColor(int id) {
	//Glow Lichen, Sea Pickle
	if (id == 3) return vec3(GLSP_R, GLSP_G, GLSP_B) * GLSP_I;
	//Brewing Stand
	if (id == 4) return vec3(BS_R, BS_G, BS_B) * BS_I;
	//Torch, Lantern, Campfire, Fire
	if (id == 5 || id == 15) {
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 3.0) * 5.0 + frameTimeCounter) * 0.1);
		return pow(vec3(TLCF_R, TLCF_G, TLCF_B), fireAnimation) * TLCF_I;
	}
	//Soul Torch, Soul Lantern, Soul Campfire, Soul Fire
	if (id == 6 || id == 16) {
		vec3 fireAnimation = vec3(1.0 - cos(sin(frameTimeCounter * 2.0) * 4.0 + frameTimeCounter * 1.25) * 0.15);
		return pow(vec3(SOUL_R, SOUL_G, SOUL_B), fireAnimation) * SOUL_I;
	}
	//End Rod
	if (id == 7) return vec3(ER_R, ER_G, ER_B) * ER_I;
	//Sea Lantern
	if (id == 8) return vec3(SL_R, SL_G, SL_B) * SL_I;
	//Glowstone
	if (id == 9) return vec3(GS_R, GS_G, GS_B) * GS_I;
	//Shroomlight, Redstone Lamp, Copper Bulbs
	if (id == 10) return vec3(SLRL_R, SLRL_G, SLRL_B) * SLRL_I;
	//Respawn Anchor, Crying Obsidian
	if (id == 11) return vec3(RACO_R, RACO_G, RACO_B) * RACO_I;
	//Lava
	if (id == 12) return vec3(LAVA_R, LAVA_G, LAVA_B + 0.02) * LAVA_I;
	//Cave Berries
	if (id == 13) return vec3(CB_R, CB_G, CB_B) * CB_I;
	//Amethyst
	if (id == 14) return vec3(AM_R, AM_G, AM_B) * AM_I;
	//Magma Block
	if (id == 21) return vec3(MB_R, MB_G, MB_B) * MB_I;

	#ifdef EMISSIVE_ORES
	#ifdef EMISSIVE_EMERALD_ORE
    //Emerald Ore
    if (id == 22) return normalize(vec3(0.05, 1.00, 0.15)) * 0.25;
	#endif
	#ifdef EMISSIVE_DIAMOND_ORE
    //Diamond Ore
    if (id == 23) return normalize(vec3(0.10, 0.40, 1.00)) * 0.25;
	#endif
	#ifdef EMISSIVE_COPPER_ORE
    //Copper Ore
    if (id == 24) return normalize(vec3(0.60, 0.70, 0.30)) * 0.25;
	#endif
	#ifdef EMISSIVE_LAPIS_ORE
    //Lapis Ore
    if (id == 25) return normalize(vec3(0.00, 0.10, 1.20)) * 0.25;
	#endif
	#ifdef EMISSIVE_GOLD_ORE
    //Gold Ore
    if (id == 26) return normalize(vec3(1.00, 0.75, 0.10)) * 0.25;
	#endif
	#ifdef EMISSIVE_IRON_ORE
    //Iron Ore
    if (id == 27) return normalize(vec3(0.70, 0.40, 0.30)) * 0.25;
	#endif
	#ifdef EMISSIVE_REDSTONE_ORE
    //Redstone Ore
    if (id == 28) return normalize(vec3(1.00, 0.05, 0.00)) * 0.25;
	#endif
	#endif

    //Lit Redstone Ore & Redstone Torch
    if (id == 29) return vec3(1.00, 0.05, 0.00);
    //Powered Rails & Shot Target
    if (id == 30) return vec3(1.00, 0.05, 0.00) * 0.5;
    //Nether Portal
    if (id == 31) return vec3(NP_R, NP_G, NP_B) * NP_I;
    //Orchre Froglight
    if (id == 32) return vec3(OF_R, OF_G, OF_B) * OF_I;
    //Verdant Froglight
    if (id == 33) return vec3(VF_R, VF_G, VF_B) * VF_I;
    //Pearlescent Froglight
    if (id == 34) return vec3(PF_R, PF_G, PF_B) * PF_I;

	#ifdef EMISSIVE_FLOWERS
    //Red flowers
    if (id == 35 || id == 309 || id == 310) return normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink flowers
    if (id == 36 || id == 305 || id == 306 || id == 311 || id == 312) return normalize(vec3(0.80, 0.20, 0.60)) * 0.20;
    //Yellow flowers
    if (id == 37 || id == 307 || id == 308) return normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue flowers
    if (id == 38) return normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White flowers
    if (id == 39) return normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange flowers
    if (id == 40) return normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

	//Jack-O-Lantern
	if (id == 41) return vec3(JL_R, JL_G, JL_B) * JL_I;
    //Enchanting table
    if (id == 42) return vec3(ET_R, ET_G, ET_B) * ET_I;
	//Red Candle
	if (id == 43) return normalize(vec3(1.0, 0.1, 0.1));
	//Orange Candle
	if (id == 44) return normalize(vec3(1.0, 0.5, 0.1));
	//Yellow Candle
	if (id == 45) return normalize(vec3(1.0, 1.0, 0.1));
	//Brown Candle
	if (id == 46) return normalize(vec3(0.7, 0.7, 0.0));
	//Green Candle
	if (id == 47) return normalize(vec3(0.1, 1.0, 0.1));
	//Lime Candle
	if (id == 48) return normalize(vec3(0.0, 1.0, 0.1));
	//Blue Candle
	if (id == 49) return normalize(vec3(0.1, 0.1, 1.0));
	//Light blue Candle
	if (id == 50) return normalize(vec3(0.5, 0.5, 1.0));
	//Cyan Candle
	if (id == 51) return normalize(vec3(0.1, 1.0, 1.0));
	//Purple Candle
	if (id == 52) return normalize(vec3(0.7, 0.1, 1.0));
	//Magenta Candle
	if (id == 53) return normalize(vec3(1.0, 0.1, 1.0));
	//Pink Candle
	if (id == 54) return normalize(vec3(1.0, 0.5, 1.0));
	//Black Candle
	if (id == 55) return normalize(vec3(0.3, 0.3, 0.3));
	//White Candle
	if (id == 56) return normalize(vec3(0.9, 0.9, 0.9));
	//Gray Candle
	if (id == 57) return normalize(vec3(0.5, 0.5, 0.5));
	//Light gray Candle
	if (id == 58) return normalize(vec3(0.7, 0.7, 0.7));
    //Candle
    if (id == 59) return normalize(vec3(0.6, 0.5, 0.4));
    //Beacon
    if (id == 60) return vec3(BC_R, BC_G, BC_B) * BC_I;
	//Sculk Sensor
	if (id == 62) return vec3(0.20, 0.55, 1.00) * 2.5;
	//Calibrated Sculk Sensor
	if (id == 63) return vec3(1.00, 0.25, 0.75) * 2.5;
	//Fungi
	if (id == 64) return vec3(1.0, 0.2, 0.1) * 0.1;
	//Crimson Stem & Hyphae
	if (id == 65) return vec3(1.0, 0.2, 0.1) * 0.2;
	//Warped Stem & Hyphae
	if (id == 66) return vec3(0.1, 0.5, 0.7) * 0.2;
	//Mob Spawner
	if (id == 69) return vec3(0.1, 0.01, 0.15);
	//End Portal With Eye
	if (id == 71) return vec3(EP_R, EP_G, EP_B) * EP_I;
	//Zinc Ore
	if (id == 72) return vec3(0.4);
	//Creaking Heart (Active)
	if (id == 73) return vec3(1.0, 0.3, 0.1);

	#ifdef EMISSIVE_FLOWERS
    //Red Potted flowers
    if (id == 74) return normalize(vec3(1.00, 0.05, 0.05)) * 0.20;
    //Pink Potted flowers
    if (id == 75) return normalize(vec3(0.80, 0.20, 0.60)) * 0.20;
    //Yellow Potted flowers
    if (id == 76) return normalize(vec3(0.80, 0.50, 0.05)) * 0.20;
    //Blue Potted flowers
    if (id == 77) return normalize(vec3(0.00, 0.15, 1.00)) * 0.20;
    //White Potted flowers
    if (id == 78) return normalize(vec3(0.80, 0.80, 0.80)) * 0.20;
    //Orange Potted flowers
    if (id == 79) return normalize(vec3(1.00, 0.70, 0.05)) * 0.20;
	#endif

    //Chorus
    if (id == 80) return vec3(0.12, 0.1, 0.1);

	//Generic emitters with different colors
	//Blocks in this range will emit their respective color
	//A good way to quickly make modded blocks emit light
	if (id == 194) return normalize(vec3(1.00, 0.05, 0.05)) * 0.50; //block.10194, red
	if (id == 195) return normalize(vec3(1.00, 0.70, 0.05)) * 0.50; //block.10195, orange
	if (id == 196) return normalize(vec3(0.80, 0.50, 0.05)) * 0.50; //block.10196, yellow
	if (id == 197) return normalize(vec3(0.10, 1.00, 0.10)) * 0.50; //block.10197, green
	if (id == 198) return normalize(vec3(0.00, 0.15, 1.00)) * 0.50; //block.10198, blue
	if (id == 199) return normalize(vec3(0.70, 0.10, 1.00)) * 0.50; //block.10199, purple
	if (id == 200) return normalize(vec3(0.80, 0.80, 0.80)) * 0.50; //block.10200, white
}

const vec3[] blocklightTintArray = vec3[](
	//Red
	vec3(1.0, 0.1, 0.1),
	//Orange
	vec3(1.0, 0.5, 0.1),
	//Yellow
	vec3(1.0, 1.0, 0.1),
	//Brown
	vec3(0.7, 0.7, 0.0),
	//Green
	vec3(0.1, 1.0, 0.1),
	//Lime
	vec3(0.1, 1.0, 0.5),
	//Blue
	vec3(0.1, 0.1, 1.0),
	//Light blue
	vec3(0.5, 0.5, 1.0),
	//Cyan
	vec3(0.1, 1.0, 1.0),
	//Purple
	vec3(0.7, 0.1, 1.0),
	//Magenta
	vec3(1.0, 0.1, 1.0),
	//Pink
	vec3(1.0, 0.5, 1.0),
	//Black
	vec3(0.1, 0.1, 0.1),
	//White
	vec3(0.9, 0.9, 0.9),
	//Gray
	vec3(0.3, 0.3, 0.3),
	//Light gray
	vec3(0.7, 0.7, 0.7),
	//Buffer
	vec3(0.0)
);