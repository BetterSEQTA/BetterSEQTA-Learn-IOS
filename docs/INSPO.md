# The Anatomy of Craft: Nitish Khagwal’s Interaction Showcase

Nitish Khagwal’s `/interactions` showcase is one of the benchmark repositories for modern micro-interaction and UI motion design. Across **124 distinct prototypes** spanning from April 2024 to October 2026, the collection demonstrates how interface engineering moves beyond static screens into living, tactile digital physical objects.

---

## Why It Feels and Looks So Good: The Core Design Philosophy

Before breaking down every single component, it is critical to understand the underlying physics and visual rules that make Khagwal’s work feel effortlessly "buttery" and intuitive:

1. **Spring Physics Over Linear Curves:** Nothing on this page moves on a standard CSS `ease-in-out` or linear duration curve. Every expansion, collapse, and translation is driven by **critically damped and slightly underdamped spring physics** (balancing mass, stiffness, and damping). When a pill expands into a card, it carries micro-momentum—overshooting by a fraction of a pixel before settling—mimicking real-world elasticity.
2. **Spatial Continuity & Shared Layout Morphing:** Modals and menus rarely "pop" into existence from thin air. Instead, triggers *become* the containers (Shared Element Transitions / FLIP animations). A button's border-radius, background fill, and inner padding smoothly interpolate into a confirmation dialog or picker. Your eye never loses track of where an element came from, eliminating **change blindness**.
3. **Optical & Concentric Geometry:** Nested elements obey strict concentric border radii ($R_{outer} = R_{inner} + Padding$). As containers morph their dimensions in real time, their corner radii dynamically recalculate frame-by-frame so corners never look pinched or warped during mid-transition.
4. **Motion Blur, Staggered Choreography & Opacity Crossfades:** When text or icons swap inside a morphing container, they don't simply snap. Outgoing labels scale down (`0.95`), blur (`filter: blur(4px)`), and fade out while incoming elements unblur and rise into place with a `20ms–40ms` stagger.
5. **Tactile Surface Aesthetics:** The visual language relies on whisper-quiet neutral palettes, `1px` specular inner borders (`rgba(255,255,255,0.08)` or subtle dark hairline borders), and multi-layered ambient shadows that expand as an element scales up to simulate elevation toward the user’s eye.
6. **Zero-Modal Context Preservation ("Human Factor" UX):** Grounded in his core principle—*"make product interaction so easy that it becomes hard for users to make errors"*—Khagwal replaces disruptive full-screen alerts with **inline disclosures**. Everything happens exactly where the user’s cursor or thumb is already resting.

---

## Complete Breakdown of Every Interaction (1–124)

Below is the comprehensive, chronological breakdown (newest to oldest) of every single interaction on `[khagwal.com/interactions/](https://khagwal.com/interactions/)`, detailing the exact micro-animations, physics, and UX rationale behind each.

---

### Late 2026: Spatial AI, Tactile Pickers & Contextual Splits

#### 1. Response Bar *(09 October 26)*

* **The Micro-Animation:** An inline AI/chat response action bar that dynamically morphs as the user interacts with feedback icons (like, dislike, regenerate, copy). Clicking a thumbs-down or follow-up trigger smoothly elongates the pill container horizontally and vertically, unfolding follow-up reason chips with a staggered spring cascade while neighboring icons slide aside without layout jitter.
* **Why the UX is Great:** Prevents feedback fatigue. Instead of opening a separate feedback modal when a user rates a response poorly, the bar expands in-place, capturing granular sentiment with zero context switching.

#### 2. Micro Progress Button *(06 October 26)*

* **The Micro-Animation:** Upon click, the button text gently compresses and shifts while an internal progress fill or circular micro-ring animates directly inside the button’s bounds. As progress hits 100%, the progress track collapses into a crisp checkmark icon with a springy scale bounce (`scale(0.6)` to `scale(1)`).
* **Why the UX is Great:** Eliminates uncertainty during asynchronous tasks (like uploading or compiling) by turning the trigger itself into a real-time progress meter, preventing double-clicks.

#### 3. Ruler Picker *(04 October 26)*

* **The Micro-Animation:** A skeuomorphic-inspired horizontal/vertical tick-mark ruler. As you drag across the ticks, the active tick mark dynamically elongates and darkens, while neighboring ticks scale in a smooth bell-curve wave (Gaussian falloff). Numbers above the indicator roll vertically like a mechanical odometer with subtle motion blur.
* **Why the UX is Great:** Standard sliders lack precision for exact numeric values, and text inputs are tedious on mobile. The ruler gives fine-grained scrubbing control with high visual and haptic-like feedback.

#### 4. Invite Code *(24 September 26)*

* **The Micro-Animation:** A Masked/Segmented code display or input box where revealing or entering characters triggers a per-character vertical slot-machine flip and a soft glow wave across the container border once validated or copied.
* **Why the UX is Great:** Turns a mundane alphanumeric string into a celebratory, high-trust artifact, giving immediate visual verification that the full code was captured accurately.

#### 5. Reversible Action *(20 September 26)*

* **The Micro-Animation:** When an action (like archiving or muting) is triggered, the row or button morphs into an active "Undo" pill where the background fill acts as a depleting countdown timer bar. Clicking undo reverses the spring trajectory, restoring the original UI state seamlessly.
* **Why the UX is Great:** Implements defensive design (preventing human error) without annoying "Are you sure?" confirmation popups before every action.

#### 6. Navigation Controls *(19 September 26)*

* **The Micro-Animation:** Back/Forward and breadcrumb pill controls that dynamically compress and expand based on navigation depth. Hovering over arrows triggers a directional micro-nudge, while long-pressing or clicking expands recent history layers in a fluid horizontal fan.
* **Why the UX is Great:** Gives spatial awareness of where the user has been and where they can go inside complex single-page applications.

#### 7. Contextual Action Split *(14 September 26)*

* **The Micro-Animation:** A unified primary action pill that, upon tap or hover, physically splits down the middle like cell division (mitosis). The single container separates into two or three distinct rounded buttons (e.g., "Edit", "Share", "Delete") with an elastic gap forming between them.
* **Why the UX is Great:** Keeps the resting UI ultra-minimal with a single clean footprint, revealing secondary actions only at the exact moment of intent.

#### 8. Voice Mode *(13 September 26)*

