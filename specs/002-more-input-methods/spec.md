# Feature Specification: Enhanced Question Input Methods

**Feature Branch**: `002-more-input-methods`
**Created**: 2025-10-08
**Status**: Draft
**Input**: User description: "More input methods. Add support for more types of questions: - Sliders - scale between two values (e.g. 1-10, with each named) - Modify yes/no method to have a tinder-like experience (swipe left or right, + buttons) - Card sorting game / 'would you rather' - sort cards based on preferences top to bottom - Energy/mood mapping - show a graph where the user can select the energy/mood/feeling at a given time/phase of a project - Emoji reactions - react to a statement with an emoji - RPG-like character sheets (with options for multiple stats per sheet) Add support for such questions. Ensure that the user experience when providing answers to those questions is immersive and engaging. Make sure to use the new input methods in a way that is intuitive and easy to use. Each category should be shown on a separate page. There are no time limits"

## Clarifications

### Session 2025-10-08

- Q: Can users proceed to the next question without ranking all cards, or must they rank every card? → A: Users can proceed with partial ranking (unranked cards are saved as "not ranked" or given default low priority)
- Q: Can users submit a character sheet with unspent points remaining? → A: Users must allocate all points before submitting (system blocks submission until budget is fully spent)
- Q: Can users submit an energy map with some time periods left empty (no energy level set)? → A: Users can submit with some periods empty (empty periods saved as null/no data)
- Q: When a user navigates back to a previous question, what happens to their original response? → A: Original response is pre-filled and editable; changes overwrite the original
- Q: When are user responses saved to persistent storage? → A: When user navigates to next/previous question (save on page transition)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scale-based Preference Collection (Priority: P1)

Users need to express nuanced opinions on a spectrum rather than binary choices, allowing for more accurate self-reflection and profile building.

**Why this priority**: Slider inputs are the foundation for quantitative preference collection and are the simplest to implement while providing immediate value for gathering dimensional feedback.

**Independent Test**: Can be fully tested by creating a question with a labeled scale (e.g., "1=Introvert, 10=Extrovert"), allowing the user to select a value, and verifying the response is saved with proper labeling.

**Acceptance Scenarios**:

1. **Given** a user is answering a scaled question, **When** they interact with the slider, **Then** they see real-time visual feedback showing the current value and its label
2. **Given** a slider has named endpoints (e.g., "Low Energy" to "High Energy"), **When** the user moves the slider, **Then** the current position displays both the numeric value and contextual label
3. **Given** a user has selected a slider value, **When** they proceed to the next question, **Then** their response is saved with both numeric value and semantic label

---

### User Story 2 - Engaging Binary Decision Making (Priority: P2)

Users should experience fun and intuitive yes/no decisions through swipe gestures and visual feedback, making the process feel more like a game than a questionnaire.

**Why this priority**: Enhances engagement for existing binary questions and provides immediate visual gratification, building on the existing yes/no framework.

**Independent Test**: Can be fully tested by presenting a yes/no question, enabling swipe left/right gestures, showing visual feedback (animations, button highlights), and verifying the choice is recorded.

**Acceptance Scenarios**:

1. **Given** a yes/no question is displayed, **When** the user swipes right or taps the right button, **Then** a positive animation plays and "yes" is recorded
2. **Given** a yes/no question is displayed, **When** the user swipes left or taps the left button, **Then** a negative animation plays and "no" is recorded
3. **Given** the user is mid-swipe, **When** they release before reaching the threshold, **Then** the card returns to center without recording a response
4. **Given** the user completes a swipe gesture, **When** the animation finishes, **Then** the next question automatically appears

---

### User Story 3 - Priority-based Card Sorting (Priority: P2)

Users need to rank multiple options by importance to reveal their true priorities, providing deeper insight than individual ratings.

**Why this priority**: Enables comparative decision-making which is often more intuitive than absolute ratings, and is critical for understanding relative preferences.

**Independent Test**: Can be fully tested by presenting multiple cards (e.g., 5 work values), allowing drag-and-drop reordering from most to least important, and verifying the final ranked order is saved.

**Acceptance Scenarios**:

1. **Given** a set of cards to sort, **When** the user drags a card, **Then** other cards shift to show available drop positions
2. **Given** cards are being sorted, **When** the user drops a card in a new position, **Then** the ranking updates with visual feedback showing the new order
3. **Given** cards have been sorted (fully or partially), **When** the user proceeds, **Then** the complete ranking is saved with ranked cards in order and unranked cards marked as "not ranked"
4. **Given** multiple cards at different positions, **When** the user reviews their choices, **Then** each card shows its rank number clearly (ranked cards) or "not ranked" indicator (unranked cards)

---

### User Story 4 - Temporal Energy/Mood Visualization (Priority: P3)

Users want to map their energy, mood, or engagement levels across different phases or times, providing a visual representation of their patterns.

**Why this priority**: Provides unique temporal insight that other input methods cannot capture, but is more complex to implement and analyze.

**Independent Test**: Can be fully tested by displaying a timeline/graph interface (e.g., "your typical work week"), allowing users to plot energy levels at different points, and saving the complete temporal pattern.

