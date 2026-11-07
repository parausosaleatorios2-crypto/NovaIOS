#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp sampler2DArray;
precision highp samplerCube;



struct RenderState
{
	int dynamicReflection;
	bool clipPlane;
	bool globalEnvironment;
	bool ambientOcclusion;
	bool rayTracedShadows, shadowMaps;
	bool blendOpacity;
	bool globalWireframe;
	bool wireframeSupersample;
	bool flipNormals;
	bool pad0, pad1;
};

layout(std140) uniform ShaderState
{
	RenderState renderState;

	vec2 frameBufferSize;

	int objectId;

	vec2 modelUvOffset;
	vec4 modelColor;

	mat4 modelMatrix;
	mat4 baseModelMatrix;
	mat4 normalMatrix;

	mat4 dynamicPlaneMatrix;
	mat4 cubeViewMatrix[6];

	vec4 clipPlane;
};

layout(std140) uniform TransformMatrices
{
	mat4 viewMatrix, projectionMatrix;
	vec3 eyePosition;
	vec2 viewportScale, viewportOffset;
};

struct DynamicReflection
{
	int clipMirror;
	bool disableEnvironment;
	vec4 offset, reflectDirection;
};

layout(std140) uniform ModelProperties
{
	vec4 modelFlip;
	vec2 uvRepeat, uvOffset;
	float normalInvert, flipNormal;

	DynamicReflection dynamicReflection;
} modelProperties;




struct Channel
{
	float gamma, amount, contrast, saturation, brightness, invert;
	bool unmultiply, pad1;
	vec2 uvRepeat, uvOffset;
	vec2 levelInput, levelOutput;
};

struct Normal
{
	bool simple, swapXY;
	vec2 invert;
};

struct SubSurfaceMaterial
{
	bool enabled;
	float intensity, diffusion, absorption, absorptionExponent, penetrationExponent, pad0, pad1;
	vec4 color;
};

struct WireframeMaterial
{
	bool enabled;			// todo: replace with shader permuts later
	float lineWidth;
	int drawMode;			// 0 = over, 1 = lines (discard other)
	int colorMode;			// 0 = use color, 1 = use material
	int transferMode;		// 0 = mix, 1 = screen, 2 = add, 3 = multiply
	bool hasFogInfluence;	// will consider fog if set to true	
	float fresnel, bias;	// fresnel term (intensity and exponent)
	vec4 color;
};

layout(std140) uniform MaterialProperties
{
	vec4 diffuseColor, specularColor, emissiveColor, reflectColor, refractColor;
	float diffuseAmount, ambientAmount, specularAmount, emissiveAmount;
	float specularShininess, specularSize, flatShading, environmentMultiplier;
	float opacity, matteShadow, matteReflection, matteUseDiffuseAlpha, twoSided;

	float reflectAmount, refractAmount;
	float refractDistortion, reflectSpecularInfluence, refractSpecularInfluence;
	float reflectFresnel, refractFresnel, reflectBias, refractBias;
	int reflectMode, refractMode;
	float emissiveFresnel, emissiveBias, emissiveDiffuse;

	float ambientOcclusionAmount, glowAmount, environmentDirection;
	float alphaThreshold;

	bool receiveShadow, ignoreIbl, energyConservation, pad0, pad1;

	SubSurfaceMaterial subSurface;

	Normal normal;

	WireframeMaterial wireframe;

	Channel diffuseChannel, specularChannel, occlusionChannel, emissiveChannel, normalChannel, environmentChannel, reflectChannel;
} material;

struct Fog
{
	vec4 color;
	float start, invDistance, falloff, pad0;
};

struct Shadow
{
	bool enabled, rayTraced;
	float penumbraDepth, softSamples, softRadius, jitter;
	float reflectionInfluence, gamma, bias;
	bool smoothSample;
	vec2 invMapSize;
	float softBlurDepthBias;
};

struct SubSurface
{
	bool enabled;
	float intensity, samples, diffusion, tintFactor, jitter, absorptionMultiplier, falloffMultiplier, lightBlending, sssBias;
};

struct AmbientOcclusion
{
	bool enabled;
	float emissiveInfluence, lightInfluence, fogInfluence, colorMode, contrast, pad0, pad1;
	vec4 color;
};

struct MatteShadow
{
	float opacity;
	float lightInfluence;
	vec4 shadowTint;
};

struct Mixer
{
	float ambient, diffuse, specular, reflect, refract, emissive, subSurface, shadows;
};

struct OutputProperties
{
	float depthMin, depthInvRange, depthClamp;

	mat4 dofViewMatrix, dofProjectionMatrix;
	float dofSpacing;
	
	float wireframeOnly;

	float specularCompression;
};

layout(std140) uniform RenderProperties
{
	Fog fog;
	Shadow shadow;
	SubSurface subSurface;
	AmbientOcclusion ao;
	MatteShadow matteShadow;
	Mixer mixer;

	OutputProperties outputProperties;

	Channel environmentChannel;

	mat4 environmentMatrix;
	vec4 environmentTint;
	float environmentExposure, environmentGamma;
	float gamma;

	float globalWireframeWidth;
	float lineWidthMultiplicator;	
} render;

struct Light
{
	vec4 position, direction, diffuse;
	float cosCone, feather, falloff;
	int type;
	
	// shadow
	int shadowId;
	float diffusion, darkness, shadowBias;
	mat4 shadowMatrix;
	mat4 projectionMatrix;
};

layout(std140) uniform Lights
{
	int numLights, pad0, pad1, pad2;
	
	Light lights[8];
	
	vec4 ambientLights;
};

in vec4 base_worldPosition;
in vec3 base_worldNormal;
in vec4 base_worldTangent;
in vec4 base_viewPosition;
in vec2 base_texCoords;
in float base_worldScale;

const float PI = 3.14159265;
const float PI2 = 6.28318531;



float fresnel(float incident, float fresnel, float bias)
{
	float resFresnel = 1.0;
	
	if (bias >= 0.01)
	{
		float inc = (fresnel > 0.0) ? 1.0 - incident : incident;
		
		float absFresnel = abs(fresnel);
		resFresnel = pow(inc, bias) * absFresnel + (1.0 - absFresnel);
	}
	
	return resFresnel;
}