* **The Micro-Animation:** Transitioning from text input to voice input causes the text bar to contract into an organic, breathing audio visualizer orb/pill. Real-time frequency bars undulate smoothly using sine-wave interpolation, and tapping "stop" smoothly collapses the waves back into transcribed text.
* **Why the UX is Great:** Bridges the gap between silent typing and ambient speaking by providing immediate visual reassurance that the microphone is hot and actively listening to vocal cadence.

#### 9. Contextual Disclosure *(07 September 26)*

* **The Micro-Animation:** Clicking an inline trigger or info badge smoothly pushes surrounding layout elements apart while unfolding a detailed card from the exact origin point of the click, using height auto-interpolation and opacity unblurring.
* **Why the UX is Great:** Allows users to drill down into metadata or secondary settings without losing sight of the parent list or document.

#### 10. Status Picker *(06 September 26)*

* **The Micro-Animation:** Clicking a current status badge (e.g., "In Progress") expands the pill into a compact vertical or radial stack of status states. Selecting a new status morphs the indicator dot's color and collapses the menu back into the pill with a satisfying snap.
* **Why the UX is Great:** Makes project management state changes feel rapid and lightweight rather than buried in clunky native HTML select dropdowns.

#### 11. Preview Slider *(28 August 26)*

* **The Micro-Animation:** Dragging the slider thumb pops up a floating preview tooltip/thumbnail directly above the thumb. As you drag left or right, the floating card tilts slightly based on drag velocity (physics-based rotation follows velocity vector) and updates its preview content in real time.
* **Why the UX is Great:** Prevents scrub-guessing (whether in video timelines or parameter adjustments) by showing the exact outcome before the user releases their finger or mouse.

#### 12. Conditional Stepper *(25 August 26)*

* **The Micro-Animation:** A multi-step flow where selecting a specific option dynamically inserts or removes subsequent step indicators in the progress bar, smoothly sliding the remaining dots to re-center the layout.
* **Why the UX is Great:** Adapts complex forms dynamically to user input so users only see steps relevant to their choices, reducing perceived form length.

#### 13. Confirm to Delete *(17 August 26)*

* **The Micro-Animation:** Clicking a trash/delete button doesn't delete immediately—instead, the button flushes crimson red and expands horizontally to reveal "Confirm Delete?" alongside a cancel `X`. The trash icon shakes slightly on initial click to signal danger.
* **Why the UX is Great:** Keeps the confirmation right under the cursor. Users have to make a conscious second click in the same spatial zone, preventing accidental data loss without a disruptive modal overlay.

---

### Mid 2026: Morphing States, Steppers & Progressive Disclosures

#### 14. Morphing Action Feedback *(08 July 26)*

* **The Micro-Animation:** A multi-phase button/bar that morphs its entire geometry through Idle → Processing (contracting into a tight pill with a spinner) → Success/Error (expanding into a status banner with descriptive text) before gently resetting.
* **Why the UX is Great:** Communicates system state changes entirely through shape and motion, so the user understands status even in peripheral vision.

#### 15. Floating Preview Chips *(05 July 26)*

* **The Micro-Animation:** Hovering over or selecting inline compact chips spawns an elevated floating preview card that glides horizontally between chips as you move your cursor across a row, maintaining a single shared floating container that morphs its dimensions to match each chip's preview payload.
* **Why the UX is Great:** Instead of destroying and recreating tooltips (which causes visual flickering), a single persistent floating portal glides smoothly, making browsing links or tags effortless.

#### 16. Stateful Button *(11 June 26)*

* **The Micro-Animation:** A button that cycles through distinct operational states (e.g., Default → Loading → Saved) using vertical text carousel transitions (old text slides up and blurs out; new text slides up from below) while the button width animates via spring physics to hug the exact width of the new label.
* **Why the UX is Great:** Dynamic width hugging prevents awkward empty padding on short words ("Save") while accommodating longer status messages ("Saving changes...") seamlessly.

#### 17. Waterlemon Guide *(09 June 26)*

* **The Micro-Animation:** A playful, interactive onboarding/guide card featuring organic, juicy spring transitions and layered illustrations/steps that peel and slide with high-personality bounce curves.
* **Why the UX is Great:** Turns dry feature documentation into an engaging, memorable interactive story that users actually want to click through.

#### 18. License Key *(03 June 26)*

* **The Micro-Animation:** A cryptographic/product license key container where characters are obfuscated by default (dots or shimmer) and unmasked with a cascading left-to-right wave animation upon clicking "Reveal", paired with a one-click copy morph.
* **Why the UX is Great:** Balances security (preventing shoulder-surfing or accidental exposure on screen shares) with effortless copying.

#### 19. Copy Confirmation *(28 May 26)*

* **The Micro-Animation:** Clicking the copy icon triggers a micro-implosion of the clipboard SVG, which immediately springs out as a checkmark accompanied by a transient "Copied!" pill expansion or badge pulse.
* **Why the UX is Great:** Gives unmistakable, instant confirmation that the clipboard payload is ready, eliminating the habit of users pressing `Cmd+C` four times just to be sure.

#### 20. Split Actions *(12 May 26)*

* **The Micro-Animation:** A primary action button flanked or joined by a secondary trigger that physically separates into independent interactive zones when engaged, using smooth gap and border-radius interpolation.
* **Why the UX is Great:** Groups closely related actions (like "Send" and "Schedule Send") into a single visual unit until the user decides to diverge.

#### 21. Revolving Cards *(10 May 26)*

* **The Micro-Animation:** A 3D-perspective stack of cards that revolve along an elliptical z-axis trajectory. As the front card is dismissed or cycled, it arcs downward and scales back while the rear card scales up, brightens (removing depth dimming), and snaps to the foreground.
* **Why the UX is Great:** Uses z-space depth to store multiple rich cards inside the screen real estate of a single card.

#### 22. Chromatic Thinking *(04 May 26)*

* **The Micro-Animation:** An AI "thinking/reasoning" indicator that replaces boring spinning wheels with an iridescent, shifting chromatic gradient aura and fluidly morphing status typography ("Analyzing...", "Synthesizing...").
* **Why the UX is Great:** Masks AI latency by mesmerizing the user with organic light movement, making wait times feel shorter and more intelligent.

#### 23. Pop Stepper *(01 May 26)*

