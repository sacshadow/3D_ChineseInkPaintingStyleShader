// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "WJDR/StandOutLine"
{
	Properties
	{
		_Color ("Main Color", Color) = (.5,.5,.5,1)
		_MainTex ("Texture", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (0, 0, 0, 0)
		_RimRate ("Rim Rate", Range(0,5)) = 2
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_OutlineColor ("Outline Color", Color) = (1,0,0,1)
		//_OutlineColor2 ("Outline Color 2", Color) = (1,0,0,1)
		_Outline ("Outline width", Float) = 0.01
		//_GroundHeight ("Ground Height", Float) = 0.01
	}
	SubShader
	{
		//Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType" = "Opaque"}
		Tags {"RenderType"="Opaque"}
		
		ZWrite On
		
		//Pass {
		//	Cull front
		//	ZTest Greater
		//	ZWrite Off
		//
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	// make fog work
		//	#pragma multi_compile_fog
		//	
		//	#include "UnityCG.cginc"
        //
		//	struct appdata
		//	{
		//		float4 vertex : POSITION;
		//		float3 normal : NORMAL;
		//		float2 uv : TEXCOORD0;
		//	};
        //
		//	struct v2f
		//	{
		//		float2 uv : TEXCOORD0;
		//		UNITY_FOG_COORDS(1)
		//		float4 vertex : SV_POSITION;
		//	};
        //
		//	sampler2D _MainTex;
		//	float4 _MainTex_ST;
		//	
		//	half4 _OutlineColor2;
		//	float _Outline;
		//	
		//	v2f vert (appdata v)
		//	{
		//		v2f o;
		//		float4 vertex = v.vertex;
		//		vertex.xyz += UnityObjectToWorldNormal(v.normal) * _Outline;
		//		vertex.xyz += v.normal * _Outline;
		//		o.vertex = UnityObjectToClipPos(vertex);
		//		//o.vertex.xyz += UnityObjectToWorldNormal(v.normal) * _Outline;
		//		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		//		UNITY_TRANSFER_FOG(o,o.vertex);
		//		return o;
		//	}
		//	
		//	fixed4 frag (v2f i) : SV_Target
		//	{
		//		// sample the texture
		//		fixed4 col =_OutlineColor2;
		//		// apply fog
		//		//UNITY_APPLY_FOG(i.fogCoord, col);
		//		return col;
		//	}
		//	ENDCG
		//}
		
		
		Pass {
			Cull front
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			half4 _OutlineColor;
			float _Outline;
			
			v2f vert (appdata v)
			{
				v2f o;
				float4 vertex = v.vertex;
				//vertex.xyz += UnityObjectToWorldNormal(v.normal) * _Outline * (1 + sin(length(vertex.xyz) * 360) * 0.5f);
				vertex.xyz += v.normal * _Outline * (1 + sin(length(vertex.xyz) * 360) * 0.5f);
				o.vertex = UnityObjectToClipPos(vertex);
				//o.vertex.xyz += UnityObjectToWorldNormal(v.normal) * _Outline;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col =_OutlineColor;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		
		
		
		Pass
		{
			Offset 0,-10
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _Color;
			float4 _RimColor;
			float _RimRate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				
				float rim = clamp(1 - saturate ( dot(worldViewDir, worldNormal)),0,1);
				//o.rim = clamp(1 - saturate ( dot(worldViewDir, worldNormal)),0,1);
				rim = clamp(pow(rim, _RimRate) * 2,0,1);
				
				//o.color = 0.35f * _RimColor;
				//o.color += clamp(_RimColor * pow (rim, _RimRate) * 2,0,1);
				//o.color = clamp(_RimColor * pow (rim, _RimRate) * 2,0,1);
				//o.color = rim * _RimColor * 2;
				
				o.color = _RimColor;
				o.color.a = rim;
				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb = lerp(col.rgb, _RimColor.rgb, i.color.a);
				
				col *= _Color;
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		
		
		
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
