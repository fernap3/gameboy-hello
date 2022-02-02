const fs = require("fs");
const os = require("os");
const PNG = require("pngjs").PNG;

const [, , infile] = process.argv;

if (infile == null)
{
	console.log("Usage: node image2data [infile]");
	process.exit(1);
}

let imageBytes;

try
{
	imageBytes = fs.readFileSync(infile);
}
catch (e)
{
	console.log("Error reading input image file; file does not exist or is inaccessible");
	process.exit(1);
}

let png;

try
{
	png = PNG.sync.read(imageBytes, { filterType: -1 });
}
catch (e)
{
	console.log("Error reading input image file; is the image a valid PNG?");
	process.exit(1);
}


// console.log({ width: png.width, height: png.height });


const pixelIntensities = makeIntensityBuffer(png.data);
const uniqueIntensities = new Set(pixelIntensities);

if (uniqueIntensities.size > 4)
	throw new Error("Currently, there must be no more than four unique colors in the input PNG");
console.log(uniqueIntensities)
return;

// for debugging just for now
// colorMap.set("c0c0c0ff", 0);
// colorMap.set("fafafaff", 1);

// console.log({ colorMap: [...colorMap.entries()] });

// const debugFile = new PNG({ width: png.width, height: png.height });
// debugFile.pack()
// .pipe(fs.createWriteStream(__dirname + "/newfile.png"))
// .on("finish", () => console.log("done"));


const tiles = new Map();
const tileMap = [...Array(18)].map(x=>Array(32).fill(0));

tiles.set("00FF00FF00FF00FF00FF00FF00FF00FF", 0)

for (let y = 0; y < png.height; y += 8)
{
	for (let x = 0; x < png.width; x += 8)
	{
		const tileOffset = (y * png.width * 4) + (x * 4);
		let currentTileHex = "";
		
		for (let ty = 0; ty < 8; ty++)
		{
			let tileRowByte1 = 0;
			let tileRowByte2 = 0;

			for (let tx = 0; tx < 8; tx++)
			{
				const pixelOffset = tileOffset + (ty * png.width * 4) + (tx * 4);
				const [r, g, b, a] = grayScaleImageBytes.slice(pixelOffset, pixelOffset + 4);
				const hexColor = r.toString(16) + g.toString(16) + b.toString(16) + a.toString(16);
				const palateColor = colorMap.get(hexColor);

				tileRowByte1 |= ((palateColor >> 1) & 1) << (7 - tx);
				tileRowByte2 |= (palateColor & 1) << (7 - tx);
			}

			currentTileHex += ((tileRowByte1 << 8) | tileRowByte2).toString(16).padStart(4, "0");
		}

		if (!tiles.has(currentTileHex))
			tiles.set(currentTileHex, tiles.size);

		tileMap[y / 8][x / 8] = tiles.get(currentTileHex);
	}
}

// console.log(tileMap, tileMap[0][0])

printTiles(tiles);
printTileMap(tileMap);



function printTiles(tiles)
{
	console.log(`SECTION "Tile data", ROM0${os.EOL}${os.EOL}Tiles:`);
	for (const tileHex of tiles.keys())
	{
		process.stdout.write("db ");

		const formattedTileHex = tileHex.match(/.{1,4}/g)
			.map(hex => `$${hex.slice(0, 2)},$${hex.slice(2, 4)}`)
			.join(", ");

		process.stdout.write(formattedTileHex);
		process.stdout.write(os.EOL);
	}
	console.log(`TilesEnd:`);
}

function printTileMap(tileMap)
{
	console.log(`SECTION "Tilemap", ROM0${os.EOL}${os.EOL}Tilemap:`);
	for (let y = 0; y < tileMap.length; y++)
	{
		const dataString = tileMap[y].map(n => `$${n.toString(16).padStart(2, "0")}`).join(", ");
		console.log(`db ${dataString}`)
	}
	console.log(`TilemapEnd:`);
}

function makeIntensityBuffer(imageBytes)
{
	if (!(imageBytes instanceof Buffer))
		throw new Error("imageBytes must be a buffer");
	
	const intensitiesBuffer = Buffer.alloc(imageBytes.length / 4);
	const uniqueIntensities = new Set();
	
	for (let i = 0; i < png.data.length; i += 4)
	{
		const [r, g, b, a] = png.data.slice(i, i + 4);
		const intensity = rgbToIntensity(r, g, b);
		intensitiesBuffer[i / 4] = intensity;
		uniqueIntensities.add(intensity);
	}

	const intensityMap = [...uniqueIntensities]
		//.sort((a, b) => a - b)
		.map((value, i) => [value, i]);

		console.log(intensityMap)

	for (let i = 0; i < intensitiesBuffer.length; i++)
	{
		console.log("looking up:", intensitiesBuffer[i])
		intensitiesBuffer[i] = intensityMap.find(e => e[0] === intensitiesBuffer[i])[1];
	}

	return intensitiesBuffer;
}

function rgbToIntensity(r, g, b)
{
	const Y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
	return 116 * Math.pow(Y, 1/3) - 16;
}