* **The Micro-Animation:** A numeric increment/decrement stepper (`-` `1` `+`) where clicking `+` or `-` causes the center number badge to physically "pop" upward or outward with an elastic scale pulse while rolling the digit.
* **Why the UX is Great:** Adds physical gratification to quantity adjustments (like cart items or ticket counts), confirming every single tap clearly.

#### 24. Status Progression *(22 April 26)*

* **The Micro-Animation:** A horizontal pipeline tracker where advancing a step sends a liquid-like fill along the connecting track, causing the destination node to swell and burst into an active icon.
* **Why the UX is Great:** Visualizes workflow momentum clearly, rewarding users as they complete stages of a multi-part process.

#### 25. Scale to Cue Focus *(11 April 26)*

* **The Micro-Animation:** Focusing on an active card or input field subtly scales up the active element (`scale(1.02)`) while simultaneously scaling down (`scale(0.97)`) and dimming/blurring background siblings.
* **Why the UX is Great:** Uses optical depth of field (like a camera lens focusing) to direct 100% of the user's cognitive attention to the current task.

#### 26. Expand Details *(06 April 26)*

* **The Micro-Animation:** A summary row that smoothly accordion-expands downward upon click, revealing nested key-value rows that stagger-fade in from top to bottom while the chevron rotates `180deg` with spring overshoot.
* **Why the UX is Great:** Keeps data tables and transaction logs scannable at a high level while keeping deep metadata one click away.

---

### Early 2026: Desktop Paradigms, Sidebars & AI Toolbars

#### 27. Fan Menu *(15 March 26)*

* **The Micro-Animation:** Clicking a floating action trigger fans out a series of action cards or circular buttons along a radial arc, each staggered by `15ms` with rotational spring physics like a hand of playing cards spreading open.
* **Why the UX is Great:** Places all revealed options at an equal radial distance from the user's thumb or cursor (optimizing Fitts's Law).

#### 28. Morphing Sidebar Controls *(22 February 26)*

* **The Micro-Animation:** Sidebar navigation items and collapse toggles that fluidly morph from full-width labeled rows into compact icon-only rail buttons when the sidebar collapses, without any abrupt layout snapping.
* **Why the UX is Great:** Preserves spatial memory—users still know where every tool lives even when the sidebar is minimized to maximize canvas space.

#### 29. Layered Progressive Disclosure *(21 February 26)*

* **The Micro-Animation:** Opening nested levels of settings stacks cards in z-space; the parent card recedes slightly backward, scales down to `0.94`, and dims, while the child layer slides up over it like a physical sheet of paper.
* **Why the UX is Great:** Users never feel "lost in sub-menus" because they can literally see the parent layer peeking out from behind the current card.

#### 30. MacOS Sidebar *(15 February 26)*

* **The Micro-Animation:** A desktop-class translucent sidebar featuring smooth section collapsing, spring-loaded active selection pills that glide vertically between items, and subtle hover highlights.
* **Why the UX is Great:** Brings native Apple desktop refinement to web applications, making navigation feel grounded and responsive.

#### 31. Split Button *(09 February 26)*

* **The Micro-Animation:** A primary action button paired with a chevron dropdown zone. Clicking the chevron morphs the button's right edge or expands an attached menu directly anchored to the button's geometry.
* **Why the UX is Great:** Exposes the default 90% use-case action for a single click while tucking power-user variations neatly beside it.

#### 32. Inline Action Confirmation *(26 January 26)*

* **The Micro-Animation:** Triggering a sensitive inline action slides an "Are you sure? [Yes] [No]" drawer directly over or inside the active row, pushing the initial label aside horizontally.
* **Why the UX is Great:** Zero eye travel required—the confirmation appears at the exact coordinates of the initial click.

#### 33. Morphing Button *(18 January 26)*

* **The Micro-Animation:** A foundational study in button geometry: a circular icon button that morphs into a wide rectangular input or confirmation panel, seamlessly interpolating `border-radius` from `50%` to `16px`.
* **Why the UX is Great:** Demonstrates how a single UI element can serve as both trigger and workspace.

#### 34. Invite Disclosure *(09 January 26)*

* **The Micro-Animation:** Clicking an "Invite" button expands the button itself into a compact card containing an email input field, role selector, and send button, complete with avatar stack animations when users are added.
* **Why the UX is Great:** Turns team collaboration into a frictionless 3-second inline task rather than routing to a settings page.

---

### Late 2025: Contextual AI, Toasts, Sliders & Micro-Feedback

#### 35. Quick Option Picker *(28 December 25)*

* **The Micro-Animation:** A compact pill that bursts open on press into a horizontal or grid array of quick-select options, snapping shut immediately once the cursor releases or selects an item.
* **Why the UX is Great:** Combines the hover/press-and-release speed of pie menus with clean modern pill aesthetics.

#### 36. Contextual AI Bar *(21 December 25)*

* **The Micro-Animation:** A floating command bar that appears on text selection or shortcut trigger, expanding smoothly from a compact sparkle icon into a prompt input with suggested AI action chips cascading underneath.
* **Why the UX is Great:** Keeps AI assistance invisible until needed, then brings the full power of an LLM directly to the selected content.

#### 37. Discrete Tabs *(07 December 25)*

* **The Micro-Animation:** A tab bar where switching tabs triggers both a sliding background pill indicator and a subtle directional scale/fade transition on the tab icons and labels.
* **Why the UX is Great:** Reinforces the spatial relationship between tabs—moving from Tab 1 to Tab 3 visually travels across the bar, orienting the user.

#### 38. Inline Toast *(29 November 25)*

* **The Micro-Animation:** Instead of spawning a toast notification in the distant corner of the screen, the notification blossoms directly out of the component or toolbar that triggered it, expanding upward or outward before folding back in.
* **Why the UX is Great:** Solves the classic UX problem on large monitors where users miss corner toasts because their eyes are focused on the center of the screen.

#### 39. Morphing Discovery Bar *(22 November 25)*

* **The Micro-Animation:** A bottom or floating search/navigation bar that dynamically changes its shape, icon set, and input width as the user switches between browsing, searching, and filtering modes.
* **Why the UX is Great:** Consolidates three separate toolbars into one adaptive surface that respects screen real estate.

#### 40. Frequency Selector *(18 November 25)*

