// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "WJDR/CIPRender_Character"
{
    Properties
    {
		_ToonShade ("ToonShader Cubemap(RGB)", CUBE) = "" { }
		_Color ("Color", Color) = (1,1,1,1)
		_Noise ("Noise", 2D) = "white" {}
		_ColorRemap("Color Remap", 2D) = "black" {}
		_OutLineRemap("OutLine Color Remap", 2D) = "black" {}
		
		_RimColor ("Rim Color", Color) = (0, 0, 0, 0)
		_RimRate ("Rim Rate", Range(0,20)) = 2
		
        _MainTex ("Texture", 2D) = "white" {}
		_TexTop ("Top", 2D) = "white" {}
		_TexSide ("Side", 2D) = "white" {}
		_Ca ("Ca", 2D) = "white" {}
		_ScaleTex ("Scale Tex (top x, top y, side x , side y)", Vector) = (1,1,1,1)
		
		_Divid ("Divid (high, mid, low, bound)", Vector) = (0.8,0.4,0.2,0.2)
		
		_Cun ("Cun", Range (-2, 2)) = 0.5
		_CRRange ("Color Remap Range", Range (1, 1000)) = 50
		
		_NoiseScale ("Noise Scale", Range (.001, 10)) = 1
		_NoiseRM ("Remap Noise Scale", Range (.001, 50)) = 1
		
		_InLineMC ("InLine MatCap (RGB)", 2D) = "white" {}
		_ILCapScale("IMC scale" , Range(0,2)) = 0.95
		
		_OutLineMC ("OutLine MatCap (RGB)", 2D) = "white" {}
		_OLCapScale("OMC scale" , Range(0,2)) = 0.95
		
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_Outline0 ("Outline width 0", Range (.001, 0.5)) = .01
		_Outline1 ("Outline width 1", Range (.001, 0.5)) = .02
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MaxOutline ("MaxOutline", Range (.0, 1)) = .5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			
            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float3 worldPos : TEXCOORD0;
                UNITY_FOG_COORDS(1)
				float2 mcUV : TEXCOORD2;
				float2 nzUV : TEXCOORD3;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				fixed3 diff : COLOR0;
				fixed3 ambient : COLOR1;
				fixed3 intensity : COLOR2;
				float2 disRim : TEXCOORD4;
				float3 cubNor : TEXCOORD5;
				float2 texcoord : TEXCOORD6;
            };
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _TexTop;
			sampler2D _TexSide;
			sampler2D _InLineMC;
			sampler2D _Noise;
			float4 _Noise_ST;
			
			sampler2D _ColorRemap;
			sampler2D _OutLineRemap;
			sampler2D _Ca;
			samplerCUBE _ToonShade;
			fixed _ILCapScale;
			fixed _NoiseRM;
			fixed4 _Color;
			fixed4 _RimColor;
			float4 _ScaleTex;
			float4 _Divid;
			fixed _Cun;
			fixed _CRRange;
			fixed _RimRate;
			
			float Sigmoid(float x, float center, float sharp) {
				return 1 / (1 + pow(100000, (-3 * sharp * (x - center))));
			}
			
			float Noise3d(float3 pos) {
				float xy = tex2D(_Noise, pos.xy).r;
				float yz = tex2D(_Noise, pos.yz).r;
				float xz = tex2D(_Noise, pos.xz).r;
				float yx = tex2D(_Noise, pos.yx).r;
				float zy = tex2D(_Noise, pos.zy).r;
				float zx = tex2D(_Noise, pos.zx).r;
				return (xy + yz + xz + yx + zy + zx)/6;
			}
			
            v2f vert (appdata v)
            {
                v2f o;
                
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
				
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 dir = normalize(worldPos - _WorldSpaceCameraPos);
				float3 map = cross(dir, worldNormal);
				map = mul((float3x3)UNITY_MATRIX_V, map);
				half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				half3 shadow = ShadeSH9(half4(worldNormal,1));
				half nol = nl + shadow;
				
				half HLightSig = Sigmoid(nol, _Divid.x,  _Divid.w);
				half MidSig = Sigmoid(nol, _Divid.y,  _Divid.w);
				half DarkSig = Sigmoid(nol, _Divid.z,  _Divid.w);
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = worldPos;
				o.normal = abs(worldNormal);
				
				o.mcUV = map.xy * 0.5 * _ILCapScale + 0.5;
				o.mcUV = float2(o.mcUV.y, -o.mcUV.x);
				// o.nzUV = o.worldPos/_NoiseRM;
				o.nzUV = TRANSFORM_TEX(v.uv, _Noise);
				
				o.diff = nl * _LightColor0.rgb;
				o.ambient = shadow;
				o.intensity = Sigmoid(o.diff.x + o.ambient.x, _Divid.x, _Divid.w);
				
				float dis = length(worldPos - _WorldSpaceCameraPos);
				o.disRim.x = max(dis/_CRRange,0);
				
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				o.disRim.y = clamp(1 - saturate ( dot(worldViewDir, worldNormal)),0,1);
				o.disRim.y = clamp(pow(o.disRim.y, _RimRate) * 2,0,1);
				
				o.cubNor = worldNormal;
				
				o.texcoord = TRANSFORM_TEX(v.uv, _MainTex);
				
				UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 cube = texCUBE(_ToonShade, i.cubNor);
				fixed4 noise = tex2D(_Noise, i.nzUV.xy);
				// fixed rd = (0.96 + noise.r*0.08);
				
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				// float2 nzy = i.worldPos.zy * rd + float2(0, 0);
				// float2 nzx = i.worldPos.zx * rd + float2(0, 0);
				// float2 nxy = i.worldPos.xy * rd + float2(0, 0);
				
				// float3 tx = tex2D(_TexSide, nzy * _ScaleTex.zw);
				// float3 ty = tex2D(_TexTop, nzx * _ScaleTex.xy);
				// float3 tz = tex2D(_TexSide, nxy * _ScaleTex.zw);
				
				// fixed4 col = _Color;
				//col.rgb *= tx * i.normal.x/3f + ty * i.normal.y/3f + tz * i.normal.z/3f;
				
				// fixed4 mc = tex2D(_InLineMC, i.mcUV);
				
				
				// fixed4 cunNoise = tex2D(_Noise, nzx*0.05);
				//fixed4 map = tex2D(_OutLineRemap, noise.rr);
				// fixed4 map = tex2D(_OutLineRemap, Noise3d(i.nzUV));
				
				// float3 cx = tex2D(_Ca, nzy * _ScaleTex.zw);
				// float3 cz = tex2D(_Ca, nxy * _ScaleTex.zw);
				
				
				
				// if(mc.r<0.5)
					// col = map;
				// else if(i.intensity.x - cunNoise.x*0.25 < _Cun)
					// col.rgb *= (tx * i.normal.x + 1 * i.normal.y + tz * i.normal.z)/(i.normal.x + i.normal.y + i.normal.z);
				

				
				// float3 ca = (cx * i.normal.x + cz * i.normal.z)/(i.normal.x + i.normal.y + i.normal.z);
				// col.rgb = lerp(col.rgb, col.rgb * ca, 1-i.diff-0.5);
               
				
				float n = (0.9 + noise.r*0.18);
				float4 col = tex2D(_MainTex, i.texcoord) * _Color * n;
				
				 // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
				//clip(-1);
				
				//fixed4 c = tex2D(_ColorRemap,float2(i.disRim.x, col.r));
				
				fixed4 c = col;
				
                return c;
            }
            ENDCG
        }
		
		Pass {
			Tags { "RenderType"="Opaque" "Queue"="Geometry"}
			
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
                //float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float distance : TEXCOORD2;
            };
			
			float _Outline0;
			float _NoiseScale;
			float _MaxOutline;
			float _NoiseRM;
			float _CRRange;
			sampler2D _Noise;
			sampler2D _ColorRemap;
			sampler2D _OutLineMC;
			sampler2D _OutLineRemap;
			fixed4 _OutlineColor;
			
            v2f vert (appdata v)
            {
                v2f o;
               
				float4 offset = tex2Dlod(_Noise, v.vertex * _NoiseScale);
			   
				float3 scaledir = mul((float3x3)UNITY_MATRIX_MV, normalize(v.normal.xyz));
				float4 worldPos = mul(UNITY_MATRIX_MV, v.vertex);
				worldPos /= worldPos.w;
				
				fixed4 test = float4(1.0, 0.0, 0.0, 0.0);
				test = mul(unity_ObjectToWorld, test);
				float scale = length(test);
				
				float3 viewDir = normalize(worldPos.xyz);
				float3 offset_pos_cs = worldPos.xyz + viewDir * _MaxOutline;
				
				float linewidth = -worldPos.z / (unity_CameraProjection[1].y);
				linewidth = sqrt(linewidth);
				worldPos.xy = offset_pos_cs.xy + scaledir.xy * (linewidth * offset.x) * _Outline0 / scale;
				worldPos.z = offset_pos_cs.z;
				
				o.vertex = mul(UNITY_MATRIX_P, worldPos);
				//o.uv = UnityObjectToClipPos(v.vertex)/_NoiseRM;
				o.worldPos = worldPos/_NoiseRM;
				
				float dis = length(worldPos - _WorldSpaceCameraPos);
				o.distance = max(dis/_CRRange,0);
				
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			float Noise3d(float3 pos) {
				float xy = tex2D(_Noise, pos.xy).r;
				float yz = tex2D(_Noise, pos.yz).r;
				float xz = tex2D(_Noise, pos.xz).r;
				float yx = tex2D(_Noise, pos.yx).r;
				float zy = tex2D(_Noise, pos.zy).r;
				float zx = tex2D(_Noise, pos.zx).r;
				return (xy + yz + xz + yx + zy + zx)/6;
			}
			
            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 map = tex2D(_OutLineRemap, Noise3d(i.worldPos));
				fixed4 c = tex2D(_ColorRemap,float2(i.distance, map.r));
				
                return c;
            }
            ENDCG
		}
		
		Pass {
			Tags { "RenderType"="Opaque" "Queue"="Geometry"}
			
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
                //float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD0;
                UNITY_FOG_COORDS(1)
				float2 mcUV : TEXCOORD2;
				fixed4 color : COLOR;
                float4 vertex : SV_POSITION;
				float distance : TEXCOORD3;
            };
			
			float _Outline1;
			float _NoiseScale;
			float _MaxOutline;
			float _NoiseRM;
			float _CRRange;
			float _Cutoff;
			fixed4 _OutlineColor;
			sampler2D _Noise;
			sampler2D _ColorRemap;
			sampler2D _OutLineRemap;
			sampler2D _OutLineMC;
			fixed _OLCapScale;
			
			float Noise3d(float3 pos) {
				float xy = tex2D(_Noise, pos.xy).r;
				float yz = tex2D(_Noise, pos.yz).r;
				float xz = tex2D(_Noise, pos.xz).r;
				float yx = tex2D(_Noise, pos.yx).r;
				float zy = tex2D(_Noise, pos.zy).r;
				float zx = tex2D(_Noise, pos.zx).r;
				return (xy + yz + xz + yx + zy + zx)/6;
			}
			
            v2f vert (appdata v)
            {
                v2f o;
				
				float4 offset = tex2Dlod(_Noise, v.vertex * _NoiseScale);
				
				float3 scaledir = mul((float3x3)UNITY_MATRIX_MV, normalize(v.normal.xyz));
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				pos /= pos.w;
				
				float3 viewDir = normalize(pos.xyz);
				float3 offset_pos_cs = pos.xyz + viewDir * _MaxOutline;
				
				fixed4 test = float4(1.0, 0.0, 0.0, 0.0);
				test = mul(unity_ObjectToWorld, test);
				float scale = length(test);
				
				float linewidth = -pos.z / (unity_CameraProjection[1].y);
				linewidth = sqrt(linewidth);
				pos.xy = offset_pos_cs.xy + scaledir.xy * (linewidth * offset.x) * _Outline1 / scale;
				pos.z = offset_pos_cs.z;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 dir = normalize(worldPos - _WorldSpaceCameraPos);
				float3 map = cross(dir, worldNormal);
				
				map = mul((float3x3)UNITY_MATRIX_V, map);
				
				o.vertex = mul(UNITY_MATRIX_P, pos);
				//o.uv = UnityObjectToClipPos(v.vertex)/_NoiseRM;
				o.worldPos = worldPos/_NoiseRM;
				o.mcUV = map.xy * 0.5 * _OLCapScale + 0.5;
				o.mcUV = float2(o.mcUV.y, -o.mcUV.x);
				o.color = float4(o.mcUV,0,1);
				
				float dis = length(worldPos - _WorldSpaceCameraPos);
				o.distance = max(dis/_CRRange,0);
				
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				UNITY_APPLY_FOG(i.fogCoord, i.color);
				fixed4 mc = tex2D(_OutLineMC, i.mcUV);
				
				clip(mc.r - _Cutoff);
				
				fixed4 map = tex2D(_OutLineRemap, Noise3d(i.worldPos));
				fixed4 c = tex2D(_ColorRemap,float2(i.distance, map.r));
				
				return c;
            }
            ENDCG
		}
		
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
