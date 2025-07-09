function q2vscode -d "Convert Amazon Q MCP server configuration to VS Code format"
    # Set default paths
    set -l input_file (test -n "$argv[1]"; and echo $argv[1]; or echo "$HOME/.aws/amazonq/mcp.json")
    set -l output_file (test -n "$argv[2]"; and echo $argv[2]; or echo "$HOME/.vscode/settings.json")
    
    # Check for help flag
    if contains -- --help $argv; or contains -- -h $argv
        echo "Amazon Q to VS Code MCP Configuration Converter"
        echo ""
        echo "Usage: q2vscode [input_file] [output_file]"
        echo ""
        echo "Arguments:"
        echo "  input_file   Path to Amazon Q mcp.json (default: ~/.aws/amazonq/mcp.json)"
        echo "  output_file  Path to VS Code settings.json (default: ~/.vscode/settings.json)"
        echo ""
        echo "Examples:"
        echo "  q2vscode"
        echo "  q2vscode custom-mcp.json vscode-settings.json"
        echo "  q2vscode --help"
        return 0
    end

    # Check if input file exists
    if not test -f "$input_file"
        echo "Error: Input file '$input_file' not found" >&2
        return 1
    end

    # Check if jq is available
    if not command -v jq >/dev/null 2>&1
        echo "Error: jq is required but not installed" >&2
        echo "Install with: brew install jq" >&2
        return 1
    end

    echo "Converting MCP configuration..."
    echo "Input:  $input_file"
    echo "Output: $output_file"

    # Create backup of existing VS Code settings if it exists
    if test -f "$output_file"
        set -l backup_file "$output_file.backup."(date +%Y%m%d_%H%M%S)
        echo "Backing up existing settings to: $backup_file"
        cp "$output_file" "$backup_file"
    end

    # Create VS Code directory if it doesn't exist
    mkdir -p (dirname "$output_file")

    # Read existing VS Code settings or create empty object
    set -l existing_settings "{}"
    if test -f "$output_file"
        set existing_settings (cat "$output_file")
    end

    # Convert Amazon Q MCP config to VS Code format
    set -l vscode_mcp_config (jq -r '
def convert_server(name; config):
  {
    command: (
      if config.command == "npx" then
        "npx"
      elif config.command == "uv" then
        "uv"  
      elif config.command == "flux-operator-mcp" then
        "flux-operator-mcp"
      else
        config.command
      end
    ),
    args: config.args,
    env: (
      if config.env and (config.env | length > 0) then
        config.env
      else
        null
      end
    )
  } | 
  with_entries(select(.value != null));

.mcpServers | 
to_entries | 
map(select(.value.disabled != true)) |
map({
  key: .key,
  value: convert_server(.key; .value)
}) |
from_entries
' "$input_file")

    # Merge with existing VS Code settings
    set -l final_config (echo "$existing_settings" | jq --argjson mcp "$vscode_mcp_config" '
. + {
  "mcp.servers": $mcp
}
')

    # Write the final configuration
    echo "$final_config" | jq . > "$output_file"

    echo ""
    echo "✅ Conversion completed successfully!"
    echo ""
    echo "Converted servers:"
    echo "$vscode_mcp_config" | jq -r 'keys[]' | while read -l server
        echo "  • $server"
    end

    echo ""
    echo "Note: Only enabled servers were converted."
    echo "Disabled servers (like opnsense) were skipped."
    echo ""
    echo "To use in VS Code:"
    echo "1. Install the MCP extension in VS Code"
    echo "2. Restart VS Code"
    echo "3. The MCP servers should be available"
    echo ""
    echo "VS Code settings updated at: $output_file"
end
