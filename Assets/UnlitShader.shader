Shader "Unlit/MyFirstShader"
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
            //#pragma是Unity内置的编绎指令用的命令,在Pass中我们就利用此命令来声明所需要的顶点着色器与片断着色器。
            //#pragma is the compile order ,here to declare vertex shader and fragment shader
            #pragma vertex vert//顶点着色器
            #pragma fragment frag//片段着色器
            // make fog work

            #include "UnityCG.cginc"

            float4 vert(float4 vertex:POSITION):SV_POSITION
            //POSITION 是语义信息，代表信息为顶点位置 semantic information for representing the information of vertexs
            //SV_POSITION 是语义信息，告诉片段着色器哪个是顶点着色器过来的信息 semantic information for representing this is the-- 
            //--vertex shader
            {
                return UnityObjectToClipPos(vertex);//将模型坐标变换成矩阵坐标
            }
            fixed4 _Color;// the properties should be defined again here, in order to be used in the shader
            fixed4 frag( ):SV_TARGET
            {
                return _Color;
            }

            ENDCG
        }
    }
}
