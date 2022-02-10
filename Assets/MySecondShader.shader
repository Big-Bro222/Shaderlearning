Shader "Unlit/MySecondShader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag
            fixed4 _Color;// the properties should be defined again here, in order to be used in the shader

            struct appdata{
                float4 vertex:POSITION;
                float2 uv:TEXCOORD;
            };//应用程序阶段的结构体
            
            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
            };//顶点着色器出传递给片段着色器的结构体

            fixed4 checker(float2 uv)//自定义的函数
            {
                float2 repeatUV;
                repeatUV.x=uv.x*2;
                repeatUV.y=uv.y*3;
                float2 c=floor(repeatUV)/2;//floor函数计算整数部分
                float checker=frac(c.x+c.y)*2;//frac函数取小数点部分，由于进行了上一个步骤，所以返回值一定为0或者0.5*2,用于计算返回黑色还是白色
                return checker;
            }

            /**********************/
            v2f vert(appdata v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=v.uv;
                return o;
            }
            
            fixed4 frag(v2f i ):SV_TARGET
            {
                fixed col=checker(i.uv);
                return col;
            }
            /**********************/

            
            ENDCG
        }
    }
}
