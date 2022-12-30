Shader "Unlit/InputShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            #include "UnityCG.cginc"
            
            //application to vert
            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 textcoord:TEXCOORD0;            
            };
            
            struct v2f{
                //SV_POSITION语义告诉unity：pos为裁剪空间中的位置信息
                float4 pos:SV_POSITION;
                //COLOR0 语义可以存储颜色信息
                fixed3 color:COLOR0;
            };

            //POSITION  SV_POSITION 是语义信息，定义输入和输出
            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //将-1，1转变为0，1
                o.color=v.normal*0.5+fixed3(0.5,0.5,0.5);
                return o;
            }
            
            //输出到render target上
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color,1);
            }
            ENDCG
        }
    }
}
