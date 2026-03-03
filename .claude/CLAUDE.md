# Amar Voice

VoiceMode is loaded as "Amar Voice" using OpenAI speech services via the voicemode plugin.

## Default State

- TTS is always enabled in the plugin (VOICEMODE_SKIP_TTS=false in ~/.voicemode/voicemode.env)
- Voice responses are OFF by default — Claude responds with text only
- User types or uses Superwhisper for speech-to-text input
- All VoiceMode MCP tools are loaded and ready to use immediately, no restart needed

## Activation

When the user says "turn on Amar voice", "enable voice", or similar:
1. Confirm voice is active with a spoken greeting using the `converse` MCP tool
2. Continue using `converse` for all responses throughout the session

When the user says "turn off Amar voice", "disable voice", or similar:
1. Stop using the converse tool
2. Return to text-only responses

## Important

- Do NOT change VOICEMODE_SKIP_TTS — it stays false permanently
- On/off is controlled by whether Claude uses the `converse` tool, not by config changes
- This means voice can be turned on/off instantly without restarting the session

## Config Location

- VoiceMode config: ~/.voicemode/voicemode.env
- Amarvoice repo: ~/git/pers/amarvoice/