vec4 contrast_saturation(vec4 color, float gamma, float contrast, float saturation, float brightness, vec2 levelInput, vec2 levelOutput)
{
	if (contrast > 0.0)
	{
		float halfWay = (contrast - 1.0) * 0.5;
		color.rgb = min(max(color.rgb, vec3(1.0)), max(vec3(0.0), color.rgb * contrast - halfWay));
	}
	else
		color.rgb = color.rgb * (contrast + 1.0) - contrast * 0.5;

	float lum = (max(max(color.r, color.g), color.b) + min(min(color.r, color.g), color.b)) * 0.5;
	color.rgb = max(vec3(0.0), color.rgb * saturation + lum * (1.0 - saturation));

	color.rgb *= brightness;

	color.rgb = (color.rgb - vec3(levelInput.x)) / vec3(max(0.01, levelInput.y - levelInput.x));
	color.rgb = max(vec3(0.0), vec3(levelOutput.x) + color.rgb * (levelOutput.y - levelOutput.x));

	color.rgb = pow(color.rgb, vec3(gamma));

	return color;
}

vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor)
{
	vec2 transformedCoords = base_texCoords * channel.uvRepeat + channel.uvOffset + modelUvOffset;

	vec4 textureColor = texture(textureSampler, transformedCoords);

	textureColor = contrast_saturation(textureColor, channel.gamma, channel.contrast, channel.saturation, channel.brightness, channel.levelInput, channel.levelOutput);

	textureColor.rgb = mix(textureColor.rgb, max(vec3(0.0), vec3(1.0) - textureColor.rgb), channel.invert);

	return textureColor * channel.amount + (1.0 - channel.amount) * defaultColor;
}



float process_wireframe_fragments()
{
	return 0.0;
}

vec4 apply_wireframe_rendering(vec4 color, float fogOpacity, float incident)
{
	return vec4(color.rgb * (1.0 - render.outputProperties.wireframeOnly), color.a);
}


vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor);

uniform sampler2D diffuseSampler;

vec4 get_diffuse_texture_color()
{
	vec4 diffuseTexture =  sample_texture_channel(diffuseSampler, material.diffuseChannel, vec4(1.0));
	
	if (diffuseTexture.a < material.alphaThreshold)
		discard;

	return diffuseTexture;
}


vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor);

uniform sampler2D specularSampler;

vec4 get_specular_texture_color()
{
	return sample_texture_channel(specularSampler, material.specularChannel, vec4(1.0));
}


float fresnel(float incident, float fresnel, float bias);

vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor);

uniform sampler2D emissiveSampler;

vec4 get_emissive_texture_color()
{
	return sample_texture_channel(emissiveSampler, material.emissiveChannel, vec4(1.0));
}

vec4 get_emissive_color(float incident, vec4 diffuse)
{
	vec4 emissiveTexture = get_emissive_texture_color();

	vec4 emissive = emissiveTexture * material.emissiveColor * material.emissiveAmount;
	emissive *= fresnel(incident, material.emissiveFresnel, material.emissiveBias);
	emissive *= render.mixer.emissive;

	return emissive * (diffuse * material.emissiveDiffuse + (1.0 - material.emissiveDiffuse));
}



vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor);

uniform sampler2D reflectSampler;

vec4 get_reflect_texture_color()
{
	return sample_texture_channel(reflectSampler, material.reflectChannel, vec4(1.0));
}


uniform sampler2D normalSampler;

vec3 get_normal_texture()
{
	vec2 transformedCoords = base_texCoords * material.normalChannel.uvRepeat + material.normalChannel.uvOffset + modelUvOffset;

	vec4 normalTexture = texture(normalSampler, transformedCoords);

	vec3 normal = (material.normal.simple ? normalTexture.xyz : normalTexture.wyz) * 2.0 - vec3(1.0);
	normal.xy *= material.normalChannel.amount;

	normal.z = sqrt(max(0.00001, 1.0 - dot(normal.xy, normal.xy)));

	if (material.normal.swapXY)
		normal.xy = normal.yx;

	normal.xy *= material.normal.invert;

	return normalize(normal);
}

mat3 get_tbn_matrix(vec3 normal)
{
	vec3 tangent = normalize(base_worldTangent.xyz);
	vec3 bitangent = normalize(cross(normal, tangent) * base_worldTangent.w);
	
	return mat3(tangent, bitangent, normal);
}

vec3 get_normal()
{
	vec3 normal = normalize(base_worldNormal * modelProperties.flipNormal);

	if (material.flatShading > 0.0)
	{
		vec3 posDx = dFdx(base_worldPosition.xyz);
		vec3 posDy = dFdy(base_worldPosition.xyz);
		
		vec3 n = -cross(posDx, posDy);
		float l = length(n);
		if (l > 0.0)
		{
			n *= 1.0 / l;
			normal = normalize(n * material.flatShading + normal * (1.0 - material.flatShading));
		}
	}

	float frontFace = (gl_FrontFacing ? 1.0 : -1.0f) * modelProperties.normalInvert;
	return normalize(get_tbn_matrix(normal) * get_normal_texture()) * mix(1.0, frontFace, material.twoSided);
}



float fresnel(float incident, float fresnel, float bias);
vec4 get_reflect_texture_color();

uniform sampler2D environmentSampler;
uniform sampler2D dynamicReflectSampler;
uniform samplerCube dynamicReflectCubeSampler;

vec4 blend_reflect(const vec4 baseReflection, const vec4 dynamicReflection)
{
	return baseReflection * (1.0 - dynamicReflection.a) + dynamicReflection;
}

vec4 get_dynamic_plane_color(vec3 direction, bool refract)
{
	vec4 dynamicReflection = vec4(0.0);

	if (renderState.dynamicReflection == 0)
		return dynamicReflection;

	if (renderState.dynamicReflection == 1 && !refract)
	{
		if (modelProperties.dynamicReflection.clipMirror != 0)
		{
			float relativePosition = dot((base_worldPosition - baseModelMatrix * modelProperties.dynamicReflection.offset).xyz, mat3(baseModelMatrix) * modelProperties.dynamicReflection.reflectDirection.xyz);

			if ((relativePosition < 0.0 && modelProperties.dynamicReflection.clipMirror == 1) ||
				(relativePosition > 0.0 && modelProperties.dynamicReflection.clipMirror == 2))
				return dynamicReflection;
		}

		vec3 normal = get_normal_texture();

		vec4 planeReflectionPosition = dynamicPlaneMatrix * base_worldPosition;
		planeReflectionPosition.xy = 0.5 * planeReflectionPosition.xy + 0.5 * planeReflectionPosition.w + normal.xy * base_worldScale * 0.25;

		dynamicReflection = textureProj(dynamicReflectSampler, planeReflectionPosition);
	}
	else if (renderState.dynamicReflection == 2)
	{
		direction.y = -direction.y;
		dynamicReflection = texture(dynamicReflectCubeSampler, direction);
	}

	return dynamicReflection;
}

