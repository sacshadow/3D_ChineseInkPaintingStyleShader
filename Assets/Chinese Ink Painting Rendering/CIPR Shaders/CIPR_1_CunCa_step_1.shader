Shader "CIPR/CIPR_1_CunCa_step_1" {
	Properties {
		
		_ColorRemap ("Color Remap", 2D) = "black" {}
		_DistanceCtrl("Distance {MaxDistance, outlineDrop, rimClose, rimFar}", Vector) = (128, 1, 1, 5)
		
		_RimColor ("Rim Color", Color) = (0,1,1,1)
		_LambertRim ("Lambert <=> RimLight", Range(0,1)) = 0.5
		
		//Gou
		_InlineControl("Inline Ctrl{range, step, noiseSize, cutoff}", Vector) = (0.1,0.5,1,0.5)
		_OutlineColor ("Outline Color", Color) = (0.05,0.05,0.05,1)
		_OutlineNoiseFB ("Outline FeiBai", 2D) = "white" {}
		_OutlineNoiseColor ("Outline Noise Color", 2D) = "white" {}
		_OutlineCtrl ("Outline Ctrl{width 0, width 1, period, amount}", Vector) = (5,2.5,1,0.1)
		_OutlineNoiseCtrl ("ON Ctrl{size0, cutoff0, size1, cutoff1}", Vector) = (1,5,1,5)
		_OutlineColorRand ("OC Rand{size, range,,}", Vector) = (1,2,1,1)
		
		//CunCa
		_Stroke("Stroke", 2D) = "white" {}
		_Noise("Noise", 2D) = "white" {}
		
		_Size("Size {cun, ca, ran, noise}", Vector) = (50,25,100,5)
		_AreaBegin("Area Begin{cun, ca, ran, noise_cun}", Vector) = (0.2,0.3, 0.4, 0)
		_AreaEnd("Area End{cun, ca, ran, noise_ca}", Vector) = (0.6,0.7, 1, 1)
		_Dark("Dark {cun, ca, ran, noise}", Vector) = (1,1,1,1)
		
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
			#include "UnityLightingCommon.cginc"
			
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
				float diff : TEXCOORD4;
				float4 rduv : TEXCOORD5;
				float3 worldPos : TEXCOORD6;
				float3 normal : TEXCOORD7;
			};
			
			sampler2D _ColorRemap;
			sampler2D _OutlineNoiseFB;
			sampler2D _OutlineNoiseColor;
			sampler2D _Stroke;
			sampler2D _Noise;
			float _LambertRim;
			float4 _DistanceCtrl;
			float4 _InlineControl;
			float4 _OutlineColor;
			float4 _RimColor;
			float4 _OutlineColorRand;
			float4 _Size;
			float4 _AreaBegin;
			float4 _AreaEnd;
			float4 _Dark;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float rimLight = clamp(1 - saturate(dot(worldViewDir, worldNormal)),0,1);
				float rimRate = lerp(_DistanceCtrl.z, _DistanceCtrl.w, pow(clamp(dist/_DistanceCtrl.x,0,1), 0.05));
				rimLight = clamp(pow(rimLight, rimRate),0,1);
				
				float nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.rimLight = rimLight;
				o.dist = dist / _DistanceCtrl.x;
				o.diff = pow(1-nl,2);
				o.rduv.xy = (worldPos.xy + worldPos.yz + worldPos.xz) * _InlineControl.z;
				o.rduv.zw = -(worldPos.xy + worldPos.yz + worldPos.xz) * _InlineControl.z;
				o.worldPos = worldPos;
				o.normal = worldNormal;
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 col = 1;
				
				float area = lerp(i.diff, i.rimLight, _LambertRim);
				//float area = i.diff;
				//float area = i.rimLight;
				
				//col.rgb = lerp(col, _RimColor, i.rimLight);
				col.rgb = lerp(col, _RimColor, area);
				
				fixed4 outlineNoise = tex2D(_OutlineNoiseFB, i.rduv.xy);
				float a = _InlineControl.x;
				float b = clamp(1-a,0,1);
				
				fixed4 crm = tex2D(_ColorRemap, i.dist.xx).r * _OutlineColor;
				fixed colNoise = tex2D(_OutlineNoiseColor, i.vertex.xy/_OutlineColorRand.x/10).r;
				fixed range = _OutlineColorRand.y/10;
				colNoise = (round(colNoise*3)/3)*range - range/4;
				crm.rgb += colNoise;
				
				//fixed cun = pow(tex2D(_Stroke, i.rduv.xy/_Size.x).r, _Dark.x);
				//fixed ca = pow(tex2D(_Stroke, i.rduv.zw/_Size.y).r, _Dark.y);
				fixed noise = pow(tex2D(_Noise, i.rduv.xy/_Size.w).b,_Dark.w);
				
				fixed strokeTop = tex2D(_Stroke, i.worldPos.xz/_Size.x).r;
				fixed strokeForward = tex2D(_Stroke, i.worldPos.xy/_Size.x).g;
				fixed strokeSide = tex2D(_Stroke, i.worldPos.zy/_Size.x).b;
				fixed strokeBottom = tex2D(_Stroke, i.worldPos.xz/_Size.x).a;
				
				fixed cun = strokeTop;
				cun = lerp(cun, strokeForward,i.normal.z);
				cun = lerp(cun, strokeSide,i.normal.x);
				cun = lerp(cun, strokeBottom,max(-i.normal.y,0));
				
				cun = pow(cun, _Dark.x);
				cun = lerp(1, clamp(cun + noise * _AreaBegin.w,0,1), smoothstep(_AreaBegin.x,_AreaEnd.x,area));
				//ca = lerp(1, clamp(ca + noise * _AreaEnd.w,0,1), smoothstep(_AreaBegin.y,_AreaEnd.y,area));
				
				fixed outline = step((i.rimLight - b)/a + outlineNoise * _InlineControl.w, _InlineControl.y);
				//fixed stroke = outline * cun * ca;
				fixed stroke = outline * cun;
				
				col.rgb = lerp(crm, col, stroke);
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
				//return area;
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
			sampler2D _OutlineNoiseColor;
			float4 _DistanceCtrl;
			float4 _OutlineColor;
			//float _OutlineWidth0;
			float4 _OutlineCtrl;
			float4 _OutlineNoiseCtrl;
			float4 _OutlineColorRand;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				float rand = 1 + sin(length(worldPos.xyz) * 180  * _OutlineCtrl.z)* _OutlineCtrl.w;
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * _OutlineCtrl.x * 0.001 * pow(o.vertex.w, _DistanceCtrl.y) * rand;
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
				fixed colNoise = tex2D(_OutlineNoiseColor, i.vertex.xy/_OutlineColorRand.x/10).r;
				fixed range = _OutlineColorRand.y/10;
				colNoise = (round(colNoise*3)/3)*range - range/4;
				col.rgb += colNoise;
				
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
			sampler2D _OutlineNoiseColor;
			float4 _DistanceCtrl;
			float4 _OutlineColor;
			//float _OutlineWidth0;
			//float _OutlineWidth1;
			float4 _OutlineCtrl;
			float4 _OutlineNoiseCtrl;
			float4 _OutlineColorRand;
			
			v2f vert (appdata v) {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float dist = length(worldPos - _WorldSpaceCameraPos);
				
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 extend = normalize(TransformViewToProjection(normal.xy));
				float rand = 1 + sin(length(worldPos.xyz) * 180  * _OutlineCtrl.z)* _OutlineCtrl.w;
				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += extend * (_OutlineCtrl.x + _OutlineCtrl.y) * 0.001 * pow(o.vertex.w, _DistanceCtrl.y) * rand;
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
				fixed colNoise = tex2D(_OutlineNoiseColor, i.vertex.xy/_OutlineColorRand.x/10).r;
				fixed range = _OutlineColorRand.y/10;
				colNoise = (round(colNoise*3)/3)*range - range/4;
				col.rgb += colNoise;
				
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
