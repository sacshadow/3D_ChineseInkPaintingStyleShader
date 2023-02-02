Shader "DW/Terrain" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_CliffColor ("CliffColor", Range(0,1)) = 0
		
		_Cliff ("Cliff", 2D) = "white" {}
		_Cliff2 ("Cliff", 2D) = "white" {}
		_CliffBump ("Cliff Bump", 2D) = "bump" {}
		_CliffBump2 ("Cliff Bump", 2D) = "bump" {}
		
		_Tex0 ("Tex 0 A", 2D) = "white" {}
		_Tex1 ("Tex 1 R", 2D) = "white" {}
		_Tex2 ("Tex 2 G", 2D) = "white" {}
		_Tex3 ("Tex 3 B", 2D) = "white" {}
		
		_LayerWeight ("Layer Wight", Vector) = (1,1,1,1)
		
		_Bump0 ("Bump 0", 2D) = "bump" {}
		_Bump1 ("Bump 1", 2D) = "bump" {}
		_Bump2 ("Bump 2", 2D) = "bump" {}
		_Bump3 ("Bump 3", 2D) = "bump" {}
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert
		//#pragma surface surf Lambert vertex:vert
		
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.0
		
		sampler2D _MainTex;
		
		sampler2D _Cliff;
		sampler2D _Cliff2;
		sampler2D _CliffBump;
		sampler2D _CliffBump2;
		
		sampler2D _Tex0;
		sampler2D _Tex1;
		sampler2D _Tex2;
		sampler2D _Tex3;
		
		float4 _LayerWeight;
		
		sampler2D _Bump0;
		sampler2D _Bump1;
		sampler2D _Bump2;
		sampler2D _Bump3;
		
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_Cliff;
			float2 uv_Cliff2;
			float2 uv_CliffBump;
			float2 uv_CliffBump2;
			float2 uv_Tex0;
			float2 uv_Tex1;
			float2 uv_Tex2;
			float2 uv_Tex3;
			float2 uv_Bump0;
			float2 uv_Bump1;
			float2 uv_Bump2;
			float2 uv_Bump3;
			float3 worldPos;
			float3 pointNor;
		};
		
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.pointNor = abs(v.normal);
		}
		
		half _Glossiness;
		half _Metallic;
		half _CliffColor;
		fixed4 _Color;
		
		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 cliff = tex2D (_Cliff, IN.uv_Cliff + float2(IN.worldPos.y/100,0));
			//fixed4 cliff = tex2D (_Cliff, IN.uv_Cliff);
			fixed4 cliff2 = tex2D (_Cliff2, IN.uv_Cliff2 + float2(0,IN.worldPos.y/100));
			//fixed4 cliff2 = tex2D (_Cliff2, IN.uv_Cliff2);
			
			cliff = lerp(_CliffColor,1,cliff);
			cliff2 = lerp(_CliffColor,1,cliff2);
			
			//fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			fixed4 c = tex2D (_MainTex, float2(IN.worldPos.x/200, IN.worldPos.z/200)) * _LayerWeight;
			fixed4 t0 = tex2D (_Tex0, IN.uv_Tex0);
			fixed4 t1 = tex2D (_Tex1, IN.uv_Tex1);
			fixed4 t2 = tex2D (_Tex2, IN.uv_Tex2);
			fixed4 t3 = tex2D (_Tex3, IN.uv_Tex3);
			
			float sum = c.r + c.g + c.b + c.a/10;
			
			float4 col = t0 * c.a/10/sum + t1 * c.r/sum + t2 * c.g/sum + t3 * c.b/sum;
			
			float l = dot(float3(1,0,0), IN.pointNor);
			float l2 = dot(float3(0,0,1), IN.pointNor);
			
			//fixed2 nml = fixed2(IN.pointNor.x, IN.pointNor.z);
			//nml *= nml;
			//sum = nml.x + nml.y;
			//nml = nml / sum;
			
			//float k = dot(float3(0,1,0), IN.pointNor);
			//float k = 1 - l - l2;
			//nml *= 1 - k;
			
			//col = (col * k + cliff * nml.x * c + cliff2 * nml.y * c ) * 1.5;
			
			o.Normal = UnpackNormal (tex2D (_CliffBump, IN.uv_CliffBump));
			
			col = (col * (1-l-l2) + cliff*l + cliff2 * l2) * 1.5;
			o.Albedo = col * (col - 0.5) * _Color;
			//o.Albedo = IN.pointNor;
			// Metallic and smoothness come from slider variables
			//o.Metallic = _Metallic;
			//o.Smoothness = _Glossiness * (col.r + col.g + col.b)/3;
			//o.Alpha = c.a;
			o.Alpha = 1;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
