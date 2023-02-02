Shader "WJDR/HouseRoofTile"
{
	Properties {
		_Color ("Color", Color) = (0.5,0.5,0.5,0.5)
		_TexTop ("Top (RGB)", 2D) = "white" {}
		_TexSide ("Side (RGB)", 2D) = "white" {}
		_DetailTop ("Detail Top (RGB)", 2D) = "white" {}
		_DetailSide ("Detail Side (RGB)", 2D) = "white" {}
		
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

		struct Input {
			float3 worldPos;
			float3 pointNor;
			float3 worldNor;
		};
		
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.pointNor = abs(v.normal);
			o.worldNor = UnityObjectToWorldNormal(v.normal);
		}
		
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float2 nzy = IN.worldPos.zy + float2(IN.worldPos.x, 0);
			float2 nzx = IN.worldPos.zx + float2(IN.worldPos.y, 0);
			float2 nxy = IN.worldPos.xy + float2(IN.worldPos.z, 0);
		
			float2 dir = normalize(IN.worldNor.zx);
			float2 dtuv = mul(float2x2(dir.y, -dir.x, dir.x, dir.y), IN.worldPos.zx) * _ScaleTDetail.xy;
		
			float3 tx = tex2D(_TexSide, nzy * _ScaleTex.zw) * tex2D(_DetailSide, nzy * _ScaleTDetail.zw);
			float3 ty = tex2D(_TexTop, nzx * _ScaleTex.xy) * tex2D(_DetailTop, dtuv);
			float3 tz = tex2D(_TexSide, nxy * _ScaleTex.zw) * tex2D(_DetailSide, nxy * _ScaleTDetail.zw);
			
			float3 rt = tx * IN.pointNor.x + ty * IN.pointNor.y + tz * IN.pointNor.z;
			
			o.Albedo = rt * _Color.rgb * 2;
			// o.Albedo.rg = abs(normalize(IN.worldNor.zx));
			// o.Albedo.b = 0;
			
			o.Alpha = _Color.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}


// {
	// Properties
	// {
		// _MainTex ("Texture", 2D) = "white" {}
		// _ScaleX("Scale X" , float) = 1
		// _ScaleY("Scale Y" , float) = 1
	// }
	// SubShader
	// {
		// Tags { "RenderType"="Opaque" }
		// LOD 100

		// Pass
		// {
			// CGPROGRAM
			// #pragma vertex vert
			// #pragma fragment frag
			// make fog work
			// #pragma multi_compile_fog
			
			// #include "UnityCG.cginc"

			// struct appdata
			// {
				// float4 vertex : POSITION;
				// float3 normal : NORMAL;
				
			// };

			// struct v2f
			// {
				// float2 uv : TEXCOORD0;
				// UNITY_FOG_COORDS(1)
				// float4 vertex : SV_POSITION;
				// float3 normal : NORMAL;
			// };

			// sampler2D _MainTex;
			// float _ScaleX;
			// float _ScaleY;
			
			// v2f vert (appdata v)
			// {
				// v2f o;
				// o.vertex = UnityObjectToClipPos(v.vertex);
				
				// o.uv = mul(unity_ObjectToWorld, v.vertex).xz;
				// o.uv.x *= _ScaleX;
				// o.uv.y *= _ScaleY;
				
				// o.normal = UnityObjectToWorldNormal(v.normal);
				// o.normal.xz = normalize(o.normal.xz);
				
				// UNITY_TRANSFER_FOG(o,o.vertex);
				// return o;
			// }
			
			// fixed4 frag (v2f i) : SV_Target
			// {

				// float2 dir = i.normal.zx;
				// float2 uv = mul(float2x2(dir.y, dir.x, -dir.x, dir.y), i.uv);

				// fixed4 col = tex2D(_MainTex, uv);
				// UNITY_APPLY_FOG(i.fogCoord, col);
				
				// return col;
			// }
			// ENDCG
		// }
	// }
// }
