Shader "Lux/Translucent Lighting/Dynamic Weather" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normalmap", 2D) = "bump" {}
		[NoScaleOffset] _SpecGlossMap("Specular", 2D) = "black" {}
		// _Glossiness ("Smoothness", Range(0,1)) = 0.5
		// _SpecColor("Specular", Color) = (0.2,0.2,0.2)

		// Lux translucent lighting properties
		[Space(4)]
		[Header(Translucent Lighting ______________________________________________________ )]
		[Space(4)]
		[NoScaleOffset] _TranslucencyTex ("Ambient Occlusion (G) Lokal Thickness (B)", 2D) = "white" {}
		_TranslucenyStrength ("Translucency Strength", Range(0,1)) = 1
		_ScatteringPower ("Scattering Power", Range(0,8)) = 4

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
		
		[Header(Dynamic Wetness ______________________________________________________ )]
		[Space(4)]
		_WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5
		[Space(4)]
		_WaterColor("Water Color", Color) = (0,0,0,0)
		[Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)
		_Lux_FlowNormalTiling("Flow Normal Tiling", Float) = 2.0
		_Lux_FlowSpeed("Flow Speed", Range (0.0, 2.0)) = 0.05
		_Lux_FlowInterval("Flow Interval", Range (0.0, 8.0)) = 1
		_Lux_FlowRefraction("Flow Refraction", Range (0.0, 0.1)) = 0.02
		_Lux_FlowNormalStrength("Flow Normal Strength", Range (0.0, 2.0)) = 1.0


	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf LuxTranslucentSpecular fullforwardshadows vertex:vert
		#pragma target 3.0
        
		#define _SNOW
		#define _WETNESS_FULL
		// Define Translucent Lighting – needed by Dynamic Weather
		#define LOD_FADE_PERCENTAGE 

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxTranslucentPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecGlossMap;
		sampler2D _TranslucencyTex;
		// All other inputs are defined in the includes

		struct Input {
			float2 lux_uv_MainTex;
			float3 viewDir;
			float3 worldNormal;
			INTERNAL_DATA
			// Lux
			float4 color : COLOR0;			// Important: declare color expilicitely as COLOR0
			float4 lux_worldPosDistance;	// needed by Water_Ripples
			float2 lux_flowDirection;		// needed by Water_Flow			
		};

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


		void surf (Input IN, inout SurfaceOutputLuxTranslucentSpecular o) {
			
			// Initialize the Lux fragment structure. Always do this first.
            // LUX_SETUP(float2 main UVs, float2 secondary UVs, half3 view direction in tangent space, float3 world position, float distance to camera, float2 flow direction, fixed4 vertex color)
			LUX_SETUP(IN.lux_uv_MainTex, float2(0,0), IN.viewDir, IN.lux_worldPosDistance.xyz, IN.lux_worldPosDistance.w, IN.lux_flowDirection, IN.color)

			// As we want to to accumulate snow according to the per pixel world normal we have to get the per pixel normal in tangent space up front using extruded final uvs from LUX_PARALLAX
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.lux_uv_MainTex));
			
			// As we do not have a height map here, we set height to Normal.z to get some variation in the water accumulation
			LUX_SET_HEIGHT( o.Normal.z )
		
			// Calculate Snow and Water Distrubution and get the refracted UVs in case water ripples and/or water flow are enabled
			// LUX_INIT_DYNAMICWEATHER(half puddle mask value, half snow mask value, half3 tangent space normal)
			LUX_INIT_DYNAMICWEATHER(1, 1, o.Normal)

		//  ///////////////////////////////
        //  Do your regular stuff:

			fixed4 c = tex2D (_MainTex, lux.finalUV.xy) * _Color;
			o.Albedo = c.rgb;
			half4 specGloss = tex2D(_SpecGlossMap, lux.finalUV.xy);
			o.Specular = specGloss.rgb;
			o.Smoothness = specGloss.a;
			o.Alpha = c.a;

			o.Normal = UnpackNormal(tex2D(_BumpMap, lux.finalUV.xy));

			half4 transOcclusion = tex2D(_TranslucencyTex, lux.finalUV.xy);
			o.Occlusion = transOcclusion.g;

		//	Lux: Write translucent lighting parameters to the output struct
			o.Translucency = transOcclusion.b * _TranslucenyStrength;
			o.ScatteringPower = _ScatteringPower;
		//  ///////////////////////////////

			// Apply dynamic water and snow
			LUX_APPLY_DYNAMICWEATHER

		}
		ENDCG
	}
	FallBack "Diffuse"
}
