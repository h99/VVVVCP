// this is a very basic template. use it to start writing your own effects.
// if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION ;

//texture   // Output of DofDownsample()
texture Tex1 <string uiname="DofDownsample";>;
sampler shrunkSampler = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex1);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture // Blurred version of the shrunk sampler
texture Tex2 <string uiname="Blurred version of the shrunk sampler";>;
sampler blurredSampler = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

  // This is the pixel shader function that calculates the actual
  // value used for the near circle of confusion.
  // "texCoords" are 0 at the bottom left pixel and 1 at the top right.
 
  struct vs2ps
{
    float4 Pos  : POSITION ;
    float2 texCoords : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS( float4 PosO  : POSITION ,
          float4 TexCd : TEXCOORD0 )
{
    vs2ps Out;
    Out.Pos = mul(PosO, tWVP);
    Out.texCoords = TexCd;
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
 float3 color;
 float coc;
 half4 blurred;
 half4 shrunk;
 shrunk = tex2D( shrunkSampler, In.texCoords );
 blurred = tex2D( blurredSampler, In.texCoords );
 color = shrunk.rgb;
 coc = 2 * max( blurred.a, shrunk.a ) - shrunk.a;
 
 return float4( color, coc );
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
