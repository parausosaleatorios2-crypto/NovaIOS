#version 300 es
precision highp float;
precision highp int;

in vec2 texCoords;

uniform vec2 screenSize;
uniform sampler2D normalTexture;
uniform mat4 invProjectionMatrix, invModelviewMatrix, viewMatrix;
uniform int aoSamples;
uniform float aoIntensity, aoRadius, aoGamma, aoBias, depthInfluence, aoFalloffExponent, aoContactEnhancement;

out vec4 fragData;

const float PI2 = 6.28318531;

float getRand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float fetchSurface(in vec2 uv, out vec3 position, out vec3 normal) {
	vec4 n = texture(normalTexture, uv);
	n.a = n.a > 0.0 ? 1.0 / n.a : 999999.0;
	vec4 vtx = vec4(uv.xy, 1.0, 1.0) * 2.0 - 1.0;
	vec4 vp = invProjectionMatrix * vtx;
	vp *= n.a;
	vp = invModelviewMatrix * vp;
	position = vp.xyz;
	normal = n.xyz;
	return n.a;
}

float ambientOcclusion(vec3 origPos, vec3 aoPos, vec3 origNormal, vec3 aoNormal, vec2 aoCoords) {
	float normalDiff = 1.0 - max(0.0, dot(aoNormal, origNormal) * 3.0 - 2.0);
	vec3 diff = (aoPos + origNormal * aoContactEnhancement) - origPos;
	float d = length(diff);
	vec3 v = (d > 0.0) ? diff / d : diff;
	bool outsideSample = aoCoords.x < 0.0 || aoCoords.x > 1.0 || aoCoords.y < 0.0 || aoCoords.y > 1.0;
	float aoFix = outsideSample ? 0.0 : normalDiff;
	float dp = dot(origNormal, v) * aoFix;
	float normBias = max(0.0, min(1.0, (dp - aoBias) / (1.0 - aoBias)));
	float att = (1.0 - min(1.0, d * 0.0025));
	return normBias * att * att * aoIntensity;
}

void main() {
	float samples = 0.0;
	vec3 origPos, origNormal;
	float na = fetchSurface(texCoords, origPos, origNormal);

	float rad = screenSize.y * aoRadius * 0.0002;
	float depthMult = min(10.0, max(1.0, depthInfluence * 0.4 * length(origPos)) * 0.01);
	rad *= min(1.0, 1.0 / depthMult);

	float ao = 0.0;
	float allSamples = float(aoSamples) * 4.0;

	while (allSamples >= 1.0 && na > 0.0) {
		float w = floor(sqrt(allSamples));
		allSamples -= w * w;
		int iTotal = int(w * w);
		for (int ji = 0; ji < iTotal; ji++) {
			float i = float(ji);
			vec2 xyGrid = vec2(mod(i, w) + 0.5, floor(i / w) + 0.5);
			float randSeed = samples;
			vec2 jitterOffset = vec2(
				0.5 - getRand(texCoords.xy + vec2(i + randSeed, i)),
				0.5 - getRand(texCoords.yx - vec2(i, i - randSeed)));
			vec2 gridSample = xyGrid + jitterOffset;
			gridSample *= 1.0 / w;
			vec2 discSample = vec2(
				sqrt(gridSample.x) * cos(PI2 * gridSample.y),
				sqrt(gridSample.x) * sin(PI2 * gridSample.y));
			discSample = pow(length(discSample), aoFalloffExponent) * normalize(discSample) * rad;
			vec3 aoPosition, aoNormal;
			fetchSurface(texCoords + discSample, aoPosition, aoNormal);
			ao += ambientOcclusion(origPos, aoPosition, origNormal, aoNormal, texCoords + discSample);
			samples++;
		}
	}

	if (samples > 0.0) ao /= samples;
	fragData = vec4(clamp(ao, 0.0, 1.0));
}
