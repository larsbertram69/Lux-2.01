#ifndef FILE_UNIQUESHADOW_SHADOWSAMPLE
#define FILE_UNIQUESHADOW_SHADOWSAMPLE

#if defined(UNIQUE_SHADOW) || defined(UNIQUE_SHADOW_LIGHT_COOKIE)
	#if (defined(DIRECTIONAL) && !defined(UNIQUE_SHADOW_LIGHT_COOKIE)) || (defined(DIRECTIONAL_COOKIE) && defined(UNIQUE_SHADOW_LIGHT_COOKIE))
		#define USE_UNIQUE_SHADOW
	#endif
#endif

#ifndef USE_UNIQUE_SHADOW
	#define UNIQUE_SHADOW_SAMPLE(i)				1.f
	#define UNIQUE_SHADOW_INTERP(i)
	#define UNIQUE_SHADOW_TRANSFER(o)
	#define UNIQUE_SHADOW_ATTENUATION(i)		1.f
	#define UNIQUE_SHADOW_SHADOW_ATTENUATION(i)	(SHADOW_ATTENUATION(i) * UNIQUE_SHADOW_ATTENUATION(i))
	#define UNIQUE_SHADOW_LIGHT_ATTENUATION(i)	(LIGHT_ATTENUATION(i) * UNIQUE_SHADOW_ATTENUATION(i))
#endif

#ifdef USE_UNIQUE_SHADOW //<-ends at the very bottom

#if defined(SHADER_API_D3D11) && !defined(UNIQUE_SHADOW_FORCE_CHEAP)

cbuffer POISSON_DISKS {
	static half2 poisson[40] = {
		half2(0.02971195f, 0.8905211f),
		half2(0.2495298f, 0.732075f),
		half2(-0.3469206f, 0.6437836f),
		half2(-0.01878909f, 0.4827394f),
		half2(-0.2725213f, 0.896188f),
		half2(-0.6814336f, 0.6480481f),
		half2(0.4152045f, 0.2794172f),
		half2(0.1310554f, 0.2675925f),
		half2(0.5344744f, 0.5624411f),
		half2(0.8385689f, 0.5137348f),
		half2(0.6045052f, 0.08393857f),
		half2(0.4643163f, 0.8684642f),
		half2(0.335507f, -0.110113f),
		half2(0.03007669f, -0.0007075319f),
		half2(0.8077537f, 0.2551664f),
		half2(-0.1521498f, 0.2429521f),
		half2(-0.2997617f, 0.0234927f),
		half2(0.2587779f, -0.4226915f),
		half2(-0.01448214f, -0.2720358f),
		half2(-0.3937779f, -0.228529f),
		half2(-0.7833176f, 0.1737299f),
		half2(-0.4447537f, 0.2582748f),
		half2(-0.9030743f, 0.406874f),
		half2(-0.729588f, -0.2115215f),
		half2(-0.5383645f, -0.6681151f),
		half2(-0.07709587f, -0.5395499f),
		half2(-0.3402214f, -0.4782109f),
		half2(-0.5580465f, 0.01399586f),
		half2(-0.105644f, -0.9191031f),
		half2(-0.8343651f, -0.4750755f),
		half2(-0.9959937f, -0.0540134f),
		half2(0.1747736f, -0.936202f),
		half2(-0.3642297f, -0.926432f),
		half2(0.1719682f, -0.6798802f),
		half2(0.4424475f, -0.7744268f),
		half2(0.6849481f, -0.3031401f),
		half2(0.5453879f, -0.5152272f),
		half2(0.9634013f, -0.2050581f),
		half2(0.9907925f, 0.08320642f),
		half2(0.8386722f, -0.5428791f)
	};
};

uniform Texture2D u_UniqueShadowTexture;
uniform SamplerComparisonState sampleru_UniqueShadowTexture;

uniform Texture2D u_UniqueShadowTextureFakePoint;
uniform SamplerState sampleru_UniqueShadowTextureFakePoint;

uniform half2 u_UniqueShadowBlockerWidth;
uniform half u_UniqueShadowBlockerDistanceScale;
uniform half2 u_UniqueShadowLightWidth;

uniform sampler2D unity_RandomRotation16;

uniform samplerCUBE _ShadowsCube;
uniform half4 _ShadowsCubeRoot;

