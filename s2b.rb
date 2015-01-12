# Massconverter from .schematic files to .bo2 files
# Usage: ruby s2b.rb
#        This will convert all schematics in the sibling folder "in".
#        The results will be placed in the folder "out".
#        Air and magenta colored wool is ignored.
#        If the file name is ending with R5 the z will use a -5 offset
#
# See: http://www.minecraftwiki.net/wiki/Schematic_File_Format
#      https://github.com/Wickth/TerrainControll/blob/master/bo2spec.txt
#
# Lisence: MIT

require 'rbconfig'

# Detect whether script is running on a Mac, change 'require' accordingly.
hostOs = RbConfig::CONFIG['host_os']
if /darwin|mac/.match(hostOs)
    if ! require "/Library/Ruby/Gems/1.8/gems/nbtfile-0.2.0/lib/nbtfile.rb"
        require "nbtfile"
    end
else
    require "nbtfile"
end

# Needy blocks are items like torches and doors, which require other blocks to
# be in place -- otherwise they'll simply fall to the ground as entities. We
# defer them to the end of the BOB output to ensure they're "built" last.
NEEDY_BLOCKS = [6, 26, 27, 28, 31, 32, 37, 38, 39, 40, 50, 51, 55, 59, 63, 64, 65, 66, 68, 69, 70, 71, 72, 75, 76, 77, 78, 81, 83, 85, 90, 96, 104, 105, 106, 111, 115, 127]
FILE_HEADER = [
"[META]",
"version=2.0",
"spawnOnBlockType=2",
"spawnSunlight=True",
"spawnDarkness=True",
"spawnWater=False",
"spawnLava=False",
"underFill=False",
"randomRotation=True",
"dig=True",
"tree=False",
"branch=False",
"needsFoundation=True",
"rarity=100",
"collisionPercentage=20",
"spawnElevationMin=0",
"spawnElevationMax=200",
"spawnInBiome=Custom",
"[DATA]"
]

# Folder names
NAME_IN = "in"
NAME_OUT = "out"

# Parse args
@options = ARGV.select { |arg| arg =~ /^\-+[a-z]+/ }
@args = ARGV - @options

# Create folders if they don't exist
Dir.mkdir(NAME_IN) if ! File::exists?(NAME_IN)
Dir.mkdir(NAME_OUT) if ! File::exists?(NAME_OUT)

# Find all the files in the in-folder
@filenames = Dir.glob(NAME_IN + "/*.*")

# Handle a file according to our rules
def handleFileName(filename)
	# Declare what to use
	schematic = nil
	zoffset = 0
	outfilename = nil
	outlines = nil
	
	# Load the schematic
	open(filename, "rb") do |io|
		schematic = NBTFile.load(io)[1]
	end
	
	# Figure out the zoffset
	matches = filename.scan(/R([0-9]+)\./)
	if matches.count == 1
		zoffset = -(matches[0][0].to_i)
	end
	
	# Create the new outfilename
	outfilename = filename.clone
	outfilename[".schematic"] = ".bo2"
	outfilename[NAME_IN+"/"] = NAME_OUT+"/"
	
	outlines = schematicToBO2(schematic, zoffset)
	
	open(outfilename, "w") do |io|
		outlines.each { |line| io.puts(line) } 
	end
	
	print "Converting " + filename + "\n"
end

# The method to convert a schematic to a list of strings (lines in a file)
def schematicToBO2(schematic, zoffset)
	ret = []
	# Slice blocks and block metadata by the size of the schematic's axes, then
	# zip the slices up into pairs of [id, metadata] for convenient consumption.
	blocks = schematic["Blocks"].bytes.each_slice(schematic["Width"]).to_a
	blocks = blocks.each_slice(schematic["Length"]).to_a
	data = schematic["Data"].bytes.each_slice(schematic["Width"]).to_a
	data = data.each_slice(schematic["Length"]).to_a
	layers = blocks.zip(data).map { |blocks, data| blocks.zip(data).map { |blocks, data| blocks.zip(data) } }
	deferred = []
    
    # Utility function that converts lines into strings.
    def stringifyLine(lineArray)
        return stringified = "#{lineArray[0]},#{lineArray[1]},#{lineArray[2]}:#{lineArray[3]}.#{lineArray[4]}"
    end
    
	ret.push(*FILE_HEADER)
	layers.each_with_index do |rows, z|
		z += zoffset
		rows.each_with_index do |columns, x|
			x -= schematic["Width"] / 2 # Center the object on the X axis
			columns.each_with_index do |(block, data), y|
				if block == 0 || 63 || (block == 35 && (data == 2 || data == 11)) then # We ignore air, standing sign, magentawool and (dark) blue wool
					next
				end
				y -= schematic["Length"] / 2 # Center the object on the Y axis
                line = [y, x, z, block, data]
				if NEEDY_BLOCKS.include?(block)
					deferred << line
				else
                    ret << stringifyLine(line)
				end
			end
		end
	end	
	
	# Write needy blocks to the end of the BOB file, respecting the order of
	# NEEDY_BLOCKS, in case some blocks are needier than others.
    deferred.sort! { |a, b| NEEDY_BLOCKS.index(a[3]) <=> NEEDY_BLOCKS.index(b[3]) }
    deferredStringified = []
    deferred.each do |lineToStringify|
        deferredStringified << stringifyLine(lineToStringify)
    end
    deferredStringified.reverse.each { |line| ret << line }
        
	return ret
end

print "== START ==\n"
# For each filename
@filenames.each do |filename|
	handleFileName(filename)
end
print "== DONE ==\n"
