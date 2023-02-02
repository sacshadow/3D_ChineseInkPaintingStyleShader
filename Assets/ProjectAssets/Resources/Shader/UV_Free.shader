Shader "WJDR/UV_Free" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_TexTop ("Top (RGB)", 2D) = "white" {}
		_TexSide ("Side (RGB)", 2D) = "white" {}
		_DetailTop ("Detail Top (RGB)", 2D) = "white" {}
		_DetailSide ("Detail Side (RGB)", 2D) = "white" {}
		_EmissionRate ("EmissionRate", Range(0,1)) = 0
		
		_ScaleTex ("Scale Tex (top x, top y, side x , side y)", Vector) = (1,1,1,1)
		_ScaleTDetail ("Scale Detail (top x, top y, side x , side y)", Vector) = (1,1,1,1)
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert
		#pragma target 4.0

		sampler2D _TexTop;
		sampler2D _TexSide;
		sampler2D _DetailTop;
		sampler2D _DetailSide;
		
		float4 _ScaleTex;
		float4 _ScaleTDetail;
		float _EmissionRate;

		struct Input {
			float3 worldPos;
			float3 pointNor;
		};
		
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.pointNor = abs(v.normal);
		}
		
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float2 nzy = IN.worldPos.zy + float2(IN.worldPos.x, 0);
			float2 nzx = IN.worldPos.zx + float2(IN.worldPos.y, 0);
			float2 nxy = IN.worldPos.xy + float2(IN.worldPos.z, 0);
		
			float3 tx = tex2D(_TexSide, nzy * _ScaleTex.zw) * (tex2D(_DetailSide, nzy * _ScaleTDetail.zw)*0.8+0.2);
			float3 ty = tex2D(_TexTop, nzx * _ScaleTex.xy) * (tex2D(_DetailTop, IN.worldPos.zx * _ScaleTDetail.xy)*0.8+0.2);
			float3 tz = tex2D(_TexSide, nxy * _ScaleTex.zw) * (tex2D(_DetailSide, nxy * _ScaleTDetail.zw)*0.8+0.2);
			
			float3 rt = tx * IN.pointNor.x + ty * IN.pointNor.y + tz * IN.pointNor.z;
			
			
			o.Albedo = rt * _Color.rgb;
			o.Emission = o.Albedo * _EmissionRate;
			o.Alpha = _Color.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
