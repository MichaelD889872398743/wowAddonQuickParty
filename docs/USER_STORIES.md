# User Stories

## US-001 — Invite Selected Player

**As a player,** I want to invite my currently selected player using a single button, so that I can quickly form a party without navigating context menus.

**Acceptance Criteria:**
- The interface provides an Invite Player button.
- The button uses the currently selected in-game target.
- The addon validates that the target is a player and is eligible for an invitation based on available API information.
- The invitation is initiated only when the button is clicked.
- If no valid target exists, the addon displays an informative message.
- The addon does not change the player's current target.

## US-002 — Invitation Failure Feedback

**As a player,** I want to see when an invitation fails or is declined, so that I know whether I need to take further action.

**Acceptance Criteria:**
- The addon listens for relevant game events or system messages concerning party invitations.
- If the game reports an invitation failure or decline, the addon displays the available information.
- Feedback may be shown inside the addon window or through an existing in-game notification mechanism.
- The original game chat messages remain unaffected.
- The addon does not attempt to retry failed invitations.
- The addon does not need to maintain invitation history.

## US-003 — Thank & Leave

**As a player,** I want to thank my current party and leave it with one button, so that I can politely end temporary cooperation.

**Acceptance Criteria:**
- The interface provides a Thank & Leave button.
- When clicked, the addon sends a predefined message to party chat.
- After requesting the message to be sent, the addon requests to leave the party.
- The default message is: "Thanks for the group! Good luck and have fun!"
- If the player is not in a party, the addon displays an informative message.
- No automatic departure occurs without a button click.

## US-004 — Minimal User Interface

**As a player,** I want a small, movable interface, so that the addon remains accessible without interfering with gameplay.

**Acceptance Criteria:**
- The interface contains two primary buttons.
- The window can be moved and shown or hidden.
- Relevant errors and feedback are displayed without requiring the player to inspect the chat window.
- The UI uses native World of Warcraft components.
- No configuration is required for basic operation.