// this is a very basic template. use it to start writing your own effects.
// if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION ;

//texture   // Output of DofNearCoc()
texture Tex <string uiname="Output of DofNearCoc()";>;
sampler colorSampler = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};

    // This vertex and pixel shader applies a 3 x 3 blur to the image in
    // colorMapSampler, which is the same size as the render target.
    // The sample weights are 1/16 in the corners, 2/16 on the edges,
    // and 4/16 in the center.
    
float4 invRenderTargetSize <string uiname="xxyy invRenderTargetSize";>;
        
struct PixelInput
  {
   float4 position : POSITION ;
   float4 texCoords : TEXCOORD0 ;
  };
 
// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

 PixelInput SmallBlurVS( float4 position : POSITION ,
                         float2 texCoords :TEXCOORD )
 {
   PixelInput Out = (PixelInput)0;

   //PixelInput Out;
   const float4 halfPixel = { -0.5, 0.5, -0.5, 0.5 };
   Out.position = mul(position,tWVP);        
   Out.texCoords = texCoords.xxyy + halfPixel * invRenderTargetSize;
   return Out;
 }
 
// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

 float4 SmallBlurPS( const PixelInput pixel ) : COLOR
 {
   float4 color;
   color = 0;
   color += tex2D( colorSampler, pixel.texCoords.xz );
   color += tex2D( colorSampler, pixel.texCoords.yz );
   color += tex2D( colorSampler, pixel.texCoords.xw );
   color += tex2D( colorSampler, pixel.texCoords.yw );
   
   return color / 4;
 }

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 SmallBlurVS();
        PixelShader  = compile ps_3_0 SmallBlurPS();
    }
}