vec4 get_environment_texture_color(const vec3 direction)
{
	Channel textureChannel = material.environmentChannel;
	if (renderState.globalEnvironment) textureChannel = render.environmentChannel;

	ivec2 texSize = textureSize(environmentSampler, 0);

	float latitude = atan(direction.x, direction.z) / PI2 + 0.5;
	float longitude = atan(direction.y, sqrt(direction.x*direction.x + direction.z*direction.z)) / PI * (1.0 - 1.0 / float(texSize.y)) + 0.5;

	vec2 coords = vec2(latitude, longitude);

	vec2 dddx, dddy;
	dddx.x = dFdx(direction.x);
	dddx.y = dFdx(direction.y);
	dddy.x = dFdy(direction.x);
	dddy.y = dFdy(direction.y);

 	vec2 coordDx = vec2(length(dddx) / PI2, dFdx(longitude));
	vec2 coordDy = vec2(length(dddy) / PI2, dFdy(longitude));
 
	vec2 transformedUV = coords * textureChannel.uvRepeat + textureChannel.uvOffset;

	vec4 environment = textureGrad(environmentSampler, transformedUV, coordDx, coordDy);

	environment.rgb = mix(environment.rgb, max(vec3(0.0), vec3(1.0) - environment.rgb), textureChannel.invert);

	environment.a *= textureChannel.amount;

	environment = contrast_saturation(environment, textureChannel.gamma * render.environmentGamma, textureChannel.contrast, textureChannel.saturation, textureChannel.brightness * render.environmentExposure, textureChannel.levelInput, textureChannel.levelOutput);

	return environment * render.environmentTint;
}

vec4 get_reflect_refract_color(float incident, vec3 normal, vec3 eyeDirection, vec4 specularTexture, vec4 diffuseLight, vec4 diffuseColor, vec2 reflectionRefractionCoeff, out vec4 dynamicReflection)
{
	float diffuseAmount = clamp((diffuseLight.x + diffuseLight.y + diffuseLight.z) / 3.0, 0.0, 1.0);

	vec4 reflectCoeff = get_reflect_texture_color();

	mat3 environmentMatrix = mat3(render.environmentMatrix);
	vec3 eyeReflectionDirection = -eyeDirection * material.environmentDirection;

	vec3 reflectDirection = normalize(reflect(eyeReflectionDirection, normal));
	vec3 refractDirection = normalize(refract(eyeReflectionDirection, normal, material.refractDistortion));

	vec3 envReflectDirection = reflectDirection * environmentMatrix;
	vec3 envRefractDirection = refractDirection * environmentMatrix;

	dynamicReflection = get_dynamic_plane_color(reflectDirection, false);

	vec4 reflectColor = material.reflectColor * blend_reflect(get_environment_texture_color(envReflectDirection) * vec4(1.0 - float((renderState.dynamicReflection != 0) && modelProperties.dynamicReflection.disableEnvironment)), dynamicReflection);
	vec4 refractColor = material.refractColor * blend_reflect(get_environment_texture_color(envRefractDirection), get_dynamic_plane_color(refractDirection, true));

	vec4 reflectSpecularInfluence = mix(vec4(1.0), specularTexture, material.reflectSpecularInfluence);
	vec4 refractSpecularInfluence = mix(vec4(1.0), specularTexture, material.refractSpecularInfluence);

	vec4 reflectIntensity = reflectionRefractionCoeff.x * material.reflectAmount * reflectCoeff * reflectSpecularInfluence * reflectColor.a * ((material.environmentDirection > 0.0) ? render.mixer.reflect * mix(1.0, diffuseAmount, render.shadow.reflectionInfluence) : 1.0);
	vec4 refractIntensity = reflectionRefractionCoeff.y * material.refractAmount * reflectCoeff * refractSpecularInfluence * refractColor.a * render.mixer.refract;

	reflectIntensity *= fresnel(incident, material.reflectFresnel, material.reflectBias);
	refractIntensity *= fresnel(incident, material.refractFresnel, material.refractBias);

	if (material.reflectMode == 1) reflectIntensity = min(vec4(1.0), reflectIntensity);
	if (material.refractMode == 1) refractIntensity = min(vec4(1.0), refractIntensity);

	reflectColor *= reflectIntensity;
	refractColor *= refractIntensity;
	dynamicReflection *= reflectIntensity;

	vec4 finalColor = diffuseColor;

	if (material.refractMode <= 1)
		finalColor = finalColor * max(vec4(0.0), vec4(1.0) - refractIntensity);
	
	finalColor += refractColor;

	if (material.reflectMode <= 1)
		finalColor = finalColor * max(vec4(0.0), vec4(1.0) - reflectIntensity);

	finalColor += reflectColor;

	return finalColor;
}


float get_fog_opacity()
{
	float viewLength = length(base_viewPosition);

	if (render.fog.falloff < 2.5) // linear/exp
	{
		float fogOpacity = clamp((viewLength - render.fog.start) * render.fog.invDistance, 0.0, 1.0);
		return pow(fogOpacity * render.fog.color.a, render.fog.falloff);
	}

	float fogOpacity = (1.0 - clamp(abs((render.fog.start - viewLength) * render.fog.invDistance), 0.0, 1.0)) * render.fog.color.a;
	return fogOpacity * fogOpacity;
}



uniform sampler2DArray shadowMapSampler, shadowRaySampler;
uniform samplerCube shadowCubemapSampler;

float sample_shadow_map(vec2 tc, float id)
{
	if (render.shadow.smoothSample)
	{
		float val = 0.0;

		float p0q0 = texture(shadowMapSampler, vec3(tc, id)).r;
		float p1q0 = texture(shadowMapSampler, vec3(tc + vec2(render.shadow.invMapSize.x, 0.0), id)).r;

		float p0q1 = texture(shadowMapSampler, vec3(tc + vec2(0.0, render.shadow.invMapSize.y), id)).r;
		float p1q1 = texture(shadowMapSampler, vec3(tc + render.shadow.invMapSize, id)).r;

		vec2 ab = fract(tc / render.shadow.invMapSize);

		float pInterp_q0 = mix(p0q0, p1q0, ab.x); 
		float pInterp_q1 = mix(p0q1, p1q1, ab.x); 

		return mix(pInterp_q0, pInterp_q1, ab.y);
	}
	else
		return texture(shadowMapSampler, vec3(tc, id)).r;
}

