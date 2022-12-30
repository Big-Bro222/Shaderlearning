Shader "Custom/Siki/SimpleTexture"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",float)=5
        _MainTex("MainTex",2D)="white"
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
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct v2f{
               float4 vertex:SV_POSITION;
               fixed3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
               float2 uv:TEXCOORD2;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld ,v.vertex);
                o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal=UnityObjectToWorldNormal(i.worldNormal);
                fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
                fixed3 albedo = tex2D(_MainTex,i.uv);
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*albedo.rgb*saturate(dot(worldNormal,worldLight));
                //fixed3 reflectDir=normalize(reflect(-worldLight,worldNormal));
                fixed3 viewDir=normalize(_WorldSpaceCameraPos-i.worldPos);
                fixed3 halfDir=normalize(worldLight+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                fixed3 color=diffuse+ambient+specular;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
