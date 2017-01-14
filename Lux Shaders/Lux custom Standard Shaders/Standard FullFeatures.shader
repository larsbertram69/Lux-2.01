Shader "Lux/Standard Lighting/Full Features" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normalmap", 2D) = "bump" {}
		[NoScaleOffset] _SpecGlossMap("Specular", 2D) = "black" {}
		// _Glossiness ("Smoothness", Range(0,1)) = 0.5
		// _SpecColor("Specular", Color) = (0.2,0.2,0.2)

		// Lux mix mapping - secondary texture set
		[Space(4)]
		[Header(Secondary Texture Set ___________________________________________________ )]
		[Space(4)]
		_Color2 ("Color", Color) = (1,1,1,1)
		[Space(4)]
		_DetailAlbedoMap("Detail Albedo (RGB) Occlusion (A)", 2D) = "grey" {}
		[NoScaleOffset] _DetailNormalMap("Normal Map", 2D) = "bump" {}
		// Additional properties
		[NoScaleOffset] _SpecGlossMap2 ("Specular", 2D) = "black" {}

		// Lux parallax extrusion properties
		[Space(4)]
		[Header(Parallax Extrusion ______________________________________________________ )]
		[Space(4)]
		[NoScaleOffset] _ParallaxMap ("Height (G) (Mix Mapping: Height2 (A) Mix Map (B)) PuddleMask (R)", 2D) = "white" {}
		_ParallaxTiling ("Parallax Tiling", Float) = 1

		// [Lux_TextureTilingDrawer] _UVRatio ("UV Ratio", Vector) = (1,1,0,0)
		_Parallax ("Height Scale", Range (0.005, 0.1)) = 0.02
		[Space(4)]
		[Toggle(EFFECT_BUMP)] _EnablePOM("Enable POM", Float) = 0.0
		_LinearSteps("- Linear Steps", Range(4, 256.0)) = 20

		// Lux dynamic weather properties
		[Space(4)]
		[Header(Dynamic Snow ______________________________________________________ )]
		[Space(4)]
		_SnowSlopeDamp("Snow Slope Damp", Range (0.0, 8.0)) = 1.0
		[Lux_SnowAccumulationDrawer] _SnowAccumulation("Snow Accumulation", Vector) = (0,1,0,0)
		[Space(4)]
		[Lux_TextureTilingDrawer] _SnowTiling ("Snow Tiling", Vector) = (2,2,0,0)
		_SnowNormalStrength ("Snow Normal Strength", Range (0.0, 2.0)) = 1.0
		[Lux_TextureTilingDrawer] _SnowMaskTiling ("Snow Mask Tiling", Vector) = (0.3,0.3,0,0)
		[Lux_TextureTilingDrawer] _SnowDetailTiling ("Snow Detail Tiling", Vector) = (4.0,4.0,0,0)
		_SnowDetailStrength ("Snow Detail Strength", Range (0.0, 1.0)) = 0.5
		_SnowOpacity("Snow Opacity", Range (0.0, 1.0)) = 0.5

		[Space(4)]
		[Header(Dynamic Wetness ______________________________________________________ )]
		[Space(4)]
		_WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5
		[Toggle(LOD_FADE_CROSSFADE)] _EnableIndependentPuddleMaskTiling("Enable independent Puddle Mask Tiling", Float) = 0.0
		_PuddleMaskTiling ("- Puddle Mask Tiling", Float) = 1

		[Header(Texture Set 1)]
		_WaterColor("Water Color (RGB) Opacity (A)", Color) = (0,0,0,0)
		[Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)
		// Mix mapping enabled so we need a 2nd Input
		[Header(Texture Set 2)]
		_WaterColor2("Water Color (RGB) Opacity (A)", Color) = (0,0,0,0)
		[Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles2("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)
		
		[Space(4)]
		_Lux_FlowNormalTiling("Flow Normal Tiling", Float) = 2.0
		_Lux_FlowSpeed("Flow Speed", Range (0.0, 2.0)) = 0.05
		_Lux_FlowInterval("Flow Interval", Range (0.0, 8.0)) = 1
		_Lux_FlowRefraction("Flow Refraction", Range (0.0, 0.1)) = 0.02
		_Lux_FlowNormalStrength("Flow Normal Strength", Range (0.0, 2.0)) = 1.0

		// Lux diffuse Scattering properties
        [Header(Diffuse Scattering Texture Set 1 ______________________________________ )]
        [Space(4)]
        _DiffuseScatteringCol("Diffuse Scattering Color", Color) = (0,0,0,1)
        _DiffuseScatteringBias("Scatter Bias", Range(0.0, 0.5)) = 0.0
        _DiffuseScatteringContraction("Scatter Contraction", Range(1.0, 10.0)) = 8.0
        // As we use mix mapping
        [Header(Diffuse Scattering Texture Set 2 ______________________________________ )]
        [Space(4)]
        _DiffuseScatteringCol2("Diffuse Scattering Color", Color) = (0,0,0,1)
        _DiffuseScatteringBias2("Scatter Bias", Range(0.0, 0.5)) = 0.0
        _DiffuseScatteringContraction2("Scatter Contraction", Range(1.0, 10.0)) = 8.0
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf LuxStandardSpecular fullforwardshadows vertex:vert
		#pragma target 3.0
        
        // Distinguish between simple parallax mapping and parallax occlusion mapping
		#pragma shader_feature _ EFFECT_BUMP
		// Enable mix mapping 
		#define GEOM_TYPE_BRANCH_DETAIL
		// Make mix mapping use texture input
		#define GEOM_TYPE_LEAF
		#define _SNOW
		#define _WETNESS_FULL
		// Allow independed puddle mask tiling
		#pragma shader_feature _ LOD_FADE_CROSSFADE

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxParallax.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"
		#include "../Lux Core/Lux Features/LuxDiffuseScattering.cginc"

		struct Input {
			float2 lux_uv_MainTex;			// Important: we must not use standard uv_MainTex as we need access to _MainTex_ST
			float2 uv_DetailAlbedoMap;
			float3 viewDir;
			float3 worldNormal;
			INTERNAL_DATA
			// Lux
			float4 color : COLOR0;			// Important: declare color expilicitely as COLOR0
			float4 lux_worldPosDistance;	// needed by Water_Ripples
			float2 lux_flowDirection;		// needed by Water_Flow			
		};

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecGlossMap;
		// half _Glossiness;
		
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			// Lux
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	    	o.color = v.color;
	    	// Calc Tangent Space Rotation
			float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal.xyz );
			// Store FlowDirection
			o.lux_flowDirection = ( mul(rotation, mul(_World2Object, float4(0,1,0,0)).xyz) ).xy;
			// Store world position and distance to camera
			float3 worldPosition = mul(_Object2World, v.vertex);
			o.lux_worldPosDistance.xyz = worldPosition;
			o.lux_worldPosDistance.w = distance(_WorldSpaceCameraPos, worldPosition);
		}


		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {
			
			// Initialize the Lux fragment structure. Always do this first.
            // LUX_SETUP(float2 main UVs, float2 secondary UVs, half3 view direction in tangent space, float3 world position, float distance to camera, float2 flow direction, fixed4 vertex color)
			LUX_SETUP(IN.lux_uv_MainTex.xy, IN.uv_DetailAlbedoMap, IN.viewDir, IN.lux_worldPosDistance.xyz, IN.lux_worldPosDistance.w, IN.lux_flowDirection, IN.color)

			// We use the LUX_PARALLAX macro which handles PM or POM and sets lux.height, lux.puddleMaskValue and lux.mipmapValue
			LUX_PARALLAX

		//  ///////////////////////////////
        //  From now on we should use lux.finalUV (float4!) to do our texture lookups.

        	// As we want to to accumulate snow according to the per pixel world normal we have to get the per pixel normal in tangent space up front using extruded final uvs from LUX_PARALLAX
            // As mixMapping is enabled we have to get both normals and blend them properly.
			o.Normal = UnpackNormal( lerp( tex2D(_BumpMap, lux.finalUV.xy), tex2D(_DetailNormalMap, lux.finalUV.zw), lux.mixmapValue.y ) );
		
			// In case independent puddle mask tiling is enabled we will have to sample _ParallaxMap again.
			#if defined (LOD_FADE_CROSSFADE)
				lux.puddleMaskValue = tex2D(_ParallaxMap, lux.finalUV.xy * _PuddleMaskTiling).r;
			#endif

			// Calculate Snow and Water Distribution and get the refracted UVs in case water ripples and/or water flow are enabled
			// LUX_INIT_DYNAMICWEATHER(half puddle mask value, half snow mask value, half3 tangent space normal)
			LUX_INIT_DYNAMICWEATHER(lux.puddleMaskValue, 1.0, o.Normal)	

		//  ///////////////////////////////
        //  Do your regular stuff:
        	// We do manually mixmapping for all output members here.
			fixed4 c = tex2D (_MainTex, lux.finalUV.xy) * _Color;
			fixed4 d = tex2D (_DetailAlbedoMap, lux.finalUV.zw) * _Color2;
			o.Albedo = lerp(c.rgb, d.rgb, lux.mixmapValue.y);
			half4 specGloss = lerp( tex2D(_SpecGlossMap, lux.finalUV.xy), tex2D(_SpecGlossMap2, lux.finalUV.zw), lux.mixmapValue.y);
			o.Specular = specGloss.rgb; //_SpecColor;
			o.Smoothness = specGloss.a; //c.a;
		//	In case uvs might be refracted by water ripples or water flow we will have to sample the normal a second time :-(
			o.Normal = UnpackNormal( lerp( tex2D(_BumpMap, lux.finalUV.xy), tex2D(_DetailNormalMap, lux.finalUV.zw), lux.mixmapValue.y ) );
			o.Alpha = 1;
		//  ///////////////////////////////

			// Apply dynamic water and snow		
			LUX_APPLY_DYNAMICWEATHER
			// Then add diffuse scattering
			LUX_DIFFUSESCATTERING(o.Albedo, o.Normal, IN.viewDir)


		}
		ENDCG
	}
	FallBack "Diffuse"
}
