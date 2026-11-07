#version 300 es
precision highp float;
precision highp int;

in vec2 texCoords;

out vec4 fragData;

uniform sampler2D blurTexture;
uniform sampler2D normalTexture;
uniform vec2 blurDirection;
uniform vec2 texelSize;
uniform int samples;
uniform float depthThreshold;
uniform float normalThreshold;
uniform float darken;

vec4 getNormal(vec2 uv) {
	vec4 normal = texture(normalTexture, uv);
	if (normal.a > 0.0)
		normal.a = 1.0 / normal.a;
	else
		normal.a = 250000.0;
	return normal;
}

void main() {
	float blur = 0.0;
	float numSamples = float(samples) + 1.0;
	float totalWeight = 0.0;
	vec4 currentNormal = getNormal(texCoords);

	float safeDepthThresh = max(depthThreshold, 1e-6);
	float safeNormalThresh = max(normalThreshold, 1e-6);

	for (int i = -samples; i <= samples; i++) {
		float p = float(i) / numSamples;
		float weight = 1.0 - p * p;
		vec4 sampleNormal = getNormal(texCoords + blurDirection * float(i));
		float delta = abs(currentNormal.a - sampleNormal.a);
		float dp = abs(dot(currentNormal.xyz, sampleNormal.xyz));
		weight *= 1.0 - pow(clamp(delta / safeDepthThresh, 0.0, 1.0), 2.0);
		weight *= pow(clamp(dp / safeNormalThresh, 0.0, 1.0), 2.0);
		totalWeight += weight;
		blur += texture(blurTexture, texCoords + blurDirection * float(i)).r * weight;
	}

	if (totalWeight > 0.0)
		fragData = vec4(clamp(pow(blur / totalWeight, 1.0 + darken), 0.0, 1.0));
	else
		fragData = vec4(1.0);
}
