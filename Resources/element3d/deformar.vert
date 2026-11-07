#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
#define VERT_SHADER
//
#ifdef VERT_SHADER

// input attributes

in vec3 inVertex;
in vec2 inTexCoord;
in vec3 inNormal;
in vec4 inTangent;

in vec3 inSurfaceNormal;

out vec3 outVertex;
out vec2 outTexCoords;
out vec3 outNormal;
out vec4 outTangent;


/*
// output 
out baseData
{
	vec3 vertex;
	vec2 texCoords;
	vec3 normal;
	vec4 tangent;
} base;
*/
// deform uniforms
// twist
uniform vec3 twistPhase;
uniform vec3 twistRotate;
uniform mat4 twistOrientation;
uniform mat4 twistOrientationInv;

// bend
uniform int bendAxis;			// bend axis: the axis that is bent, not the axis where bend around(!!)
uniform float bendAngle;
uniform bool bendCenter;
uniform mat4 bendOrientation;
uniform mat4 bendOrientationInv;

// taper
uniform float taperAmount;
uniform float taperCurve;
uniform bool taperSymmetrical;
uniform mat4 taperOrientation;
uniform mat4 taperOrientationInv;

// noise
uniform float noiseBlur;
uniform float noiseSmoothNormals;

// displacement & noise
uniform sampler2D displacementMap;
uniform int displacementMappingType;
uniform float normalStrength;
uniform float expandAlongNormal;
uniform vec2 uvRepeat;
uniform vec2 uvOffset;

// fractal
uniform float fractal;
uniform float fractalDistort;
uniform float fractalScale;
uniform float fractalEvolution;
uniform float fractalExponent;
uniform float fractalMin;
uniform float fractalMax;
uniform float fractalOffset;
uniform vec3 distortionDirectionScale;
uniform int fractalDistortionMethod;

uniform float noiseSeed;

// general deform settings
uniform mat4 deformOrientation;
uniform mat4 deformOrientationInv;
uniform vec3 deformScale;

uniform bool displaceEnabled;
uniform bool twistEnabled;
uniform bool bendEnabled;
uniform bool taperEnabled;
uniform bool fractalEnabled;

uniform vec3 modelFlip;

vec3 deformationNormalizeScale;

// deform helper functions
float getRand3(vec3 co)
{
	return mod(sin(dot(co, vec3(12.9898, 78.233, 45.1212))) * 43758.5453, 1.0) * 2.0 - 1.0;
}

mat4 rotationMatrix(vec3 axis, float angle)
{
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;
	return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
		oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
		oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
		0.0, 0.0, 0.0, 1.0);
}