half SampleUniqueD3D11(half4 uv, half4 screen) {
	float dist = u_UniqueShadowTextureFakePoint.Sample(sampleru_UniqueShadowTextureFakePoint, float2(0,0)).a;
	for(int j = 0; j < 10; ++j) {
		const half2 poi = poisson[j + 24];
		const half2 off = poi * u_UniqueShadowBlockerWidth;
		float depth = u_UniqueShadowTexture.Sample(sampleru_UniqueShadowTextureFakePoint, uv.xy + off).r;
		
		float d = uv.z - depth;
		dist += max(0.f, d);
	}
	dist *= u_UniqueShadowBlockerDistanceScale;
	
#if 0
	const float randomRotationTextureSize = 1.f / 16.f;
	float4 rotation = tex2D(unity_RandomRotation16, screen.xy * _ScreenParams.xy * randomRotationTextureSize) * 2.f - 1.f;
#elif 0
	const half s = sin(uv.x * 20.f);
	const half c = cos(uv.y * 20.f);
#endif

	half shadow = 0.f;
	for(int i = 0; i < 32; ++i) {
		const float c_LightWidth = lerp(u_UniqueShadowLightWidth.x, u_UniqueShadowLightWidth.y, min(1.f, dist));

#if 0
		half2 poi = poisson[i];
		poi.x = dot( poi.xy, rotation.rg );
		poi.y = dot( poi.xy, rotation.ba );
		const half2 rotPoi = poi;
#else
		const half2 poi = poisson[i];
		//const half2 rotPoi = half2(c * poi.x - s * poi.y, s * poi.x + c * poi.y);
		const half2 rotPoi = poi;
#endif

		const half2 off = rotPoi * c_LightWidth;
		shadow += u_UniqueShadowTexture.SampleCmpLevelZero(sampleru_UniqueShadowTexture, uv.xy + off, uv.z);
	} 

	return shadow / 32.f;
}

#define UNIQUE_SHADOW_SAMPLE(i) SampleUniqueD3D11(i.uniqueShadowPos, half4(0,0,0,0)/*i.pos*/)

#else//defined(SHADER_API_D3D11) && !defined(UNIQUE_SHADOW_FORCE_CHEAP)

static half2 poisson[8] = {
	half2(0.02971195f, -0.8905211f),
	half2(0.2495298f, 0.732075f),
	half2(-0.3469206f, -0.6437836f),
	half2(-0.01878909f, 0.4827394f),
	half2(-0.2725213f, -0.896188f),
	half2(-0.6814336f, 0.6480481f),
	half2(0.4152045f, -0.2794172f),
	half2(0.1310554f, 0.2675925f),
};

// Normally, we would just force define SHADOWS_NATIVE to auto-set these correctly,
// but that currently seems to cause issues with surface shaders.
#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_D3D9)
	#undef UNITY_DECLARE_SHADOWMAP
	#undef UNITY_SAMPLE_SHADOW
#endif
#if defined(SHADER_TARGET_GLSL)
	// OpenGL-like platforms, when "native shadow maps" are supported: special hlsl2glsl syntax
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2DShadow tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) shadow2D (tex,(coord).xyz)
#elif defined(SHADER_API_D3D9)
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) tex2Dproj (tex,float4((coord).xyz,1)).r
#endif

UNITY_DECLARE_SHADOWMAP(u_UniqueShadowTexture);
uniform half2 u_UniqueShadowFilterWidth;

half SampleUniqueD3D9OGL(const half4 coords) {
	half4 uv = coords;
	half shadow = 0.f;
	for(int i = 0; i < 8; ++i) {
		uv.xy = coords.xy + poisson[i] * u_UniqueShadowFilterWidth;
		shadow += UNITY_SAMPLE_SHADOW(u_UniqueShadowTexture, uv.xyz);
	} 
	return shadow / 8.f;
}

#define UNIQUE_SHADOW_SAMPLE(i) SampleUniqueD3D9OGL(i.uniqueShadowPos)

#endif//defined(SHADER_API_D3D11) && !defined(UNIQUE_SHADOW_FORCE_CHEAP)


uniform float4x4 u_UniqueShadowMatrix;

#define UNIQUE_SHADOW_INTERP(i)				half4 uniqueShadowPos : TEXCOORD##i ;
#define UNIQUE_SHADOW_TRANSFER(o)			o.uniqueShadowPos = mul(u_UniqueShadowMatrix, float4(posWorld.xyz, 1.f));
#define UNIQUE_SHADOW_ATTENUATION(i)		UNIQUE_SHADOW_SAMPLE(i)
#define UNIQUE_SHADOW_SHADOW_ATTENUATION(i)	(SHADOW_ATTENUATION(i) * UNIQUE_SHADOW_ATTENUATION(i))
#define UNIQUE_SHADOW_LIGHT_ATTENUATION(i)	(LIGHT_ATTENUATION(i) * UNIQUE_SHADOW_ATTENUATION(i))

#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD) || defined(UNIQUE_SHADOW_FORCE_REPLACE_BUILTIN)
	#undef SHADOW_COORDS
	#undef TRANSFER_SHADOW
	#undef SHADOW_ATTENUATION
	#define SHADOW_COORDS(i)					UNIQUE_SHADOW_INTERP(i)
	#define TRANSFER_SHADOW						o.uniqueShadowPos = mul(u_UniqueShadowMatrix, float4(worldPos.xyz, 1.f));
	#define SHADOW_ATTENUATION(i)				UNIQUE_SHADOW_SAMPLE(i);
#endif

#endif//USE_UNIQUE_SHADOWS
#endif //FILE_UNIQUESHADOW_SHADOWSAMPLE