* **The Micro-Animation:** A scheduling control (Daily, Weekly, Monthly, Custom) where changing the cadence smoothly animates supplementary sub-controls (like day-of-week pills or date pickers) in and out of the container height.
* **Why the UX is Great:** Makes complex recurring schedule logic (often a nightmare in calendar apps) feel effortless and self-explanatory.

#### 41. Labeled Progress Indicator *(09 November 25)*

* **The Micro-Animation:** A progress bar accompanied by a dynamic percentage badge and step label that physically tracks along the leading edge of the progress fill, tilting slightly as it accelerates and decelerates.
* **Why the UX is Great:** Fuses the visual bar and the text readout into a single focal point so the user's eye doesn't have to dart back and forth.

#### 42. Timed Undo Action *(07 November 25)*

* **The Micro-Animation:** Upon deleting or archiving an item, a circular SVG stroke ring or linear bar visibly counts down around the "Undo" button. If clicked before completion, the item springs back into its list slot.
* **Why the UX is Great:** Gives transparent visibility into *how much time* remains to reverse a mistake, reducing user anxiety.

#### 43. Inline Feedback Action *(01 November 25)*

* **The Micro-Animation:** Clicking a feedback trigger smoothly unfolds a micro-survey (emoji ratings or quick tags) inside the current card, collapsing into a warm "Thank you" badge upon selection.
* **Why the UX is Great:** Dramatically increases feedback completion rates by removing page reloads and external survey links.

#### 44. Adaptive Slider *(25 October 25)*

* **The Micro-Animation:** A slider bar that dynamically changes its thickness, color intensity, or internal icon states as the value crosses specific thresholds (e.g., low, medium, high/warning).
* **Why the UX is Great:** Conveys qualitative meaning alongside quantitative value—users *feel* when they are pushing a setting into high or maximum territory.

#### 45. Quick Switcher *(21 October 25)*

* **The Micro-Animation:** A keyboard-or-click-driven workspace/project switcher where the active selection highlight glides with zero-latency spring physics and previews update instantaneously alongside the list.
* **Why the UX is Great:** Built for high-velocity power users who navigate interfaces at the speed of thought.

#### 46. Quick Feedback *(17 October 25)*

* **The Micro-Animation:** A compact reaction/rating widget where hovering over sentiment icons causes them to scale up and animate with expressive micro-movements, morphing the container into an optional comment box on click.
* **Why the UX is Great:** Captures both rapid 1-click sentiment and optional qualitative context in a single fluid flow.

#### 47. Inline Overflow *(10 October 25)*

* **The Micro-Animation:** Clicking a `•••` (more) button doesn't open a floating dropdown menu; instead, the toolbar itself elongates horizontally, sliding the overflow items directly into the main row while transforming `•••` into a close `×` button.
* **Why the UX is Great:** Eliminates z-index clipping issues and awkward floating menus by keeping all actions on the exact same horizontal plane.

#### 48. Shuffle Pinned Item *(05 October 25)*

* **The Micro-Animation:** Cycling through pinned cards or items triggers a physical deck-shuffle animation—the top item arcs outto the side and tucks neatly behind the stack while the next item springs forward.
* **Why the UX is Great:** Turns static "pinned" announcements or notes into a compact, browsable carousel that occupies minimal vertical height.

#### 49. Show QR *(21 September 25)*

* **The Micro-Animation:** Clicking a small "QR Code" pill smoothly expands the button into a square card, scaling the QR matrix up from the center with a crisp focus-in transition and brightness lift.
* **Why the UX is Great:** Keeps ugly, high-contrast QR codes hidden until the exact second someone needs to scan their screen.

#### 50. Set Status *(14 September 25)*

* **The Micro-Animation:** A profile status setter where selecting an emoji and typing a status message dynamically updates the user badge in real time, with preset duration pills sliding in underneath.
* **Why the UX is Great:** Streamlines the Slack/Discord-style status workflow into a single, cohesive micro-card.

#### 51. Switch Disclosure *(12 September 25)*

* **The Micro-Animation:** Toggling a switch to `ON` immediately expands the parent container downward to reveal dependent sub-settings; toggling `OFF` smoothly folds them back up and shrinks the card height.
* **Why the UX is Great:** Enforces logical hierarchy—users never see disabled/grayed-out sub-options cluttering the screen when a master toggle is off.

---

### Mid 2025: Input Stacks, Voice Transcription & Table Controls

#### 52. Split To Edit *(31 August 25)*

* **The Micro-Animation:** Clicking a read-only data pill or value splits the single element into editable input segments (e.g., splitting a full name or date range into separate inputs) plus a save checkmark button.
* **Why the UX is Great:** Maintains clean, readable typography when viewing data, while providing structured inputs when editing.

#### 53. Step Pager *(27 August 25)*

* **The Micro-Animation:** A pagination and onboarding dot indicator where the active dot stretches like taffy (inchworm effect) to bridge the gap to the next dot before contracting its tail.
* **Why the UX is Great:** Adds organic continuity to step transitions, visually pulling the user forward.

#### 54. Event Reminders *(17 August 25)*

* **The Micro-Animation:** Adding or toggling reminders for an event triggers a bell icon ring animation (pendulum rotation) and smoothly inserts time-offset chips (`15m before`, `1h before`) into the card stack.
* **Why the UX is Great:** Reinforces time-based alerts with immediate auditory-inspired visual motion.

#### 55. Emoji Spree Choice Chips *(08 August 25)*

* **The Micro-Animation:** Selecting a choice chip triggers a playful burst or spring bounce of its embedded emoji while the chip border and fill transition to an active state with a slight scale lift.
* **Why the UX is Great:** Injects warmth and delight into preference selection screens or onboarding quizzes.

#### 56. Progressive Input Stack *(31 July 25)*

* **The Micro-Animation:** Completing one input field and pressing Enter causes the completed field to compress and stack neatly at the top as a compact summary chip while the next input field slides up into the primary focus zone.
* **Why the UX is Great:** Combines the focus of one-question-at-a-time Typeform flows with the full visibility of a traditional form.

#### 57. Carousel Navigator *(20 July 25)*

* **The Micro-Animation:** A thumbnail/dot scrubber for media carousels that expands on hover/drag, magnifying the active index while smoothly gliding the main viewport content in sync.
* **Why the UX is Great:** Lets users jump across large galleries rapidly without clicking a "Next" arrow ten times.

