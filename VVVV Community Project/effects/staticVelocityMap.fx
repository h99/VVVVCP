//@author: micro.D
//@help: RGB = CurrentFrame.XYZ - PrevFrame.XYZ
//@tags: direction, velocity
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 ptWVP <string uiname="Previous frame WVP";>;
float4x4 ctWVP <string uiname="Current frame WVP";>;
float4x4 postTr <string uiname="Post Colorization Transform";>;
float Gain = 1;
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

struct vs2ps
{
    float4 Pos : POSITION;
    float2 TexCd : TEXCOORD0;
    float4 col : COLOR0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VSc(
    float4 Pos : POSITION,
    float2 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    float4 p1=mul(Pos, ctWVP);
    float4 p2=mul(Pos, ptWVP);
    Out.Pos = mul(p1, postTr);
    Out.col.rgb = .5 + (p2.xyz - p1.xyz)*Gain;
    Out.col.a = 1;

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
};
vs2ps VSp(
    float4 Pos : POSITION,
    float2 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    float4 p1=mul(Pos, ctWVP);
    float4 p2=mul(Pos, ptWVP);
    Out.Pos = mul(p2, postTr);
    Out.col.rgb = .5 + (p2.xyz - p1.xyz)*Gain;
    Out.col.a = 1;

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
};
vs2ps VSe(
    float4 Pos : POSITION,
    float2 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    float4 p1=mul(Pos, ctWVP);
    float4 p2=mul(Pos, ptWVP);
	float4 p3=mul(p1+((p1-p2)*Gain)/2, postTr);
    Out.Pos = mul(p3, postTr);
    Out.col.rgb = .5 + (p2.xyz - p1.xyz)*Gain;
    Out.col.a = 1;

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
}
vs2ps VSa(
    float4 Pos : POSITION,
    float2 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    float4 p1=mul(Pos, ctWVP);
    float4 p2=mul(Pos, ptWVP);
	float4 p3=mul((p1+p2)/2, postTr);
    Out.Pos = mul(p3, postTr);
    Out.col.rgb = .5 + (p2.xyz - p1.xyz)*Gain;
    Out.col.a = 1;

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0

    float4 col = In.col;
    col.a = tex2D(Samp, In.TexCd).a;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique NextFrameEstimation
{
    pass P0
    {
        VertexShader = compile vs_3_0 VSc();
        PixelShader = compile ps_3_0 PS();
    }
	pass P1
    {
        VertexShader = compile vs_3_0 VSp();
        PixelShader = compile ps_3_0 PS();
    }
	pass P2
    {
        VertexShader = compile vs_3_0 VSe();
        PixelShader = compile ps_3_0 PS();
    }
}
technique AverageOfFrames
{
    pass P0
    {
        VertexShader = compile vs_3_0 VSc();
        PixelShader = compile ps_3_0 PS();
    }
	pass P1
    {
        VertexShader = compile vs_3_0 VSp();
        PixelShader = compile ps_3_0 PS();
    }
	pass P2
    {
        VertexShader = compile vs_3_0 VSa();
        PixelShader = compile ps_3_0 PS();
    }
}