**Acceptance Scenarios**:

1. **Given** an energy mapping interface with time periods, **When** the user clicks/taps a time point, **Then** they can set the energy level for that period
2. **Given** the user is mapping energy across a timeline, **When** they set multiple points, **Then** a line/curve connects the points showing the pattern
3. **Given** the user has completed their energy map (with some or all periods set), **When** they submit, **Then** all temporal data points are saved with timestamps/period labels, and empty periods are saved as null/no data
4. **Given** energy levels need to be adjusted, **When** the user modifies a previously set point, **Then** the visualization updates smoothly

---

### User Story 5 - Emoji-based Quick Reactions (Priority: P3)

Users can express immediate emotional or intuitive responses to statements through emoji selection, providing quick sentiment capture.

**Why this priority**: Adds emotional dimension to data collection and is quick to complete, but provides less structured data than other methods.

**Independent Test**: Can be fully tested by showing a statement with emoji options (e.g., "How do you feel about meetings?" with 😍😊😐😕😤), capturing the selected emoji, and saving the response.

**Acceptance Scenarios**:

1. **Given** a statement with emoji reaction options, **When** the user taps an emoji, **Then** it animates and is highlighted as selected
2. **Given** multiple statements requiring emoji reactions, **When** the user selects an emoji, **Then** the response is saved and the next statement appears
3. **Given** emoji options are displayed, **When** the user hovers/taps an emoji, **Then** it shows a label or enlarges to preview the selection
4. **Given** the user has selected an emoji, **When** they want to change it, **Then** they can tap a different emoji to update their response

---

### User Story 6 - RPG Character Sheet Stats (Priority: P3)

Users can distribute points across multiple attributes to build a "character sheet" representing their work style, skills, or preferences through a familiar gaming metaphor.

**Why this priority**: Provides a fun, engaging way to capture multi-dimensional profiles, but requires more complex interactions and is most valuable when combined with other data.

**Independent Test**: Can be fully tested by presenting a character sheet with multiple stats (e.g., "Leadership", "Technical", "Creative"), allowing point allocation with constraints (e.g., 20 total points), and saving the complete stat distribution.

**Acceptance Scenarios**:

1. **Given** a character sheet with multiple stats and a point budget, **When** the user allocates points to a stat, **Then** the remaining budget updates in real-time
2. **Given** the user is distributing points, **When** they try to exceed the budget, **Then** the system prevents over-allocation and shows a warning
3. **Given** stats have minimum/maximum values, **When** the user adjusts a stat, **Then** constraints are enforced visually
4. **Given** the user has not allocated all points, **When** they try to submit or proceed, **Then** the system blocks submission and indicates remaining points must be allocated
5. **Given** multiple character sheets for different categories, **When** the user completes one sheet with all points allocated, **Then** their allocation is saved before proceeding to the next
6. **Given** the user has allocated all points, **When** they submit, **Then** the complete stat distribution is saved with all values

---

### Edge Cases

- What happens when a user starts a swipe gesture but rotates their device mid-gesture?
- **Incomplete card sorting**: Users can proceed with partial ranking; unranked cards are saved as "not ranked" or given default low priority
- What happens when a user tries to set two energy points at the exact same time on the timeline?
- **Character sheet incomplete allocation**: System blocks submission when points are not fully allocated and displays a message indicating remaining points must be spent
- What happens when emoji options don't render on older devices/browsers?
- How does touch interaction work when the user has accessibility settings enabled (e.g., reduced motion)?
- **Navigating back to previous question**: Original response is pre-filled and editable; any changes overwrite the original when navigating away
- How does the system handle very long card labels that don't fit in the UI?
- What happens when network connectivity is lost during an animated transition?
- **Incomplete energy map**: Users can submit energy maps with empty time periods; empty periods are saved as null/no data

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support slider input with configurable minimum and maximum values (numeric range 1-100)
- **FR-002**: System MUST display semantic labels for slider endpoints and intermediate values
- **FR-003**: System MUST provide real-time visual feedback as the user adjusts a slider
- **FR-004**: System MUST support both swipe gestures and button taps for yes/no questions
- **FR-005**: System MUST play distinct animations for positive (yes/right) and negative (no/left) responses
- **FR-006**: System MUST implement swipe threshold detection to determine when a gesture completes vs. cancels
- **FR-007**: System MUST support drag-and-drop reordering of cards with visual drop zone indicators
- **FR-008**: System MUST preserve and save the complete ranking order of sorted cards, including both ranked cards (with their positions) and unranked cards (marked as "not ranked")
- **FR-009**: System MUST display rank numbers on sorted cards and "not ranked" indicator on unranked cards
- **FR-010**: System MUST provide a timeline or phase-based interface for energy/mood mapping
- **FR-011**: System MUST allow users to plot multiple data points on the energy/mood graph (partial coverage allowed)
- **FR-012**: System MUST connect plotted points with a line or curve to visualize patterns
- **FR-013**: System MUST save temporal data with associated time periods or phase labels, including empty periods as null/no data
- **FR-014**: System MUST display a set of selectable emoji reactions for statements
- **FR-015**: System MUST provide visual feedback when an emoji is selected (animation, highlight)
- **FR-016**: System MUST save the selected emoji value with semantic meaning preserved
- **FR-017**: System MUST implement character sheet interface with multiple named stats/attributes
- **FR-018**: System MUST enforce point budget constraints during character sheet allocation and block submission until all points are allocated
- **FR-019**: System MUST update remaining budget in real-time as points are allocated
- **FR-020**: System MUST prevent point over-allocation on character sheets and display warning when unallocated points remain during submission attempt
- **FR-021**: System MUST save complete stat distributions from character sheets only when all points have been allocated
- **FR-022**: System MUST display each question type on a separate page
- **FR-023**: System MUST support navigation between question pages (next/previous)
- **FR-024**: System MUST preserve user responses when navigating between pages and persist responses on page transition
- **FR-025**: System MUST associate saved responses with the correct question and input method type
- **FR-026**: System MUST handle touch and mouse input for all interaction types
- **FR-027**: System MUST provide visual state feedback for incomplete vs. complete responses
- **FR-028**: System MUST support configurable emoji sets per question (minimum 3, maximum 10 emojis)
- **FR-029**: System MUST support configurable number of cards for sorting (minimum 3, maximum 15 cards)
- **FR-030**: System MUST support configurable character sheet stats (minimum 3, maximum 10 stats)
- **FR-031**: System MUST label each temporal data point with its corresponding time period or phase
- **FR-032**: System MUST allow editing of previously set values within the same session by pre-filling original responses when navigating back and allowing changes that overwrite the original
- **FR-033**: System MUST save user responses to persistent storage when user navigates to next/previous question (save on page transition)

