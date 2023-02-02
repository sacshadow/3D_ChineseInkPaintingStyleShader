Shader "CIPR/CIPR_0_Gou_step_1" {
	Properties {
		
		_ColorRemap ("Color Remap", 2D) = "black" {}
		_DistanceCtrl("Distance {MaxDistance, outlineDrop, rimClose, rimFar}", Vector) = (128, 1, 1, 5)
		
		_RimColor ("Rim Color", Color) = (0,1,1,1)
		//_RimRate ("Rim Rate", Range(0,5)) = 1
		
		_InlineControl("Inline Ctrl{range, step, noiseSize, noise cutoff}", Vector) = (0.1,0.5,1,0.5)
		
		_OutlineColor ("Outline Color", Color) = (0.05,0.05,0.05,1)
		_OutlineNoiseFB ("Outline FeiBai", 2D) = "white" {}
		_OutlineWidth0 ("Outline width 0", Range(0, 20)) = 1
		_OutlineWidth1 ("Outline width 1", Range(0, 20)) = 1
		_OutlineNoiseCtrl ("ON Ctrl{size0, cutoff0, size1, cutoff1}", Vector) = (1,5,1,5)
	}
	SubShader {
		//Texture pass
		Pass {
			Tags { "RenderType"="Opaque"}
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float rimLight : TEXCOORD2;
				float dist : TEXCOORD3;
			};
			
			sampler2D _ColorRemap;
			sampler2D _OutlineNoiseFB;
			float4 _DistanceCtrl;
			float4 _InlineControl;
			float4 _OutlineColor;
			float4 _RimColor;
			//float _RimRate;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float rimLight = clamp(1 - saturate(dot(worldViewDir, worldNormal)),0,1);
				float rimRate = lerp(_DistanceCtrl.z, _DistanceCtrl.w, pow(clamp(dist/_DistanceCtrl.x,0,1), 0.05));
				rimLight = clamp(pow(rimLight, rimRate),0,1);
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = (worldPos.xy + worldPos.yz + worldPos.xz) * _InlineControl.z;
				o.rimLight = rimLight;
				o.dist = dist / _DistanceCtrl.x;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				// sample the texture
				fixed4 col = 1;
				
				col.rgb = lerp(col, _RimColor, i.rimLight);
				
				fixed4 noise = tex2D(_OutlineNoiseFB, i.uv);
				float a = _InlineControl.x;
				float b = clamp(1-a,0,1);
				
				
				fixed4 crm = tex2D(_ColorRemap, i.dist.xx).r * _OutlineColor;
				col.rgb = lerp(crm, col, step((i.rimLight - b)/a + noise * _InlineControl.w, _InlineControl.y));
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		
		//Outline 0
		Pass {
			Tags {"RenderType"="Opaque" "IgnoreProjector"="True" }
			Cull Front
			//Offset -10,0
			
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float dist : TEXCOORD2;
			};
			
			sampler2D _ColorRemap;
			sampler2D _OutlineNoiseFB;
			float4 _DistanceCtrl;
			float4 _OutlineColor;
			float _OutlineWidth0;
			float4 _OutlineNoiseCtrl;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * _OutlineWidth0 * 0.001 * pow(o.vertex.w, _DistanceCtrl.y);
				o.uv = (worldPos.xy + worldPos.yz + worldPos.xz) * _OutlineNoiseCtrl.x;
				o.dist = dist / _DistanceCtrl.x;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 noise = tex2D(_OutlineNoiseFB, i.uv);
				clip(noise - _OutlineNoiseCtrl.y/10);
				
				//fixed4 col = _OutlineColor;
				
				fixed4 col = tex2D(_ColorRemap, i.dist.xx).r * _OutlineColor;
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		
		//Outline 1
		Pass {
			Tags { "RenderType"="Opaque" "IgnoreProjector"="True"}
			Cull Front
			Offset 20,0
			
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float dist : TEXCOORD2;
			};
			
			sampler2D _ColorRemap;
			sampler2D _OutlineNoiseFB;
			float4 _DistanceCtrl;
			float4 _OutlineColor;
			float _OutlineWidth0;
			float _OutlineWidth1;
			float4 _OutlineNoiseCtrl;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * (_OutlineWidth0 + _OutlineWidth1) * 0.001 * pow(o.vertex.w, _DistanceCtrl.y);
				o.uv = (worldPos.xy + worldPos.yz + worldPos.xz) * _OutlineNoiseCtrl.z;
				o.dist = dist / _DistanceCtrl.x;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 noise = tex2D(_OutlineNoiseFB, i.uv);
				clip(noise - _OutlineNoiseCtrl.w/10);
				
				//fixed4 col = _OutlineColor;
				
				fixed4 col = tex2D(_ColorRemap, i.dist.xx).r * _OutlineColor;
				
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
