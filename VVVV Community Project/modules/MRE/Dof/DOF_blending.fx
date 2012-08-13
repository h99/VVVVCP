// this is a very basic template. use it to start writing your own effects.
// if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION ;

//texture // Original source image
texture Tex <string uiname="Color Texture";>;
sampler colorSampler = sampler_state    
{
    Texture   = (Tex);         
    MipFilter = none;       
    MinFilter = none;
    MagFilter = none;
};

//texture // Output of SmallBlurPS()
texture smallBlurTex <string uiname="Texture Output of SmallBlurPS()";>;
sampler smallBlurSampler = sampler_state    
{
    Texture   = (smallBlurTex);         
    MipFilter = linear;        
    MinFilter = linear;
    MagFilter = linear;
};

//texture  // Blurred output of DofDownsample()
texture largeBlurTex <string uiname="Texture Blurred output of DofDownsample()";>;
sampler largeBlurSampler = sampler_state    
{
    Texture   = (largeBlurTex);          
    MipFilter = linear;         
    MinFilter = linear;
    MagFilter = linear;
};

//texture // Depth texture
texture DepthTex <string uiname="Depth Texture";>;
sampler depthSampler = sampler_state   
{
    Texture   = (DepthTex);         
    MipFilter = none;         
    MinFilter = none;
    MagFilter = none;
};

int debug;

struct vs2ps
{
    float4 Pos  : POSITION ;
    float2 TexCd : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO  : POSITION ,
    float4 TexCd : TEXCOORD0 )
{
    vs2ps Out;
    Out.Pos = mul(PosO, tWVP);
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

 float2 invRenderTargetSize;
 float4 dofLerpScale;
 float4 dofLerpBias;
 float3 dofEqFar;
 
 float4 tex2Doffset( sampler s, float2 tc, float2 offset )
 {  
  return tex2D( s, tc + offset * invRenderTargetSize );  
 }
 
 half3 GetSmallBlurSample( float2 texCoords )
 {
   half3 sum;
   const half weight = 4.0 / 17;
   sum = 0;  // Unblurred sample done by alpha blending
   sum += weight * tex2Doffset( colorSampler, texCoords, float2(+0.5, -1.5) ).rgb;
   sum += weight * tex2Doffset( colorSampler, texCoords, float2(-1.5, -0.5) ).rgb;
   sum += weight * tex2Doffset( colorSampler, texCoords, float2(-0.5, +1.5) ).rgb;
   sum += weight * tex2Doffset( colorSampler, texCoords, float2(+1.5, +0.5) ).rgb;
   return sum;
 }

//Added "pure" input to blend with the original image
 half4 InterpolateDof( half3 pure, half3 small, half3 med, half3 large, half t )
 {
   half4 weights;
   half3 color;
  
    // Efficiently calculate the cross-blend weights for each sample.
    // Let the unblurred sample to small blur fade happen over distance
    // d0, the small to medium blur over distance d1, and the medium to
    // large blur over distance d2, where d0 + d1 + d2 = 1.
    // dofLerpScale = float4( -1 / d0, -1 / d1, -1 / d2, 1 / d2 );
    // dofLerpBias = float4( 1, (1 - d2) / d1, 1 / d2, (d2 - 1) / d2 );

   weights = saturate( t * dofLerpScale + dofLerpBias );
   weights.yz = min( weights.yz, 1 - weights.xy );
   weights.x = 1-dot( weights.yzw, half3( 16.0 / 17, 1.0, 1.0));
   color = weights.x * pure + weights.y * small + weights.z * med + weights.w * large;

   return half4( color, 1 );
 }
 
half4 ApplyDepthOfField(vs2ps In): COLOR
 {
   half3 pure = tex2D( colorSampler, In.TexCd );
   half3 small;
   half4 med;
   half3 large;
   half depth;
   half nearCoc;
   half farCoc;
   half coc;
   small = GetSmallBlurSample( In.TexCd );
   med = tex2D( smallBlurSampler, In.TexCd );
   large = tex2D( largeBlurSampler, In.TexCd ).rgb;
   nearCoc = med.a;
   depth = tex2D( depthSampler, In.TexCd ).z;
   if ( depth > 1.0e6 )
   {
     coc = nearCoc; // We don't want to blur the sky.
   }
   else
   {
    // dofEqFar.x and dofEqFar.y specify the linear ramp to convert
    // to depth for the distant out-of-focus region.
    // dofEqFar.z is the ratio of the far to the near blur radius.
     farCoc = saturate( dofEqFar.x * depth + dofEqFar.y );
     coc = max( nearCoc, farCoc * dofEqFar.z );
   }
   
   if      (debug == 1) {return float4(coc.xxx,1);}
   else if (debug == 2) {return float4(small,1);}
   else if (debug == 3) {return float4(med.xyz,1);}
   else if (debug == 4) {return float4(large,1);}
   else if (debug == 5) {return float4(InterpolateDof( pure, small, med.rgb, large, coc ).aaa,1);}
   else

 	return InterpolateDof( pure, small, med.rgb, large, coc );
 }

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 ApplyDepthOfField();
    }
}