### Key Entities

- **Question**: Represents a single question with an associated input method type (slider, swipe, card_sort, energy_map, emoji_reaction, character_sheet), question text, and configuration parameters
- **Slider Configuration**: Minimum value, maximum value, endpoint labels, optional intermediate labels, step size
- **Swipe Configuration**: Animation preferences, swipe threshold distance, positive/negative labels
- **Card Set**: Collection of cards with text/labels to be sorted, optional descriptions; supports partial ranking with unranked cards marked as "not ranked"
- **Energy Map Configuration**: Time periods or phases to be mapped, energy scale range, axis labels; supports partial data entry with empty periods stored as null
- **Emoji Set**: Collection of emoji options with associated semantic values/labels
- **Character Sheet**: Set of named stats/attributes, point budget, min/max values per stat; requires full point allocation before submission
- **Response**: User's answer captured with the appropriate data structure (numeric value for slider, boolean for swipe, ordered array for cards with ranked/unranked status, temporal points for energy map with null for empty periods, emoji value for reaction, stat distribution object for character sheet), linked to the question; saved on page transition and pre-filled when navigating back for editing
- **Session**: Collection of responses across multiple questions, tracks progress and allows navigation with response persistence on page transitions

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All interactions work smoothly on both touch devices and with mouse input
- **SC-002**: 90% of users successfully complete their first question of each type without errors or confusion
- **SC-003**: Swipe gesture recognition accuracy is above 95% (correct gesture interpretation)
- **SC-004**: All animations complete within 500ms to maintain engagement without feeling slow
- **SC-005**: Users can navigate back to previous questions and see their saved responses accurately 100% of the time
- **SC-006**: System maintains response data integrity across page navigation with 100% accuracy
- **SC-007**: Users report the experience as "immersive" or "engaging" in at least 80% of feedback surveys
- **SC-008**: Task completion rate for multi-step questions (card sorting, character sheets) exceeds 85%
- **SC-009**: Users can understand how to interact with each new input method within 3 seconds of seeing it
- **SC-010**: Zero data loss occurs during swipe gestures, drag operations, or page transitions

## Assumptions

- Users are accessing the application on devices with modern browsers supporting CSS animations and touch/mouse events
- Questions are presented one at a time in a linear flow (no branching logic based on answers)
- Character sheet point budgets are positive integers between 10 and 100
- Energy/mood mapping uses a fixed scale (e.g., 0-10 or low/medium/high) rather than absolute values
- Emoji reactions use standard Unicode emojis that render consistently across platforms
- Card sorting is single-column vertical arrangement (top = most important, bottom = least important)
- All input methods require at least one interaction to be considered "answered"
- Slider step size defaults to 1 unless configured otherwise
- Swipe gestures require minimum 30% screen width travel to register as complete
- Users complete questions in a single session (no multi-session resume functionality required for MVP)
- Accessibility features (screen readers, keyboard navigation) will follow standard web practices but are not the primary focus of the immersive interaction design
- There are no time limits for answering questions - users can take as long as they need

## Out of Scope

- Multi-user collaborative question answering
- Real-time comparison of responses between users
- AI-powered question recommendations based on previous answers
- Video or audio-based question types
- Export of individual question responses to external formats
- Branching question logic based on previous answers
- Time-limited questions with countdown timers
- Leaderboards or competitive elements
- Integration with external personality assessment tools
- Custom emoji upload (limited to standard Unicode sets)
- 3D visualizations or advanced graphics
- Voice input for any question type
