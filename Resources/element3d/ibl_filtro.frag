#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp samplerCube;



in vec2 texCoords;

out vec4 fragData[1];

uniform samplerCube textureSampler;
uniform sampler2D samplesSampler;

uniform vec3 initialCoord;
uniform vec3 coordIncX, coordIncY;

uniform float sampleLod;

uniform uint numSamples, roughnessLayer;

void main()
{
	vec3 textureDirection = normalize(initialCoord + texCoords.x * coordIncX + texCoords.y * coordIncY);

	vec3 upVector = (abs(textureDirection.z) < 0.999) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 tangentX = normalize(cross(upVector, textureDirection));
	vec3 tangentY = cross(textureDirection, tangentX);	

	vec4 irradiance = vec4(0.0);

	float totalWeight = 0.0;

	for (uint sampleIndex = 0u; sampleIndex < numSamples; sampleIndex++)
	{
		vec3 samplePoint = texelFetch(samplesSampler, ivec2(sampleIndex, roughnessLayer), 0).xyz;

		vec3 H = tangentX * samplePoint.x + tangentY * samplePoint.y + textureDirection * samplePoint.z;

		vec3 L = reflect(-textureDirection, H);

		float ndotl = dot(textureDirection, L);

		if (ndotl > 0.0)
		{
			irradiance += textureLod(textureSampler, L, sampleLod) * ndotl;
			totalWeight += ndotl;
		}
	}

	irradiance /= totalWeight;
	
	fragData[0] = irradiance;
}

