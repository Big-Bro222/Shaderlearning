Shader "Custom/Siki/SimpleNormal"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",float)=5
        _MainTex("MainTex",2D)="white"
        _BumpMap("Normal Map",2D)="bump"
        _BumpScale("Bump Scale",float)=1
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
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            struct v2f{
                float4 vertex:SV_POSITION;
                fixed3 lightDir:TEXCOORD0;
                float3 viewDir:TEXCOORD1;
                float2 uv:TEXCOORD2;
                float2 normalUV:TEXCCOORD3;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                //o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.normalUV= TRANSFORM_TEX(v.texcoord,_BumpMap);
                TANGENT_SPACE_ROTATION;
                //float3 binormal=cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
                //float3x3 rotation=float3(v.tangent.xyz ,binormal,v.normal);
                o.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir=mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentViewDir=normalize(i.viewDir);
                fixed3 tangentLightDir=normalize(i.lightDir);

                fixed4 packed_normal = tex2D(_BumpMap,i.normalUV);

                //fixed3 tangentNormal;
                //mapping from (0,1)to(-1,1)
                //tangentNormal.xy=packed_normal*_BumpScale;
                //x*x+y*y+z*z=1
                //tangentNormal.z=sqrt(1-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 tangentNormal=UnpackNormal(packed_normal);
                tangentNormal.xy*=_BumpScale;

                
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 albedo = tex2D(_MainTex,i.uv);
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*albedo.rgb*saturate(dot(tangentLightDir,tangentNormal));
                //fixed3 reflectDir=normalize(reflect(-worldLight,worldNormal));
                fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(tangentNormal,halfDir)),_Gloss);
                fixed3 color=diffuse+ambient+specular;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
