Shader "Unlit/Forward"
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
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag           
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
 
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct v2f{
               float4 vertex:SV_POSITION;
               fixed3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
                float3 vertexLight:TEXCOORD2;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld ,v.vertex).xyz;
#ifdef LIGHTMAP_OFF
				float3 shLight = ShadeSH9(float4(v.normal,1.0));
				o.vertexLight = shLight;
#ifdef VERTEXLIGHT_ON
				float3 vertexLight = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
				unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
				unity_4LightAtten0, o.worldPos, o.worldNormal);
				o.vertexLight += vertexLight;
#endif
#endif
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLight));
                
                fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir=normalize(worldLight+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                fixed3 color=diffuse+ambient+specular+i.vertexLight;
                return fixed4(color,1);
            }
            ENDCG
        }
    
        Pass
        {
            Tags{"LightMode"="ForwardAdd"}
            Blend One One
            
            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag           
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
 
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct v2f{
               float4 vertex:SV_POSITION;
               fixed3 worldNormal:TEXCOORD0;
               float3 worldPos:TEXCOORD1;
                LIGHTING_COORDS(2,3)
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld ,v.vertex).xyz;

                //calculate shadows and attenion
                TRANSFER_VERTEX_TO_FRAGMENT(o);                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLight=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLight));
                
                fixed3 viewDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 halfDir=normalize(worldLight+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                fixed atten =LIGHT_ATTENUATION(i);
                fixed3 color=(diffuse+specular)*atten;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}