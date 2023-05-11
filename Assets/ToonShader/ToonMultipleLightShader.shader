Shader "Toon/ToonMultipleLightShader"
{
    Properties
    {
        _Tint("Tint",Color)=(1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _UnlitColor("Shadow Color",Color)=(0.5,0.5,0.5,1)
        _MultiListFadeDistance("MultiList FadeDistance",Float)=20
        
        _RimColor("Rim Color",Color)=(0.5,0.5,0.5,1)
        _RimLightSampler ("RimLight Sampler", 2D) = "white" {}
        _RimIntensity("Rim Intensity",Float)=10
        _UnlitThreshold("Shadow Range",Range(0,1))=0.1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Geometry" "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 posWorld:TEXCOORD0;
                float3 normal:TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 camDir: TEXCOORD3;
                float3 lightDir: TEXCOORD4;
                LIGHTING_COORDS(5, 6)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Tint;
            fixed4 _UnlitColor;
            
            float _UnlitThreshold;
            float _MultiListFadeDistance;

            fixed4 _RimColor;
            sampler2D _RimLightSampler;
            float _RimIntensity;

            float _LitCount;
            float4 _LitPosList[10];
            float4 _LitColList[10];

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.camDir = normalize(_WorldSpaceCameraPos - o.posWorld);
                o.lightDir = WorldSpaceLightDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Tint;

                //add fire shake effect
                fixed4 pointLitCol = fixed4(0, 0, 0, 0);
                fixed pointLit = 0;
                float3 shakeOffset = float3(0, 0, 0);
                shakeOffset.x = sin(_Time.z * 15);
                shakeOffset.y = sin(_Time.z * 13+5);
                shakeOffset.z = sin(_Time.z * 12+7);

                for (int n = 0; n < _LitCount; n++)
                {
                    float litDist = distance(_LitPosList[n].xyz, i.posWorld.xyz);
                    float viewDist = distance(_LitPosList[n].xyz, _WorldSpaceCameraPos);
                    float viewFade = 1 - saturate(viewDist / _MultiListFadeDistance);
                    if (litDist < _MultiListFadeDistance)
                    {
                        float3 litDir = _LitPosList[n].xyz - i.posWorld.xyz;
                        litDir += shakeOffset * 0.07 * _LitPosList[n].w;
                        litDir = normalize(litDir);
                        fixed newlitValue = max(0, dot(i.normal, litDir)) * (_LitPosList[n].w - litDist) * viewFade >
                            0.3;
                        fixed4 newlitCol = newlitValue * fixed4(_LitColList[n].xyz, 1);
                        pointLitCol = lerp(pointLitCol, newlitCol, newlitValue);
                    }
                }
                
                //light and shadow
                float3 normalDirection = normalize(i.normal);
                float attenuation = LIGHT_ATTENUATION(i);
                float3 lightDirection = normalize(_WorldSpaceLightPos0).xyz;
                fixed3 lightColor = _Tint.rgb * _UnlitColor.rgb * _LightColor0.rgb;
                if (attenuation * max(0.0, dot(normalDirection, lightDirection)) >= _UnlitThreshold)
                {
                    lightColor = _LightColor0.rgb * _Tint.rgb;
                }

                //Rimlight
                float normalDotCam = dot(i.normal, i.camDir.xyz);
                float falloffU = clamp(1.0 - abs(normalDotCam), 0.02, 0.98);

                float rimlightDot = saturate(0.5 * (dot(i.normal, i.lightDir + float3(-1, 0, 0)) + 1.5));
                falloffU = saturate(rimlightDot * falloffU);
                falloffU = tex2D(_RimLightSampler, float2(falloffU, 0.25f)).r;
                float3 rimCol = falloffU * col * _RimColor * _RimIntensity;

                return float4(col.rgb * (lightColor.rgb + pointLitCol) + rimCol, 1.0);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}