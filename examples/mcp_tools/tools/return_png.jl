using Images
using FileIO

function create_test_pattern()
    # Create a 256x256 test pattern
    img = zeros(RGB{N0f8}, 256, 256)
    
    # Draw some simple patterns
    for i in 1:256, j in 1:256
        # Create a gradient pattern
        img[i,j] = RGB{N0f8}(
            (i-1)/256,  # Red varies horizontally
            (j-1)/256,  # Green varies vertically
            ((i+j)/2)/256  # Blue varies diagonally
        )
    end
    
    # Save to a temporary buffer
    buf = IOBuffer()
    save(Stream(format"PNG", buf), img)

    return take!(buf)
end

# Define the tool
test_pattern_tool = MCPTool(
    name = "test_pattern",
    description = "Generate a test pattern PNG image",
    parameters = [],  # No parameters needed
    handler = _ -> ImageContent(
        data = create_test_pattern(),
        mime_type = "image/png"
    ),
    return_type = ImageContent
)