#### 58. Step Indicator *(17 July 25)*

* **The Micro-Animation:** Numbers inside step circles morph into checkmarks with a circular fill sweep as each stage completes, connected by an animated progress line.
* **Why the UX is Great:** Provides crystal-clear orientation in checkout or setup wizards.

#### 59. Draw Signature *(14 July 25)*

* **The Micro-Animation:** An inline signature pad that unfolds from a "Sign Document" button, featuring pressure-simulated smooth ink rendering, a clear-canvas shake/fade reset, and a morphing "Apply Signature" confirmation that stamps the signature onto the line.
* **Why the UX is Great:** Makes digital signing feel authentic and personal rather than a clunky pop-up iframe.

#### 60. Edit Badge *(03 July 25)*

* **The Micro-Animation:** Clicking a status or category badge transforms its static text label into an active cursor-ready text input or color-swatch selector directly inside the badge's pill boundary.
* **Why the UX is Great:** Allows instant renaming and re-coloring of tags without opening a separate "Manage Tags" modal.

#### 61. Pin Item *(12 June 25)*

* **The Micro-Animation:** Clicking the pin icon rotates the thumbtack `45deg` and drives it downward with a springy "poke" animation, while the item card detaches and smoothly glides to the pinned top section of the list.
* **Why the UX is Great:** Literally illustrates the metaphor of pinning something to the top of a board.

#### 62. Transcribe Voice Message *(04 June 25)*

* **The Micro-Animation:** Clicking a "Transcribe" button next to an audio waveform morphs the waveform bars into shimmering text skeleton lines, which then resolve word-by-word into a readable paragraph expanding below the audio player.
* **Why the UX is Great:** Visually links the audio waves to the resulting text, making AI transcription feel magical and cohesive.

#### 63. Quick Paste *(30 May 25)*

* **The Micro-Animation:** Detecting clipboard content surfaces a floating or inline "Paste from clipboard" chip that, when clicked, physically flies the text string from the chip into the target input field before dissolving.
* **Why the UX is Great:** Saves mobile and desktop users from long-pressing or keyboard shortcuts when entering OTP codes or URLs.

#### 64. Run Action *(22 May 25)*

* **The Micro-Animation:** A workflow/command trigger button that shows live execution steps scrolling inside the button or adjacent pill as a script or automation runs, ending with a green completion pulse.
* **Why the UX is Great:** Gives developer-tool transparency inside a clean consumer-grade button.

#### 65. Journal Navigation *(13 May 25)*

* **The Micro-Animation:** A date-based journal scrubber where flipping through days or months triggers a tactile page-turn or vertical date-wheel cascade with soft blur transitions between entries.
* **Why the UX is Great:** Evokes the calm, reflective feeling of flipping through a physical paper notebook.

#### 66. Predictive Text *(05 May 25)*

* **The Micro-Animation:** As the user types, ghosted inline autocomplete suggestions fade in smoothly ahead of the caret; pressing `Tab` sends a subtle shimmer wave across the suggested words as they solidify into black ink.
* **Why the UX is Great:** Distinguishes clearly between what the user has typed and what the AI is suggesting, with satisfying confirmation on acceptance.

#### 67. Tree Menu *(28 April 25)*

* **The Micro-Animation:** A hierarchical folder/file tree with curved SVG connector lines (`├`, `╰`) that dynamically draw and retract as parent folders expand and collapse with spring height transitions.
* **Why the UX is Great:** Solves the visual confusion of deep nesting by clearly tracing parent-child relationships with animated guide lines.

#### 68. Inline Table Control *(19 April 25)*

* **The Micro-Animation:** Hovering or selecting rows in a data table smoothly surfaces floating inline action pills (Edit, Duplicate, Delete) and cell-level steppers/dropdowns without shifting column widths.
* **Why the UX is Great:** Prevents the dreaded "table column jump" while giving spreadsheet-level editing speed.

#### 69. Extended Toolbar *(11 April 25)*

* **The Micro-Animation:** A floating formatting or canvas toolbar that dynamically unfolds a second tier or side wing of advanced tools when a tool category (like Typography or Shapes) is selected.
* **Why the UX is Great:** Keeps the canvas unobstructed by default while scaling up to full creative suite complexity on demand.

#### 70. Select AI Agent *(07 April 25)*

* **The Micro-Animation:** Clicking the active AI model/agent pill expands a rich selector card showcasing agent avatars, specialty badges, and speed/intelligence indicators, morphing the prompt bar's accent glow to match the chosen agent.
* **Why the UX is Great:** Gives distinct visual identity to different AI personas so the user always knows which model they are talking to.

---

### Early 2025: Disclosures, Pickers, Currencies & Maps

#### 71. Filter Disclosure *(29 March 25)*

* **The Micro-Animation:** Clicking "Filter" expands a multi-facet filter bar where selecting criteria adds animated active filter pills into the main bar, updating the badge count with a rolling number transition.
* **Why the UX is Great:** Lets users build complex filter queries visually while seeing active constraints at a glance.

#### 72. Voice Note *(20 March 25)*

* **The Micro-Animation:** Holding or tapping the mic button expands a live recording capsule with a ticking timer, real-time amplitude bars, and slide-to-cancel / lock-recording micro-targets.
* **Why the UX is Great:** Mirrors the gold-standard messaging UX (like WhatsApp/iMessage) with elevated web polish and unmistakable recording state cues.

#### 73. Reveal and Copy *(11 March 25)*

* **The Micro-Animation:** A sensitive credential pill (like an API key or password) covered in an animated particle/dot mask. Clicking reveals the characters with a left-to-right optical wipe while simultaneously morphing the action icon into a copy trigger.
* **Why the UX is Great:** Combines privacy protection and clipboard utility into a tight two-step micro-flow.

#### 74. Save Toggle *(28 January 25)*

* **The Micro-Animation:** A bookmark/save button that, upon click, fills the bookmark ribbon with a vertical liquid rise, bounces upward with spring physics, and optionally exposes a "Saved to Collection ▾" quick-picker.
* **Why the UX is Great:** Rewards content curation with a tactile animation while allowing immediate folder organization.

#### 75. Feature Tour *(19 January 25)*

