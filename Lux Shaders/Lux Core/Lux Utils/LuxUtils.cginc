#ifndef LUX_UTILS_INCLUDED
#define LUX_UTILS_INCLUDED

//-------------------------------------------------------------------------------------

#define LUX_METALLIC_TO_SPECULAR \
    o.Specular = lerp (unity_ColorSpaceDielectricSpec.rgb, o.Albedo, o.Metallic); \
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a; \
    half oneMinusReflectivity = oneMinusDielectricSpec - o.Metallic * oneMinusDielectricSpec; \
    o.Albedo *= oneMinusReflectivity;

//-------------------------------------------------------------------------------------

// Some Copies from the original Standard Utils cginc - so we do not have to include it

half3 Lux_BlendNormals(half3 n1, half3 n2)
{
    return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
}

half3 Lux_UnpackScaleNormal(half2 packednormal, half bumpScale)
{
    
    half3 normal;
    normal.xy = (packednormal.xy * 2 - 1);
    #if (SHADER_TARGET >= 30)
        // SM2.0: instruction count limitation
        // SM2.0: normal scaler is not supported
        normal.xy *= bumpScale;
    #endif
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    return normal;
    
}

//-------------------------------------------------------------------------------------

// little helpers for GI calculation
/*
#define UNITY_GLOSSY_ENV_FROM_SURFACE(x, s, data)				\
	Unity_GlossyEnvironmentData g;								\
	g.roughness		= 1 - s.Smoothness;							\
	g.reflUVW		= reflect(-data.worldViewDir, s.Normal);	\


	#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
		#define UNITY_GI(x, s, data) x = UnityGlobalIllumination (data, s.Occlusion, s.Normal);
	#else
		#define UNITY_GI(x, s, data) 								\
			UNITY_GLOSSY_ENV_FROM_SURFACE(g, s, data);				\
			x = UnityGlobalIllumination (data, s.Occlusion, s.Normal, g);
	#endif

    */

#endif // LUX_UTILS_INCLUDED