float getRand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 getQmcPosition(float i, float w, vec4 basePos, float radius, float jitter, vec3 discU, vec3 discV)
{
	// calculate a grid from 0...w(xy)
	vec2 xyGrid = vec2(mod(i, w) + 0.5, floor(i / w) + 0.5);

	// define a jitter offset from 0...1
	vec2 jitterOffset = vec2(0.5 - getRand(gl_FragCoord.xy / frameBufferSize.xy + vec2(i + w, i) * 1.0 / frameBufferSize.x), 0.5 - getRand(gl_FragCoord.yx / frameBufferSize.yx - vec2(i, i - w) * 1.0 / frameBufferSize.x)) * jitter;
			
	// place that jittered sample inside the grid
	vec2 gridSample = xyGrid + jitterOffset;

	// normalize the grid from 0...1
	gridSample *= 1.0 / w;

	// project that grid into a disc with equal stratas (but jittered)
	vec2 discSample = vec2(sqrt(gridSample.x) * cos(PI2 * gridSample.y), sqrt(gridSample.x) * sin(PI2 * gridSample.y)) * radius;

	// now calculate the real shadow point geometry (jittered)
	return (basePos + vec4(discU * discSample.x, 0.0) + vec4(discV * discSample.y, 0.0));
}

float qmcShadowLookupCube(float i, float w, float radius, float jitter, vec3 discU, vec3 discV, int shadowId, vec3 lightVector)
{
	vec3 lookup = lightVector;
	lookup *= vec3(-1.0, 1.0, -1.0);
	return texture(shadowCubemapSampler, normalize(getQmcPosition(i, w, vec4(lookup, 0.0), radius, jitter, discU, discV).xyz)).r;
}

float qmcShadowLookup(float i, float w, float radius, float jitter, vec3 discU, vec3 discV, int shadowId, mat4 shadowMatrix)
{
	// now calculate the real shadow point geometry (jittered) (world space radius to the shadow matrix!)
	vec4 shadowPoint = shadowMatrix * getQmcPosition(i, w, base_worldPosition, radius, jitter, discU, discV);
	shadowPoint /= shadowPoint.w;
	
	if(shadowPoint.x >= 0.0 && shadowPoint.x <= 1.0 &&
	   shadowPoint.y >= 0.0 && shadowPoint.y <= 1.0)
	{
		// finally, sample the shadow map at this point
		return sample_shadow_map(shadowPoint.xy, float(shadowId));	
	}
	else
		return 9999999.0;
}

// calculate correct shadow samples and take into account depth map accuracy issues for flat surfaces. the returned value is added to the shadow term since the comparison is done inline
float qmcShadowLookupComp(float i, float w, float radius, float jitter, vec3 discU, vec3 discV, int shadowId, mat4 shadowMatrix, float sampleDepth)
{
	// now calculate the real shadow point geometry (jittered) (world space radius to the shadow matrix!)
	vec4 shadowPoint = shadowMatrix * getQmcPosition(i, w, base_worldPosition, radius, jitter, discU, discV);
	shadowPoint /= shadowPoint.w;
	
	if(shadowPoint.x >= 0.0 && shadowPoint.x <= 1.0 &&
	   shadowPoint.y >= 0.0 && shadowPoint.y <= 1.0)
	{
		return (sample_shadow_map(shadowPoint.xy, float(shadowId)) < (shadowPoint.z - abs(shadowPoint.z - sampleDepth) * render.shadow.softBlurDepthBias)) ?  0.0 : 1.0;
	}
	else
		return 1.0;
}