* **The Micro-Animation:** A multi-step onboarding card that smoothly morphs its height, illustration viewport, and progress dots as the user clicks "Next", using directional horizontal crossfades for the content and spring resizing for the outer shell.
* **Why the UX is Great:** Keeps the user anchored in a single morphing frame rather than flashing jarring new modal windows for each step of a tour.

#### 76. Slot Picker *(12 January 25)*

* **The Micro-Animation:** Selecting a date smoothly reveals available time-slot pills in a staggered grid cascade; clicking a time slot morphs the slot itself or expands a confirmation bar at the bottom of the card.
* **Why the UX is Great:** Removes the friction of calendar booking by showing date and time availability in one unified, responsive card.

#### 77. Swap Currency *(01 January 25)*

* **The Micro-Animation:** Clicking the central swap arrow button (`⇅`) between two currency cards rotates the icon `180deg` while physically swapping the top and bottom currency rows in z-space (one passes slightly over the other) and recalculating the exchange rate with rolling digits.
* **Why the UX is Great:** Visually proves that the "From" and "To" currencies have traded places, preventing expensive user confusion in fintech apps.

---

### Late 2024: Scroll Islands, Continuous Tabs, Calculators & Sliders

#### 78. Schedule Button *(24 December 24)*

* **The Micro-Animation:** Clicking "Schedule" next to a primary publish/send button morphs the button cluster into a compact date-and-time selector popover anchored seamlessly to the button's base.
* **Why the UX is Great:** Turns scheduling from a heavy modal dialog into a lightweight extension of the primary CTA.

#### 79. View on Map *(18 December 24)*

* **The Micro-Animation:** Clicking an address pill or "View on Map" badge smoothly expands the pill into an interactive mini-map card with an animated location pin dropping from above (`translateY(-20px)` to `0` with bounce) and a soft radar pulse ring.
* **Why the UX is Great:** Lets users verify location geography inline without kicking them out to a separate Google Maps tab.

#### 80. Collection Grid Disclosure *(11 December 24)*

* **The Micro-Animation:** A folder or collection card featuring a $2 \times 2$ mini-thumbnail grid preview. Clicking the card smoothly fans and scales those exact four thumbnails outward into a full browsable grid while fading in the remaining items.
* **Why the UX is Great:** Classic shared-element continuity—the preview thumbnails literally become the gallery items.

#### 81. Floating Button Disclosure *(29 November 24)*

* **The Micro-Animation:** A bottom-right Floating Action Button (`+`) that morphs its circular bounds into a full multi-option creation menu or input card while rotating the `+` by `45deg` into a close `×` button pinned to the corner.
* **Why the UX is Great:** Keeps the close button in the exact spot where the open button was clicked, allowing rapid toggle-off via muscle memory.

#### 82. Card Splitting Accordion *(25 November 24)*

* **The Micro-Animation:** Instead of simply expanding an accordion row inside a single list container, clicking an item physically *splits* the parent list card into two separate rounded cards—creating an actual background gap above and below the expanded item.
* **Why the UX is Great:** Isolates the active item visually by giving it its own independent card boundaries and drop shadow, eliminating visual clutter from neighboring rows.

#### 83. Scroll Island ↗ *(26 October 24)*

* **The Micro-Animation:** Inspired by Apple's Dynamic Island, a floating top pill displays the current article section title and a circular reading-progress ring (plus numeric percentage). Clicking the island smoothly expands it into a full interactive Table of Contents index, dimming and blurring the background article while letting you jump to any heading.
* **Why the UX is Great:** Solves long-form reading orientation on both mobile and desktop—giving constant progress feedback in a tiny footprint and instant chapter navigation on tap.

#### 84. Continuous Tabs ↗ *(22 October 24)*

* **The Micro-Animation:** A tab bar where the active indicator pill uses SVG gooey/metaball physics or fluid width-stretching interpolation as it travels between tabs, paired with smooth color inversion on the text label as the pill passes underneath it (via `mix-blend-mode` or clipped twin layers).
* **Why the UX is Great:** Makes tab switching feel like a continuous physical slider rather than discrete digital jumps.

#### 85. Dropdown Disclosure *(14 October 24)*

* **The Micro-Animation:** Clicking a trigger button morphs the button's own border and background downward into the dropdown list container rather than spawning a detached box below it.
* **Why the UX is Great:** Eliminates the visual gap between trigger and menu, making the component feel unified and structurally solid.

#### 86. Returns Calculator Snippet *(30 September 24)*

* **The Micro-Animation:** An investment/SIP calculator card where dragging the contribution or timeframe sliders updates the projected return numerals with high-speed odometer rolling digits and dynamically flexes the visual return bar/chart in real time.
* **Why the UX is Great:** Turns financial math into tactile play—users immediately see the compounding power of small slider adjustments.

#### 87. Transaction List *(26 September 24)*

* **The Micro-Animation:** Clicking a transaction row in a banking list expands the row into a detailed receipt view (showing merchant category, timestamp, card used, and split/note options) while subtly pushing other transactions apart.
* **Why the UX is Great:** Gives full receipt transparency without leaving the main account feed.

#### 88. Calendar Widget *(24 September 24)*

* **The Micro-Animation:** A compact square calendar widget where clicking a date smoothly slides the calendar grid aside or compresses it into a header while unfolding the day's schedule agenda underneath.
* **Why the UX is Great:** Balances month-level spatial awareness with day-level hourly detail inside a constrained widget footprint.

#### 89. Send Money *(21 September 24)*

* **The Micro-Animation:** A peer-to-peer payment flow where entering an amount scales the numerals dynamically to fit, and clicking "Send" collapses the keypad into a morphing verification/success card with the recipient's avatar pulsing at the center.
* **Why the UX is Great:** Builds high emotional confidence during financial transactions through deliberate, reassuring motion stages.

#### 90. Share Sheet *(20 September 24)*

* **The Micro-Animation:** Clicking "Share" morphs the button into a multi-row share card featuring quick-copy link feedback, social app icons that lift on hover, and inline permission toggles.
* **Why the UX is Great:** Replaces generic OS share sheets with a branded, context-aware sharing hub.

#### 91. Diary Empty State *(17 September 24)*

