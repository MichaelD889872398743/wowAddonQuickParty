# Vision

Make spontaneous cooperation in the open world quick, convenient, and friendly, without taking control away from the player.

The addon follows three principles:

1. **Manual interaction:** Every invitation and departure is explicitly initiated by the player.
2. **Minimalism:** A compact interface with two actions and no unnecessary features.
3. **Clear feedback:** Inform the player when an action cannot be performed or the game reports a failure.

# Scope

## In Scope — V1

- Compact two-button interface.
- Manual invitation of the currently selected player.
- Basic target validation.
- Invitation failure and decline feedback using available game events or messages.
- Party thank-you message followed by leaving the group.
- Movable and hideable window.
- Compatibility with World of Warcraft: Forever.

## Out of Scope

- Mouseover invitations.
- Automatic invitations or player discovery.
- Proximity-based invitations.
- Scanning chat channels for players.
- Quest comparison or tracking.
- Automatic greetings.
- Automatic party departure.
- Invitation retries.
- Invitation or group history.
- Advanced party management.
- External services or integrations.

# Technical Direction

- **Language:** Lua
- **Interface:** Native World of Warcraft UI API
- **Addon manifest:** TOC
- **Dependencies:** None
- **Persistent settings:** Only window position and visibility, if necessary
- **Target:** World of Warcraft: Forever

The implementation should use the game's existing party and chat APIs, with minimal state and no unnecessary abstraction.

## Success Criteria

The addon is successful when the player can select another player, invite them with one click, receive useful feedback if the invitation fails, and send a thank-you message before leaving the party with one additional click.

All decisions remain under the player's control.