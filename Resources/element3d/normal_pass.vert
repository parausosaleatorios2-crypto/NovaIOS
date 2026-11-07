#version 300 es
precision highp float;
precision highp int;

in vec4 inPosition;
in vec3 inNormal;

struct RenderState {
	int dynamicReflection;
	bool clipPlane, globalEnvironment, ambientOcclusion;
	bool rayTracedShadows, shadowMaps;
	bool blendOpacity;
	bool globalWireframe, wireframeSupersample, flipNormals;
	bool pad0, pad1;
};
layout(std140) uniform ShaderState {
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
layout(std140) uniform TransformMatrices {
	mat4 viewMatrix, projectionMatrix;
	vec3 eyePosition;
	vec2 viewportScale, viewportOffset;
};
struct DynamicReflection {
	int clipMirror;
	bool disableEnvironment;
	vec4 offset, reflectDirection;
};
layout(std140) uniform ModelProperties {
	vec4 modelFlip;
	vec2 uvRepeat, uvOffset;
	float normalInvert, flipNormal;
	DynamicReflection dynamicReflection;
} modelProperties;

out vec3 fragNormal;
out float fragViewDepth;

void main() {
	vec4 worldPos = modelMatrix * (inPosition * modelProperties.modelFlip);
	vec4 viewPos = viewMatrix * worldPos;
	gl_Position = projectionMatrix * viewPos;
	mat3 normalMat = mat3(normalMatrix);
	fragNormal = normalize(normalMat * (inNormal * modelProperties.modelFlip.xyz));
	fragViewDepth = -viewPos.z;
}