* **The Micro-Animation:** An empty journal view featuring an inviting, subtly animated illustration/card stack that, when clicked to "Write First Entry", smoothly unfolds from the empty state artwork directly into the active text editor.
* **Why the UX is Great:** Bridges the gap between "nothing here yet" and active creation, removing writer's block friction.

#### 92. Fluid Tabs *(14 September 24)*

* **The Micro-Animation:** Tabs that react to cursor proximity and click velocity with elastic pill stretching—when switching between distant tabs, the active indicator elongates mid-flight and snaps back to standard pill width upon arrival.
* **Why the UX is Great:** Injects classic Disney animation principles (*squash and stretch*) into everyday UI navigation.

#### 93. Knob Slider *(11 September 24)*

* **The Micro-Animation:** A rotary dial/knob control inspired by high-end audio hardware (like Teenage Engineering), featuring precision tick marks around the perimeter that illuminate sequentially as you drag radially, with a crisp numeric readout in the center.
* **Why the UX is Great:** Saves horizontal space compared to linear sliders while offering rich, tactile angular manipulation.

#### 94. Create New Disclosure *(09 September 24)*

* **The Micro-Animation:** A `+ Create New` button that expands in-place into a grid or list of creation templates (Document, Folder, Project, Task), with each icon subtly animating on hover.
* **Why the UX is Great:** Keeps workspace headers clean with a single CTA while supporting multi-object creation workflows.

#### 95. Flower Menu *(02 September 24)*

* **The Micro-Animation:** Clicking a central circular button causes 5–6 circular sub-action buttons to bloom outward radially like flower petals, rotating slightly as they reach full extension.
* **Why the UX is Great:** A visually striking radial menu pattern ideal for creative canvas tools or floating mobile shortcuts.

---

### Mid 2024: Widgets, Scrubbers, Carousels & Foundational Micro-Interactions

#### 96. Run Widget *(29 August 24)*

* **The Micro-Animation:** A fitness activity widget displaying pace, distance, and an animated route polyline that traces itself across the card, expanding on tap to reveal lap splits and heart-rate zones.
* **Why the UX is Great:** Condenses complex telemetry data into an energetic, glanceable card.

#### 97. Fund Widget *(26 August 24)*

* **The Micro-Animation:** A portfolio/crowdfunding progress widget where hovering or toggling time horizons smoothly morphs the sparkline/bar visual and rolls the currency totals.
* **Why the UX is Great:** Makes financial tracking feel dynamic and responsive to user exploration.

#### 98. Waveform Scrub *(21 August 24)*

* **The Micro-Animation:** Dragging across an audio waveform magnifies the vertical amplitude bars directly beneath the cursor like a dock magnification wave, while smoothly updating the timestamp pill and audio playhead.
* **Why the UX is Great:** Makes scrubbing through podcasts or voice notes on small touchscreens accurate and visually rewarding.

#### 99. Weight Widget *(17 August 24)*

* **The Micro-Animation:** A health tracker widget featuring an inertia-driven mechanical scale dial; dragging the dial updates the weight readout to the tenth of a kilogram/pound with subtle tick-by-tick visual resistance.
* **Why the UX is Great:** Turns daily health logging from a chore into a satisfying 2-second tactile habit.

#### 100. List Stack *(12 August 24)*

* **The Micro-Animation:** A collapsed stack of notification or task cards where only the top card is fully visible and lower cards peek out underneath with progressive scale (`0.95`, `0.90`) and opacity reduction. Clicking fans the entire stack vertically into a scrollable list.
* **Why the UX is Great:** Tames notification overload by collapsing 5+ items into the vertical footprint of 1.2 cards until the user is ready to triage them.

#### 101. Scrub Slider *(08 August 24)*

* **The Micro-Animation:** A precision media or parameter scrubber with dense tick marks that shift with parallax momentum as you drag, dynamically adjusting scrub sensitivity based on drag speed.
* **Why the UX is Great:** Solves the tension between fast coarse scrubbing and slow frame-accurate adjustments.

#### 102. Pricing Widget *(05 August 24)*

* **The Micro-Animation:** A SaaS pricing card where toggling between Monthly and Annual billing triggers a spring-loaded sliding toggle pill, an animated "Save 20%" badge bounce, and an odometer digit roll on the price tag (`$29` → `$24`).
* **Why the UX is Great:** Highlights the exact dollar savings visually through motion, drawing the user's eye directly to the value proposition.

#### 103. Switch Mode *(31 July 24)*

* **The Micro-Animation:** A Light/Dark/System theme switcher where clicking morphs the sun rays into a crescent moon (and vice versa) with rotational spring physics while smoothly crossfading the card's surface palette.
* **Why the UX is Great:** Turns a utilitarian preference toggle into a signature moment of brand craft.

#### 104. Dock *(28 July 24)*

* **The Micro-Animation:** A macOS-inspired application dock featuring cosine-based proximity magnification—moving the cursor across an icon smoothly scales that icon and its immediate neighbors along a continuous bell curve, while clicking bounces the icon vertically.
* **Why the UX is Great:** Allows dozens of tool icons to fit in a compact bar while making the target icon huge and easy to click when approached.

#### 105. Radial Carousel *(26 July 24)*

* **The Micro-Animation:** Items arranged along a curved wheel/dial arc; swiping or clicking rotates the wheel with rotational inertia, snapping each item into the top/center focal slot with a subtle scale boost.
* **Why the UX is Great:** Aligns naturally with the curved arc of a human thumb holding a smartphone one-handed.

#### 106. Fractional Picker *(24 July 24)*

* **The Micro-Animation:** A fine-tuned numeric picker that lets users select whole numbers and fractional increments (`0.25`, `0.5`, `0.75`) via a hybrid wheel/tick slider that snaps crisply to each fractional detent.
* **Why the UX is Great:** Eliminates keyboard typing for measurements, recipes, or financial shares.

#### 107. Carousel Slider *(19 July 24)*

* **The Micro-Animation:** A card carousel where dragging horizontally applies subtle 3D perspective tilt and scale compression to outgoing cards while expanding the incoming card into full focus.
* **Why the UX is Great:** Gives tangible weight and momentum to horizontal content browsing.

#### 108. Editable Chip *(13 July 24)*

* **The Micro-Animation:** Clicking an inline filter or tag chip expands its width smoothly to accommodate an active text cursor and a delete/confirm action without breaking the surrounding flex-wrap layout.
* **Why the UX is Great:** Lets users fix a typo in a tag or search token instead of deleting the whole chip and typing it over again.

