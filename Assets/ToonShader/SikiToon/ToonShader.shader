Shader "Toon/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DiffuseColor("Diffuse",Color)=(1,1,1,1)
        _Outline("Outline Width",Range(0,1))=1
        _OutlineColor("Outline Color",Color)=(0,0,0,1)
        _Steps("Steps",Range(1,30)) = 1
        _ToonEffect("ToonEffect", Range(0,1)) = 0.5
        _Specular("Specular Color",Color)=(1,1,1,1)
        _SpecularScale("Specular Scale",Range(0.0001,3))=1
        _RimColor("Rim Light Color",Color)=(1,1,1,1)
        _RimPower("Rim Strength", Range(0.00000001,3))=1
        _XRayColor("Oculusion Color",Color)=(1,1,1,1)
        _XRayPower("XRay Power",Range(0.0001,3))=1
    }
    SubShader
    {
        Tags
        {
            "Queue"= "Geometry+1000" "RenderType"="Opaque"
        }
        LOD 100
        Pass
        {
            Name "Outline"
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float _Outline;
            fixed4 _OutlineColor;
            float _Steps;
            float _ToolEffect;


            v2f vert(appdata_base v)
            {
                v2f o;
                //物体法线外扩
                //v.vertex.xyz+=_Outline*v.normal;
                //o.vertex = UnityObjectToClipPos(v.vertex);

                //视角空间法线外拓
                //float4 pos = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, v.vertex));
                //float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                //pos = pos + float4(normal,0) * _Outline;
                //o.vertex =  mul(UNITY_MATRIX_P, pos);

                //裁剪空间法线外拓
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                float2 viewNormal = TransformViewToProjection(normal.xy);
                o.vertex.xy += viewNormal * _Outline;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldPos:TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _DiffuseColor;
            float _Steps;
            float _ToonEffect;
            fixed4 _RimColor;
            float _RimPower;
            float _SpecularScale;
            fixed4 _Specular;

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, o.pos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);

                //view Direction
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //Diffuse light steps
                float difLight = dot(worldLightDir, i.worldNormal) * 0.5 + 0.5;
                difLight = smoothstep(0, 1, difLight);
                float toon = floor(difLight * _Steps) / _Steps;
                difLight = lerp(difLight, toon, _ToonEffect);
                fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * difLight;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;


                fixed3 halfDir = normalize(worldLightDir + viewDir);
                float spec = dot(i.worldNormal, halfDir);
                fixed w = fwidth(spec) * 2.0;
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(
                    0.0001, _SpecularScale);


                /*float rim = 1 - dot(i.worldNormal, viewDir);
                fixed3 rimColor = _RimColor * pow(rim, 1 / _RimPower);*/
                float rimdot = 1 - dot(i.worldNormal, viewDir);
                float rimIntensity = smoothstep(_RimPower - 0.01, _RimPower + 0.01, rimdot);
                float4 rim = rimIntensity * _RimColor;
                
                return float4(ambient + diffuse + specular + rim, 1);
            }
            ENDCG
        }
        Pass
        {
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

    }
}