void get_shadow_sss(int shadowId, vec3 lightVector, mat4 shadowMatrix, mat4 projectionMatrix, float bias, float sssBias, float diffusion, float darkness, out float shadow, out float subSurface, bool isPointLight)
{
	shadow = 1.0;
	subSurface = 0.0;

	if (shadowId < 0)
		return;

	bool shadowsEnabled = render.shadow.enabled && material.receiveShadow;

	// raytraced shadows
	if (shadowsEnabled && render.shadow.rayTraced && renderState.rayTracedShadows)
	{
		float viewDistance = length(base_viewPosition);
		vec4 shadowValue = texelFetch(shadowRaySampler, ivec3(gl_FragCoord.xy * viewportScale + viewportOffset, shadowId), 0);
		
		vec2 shadowDistance = abs(shadowValue.yw - viewDistance);
		if (abs(shadowDistance.x - shadowDistance.y) < 5.0)
			shadow = (shadowValue.x + shadowValue.z) * 0.5;
		else if (shadowDistance.x < shadowDistance.y || shadowValue.w < 0.1)
			shadow = shadowValue.x;
		else
			shadow = shadowValue.z;

		shadow = (darkness > 1.0) ? pow(shadow, darkness) : mix(1.0, shadow, darkness);

		shadow = mix(1.0, shadow, render.mixer.shadows);
	}

	if (base_worldPosition.w <= 0.0 || !renderState.shadowMaps)
		return;

	vec4 shadowVertexCubemapSpace;
	vec4 shadowVertexMapSpace;
	float compZ = 0.0;
	float compZSSS = 0.0;

	// calculate each depth comparison value for shadow maps and shadow cube maps
	if(isPointLight == false)
	{
		shadowVertexMapSpace = shadowMatrix * base_worldPosition;
		compZ = shadowVertexMapSpace.z - bias;
		compZ /= shadowVertexMapSpace.w;
		compZ += 0.00001;

		compZSSS = shadowVertexMapSpace.z - sssBias;
		compZSSS /= shadowVertexMapSpace.w;
		compZSSS += 0.00001;
	}
	else
	{
		vec3 absLV = abs(lightVector);
		compZ = -max(absLV.x, max(absLV.y, absLV.z));
		shadowVertexCubemapSpace = projectionMatrix * vec4(0.0, 0.0, compZ, 1.0);
		compZ = ((shadowVertexCubemapSpace.z - bias) / shadowVertexCubemapSpace.w) * 0.5 + 0.5;	
		compZ += 0.00001;
		
		// ToDo: SSS compZSSS
	}

	// define jitter disc vectors for this sample
	vec3 discU = normalize(base_worldTangent.xyz);
	vec3 discV = normalize(cross(base_worldNormal, discU) * base_worldTangent.w);

	// shadow maps: soft PCF shadows (monte carlo strata sampling) in world space (instead of usual image space)
	if (shadowsEnabled && !render.shadow.rayTraced)
	{
		// disc vectors for this sample
		vec3 discU = normalize(base_worldTangent.xyz);
		vec3 discV = normalize(cross(base_worldNormal, discU) * base_worldTangent.w);

		float w = render.shadow.softSamples * render.shadow.softSamples;
		float div = 0.0;			// sample divisor
		float penumbraRadius = 0.0;	// radius used for diffuse penumbra sampling

		// first step: if the light has a penumbra based on depth, sample in the whole diffusion area in order to detect fragments that
		// affect the penumbra, but weigh them on their distance to the occluder
		if(diffusion > 0.0)
		{
			
			if(isPointLight == false)
			{
				for(float i = 0.0; i < w; i++)
				{
					div += 1.0;
					float dl = qmcShadowLookup(i, render.shadow.softSamples, 100.0 + 2.0 * penumbraRadius / div, render.shadow.jitter, discU, discV, shadowId, shadowMatrix);
					penumbraRadius += diffusion * max(0.0, (compZ - dl) * shadowVertexMapSpace.w)  / render.shadow.penumbraDepth;				
				}
			}
			else
			{
				for(float i = 0.0; i < w; i++)
				{
					div += 1.0;
					float dl = qmcShadowLookupCube(i, render.shadow.softSamples, 100.0 + 2.0 * penumbraRadius / div, render.shadow.jitter, discU, discV, shadowId, lightVector);
					penumbraRadius += diffusion * max(0.0, (compZ - dl) * shadowVertexCubemapSpace.w)  / render.shadow.penumbraDepth;				
				}
			}
				
			penumbraRadius /= div;
			div = 0.0;		
		}

		// next sample in the given soft blur radius + penumbra radius and fetch all samples that add to the shadow
		if(isPointLight == false)
		{
			for(float i = 0.0; i < w; i++)
			{
				div += 1.0;	
				shadow += qmcShadowLookupComp(i, render.shadow.softSamples, render.shadow.softRadius + penumbraRadius, render.shadow.jitter, discU, discV, shadowId, shadowMatrix, compZ);
			}
		}
		else
		{
			for(float i = 0.0; i < w; i++)
			{
				div += 1.0;
				float d = qmcShadowLookupCube(i, render.shadow.softSamples, render.shadow.softRadius + penumbraRadius, render.shadow.jitter, discU, discV, shadowId, lightVector);
				shadow += (d < compZ) ?  0.0 : 1.0;
			}
		}
		

		// calculate the average shadow
		shadow = (shadow - 1.0) / div;
		
		// adjust darkness factor accordingly
		shadow = (darkness > 1.0) ? pow(shadow, darkness) : mix(1.0, shadow, darkness);

		// apply gamma
		shadow = pow(shadow, render.shadow.gamma);

		shadow = mix(1.0, shadow, render.mixer.shadows);
	}

	

	// 2. calculate SSS
	if (render.subSurface.enabled && material.subSurface.enabled)
	{
		// disc vectors for this sample
		vec3 discU = normalize(shadowMatrix * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
		vec3 discV = normalize(shadowMatrix * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
		
		float w = render.subSurface.samples * render.subSurface.samples;

		if(isPointLight == false)
		{
			for(float i = 0.0; i < w; i++)
			{
				float d = qmcShadowLookup(i, render.subSurface.samples, material.subSurface.diffusion * render.subSurface.diffusion, render.subSurface.jitter, discU, discV, shadowId, shadowMatrix);
				// add the SSS value if that point is occluded
				subSurface += (d < compZSSS) ?  0.0 : 1.0;
			}
		}
		else
		{
			for(float i = 0.0; i < w; i++)
			{
				float d = qmcShadowLookupCube(i, render.subSurface.samples, material.subSurface.diffusion * render.subSurface.diffusion, render.subSurface.jitter, discU, discV, shadowId, lightVector);
				// add the SSS value if that point is occluded
				subSurface += (d < compZSSS) ?  0.0 : 1.0;
			}
		}

		// build the average SSS factor
		subSurface = subSurface / w;
		subSurface = pow(clamp(subSurface - material.subSurface.absorption * render.subSurface.absorptionMultiplier, 0.0, 1.0), material.subSurface.absorptionExponent * render.subSurface.falloffMultiplier); // todo: avoid banding here 
		subSurface *= render.mixer.subSurface;
	}
}



const vec4 lumaCoefficient = vec4(0.2126, 0.7152, 0.0722, 0.0);

void calculate_lights(vec3 normal, vec3 eyeDirection, float roughness, float specularShininess, float specularSize, out float totalShadow, out vec4 diffuseLight, out vec4 specularLight)
{
	diffuseLight = vec4(0.0);
	specularLight = vec4(0.0);
	totalShadow = 0.0;
	
	for (int i = 0; i < numLights; i++)
	{
		float shadowValue, subSurface;

		vec4 lightVector = lights[i].position - base_worldPosition;
		float lightDistance = length(lightVector.xyz);

		get_shadow_sss(lights[i].shadowId, lightVector.xyz, lights[i].shadowMatrix, lights[i].projectionMatrix, lights[i].shadowBias, render.subSurface.sssBias, lights[i].diffusion, lights[i].darkness, shadowValue, subSurface,  lights[i].type == 2);

		float luminosity = 1.0 / (1.0 + lightDistance * lights[i].falloff + lightDistance * lightDistance * lights[i].falloff * 0.2);

		// diffuse
		vec3 lightDirection = (lights[i].type == 1) ? lights[i].direction.xyz : normalize(lightVector).xyz;
		float ndotl = max(0.0, dot(lightDirection, normal));

		float lightExponent = 1.0;
		if (render.subSurface.enabled && material.subSurface.enabled)
			lightExponent = material.subSurface.penetrationExponent;
		float diffuseCoeff = pow(ndotl, lightExponent) * shadowValue * luminosity;
		float sssDiffuseCoeff = pow(max(0.0, min(1.0, dot(lightDirection, normal) - render.subSurface.lightBlending)), lightExponent) * shadowValue * luminosity;

		if (lights[i].type == 3) // spot light
		{
			float spotEffect = dot(lights[i].direction.xyz, -lightDirection);
			float spotSideFalloff = 0.0;
			
			if (spotEffect > lights[i].cosCone)
			{
				float feather = 1.0;

				if (lights[i].feather > 0.0)
				{
					feather = max(0.0, (acos(lights[i].cosCone) - acos(spotEffect)) / acos(lights[i].cosCone));
					feather = clamp(feather / lights[i].feather, 0.0, 1.0);
				}
				
				spotSideFalloff = clamp(pow(smoothstep(0.0, 1.0, feather), 2.0), 0.0, 1.0);
			}

			diffuseCoeff *= spotSideFalloff;
			subSurface *= spotSideFalloff;
			shadowValue = mix(1.0, shadowValue, spotSideFalloff);
		}

		float matteLightMix = mix(1.0, render.matteShadow.lightInfluence, material.matteShadow);
		float lightValue = mix(1.0, luminosity * dot(lights[i].diffuse.xyz, vec3(1.0 / 3.0)), matteLightMix);
		totalShadow += min(1.0, lightValue * (1.0 - shadowValue)); 

		// fade out shadow based on the opacity
		totalShadow = mix(totalShadow, mix(0.0, totalShadow, render.matteShadow.opacity), material.matteShadow);

		diffuseLight += (diffuseCoeff * lights[i].diffuse) * render.mixer.diffuse * material.diffuseAmount;

		// sub surface
		float diffLightIntensity = dot(lights[i].diffuse, lumaCoefficient);

		vec4 subSurfaceColor = mix(material.subSurface.color, lights[i].diffuse * material.subSurface.color, dot(material.subSurface.color, lumaCoefficient) * render.subSurface.tintFactor);

		diffuseLight += subSurfaceColor * clamp(subSurface - sssDiffuseCoeff, 0.0, 1.0) * material.subSurface.intensity * render.subSurface.intensity * diffLightIntensity;

		// specular
		if (roughness >= 0.0)
		{
			// cook-torrance
			vec3 halfVector = normalize(lightDirection + eyeDirection);
			float ndoth = max(0.0, dot(normal, halfVector));

			float roughnessAdjusted = roughness * 0.875 + 0.125;
		
			float alpha = roughnessAdjusted * roughnessAdjusted * roughnessAdjusted;
			float alphaSqr = alpha * alpha;

			float dDenom = (ndoth * ndoth) * (alphaSqr - 1.0) + 1.0;
			float D = alphaSqr / (PI * dDenom * dDenom);

			float k = alpha / 2.0;

			float ndotv = max(0.0, dot(normal, eyeDirection));

			float Gv = 1.0 / (ndotv * (1.0 - k) + k);
			float Gl = 1.0 / (ndotl * (1.0 - k) + k);

			float specularValue = (D * Gv * Gl / 4.0) * ndotv;

			float specularCompression = render.outputProperties.specularCompression * min(1.0, max(0.0, specularValue - 1.0) * 100.0); // 0-1 is always uncompressed

			specularLight += mix(specularValue, log2(specularValue + 1.0), specularCompression) * lights[i].diffuse * diffuseCoeff;
		}
		else
		{
			vec3 reflectDir = normalize(reflect(-lightDirection, normal));
			float specularDot = max(0.0, dot(reflectDir, eyeDirection));
			float specularAmount = pow(clamp(specularDot * specularSize, 0.0, 1.0), specularShininess * 640.0);
		
			specularLight += specularAmount * lights[i].diffuse * luminosity * min(1.0, ndotl * 10.0) * shadowValue;
		}
	}
}

void calculate_lighting(vec3 normal, vec3 eyeDirection, out float totalShadow, out vec4 ambientLight, out vec4 diffuseLight, out vec4 specularLight)
{
	ambientLight = ambientLights;
	
	calculate_lights(normal, eyeDirection, -1.0, material.specularShininess, material.specularSize, totalShadow, diffuseLight, specularLight);

	//
	ambientLight *= render.mixer.ambient * material.ambientAmount;
	specularLight *= render.mixer.specular * material.specularAmount;

	float ambientLightInfluence = mix(dot(ambientLight.xyz, vec3(1.0 / 3.0)), 0.0, material.matteShadow);

	totalShadow = (numLights == 0) ? 0.0 : clamp(totalShadow / float(numLights) - ambientLightInfluence, 0.0, 1.0);
}


vec4 sample_texture_channel(sampler2D textureSampler, const Channel channel, vec4 defaultColor);

uniform sampler2D occlusionSampler;

vec4 get_occlusion_texture_color()
{
	return sample_texture_channel(occlusionSampler, material.occlusionChannel, vec4(1.0));
}


uniform samplerCube iblSampler;

vec4 get_ibl_texture_color(vec3 direction, float lod)
{
	if (modelProperties.dynamicReflection.disableEnvironment)
		return vec4(0.0);

	Channel textureChannel = material.environmentChannel;
	if (renderState.globalEnvironment) textureChannel = render.environmentChannel;

	if (textureChannel.uvRepeat != vec2(1.0) || textureChannel.uvOffset != vec2(0.0))
	{
		float latitude = atan(direction.x, direction.z) / PI2 + 0.5;
		float longitude = atan(direction.y, sqrt(direction.x*direction.x + direction.z*direction.z)) / PI + 0.5;

		vec2 transformedUV = vec2(latitude, longitude) * textureChannel.uvRepeat + textureChannel.uvOffset;

		transformedUV.y = mod(transformedUV.y, 1.0);

		vec2 transformedAngle = vec2((transformedUV.x - 0.5) * PI2, (transformedUV.y - 0.5) * PI);

		vec2 cosAngle = cos(transformedAngle), sinAngle = sin(transformedAngle);

		direction = vec3(cosAngle.y * sinAngle.x, sinAngle.y, cosAngle.y * cosAngle.x);
	}

	vec4 environment = textureLod(iblSampler, direction, lod);

	environment.a *= textureChannel.amount;

	environment = contrast_saturation(environment, textureChannel.gamma * render.environmentGamma, textureChannel.contrast, textureChannel.saturation, textureChannel.brightness * render.environmentExposure, textureChannel.levelInput, textureChannel.levelOutput);

	environment.rgb = mix(environment.rgb, max(vec3(0.0), vec3(1.0) - environment.rgb), textureChannel.invert);

	return environment * render.environmentTint;
}

vec4 blend_reflect_pbr(const vec4 baseReflection, const vec4 dynamicReflection)
{
	return baseReflection * (1.0 - dynamicReflection.a) + dynamicReflection;
}

vec4 get_dynamic_pbr_color(vec3 direction, bool refract, float lod)
{
	vec4 dynamicReflection = vec4(0.0);

	if (renderState.dynamicReflection == 0)
		return dynamicReflection;

	if (renderState.dynamicReflection == 1 && !refract)
	{
		if (modelProperties.dynamicReflection.clipMirror != 0)
		{
			float relativePosition = dot((base_worldPosition - baseModelMatrix * modelProperties.dynamicReflection.offset).xyz, mat3(baseModelMatrix) * modelProperties.dynamicReflection.reflectDirection.xyz);

			if ((relativePosition < 0.0 && modelProperties.dynamicReflection.clipMirror == 1) ||
				(relativePosition > 0.0 && modelProperties.dynamicReflection.clipMirror == 2))
				return dynamicReflection;
		}

		vec3 normal = get_normal_texture();

		vec4 planeReflectionPosition = dynamicPlaneMatrix * base_worldPosition;
		planeReflectionPosition.xy = 0.5 * planeReflectionPosition.xy + 0.5 * planeReflectionPosition.w + normal.xy * base_worldScale * 0.25;

		dynamicReflection = textureProjLod(dynamicReflectSampler, planeReflectionPosition, lod);
	}
	else if (renderState.dynamicReflection == 2)
	{
		direction.y = -direction.y;
		dynamicReflection = textureLod(dynamicReflectCubeSampler, direction, lod);
	}

	return dynamicReflection;
}

vec4 get_pbr_color(vec3 direction, float lod, bool refraction, out vec4 dynamicColor)
{
	mat3 environmentMatrix = mat3(render.environmentMatrix);

	vec4 iblColor = get_ibl_texture_color(direction * environmentMatrix, lod) * material.environmentMultiplier;

	dynamicColor = get_dynamic_pbr_color(direction, refraction, lod);

	return blend_reflect_pbr(iblColor, dynamicColor);
}

vec4 calculate_pbr(vec4 diffuseColor, vec3 normal, vec3 eyeDirection, out float totalShadow, out vec4 dynamicReflection, vec4 pbrCoeff)
{
	vec4 reflectTexture = min(vec4(1.0), get_reflect_texture_color());
	vec4 metallicTexture = min(vec4(1.0), reflectTexture * material.reflectAmount * render.mixer.reflect);
	float originalRoughness = 1.0 - clamp(get_specular_texture_color().x * material.specularShininess, 0.0, 1.0);

	float eyeDotNormal = max(0.0, 1.0 - abs(dot(normal, eyeDirection)));

	float specLightRoughness = mix(pow(eyeDotNormal, 8.0), 1.0, originalRoughness); // increased roughness on edges
	
	float roughness = mix(pow(eyeDotNormal, 64.0), 1.0, originalRoughness);			 // 
	roughness = (renderState.dynamicReflection == 1) ? originalRoughness : roughness; // disable edge roughness when mirror is enabled

	const float diffuseRoughnessFresnel = 0.6;
	vec4 roughnessFresnel = mix(vec4(1.0 - roughness * diffuseRoughnessFresnel), vec4(1.0), metallicTexture);

	const float minimumDiffuseReflection = 0.01;
	vec4 metallicAmount = metallicTexture * material.reflectColor * (1.0 - minimumDiffuseReflection) + vec4(minimumDiffuseReflection);

	metallicAmount = mix(pow(eyeDotNormal, 5.0) * roughnessFresnel, vec4(1.0), metallicAmount); // schlick fresnel

	// direct lighting
	vec4 diffuseLight, specularLight;
	calculate_lights(normal, eyeDirection, specLightRoughness, 1.0, 1.0, totalShadow, diffuseLight, specularLight);

	vec4 ambientLight = ambientLights * render.mixer.ambient * material.ambientAmount;

	float totalDiffuse = clamp(dot(diffuseLight.xyz, vec3(1.0 / 3.0)), 0.0, 1.0);

	float ambientLightInfluence = mix(dot(ambientLight.xyz, vec3(1.0 / 3.0)), 0.0, material.matteShadow);

	totalShadow = (numLights == 0) ? 0.0 : clamp(totalShadow / float(numLights) - ambientLightInfluence, 0.0, 1.0);

	specularLight *= render.mixer.specular * material.specularAmount * pbrCoeff.w;
	diffuseLight += ambientLight;

	// indirect lighting
	// specular component
	float metallicAmountSqrt = sqrt(clamp(length(reflectTexture.xyz), 0.0, 1.0));
	//float ior = (1.0 - metallicAmountSqrt) / (1.0 + metallicAmountSqrt);

	vec3 reflectDirection = normalize(reflect(-eyeDirection, normal));
	vec3 refractDirection = normalize(refract(-eyeDirection, normal, material.refractDistortion * metallicAmountSqrt));

	float pbrLod = roughness * 6.0;

	specularLight += get_pbr_color(reflectDirection, pbrLod, false, dynamicReflection) * pbrCoeff.z;

	float reflectionInfluence = mix(1.0, totalDiffuse, render.shadow.reflectionInfluence);

	// diffuse component
	mat3 environmentMatrix = mat3(render.environmentMatrix);

	diffuseLight += get_ibl_texture_color(normal * environmentMatrix, 6.0) * material.environmentMultiplier * reflectionInfluence;
	diffuseLight *= diffuseColor;
	diffuseLight *= get_occlusion_texture_color();

	// refraction component
	vec4 dynamicRefraction;
	vec4 refractionLight = get_pbr_color(refractDirection, pbrLod, true, dynamicRefraction) * material.refractColor;
	vec4 refractAmount = min(vec4(1.0), render.mixer.refract * material.refractAmount * mix(vec4(1.0), reflectTexture, material.refractSpecularInfluence));

	// influences
	refractionLight *= reflectionInfluence;
	specularLight *= reflectionInfluence;
	dynamicReflection *= reflectionInfluence * metallicAmount;

	vec4 energyConservation = material.energyConservation ? metallicAmount : vec4(dot(metallicAmount.rgb, vec3(1.0 / 3.0)));

	// finalColor
	vec4 finalPbr = mix(diffuseLight * pbrCoeff.x, refractionLight * pbrCoeff.y, refractAmount) * (vec4(1.0) - energyConservation) + specularLight * metallicAmount;

	return finalPbr;
}


uniform sampler2D ambientOcclusionSampler;

float get_ambient_occlusion(vec4 emissiveCoeff, vec4 diffuseLight, vec4 ambientLight, float fogOpacity, out vec4 aoColor)
{
	if (!render.ao.enabled || !renderState.ambientOcclusion)
	{
		aoColor = vec4(1.0);
		return 1.0;
	}

	float emissiveAmount = clamp((emissiveCoeff.x + emissiveCoeff.y + emissiveCoeff.z) / 3.0, 0.0, 1.0);
	float diffuseAmount = clamp((diffuseLight.x + diffuseLight.y + diffuseLight.z) / 3.0, 0.0, 1.0);

	float aoAmount = 1.0 - texelFetch(ambientOcclusionSampler, ivec2(gl_FragCoord.xy * viewportScale + viewportOffset), 0).r;

	aoAmount += (aoAmount * aoAmount * aoAmount * (aoAmount * (aoAmount * 6.0 - 15.0) + 10.0) - aoAmount) * render.ao.contrast;
	
	aoAmount *= 1.0 - emissiveAmount * (1.0 - render.ao.emissiveInfluence);
	aoAmount *= max(0.0, 1.0 - max(0.0, diffuseAmount - 0.5) * render.ao.lightInfluence);
	aoAmount *= 1.0 - fogOpacity * render.ao.fogInfluence;
	
	float ambientOcclusion = 1.0 - clamp(aoAmount * material.ambientOcclusionAmount, 0.0, 1.0);

	// color
	vec4 tintAoColor = mix(vec4(0.0), render.ao.color * 0.5, min(1.0, ambientOcclusion * 2.0));		// bottom gradient
	tintAoColor = mix(tintAoColor, render.ao.color, max(0.0, ambientOcclusion * 2.0 - 1.0));		// top gradient

    aoColor = mix(tintAoColor, render.ao.color, render.ao.colorMode);

	return ambientOcclusion;
}

vec4 apply_matte(float alphaDiffuse, vec4 dynamicReflection, vec4 aoColor, float ambientOcclusion, float shadow, vec4 fragmentColor)
{
	// matte alpha
	fragmentColor = mix(aoColor, fragmentColor, ambientOcclusion);

	float alphaMatte = mix(1.0 - material.matteShadow, alphaDiffuse, material.matteUseDiffuseAlpha);

	float finalOpacity = alphaMatte;
	fragmentColor *= alphaMatte;

	// matte shadow
	vec4 matteShadowColor = mix(aoColor, render.matteShadow.shadowTint * shadow, ambientOcclusion);
	float matteShadow = ((1.0 - ambientOcclusion) + shadow * ambientOcclusion) * material.matteShadow;

	// blend matte shadow and alpha
	fragmentColor += matteShadowColor * matteShadow * (1.0 - finalOpacity);
	finalOpacity += matteShadow * (1.0 - finalOpacity);

	// matte reflection
	float reflectionMatte = 1.0 - material.matteReflection * (1.0 - material.matteUseDiffuseAlpha) * (1.0 - material.matteShadow);

	finalOpacity *= reflectionMatte;
	fragmentColor *= reflectionMatte;

	float dynamicReflectionOpacity = material.matteReflection * (1.0 - finalOpacity);

	fragmentColor = fragmentColor * (1.0 - dynamicReflectionOpacity * dynamicReflection.a) + dynamicReflection * dynamicReflectionOpacity;
	//fragmentColor = mix(fragmentColor, dynamicReflection, material.matteReflection * (1.0 - finalOpacity) * dynamicReflection.a);

	finalOpacity = mix(finalOpacity, 1.0, material.matteReflection * dynamicReflection.a);

	//
	return vec4(fragmentColor.rgb, finalOpacity * material.opacity * modelColor.a);
}



void clip_plane()
{
	if (!renderState.clipPlane || dot(base_worldPosition.xyz, clipPlane.xyz) + clipPlane.w > 0.0)
		return;

	discard;
}



uniform vec4 saidaBgColor;
uniform bool saidaGammaCorrect;
uniform float saidaGamma, saidaHighlightCompression;

vec4 saida_071(vec4 color)
{
	float alpha = min(1.0, color.a);

	if (saidaBgColor.a > 0.0)
		color = vec4(color.rgb * alpha + saidaBgColor.rgb * (1.0 - alpha), 1.0);

	if (saidaHighlightCompression > 0.0)
	{
		vec3 compressedColor = log(max(vec3(0.0), color.rgb - vec3(0.5)) * 4.0 + vec3(1.0)) * (1.0 / 4.0) + min(vec3(0.5), color.rgb);
		color.rgb = mix(color.rgb, compressedColor, saidaHighlightCompression);
	}

	if (saidaGammaCorrect)
		color.rgb = pow(color.rgb, vec3(saidaGamma));

	return color;
}

out vec4 fragData[1];

void main()
{
	clip_plane();

	vec3 normal = get_normal();

	vec3 eyeDirection = normalize(eyePosition - base_worldPosition.xyz);

	float incident = clamp(dot(normal, eyeDirection), 0.0, 1.0);

	float shadow;
	vec4 ambientLight, diffuseLight, specularLight;
	calculate_lighting(normal, eyeDirection, shadow, ambientLight, diffuseLight, specularLight);

	vec4 diffuseTexture = get_diffuse_texture_color();
	vec4 specularTexture = get_specular_texture_color();
	vec4 occlusionTexture = get_occlusion_texture_color();

	vec4 diffuseColor = diffuseTexture * material.diffuseColor * modelColor;

	vec4 diffuseCoeff = (ambientLight + diffuseLight) * diffuseColor * occlusionTexture;
	vec4 specularCoeff = specularLight * material.specularColor * specularTexture * occlusionTexture;
	vec4 emissiveCoeff = get_emissive_color(incident, diffuseColor);

	vec4 dynamicReflection;
	vec4 finalColor = emissiveCoeff + specularCoeff + get_reflect_refract_color(incident, normal, eyeDirection, specularTexture, diffuseLight, diffuseCoeff, vec2(1.0), dynamicReflection);

	float fogOpacity = get_fog_opacity();
	vec4 fragmentColor = mix(finalColor, render.fog.color, fogOpacity);
	fragmentColor.a = diffuseColor.a;

	dynamicReflection = mix(dynamicReflection, render.fog.color, fogOpacity);

	vec4 aoColor;
	float ambientOcclusion = get_ambient_occlusion(emissiveCoeff, diffuseLight, ambientLight, fogOpacity, aoColor);

	fragmentColor = apply_matte(diffuseColor.a, dynamicReflection, aoColor, ambientOcclusion, shadow, fragmentColor);

	fragmentColor = apply_wireframe_rendering(fragmentColor, fogOpacity, incident);

	if (renderState.blendOpacity)
	{
		fragmentColor.a *= min(1.0, max(fragmentColor.r, max(fragmentColor.g, fragmentColor.b)));
		if (fragmentColor.a > 0.0)
			fragmentColor /= fragmentColor.a;
	}

	fragData[0] = saida_071(fragmentColor);
}