#### 109. Wiggling Cards *(07 July 24)*

* **The Micro-Animation:** Long-pressing or entering edit mode causes a grid of cards to enter an asynchronous, organic jiggle/wiggle oscillation (with randomized phase offsets so no two cards move identically), exposing `−` delete badges and drag-to-reorder physics.
* **Why the UX is Great:** Immediately signals that the UI has shifted from "consumption mode" to "customization/reordering mode."

#### 110. Pagination *(28 June 24)*

* **The Micro-Animation:** Clicking page numbers or arrows slides the active selection box smoothly across the number track while truncating distant page numbers (`...`) with fluid width and opacity transitions.
* **Why the UX is Great:** Keeps multi-page navigation stable so the Next/Previous buttons never jump around under the user's cursor.

#### 111. Range Selection Slider *(26 June 24)*

* **The Micro-Animation:** A dual-thumb min/max price or value slider featuring an interactive histogram or fill bar between the thumbs; dragging either thumb updates floating value pills that intelligently merge or avoid colliding when thumbs get close together.
* **Why the UX is Great:** Solves the classic dual-slider bug where min and max tooltips overlap and become unreadable when narrow ranges are selected.

#### 112. Stepper *(21 June 24)*

* **The Micro-Animation:** A clean numeric stepper where holding or tapping `+`/`−` pulls the pill slightly in the direction of the click (elastic tug) while cycling the counter digits vertically.
* **Why the UX is Great:** Gives directional physical feedback even on non-haptic desktop screens.

#### 113. Task Widget Disclosure *(11 June 24)*

* **The Micro-Animation:** Checking off a task in a compact widget triggers a satisfying strikethrough sweep and checkbox bounce, while clicking the widget header unfolds the full checklist and progress bar.
* **Why the UX is Great:** Makes completing to-do items genuinely addictive through micro-rewards.

#### 114. Card Swipe *(07 June 24)*

* **The Micro-Animation:** Tinder/deck-style gesture physics where dragging a card left or right rotates it around a bottom pivot point, progressively revealing contextual action stamps (Approve/Reject or Archive/Keep) before flinging off-screen Along the release velocity vector.
* **Why the UX is Great:** Turns high-volume triage (emails, expenses, flashcards) into a fast, intuitive gesture loop.

#### 115. Voice Chat Disclosure *(04 June 24)*

* **The Micro-Animation:** Clicking a "Join Voice" pill expands the button into a live audio room controller showing connected participant avatars with speaking indicator rings, a mute toggle, and disconnect action.
* **Why the UX is Great:** Embeds lightweight synchronous voice collaboration directly into project tools without launching a heavy video call screen.

#### 116. Add Cash Disclosure *(01 June 24)*

* **The Micro-Animation:** Clicking "+ Add Cash" on a wallet balance card smoothly unfolds quick-amount preset pills (`+$10`, `+$50`, `+$100`) and a payment source selector directly inside the balance card's bottom half.
* **Why the UX is Great:** Reduces wallet top-ups to two taps without leaving the dashboard.

#### 117. Inline Edit *(18 May 24)*

* **The Micro-Animation:** Hovering over a text field reveals a subtle pencil cue; clicking smoothly morphs the static text container into an active input box with a soft focus ring and inline Save (`✓`) / Cancel (`✕`) micro-buttons sliding in from the right.
* **Why the UX is Great:** Eliminates full-form "Edit Mode" pages for simple profile or title updates.

#### 118. Inline Disclosure Delete *(10 May 24)*

* **The Micro-Animation:** An early exploration of safe deletion: clicking the trash icon slides a crimson confirmation curtain across the row or button, requiring a deliberate second click to finalize removal.
* **Why the UX is Great:** Prevents accidental destructive clicks while keeping the interaction fast and modal-free.

#### 119. Feedback *(06 May 24)*

* **The Micro-Animation:** A floating "Feedback" pill that morphs smoothly into a compact textarea card with emoji sentiment selectors, collapsing into a celebratory confirmation state upon submission.
* **Why the UX is Great:** Always accessible, never intrusive, and takes less than 5 seconds to complete.

#### 120. Swap Form *(04 May 24)*

* **The Micro-Animation:** A toggleable authentication or conversion form (e.g., Sign In ↔ Sign Up, or Buy ↔ Sell) where switching modes smoothly animates the extra input fields in and out while cross-fading the primary CTA label.
* **Why the UX is Great:** Maintains visual anchor points (like the email field and submit button) while gracefully adapting the form height.

#### 121. Tags *(30 April 24)*

* **The Micro-Animation:** An interactive tag input and selector where adding a tag scales the new pill in from `0.8` with a spring bounce, and removing a tag collapses its width and margin to zero so remaining tags glide together smoothly.
* **Why the UX is Great:** Eliminates harsh layout jumps when adding or deleting multiple metadata tags.

#### 122. Dialog Stack *(28 April 24)*

* **The Micro-Animation:** Triggering a secondary modal or confirmation from inside an existing dialog pushes the first dialog backward in 3D space (scaling down and darkening slightly) while stacking the new dialog cleanly on top. Dismissing the top card pulls the original card back to `scale(1)`.
* **Why the UX is Great:** Visually preserves the user's mental stack so they know exactly what they will return to when they close the current prompt.

#### 123. Activities *(14 April 24)*

* **The Micro-Animation:** A live activity feed widget where new events slide in from the top, pushing older items down with staggered spring physics, and clicking an activity expands its payload inline.
* **Why the UX is Great:** Makes system logs and social notifications feel alive and chronological without jarring screen refreshes.

#### 124. Continuous Pagination *(05 April 24)*

* **The Micro-Animation:** The foundational entry in the collection: a pagination control where the active indicator morphs continuously across page indices with fluid pill stretching and subtle number scale transitions.
* **Why the UX is Great:** Sets the tone for the entire collection—proving that even the humblest, most overlooked UI component on the web can feel extraordinary when treated with physics, optical care, and motion continuity.

---

For a quick visual roundup of how this showcase fits alongside other top motion design resources, check out this short video on [award winning design inspirations tools](https://www.youtube.com/shorts/vHrWIrl0ThQ), which highlights Khagwal's interactions page as an essential reference for UI/UX designers.