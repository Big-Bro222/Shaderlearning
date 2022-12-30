Shader "Custom/Siki/SpecularFrag"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",float)=5
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
 
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct v2f{
               float4 vertex:SV_POSITION;
               fixed3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld ,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal=UnityObjectToWorldNormal(i.worldNormal);
                fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLight));
                fixed3 reflectDir=normalize(reflect(-worldLight,worldNormal));
                fixed3 viewDir=normalize(_WorldSpaceCameraPos-i.worldPos);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(reflectDir,viewDir)),_Gloss);
                fixed3 color=diffuse+ambient+specular;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
