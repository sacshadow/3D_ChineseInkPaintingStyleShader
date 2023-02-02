Shader "WJDR/CIPR_00_Terrain"
{
	Properties
	{
		_Color ("Main Color", Color) = (0.898,0.8588,0.8235,1)
		_ColorRemap("Color Remap {distance r}", 2D) = "black" {}
		_RemapCtrl("RC{dis x, noise y, depth z, dry w}", Vector) = (256,128,0.6,0.25)
		
		_OutlineMC ("MatCap {outline r, inline g, noise b, strokes a}", 2D) = "black" {}
		_OutlineWidth0 ("Outline width 0", Range(0, 20)) = 1
		_OutlineWidth1 ("Outline width 1", Range(0, 20)) = 1
		_OutlineCtrl ("OC{offset x, persp y, size zw}", Vector) = (0,1,10,10)
		
		_InlineCtrl ("IC{offset x, persp y, size zw}", Vector) = (0,1,10,10)
		_InlineStroke ("{size col} noise xy stroke zw", Vector) = (0.5,0.5,2,0.6)
		_InlineStrokeColor ("Inline width 0", Range(0, 4)) = 2
			
		_RimRate ("Rim Rate", Range(0,10)) = 2
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	}
	SubShader
	{	
		//Color Pass
		Pass
		{
			
			Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
			LOD 100
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
        
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
        
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
        
			struct v2f
			{
				float4 pos : SV_POSITION;
				// float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 mcrm : TEXCOORD2;
				LIGHTING_COORDS(3,4)
			};
			
			sampler2D _OutlineMC;
			sampler2D _ColorRemap;
			float4 _Color;
			float4 _InlineCtrl;
			float4 _InlineStroke;
			float4 _RemapCtrl;
			float _InlineStrokeColor;
			float _RimRate;
			
			v2f vert (appdata v)
			{
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				float3 map = cross(worldNormal, worldViewDir);
				map = mul((float3x3)UNITY_MATRIX_V, map);
				float rand = (1 + sin(length(worldPos.xyz) * 180))*0.5;
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				extend = float2(extend.y,extend.x)*0.5 + 0.5;
				
				float rim = clamp(1 - saturate ( dot(worldViewDir, worldNormal)),0,1);
				rim = clamp(pow(rim, _RimRate) * 2,0,1);
				float range = clamp(lerp(-_InlineCtrl.x/10,1,length(map.xy)),0,1);
				
				v2f o;
				// o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = worldPos.yx + worldPos.xz + worldPos.yz;
				// o.uv = worldPos.xy + worldPos.zy;
				o.mcrm.xy = normalize(map.xy + extend) * range * _InlineCtrl.zw/10 * 0.5 + 0.5;
				// o.mcrm.xy = normalize(map.xy) * range * _InlineCtrl.zw/10 * 0.5 + 0.5;
				o.mcrm.z = rim;
				o.mcrm.w = length(worldPos - _WorldSpaceCameraPos)/_RemapCtrl.x;
				// o.mcrm.zw = extend.xy;
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				
				return o;
			}
        
			fixed4 frag (v2f i) : SV_Target
			{
				// fixed noise0 = tex2D(_OutlineMC, i.uv/_InlineStroke.x).b;
				fixed noise1 = tex2D(_OutlineMC, i.uv/_InlineStroke.z/10).a;
				// fixed c = tex2D(_OutlineMC, i.mcrm.xy).g;
				// fixed4 col = tex2D(_ColorRemap, i.mcrm.ww) * _Color;
				// col.xy = i.uv;
				// col.xy = i.mcrm.zw;
				// col.xy = (i.mcrm.zw + i.mcrm.xy)/2;
				
				// col = 1-c* clamp(i.mcrm.z  - noise0*_InlineStroke.y - noise1*_InlineStroke.w,0,1)*(1-col)*_InlineStrokeColor;
				// col = 1 - noise0*_InlineStroke.y - noise1*_InlineStroke.w;
				// col = 1 - noise1*_InlineStroke.w;
				
				// float attenuation = lerp(0.5 * noise1,1,LIGHT_ATTENUATION(i));
				float attenuation = lerp(0.5,1,LIGHT_ATTENUATION(i));
				fixed4 col = 1 * attenuation;
				
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
				// return 1;
				
				// return 1-i.mcrm.z * c;
				// return 1-c*i.mcrm.z * clamp(0.6 + noise*0.4,0,1);
			}
			ENDCG
		}
		
		//Outline 0
		Pass
		{
			Tags { "RenderType"="Opaque"}
			Cull Front
			
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float2 mcUV : TEXCOORD2;
				float4 rmUV : TEXCOORD3;
			};
			
			sampler2D _OutlineMC;
			sampler2D _ColorRemap;
			
			float4 _RemapCtrl;
			float4 _OutlineCtrl;
			float _OutlineWidth0;
			// float _RimRate;
			float _Cutoff;

			v2f vert (appdata v)
			{
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				float3 map = cross(worldNormal, worldViewDir);
				map = mul((float3x3)UNITY_MATRIX_V, map);
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				float rand = (1 + sin(length(worldPos.xyz) * 180))*0.5;
				
				// float rim = clamp(1 - saturate ( dot(worldViewDir, worldNormal)),0,1);
				// rim = clamp(pow(rim, _RimRate) * 2,0,1);
				float range = clamp(lerp(-_OutlineCtrl.x/10,1,length(map.xy)),0,1);
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * _OutlineWidth0 * 0.01 * pow(o.vertex.w, _OutlineCtrl.y)*rand;
				o.vertex.z += -0.001;
				o.uv = v.uv;
				o.mcUV = normalize(normalize(map.xy) + float2(-extend.y,extend.x)) * range * _OutlineCtrl.zw/10 * 0.5 + 0.5;
				o.rmUV = length(worldPos - _WorldSpaceCameraPos)/_RemapCtrl.x;
				// o.color = 0;
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed noise = tex2D(_OutlineMC, i.vertex.xy/_RemapCtrl.y*i.rmUV.y*100).b;
				fixed mask = tex2D(_OutlineMC, i.mcUV).r;
				fixed4 col = tex2D(_ColorRemap, i.rmUV);
				col.rgb = 1 - ((1-col.rgb) * mask * clamp(_RemapCtrl.z + noise,0,1.1));
				// fixed4 col = 0;
				// col.xy = i.mcUV;
				
				clip(mask - _Cutoff);
				
				clip(noise - _RemapCtrl.w);
				
				UNITY_APPLY_FOG(i.fogCoord, col);
				// return mask;
				// return 1 - mask;
				return col;
			}
			ENDCG
		}
		
		//Outline 1
		Pass
		{
			Tags { "RenderType"="Opaque"}
			Cull Front
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
        
			#include "UnityCG.cginc"
        
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
        
			struct v2f
			{
				float2 rmUV : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};
			
			sampler2D _OutlineMC;
			sampler2D _ColorRemap;
			float4 _RemapCtrl;
			float4 _OutlineCtrl;
			float _OutlineWidth1;
			
			v2f vert (appdata v)
			{
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				float rand = (1 + sin(length(worldPos.xyz) * 180))*0.5;
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * _OutlineWidth1 * 0.01 * pow(o.vertex.w, _OutlineCtrl.y)*rand;
				o.vertex.z -= 0.001;
				o.rmUV = length(worldPos - _WorldSpaceCameraPos)/_RemapCtrl.x;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
        
			fixed4 frag (v2f i) : SV_Target
			{
				fixed noise = tex2D(_OutlineMC, i.vertex.xy/(_RemapCtrl.y*i.rmUV.y)).b;
				fixed4 col = tex2D(_ColorRemap, i.rmUV);
				col.rgb = 1 - ((1-col.rgb) * clamp(_RemapCtrl.z + noise,0,1.1));
				
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
			
			
		}
		
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		
	}
	FallBack "Diffuse"
}