// deform functions
void twist(inout vec4 shVertex, inout vec3 shNormal, inout vec4 shTangent)
{
	// transform to twist-space
	shVertex = twistOrientation * shVertex;
	shNormal = (twistOrientation * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (twistOrientation * shTangent).xyz;
	
	vec3 rotationAmount;
	rotationAmount.x = shVertex.x / (deformationNormalizeScale.x > 0.0 ? deformationNormalizeScale.x : 1.0);
	rotationAmount.y = shVertex.y / (deformationNormalizeScale.y > 0.0 ? deformationNormalizeScale.y : 1.0);
	rotationAmount.z = shVertex.z / (deformationNormalizeScale.z > 0.0 ? deformationNormalizeScale.z : 1.0);


	// todo: optimize
	mat4 deformX = rotationMatrix(vec3(1.0, 0.0, 0.0), twistPhase.x + twistRotate.x * rotationAmount.x);
	mat4 deformY = rotationMatrix(vec3(0.0, 1.0, 0.0), twistPhase.y + twistRotate.y * rotationAmount.y);
	mat4 deformZ = rotationMatrix(vec3(0.0, 0.0, 1.0), twistPhase.z + twistRotate.z * rotationAmount.z);
	shVertex = deformX * shVertex;
	shVertex = deformY * shVertex;
	shVertex = deformZ * shVertex;

	shNormal = normalize((deformX * vec4(shNormal, 0.0)).xyz);
	shNormal = normalize((deformY * vec4(shNormal, 0.0)).xyz);
	shNormal = normalize((deformZ * vec4(shNormal, 0.0)).xyz);

	shTangent = vec4(normalize((deformX * shTangent).xyz), inTangent.w);
	shTangent = vec4(normalize((deformY * shTangent).xyz), inTangent.w);
	shTangent = vec4(normalize((deformZ * shTangent).xyz), inTangent.w);

	// transform back to deform-space
	shVertex = twistOrientationInv * shVertex;
	shNormal = (twistOrientationInv * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (twistOrientationInv * shTangent).xyz;

}

void bend(inout vec4 shVertex, inout vec3 shNormal, inout vec4 shTangent)
{
	if(bendAngle == 0.0) 
		return;

	float bendLocalAngle = bendAngle;

	// transform to bend-space
	shVertex = bendOrientation * shVertex;
	shNormal = (bendOrientation * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (bendOrientation * shTangent).xyz;

	deformationNormalizeScale *= modelFlip;

	vec4 center;
	mat4 rotMatrix;
	vec3 projectionBase;
	vec3 projectionShift = vec3(0.0, 0.0, 0.0);
	vec3 centerShift = vec3(0.0, 0.0, 0.0);

	vec3 rotationAmount;
	rotationAmount.x = shVertex.x / (deformationNormalizeScale.x > 0.0 ? deformationNormalizeScale.x : 1.0);
	rotationAmount.y = shVertex.y / (deformationNormalizeScale.y > 0.0 ? deformationNormalizeScale.y : 1.0);
	rotationAmount.z = shVertex.z / (deformationNormalizeScale.z > 0.0 ? deformationNormalizeScale.z : 1.0);

	if(bendAxis == 0) // X
	{ 
		projectionBase = vec3(0.0, 1.0, 1.0);
		center = vec4(0.0, 1.0 / (bendLocalAngle / deformationNormalizeScale.x), 0.0, 1.0);
		float rotationAngle = rotationAmount.x * bendLocalAngle;
		rotMatrix = rotationMatrix((vec4(0.0, 0.0, 1.0, 0.0)).xyz, -1.0 * rotationAngle);
		centerShift.y = -deformationNormalizeScale.x / bendLocalAngle;
	}
	else if(bendAxis == 1) // Y
	{
		projectionBase = vec3(1.0, 0.0, 1.0);
		center = vec4(1.0 / (bendLocalAngle / deformationNormalizeScale.y), 0.0, 0.0, 1.0);
		float rotationAngle = rotationAmount.y * bendLocalAngle;
		rotMatrix = rotationMatrix((vec4(0.0, 0.0, 1.0, 0.0)).xyz, rotationAngle);
		centerShift.x = -deformationNormalizeScale.y / bendLocalAngle;
	}
	else if(bendAxis == 2) // Z
	{
		projectionBase = vec3(1.0, 1.0, 0.0);
		center = vec4(1.0 / (bendLocalAngle / deformationNormalizeScale.z), 0.0, 0.0, 1.0);
		float rotationAngle = rotationAmount.z * bendLocalAngle;
		rotMatrix = rotationMatrix((vec4(0.0, 1.0, 0.0, 0.0)).xyz, -1.0 * rotationAngle);
		centerShift.x = -deformationNormalizeScale.z / bendLocalAngle;
	}


	shVertex.xyz -= center.xyz;
	shVertex.xyz *= projectionBase;
	shVertex.xyz += projectionShift;
	shVertex = rotMatrix * shVertex;

	shVertex.xyz += center.xyz;
	if(bendCenter)
		shVertex.xyz += centerShift;
	
	
	shNormal = (rotMatrix * vec4(shNormal, 0.0)).xyz;
	shNormal = normalize(shNormal);
	shTangent.xyz = (rotMatrix * shTangent).xyz;
	shTangent = vec4(normalize(shTangent.xyz), shTangent.w);

	// transform back to deform-space
	shVertex = bendOrientationInv * shVertex;
	shNormal = (bendOrientationInv * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (bendOrientationInv * shTangent).xyz;

	deformationNormalizeScale *= modelFlip;
}

float getTaperIntensity(float y)
{
	float s = (y + 1.0) / 2.0;
	if(taperSymmetrical)
		s = abs(y);
	return s * taperAmount + sin(s * 3.1415) * taperCurve;
}

void taper(inout vec4 shVertex, inout vec3 shNormal, inout vec4 shTangent)
{
	// transform to taper-space
	shVertex = taperOrientation * shVertex;
	shNormal = (taperOrientation * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (taperOrientation * shTangent).xyz;
	
	float taperIntensity = getTaperIntensity(shVertex.y);
	shVertex.xz += shVertex.xz * taperIntensity;

	// transform back to deform-space
	shVertex = taperOrientationInv * shVertex;
	shNormal = (taperOrientationInv * vec4(shNormal, 0.0)).xyz;
	shTangent.xyz = (taperOrientationInv * shTangent).xyz;
}

vec4 texture2D_bilinear(sampler2D tex, vec2 uv)
{
	vec2 f = fract(uv.xy * 1024.0);
	vec4 t00 = texture(tex, uv);
	vec4 t10 = texture(tex, uv + vec2(1.0 / 1024.0, 0.0));
	vec4 tA = mix(t00, t10, f.x);
	vec4 t01 = texture(tex, uv + vec2(0.0, 1.0 / 1024.0));
	vec4 t11 = texture(tex, uv + vec2(1.0 / 1024.0, 1.0 / 1024.0));
	vec4 tB = mix(t01, t11, f.x);
	return mix(tA, tB, f.y);
}

float readDisplacementMap(vec2 uv)
{
	return texture2D_bilinear(displacementMap, uv).r;
}

// apply displacement to a given vertex while taking other vertices into account
void displace(inout vec4 shVertex, in vec3 shNormal, inout vec4 shTangent, in vec2 uv, out vec3 displaceNormal)
{
	vec3 shNoiseCoord;

	switch (displacementMappingType)
	{
	case 1: // Simple Sphere Mapping
		{
			vec3 v = normalize(shVertex.xyz);
			shNoiseCoord = vec3(-0.5 - (atan(v.x, v.z) / 3.1415) / 2.0, (asin(v.y) / 3.1415), 0.0);
		}
		break;
	case 2: // Plane XY
		shNoiseCoord = vec3(shVertex.x + 1.0, shVertex.y + 1.0, 0.0) * 0.5;
		break;
	case 3: // Plane YZ
		shNoiseCoord = vec3(shVertex.y + 1.0, shVertex.z + 1.0, 0.0) * 0.5;
		break;
	case 4: // Plane XZ
		shNoiseCoord = vec3(shVertex.x + 1.0, shVertex.z + 1.0, 0.0) * 0.5;
		break;
	case 5:
		shNoiseCoord = vec3(shVertex.x + 1.0, shVertex.y + 1.0, 0.0) * 0.5;
		shNoiseCoord += vec3(shVertex.y + 1.0, shVertex.z + 1.0, 0.0) * 0.5;
		shNoiseCoord += vec3(shVertex.x + 1.0, shVertex.z + 1.0, 0.0) * 0.5;
		shNoiseCoord /= 3.0;
		break;
	case 0:
	default: // uv mapping
		shNoiseCoord = vec3(uv.x, uv.y, 0.0);
		break;
	}
	
	shNoiseCoord.xy = shNoiseCoord.xy * uvRepeat + uvOffset;

	shNoiseCoord.x = fract(shNoiseCoord.x);
	shNoiseCoord.y = fract(shNoiseCoord.y);

	vec3 p[4];
	vec3 normal;
	float noiseNormalizeRange = 1.0 / 1024.0 + 0.1 * (5.0 * noiseSmoothNormals + noiseBlur);

	// displace vertex based on actual parameters
	float nPos = readDisplacementMap(shNoiseCoord.xy);
	shVertex.xyz += nPos * shNormal;

	// sample close neighbours for normal estimation
	shNoiseCoord.z = nPos;
	p[0] = shNoiseCoord + vec3(-noiseNormalizeRange, 0.0, 0.0);
	p[1] = shNoiseCoord + vec3(noiseNormalizeRange, 0.0, 0.0);
	p[2] = shNoiseCoord + vec3(0.0, noiseNormalizeRange, 0.0);
	p[3] = shNoiseCoord + vec3(0.0, -noiseNormalizeRange, 0.0);

	p[0].z = readDisplacementMap(p[0].xy);
	p[1].z = readDisplacementMap(p[1].xy);
	p[2].z = readDisplacementMap(p[2].xy);
	p[3].z = readDisplacementMap(p[3].xy);

	// calculate base normals
	vec3 a = normalize(p[0] - shNoiseCoord);
	vec3 b = normalize(p[1] - shNoiseCoord);
	vec3 c = normalize(p[2] - shNoiseCoord);
	vec3 d = normalize(p[3] - shNoiseCoord);

	// build surface normal accordingly
	displaceNormal = normalize(vec3(normalize(cross(d, b)) + normalize(cross(c, a))));
	
	// scale the xy component of the normal so that we can approximate the normal issue
	displaceNormal.xy *= (1.0 + normalStrength);
	displaceNormal = normalize(displaceNormal);
}

vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float mod289(float x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
	return mod289(((x*34.0) + 1.0)*x);
}

float permute(float x) {
	return mod289(((x*34.0) + 1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
	return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 grad4(float j, vec4 ip)
{
	const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
	vec4 p, s;

	p.xyz = floor(fract(vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
	p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
	s = vec4(lessThan(p, vec4(0.0)));
	p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

	return p;
}

// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451

// https://github.com/hughsk/glsl-noise/blob/master/LICENSE
float snoise(vec4 v)
{
	const vec4 C = vec4(0.138196601125011, // (5 - sqrt(5))/20 G4
		0.276393202250021, // 2 * G4
		0.414589803375032, // 3 * G4
		-0.447213595499958); // -1 + 4 * G4

	// First corner
	vec4 i = floor(v + dot(v, vec4(F4)));
	vec4 x0 = v - i + dot(i, C.xxxx);

	// Other corners

	// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
	vec4 i0;
	vec3 isX = step(x0.yzw, x0.xxx);
	vec3 isYZ = step(x0.zww, x0.yyz);
	// i0.x = dot( isX, vec3( 1.0 ) );
	i0.x = isX.x + isX.y + isX.z;
	i0.yzw = 1.0 - isX;
	// i0.y += dot( isYZ.xy, vec2( 1.0 ) );
	i0.y += isYZ.x + isYZ.y;
	i0.zw += 1.0 - isYZ.xy;
	i0.z += isYZ.z;
	i0.w += 1.0 - isYZ.z;

	// i0 now contains the unique values 0,1,2,3 in each channel
	vec4 i3 = clamp(i0, 0.0, 1.0);
	vec4 i2 = clamp(i0 - 1.0, 0.0, 1.0);
	vec4 i1 = clamp(i0 - 2.0, 0.0, 1.0);

	// x0 = x0 - 0.0 + 0.0 * C.xxxx
	// x1 = x0 - i1 + 1.0 * C.xxxx
	// x2 = x0 - i2 + 2.0 * C.xxxx
	// x3 = x0 - i3 + 3.0 * C.xxxx
	// x4 = x0 - 1.0 + 4.0 * C.xxxx
	vec4 x1 = x0 - i1 + C.xxxx;
	vec4 x2 = x0 - i2 + C.yyyy;
	vec4 x3 = x0 - i3 + C.zzzz;
	vec4 x4 = x0 + C.wwww;

	// Permutations
	i = mod289(i);
	float j0 = permute(permute(permute(permute(i.w) + i.z) + i.y) + i.x);
	vec4 j1 = permute(permute(permute(permute(
		i.w + vec4(i1.w, i2.w, i3.w, 1.0))
		+ i.z + vec4(i1.z, i2.z, i3.z, 1.0))
		+ i.y + vec4(i1.y, i2.y, i3.y, 1.0))
		+ i.x + vec4(i1.x, i2.x, i3.x, 1.0));

	// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
	// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
	vec4 ip = vec4(1.0 / 294.0, 1.0 / 49.0, 1.0 / 7.0, 0.0);

	vec4 p0 = grad4(j0, ip);
	vec4 p1 = grad4(j1.x, ip);
	vec4 p2 = grad4(j1.y, ip);
	vec4 p3 = grad4(j1.z, ip);
	vec4 p4 = grad4(j1.w, ip);

	// Normalise gradients
	vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	p4 *= taylorInvSqrt(dot(p4, p4));

	// Mix contributions from the five corners
	vec3 m0 = max(0.6 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	vec2 m1 = max(0.6 - vec2(dot(x3, x3), dot(x4, x4)), 0.0);
	m0 = m0 * m0;
	m1 = m1 * m1;
	return 49.0 * (dot(m0*m0, vec3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
		+ dot(m1*m1, vec2(dot(p3, x3), dot(p4, x4))));
}

float fractalNoise(vec4 v)
{
	float n = snoise(v);
	return sign(n) * pow(abs(n), fractalExponent);
}

void main()
{
	vec4 shVertex = vec4(inVertex, 1.0);
	vec3 shNormal = inNormal;
	vec4 shTangent = inTangent;
	vec3 shSurfaceNormal = normalize(inSurfaceNormal);

	// apply expansion (maybe we move this to the model shader and let it bypass deforms, but we need to drag this through RT as well...)
	shVertex.xyz += shSurfaceNormal * expandAlongNormal * 0.1;
	shVertex.xyz *= 1.0 - expandAlongNormal * 0.1;

	if (displaceEnabled)
	{
		// apply displacement if available
		vec3 displaceNormal = vec3(0.0, 0.0, 1.0);
		displace(shVertex, shSurfaceNormal, shTangent, inTexCoord, displaceNormal);

		// recalculate normals and tangent base
		vec3 t = normalize(shTangent.xyz);
		vec3 b = normalize(cross(shNormal, shTangent.xyz)) * shTangent.w;
		shNormal = normalize(mat3(t, b, shNormal) * displaceNormal);
		shTangent = vec4(normalize(cross(shNormal, b)), 1.0);
	}

	// transform vertices to deformation space
	shVertex = deformOrientation * (shVertex * vec4(modelFlip, 1.0));
	deformationNormalizeScale = deformScale * modelFlip;
	shNormal = (deformOrientation * vec4(shNormal * modelFlip, 0.0)).xyz;
	shTangent.xyz = (deformOrientation * shTangent).xyz;
	shSurfaceNormal = (deformOrientation * vec4(shSurfaceNormal * modelFlip, 0.0)).xyz;

	const float fractalEffectScale = 0.5;

	if (fractalEnabled)
	{
		// apply fractal noise
		float sn = fractalNoise(vec4(shVertex.xyz * fractalScale, 1.0 + noiseSeed + fractalEvolution));

		// distort positioning one-dimensional offset based
		if(fractalDistortionMethod == 0 || fractalDistortionMethod == 2)
		{
			// min/max
			sn = clamp(sn, fractalMin * 2.0 - 1.0, fractalMax * 2.0 - 1.0);

			vec3 d = vec3(fractalNoise(vec4(shVertex.xyz * fractalScale, 1.0 + noiseSeed + fractalEvolution)), 
						  fractalNoise(vec4(shVertex.xyz * fractalScale, 1.0 + 2.0 * fractalDistort + noiseSeed + fractalEvolution)), 
						  fractalNoise(vec4(shVertex.xyz * fractalScale, 1.0 + 6.0 * fractalDistort + noiseSeed + fractalEvolution)));
			if(length(d) > 0.0)
				d = normalize(d);
			shVertex.xyz += mix(shSurfaceNormal * sn, d, min(1.0, fractalDistort)) * fractal * distortionDirectionScale * fractalEffectScale + shNormal * fractalOffset;
		}

		// distort 3D vtx evolution based
		if(fractalDistortionMethod == 1)
		{
			vec3 distNormal = shSurfaceNormal * clamp(sn, fractalMin * 2.0 - 1.0, fractalMax * 2.0 - 1.0);

			sn = abs(sn);
			sn = clamp(sn, fractalMin, fractalMax);

			vec3 distVtx = vec3(fractalNoise(vec4(shVertex.xyz * fractalScale, shVertex.x + noiseSeed + fractalEvolution)),
								fractalNoise(vec4(shVertex.xyz * fractalScale, shVertex.y + noiseSeed + fractalEvolution)), 
								fractalNoise(vec4(shVertex.xyz * fractalScale, shVertex.z + noiseSeed + fractalEvolution)));
			if(length(distVtx) > 0.0)
				distVtx = normalize(distVtx);
			distVtx *= sn;

			vec3 dist[2];
			dist[0] = distNormal * distortionDirectionScale * fractal * fractalEffectScale + shSurfaceNormal * fractalOffset;
			dist[1] = distVtx * distortionDirectionScale * fractal * fractalEffectScale + shSurfaceNormal * fractalOffset;

			shVertex.xyz = mix(dist[0] + shVertex.xyz, dist[1] + shVertex.xyz, min(1.0, fractalDistort));
		}

		// vertex distortion
		if(fractalDistortionMethod == 3)
		{
			vec3 offset = vec3(0.1253 + noiseSeed, 0.714 + noiseSeed, -0.25 - noiseSeed);
			vec3 distortion = vec3(fractalNoise(vec4(shVertex.xyz * fractalScale, fractalEvolution)), 
								   fractalNoise(vec4(shVertex.xyz * fractalScale + offset, fractalEvolution)), 
								   fractalNoise(vec4(shVertex.xyz * fractalScale + offset * 2.0, fractalEvolution))) * distortionDirectionScale * fractal * 0.5;
			shVertex.xyz += distortion;
		}
	}
	 
	if (taperEnabled)
		taper(shVertex, shNormal, shTangent);

	if (twistEnabled)
		twist(shVertex, shNormal, shTangent);

	if (bendEnabled)
		bend(shVertex, shNormal, shTangent);

	// transform vertices to world space
	shVertex = (deformOrientationInv * shVertex) * vec4(modelFlip, 1.0);
	shNormal = (deformOrientationInv * vec4(shNormal, 0.0)).xyz * modelFlip;
	shTangent.xyz = (deformOrientationInv * shTangent).xyz;

	// map changed input to output vertices
	/*base.vertex = shVertex.xyz;
	base.normal = shNormal;
	base.tangent = shTangent;
	base.texCoords = inTexCoord;*/

	outVertex = shVertex.xyz;
	outTexCoords = inTexCoord;
	outNormal = shNormal;
	outTangent = shTangent;


}

#else
/*
// geometry shader normal calculation was removed due to errors on old mac drivers. Tramsform Feedback is written wrong on a few AMD 5x cards.
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

// output
in baseData
{
	vec3 vertex;
	vec2 texCoords;
	vec3 normal;
	vec4 tangent;
} base[];

out vec3 outVertex;
out vec2 outTexCoords;
out vec3 outNormal;
out vec4 outTangent;

uniform bool calculateFaceNormals;

void main()
{
	vec3 a = normalize(base[1].vertex - base[0].vertex);
	vec3 b = normalize(base[2].vertex - base[0].vertex);
	vec3 normal = cross(a, b);

	for (int i = 0; i < 3; i++)
	{
		outVertex = base[i].vertex;
		outTexCoords = base[i].texCoords;
		if (calculateFaceNormals && length(normal) > 0.0)
			outNormal = normalize(normal);
		else
			outNormal = base[i].normal;
		outTangent = base[i].tangent;
		EmitVertex();
	}

	EndPrimitive();
}*/

#endif
