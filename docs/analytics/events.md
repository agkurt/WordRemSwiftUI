# WordRem AI — Analytics (GA4 / Firebase)

Few events, rich parameters. Every event answers one question; the `action` parameter says what happened
inside it. Code: `WordRemSwiftUI/Services/Analytics/Track.swift` (the only place that calls Firebase).

Firebase project: `wordrem-ai` (GA4 property in the "WordRem" Analytics account).

## Identity & user properties

- `user_id`: RevenueCat app user id (anonymous, no personal data). Same id RevenueCat uses, so GA4 and
  RevenueCat can be joined. RevenueCat also gets the Firebase app instance id.
- User properties (sent with every event automatically):

| Property | Example | Meaning |
|---|---|---|
| `wr_user_id` | `8cba80a1b9e3…` | Anonymous user id (RevenueCat id without the `$RCAnonymousID:` prefix) |
| `native_lang` | `tr` | Learner's own language |
| `target_lang` | `de` | Language being learned now |
| `ui_lang` | `tr` | App interface language |
| `langs_count` | `2` | How many languages they learn |
| `level` | `1` | Proficiency 0–4 |
| `tier` | `free` / `trial` / `pro` | Subscription state |
| `lessons_done` | `3-5` | Completed lessons, bucketed (0, 1-2, 3-5, 6-10, 11-25, 26+) |
| `onboarding_done` | `yes` | Finished onboarding |
| `paywall_views` | `2` | Paywalls seen so far, bucketed (0, 1, 2, 3-5, 6+) |

## Events

### 1. `onboarding_step` — where do new users drop?
| Param | Values |
|---|---|
| `action` | `view`, `complete`, `back`, `finish` |
| `step` | `welcome`, `native_language`, `target_language`, `name`, `demo` |
| `step_index` | 0–4 |
| `time_on_step_sec` | seconds spent on the step (on complete/back) |
| `native_lang`, `target_lang` | choices so far |
| `has_name` | 1/0 |

### 2. `paywall_action` — how engaged are they, where do we lose them?
| Param | Values |
|---|---|
| `action` | `view`, `step_view`, `plan_select`, `cta_tap`, `purchase_start`, `purchase_success`, `purchase_cancel`, `purchase_fail`, `restore_start`, `restore_success`, `restore_fail`, `legal_open`, `plans_load_fail`, `close` |
| `entry_point` | `onboarding`, `lesson_limit`, `profile`, `ai_quiz`, `grammar_voice`, `other` |
| `paywall_step` | `value`, `plans`, `trial` |
| `max_step` | furthest step reached (0 value, 1 plans, 2 trial) |
| `plan_id`, `plan_period` | product id, `annual` / `monthly` / `weekly` |
| `price`, `currency` | numeric price, ISO code |
| `has_trial`, `trial_days` | 1/0, days |
| `time_on_paywall_sec` | seconds since the paywall opened |
| `plan_switches` | how many times they changed plan |
| `view_index` | nth paywall this user has seen |
| `legal_doc` | `privacy` / `terms` |
| `error_code` | StoreKit / RevenueCat error |

`close` carries `time_on_paywall_sec`, `max_step`, `plan_switches` and the last `plan_id`: it is the
"why did they leave" row.

### 3. `purchase` (GA4 recommended event → revenue)
`value`, `currency`, `transaction_id`, `plan_id`, `plan_period`, `has_trial`, `entry_point`.
For a free trial start `value` is 0 (real revenue comes from RevenueCat → Firebase integration).

### 4. `lesson_session` — do lessons work and keep people?
| Param | Values |
|---|---|
| `action` | `start`, `connected`, `connect_fail`, `complete`, `exit`, `time_up`, `limit_hit` |
| `mode` | `goal`, `free_chat`, `demo`, `setup`, `word_practice`, `level_review` |
| `lesson_id` | chapter/goal id (`goal` mode) |
| `duration_sec` | spoken time so far |
| `user_turns`, `answers`, `correct`, `accuracy_pct` | engagement & success |
| `progress_pct` | lesson pieces done / total |
| `stage` | `warmup`, `teaching`, `roleplay`, `done` |
| `connect_ms` | time to connect (on `connected`) |
| `via_relay`, `reconnects` | network path, drops |
| `error_code` | connection error (on `connect_fail`) |

### 5. `tutor_interaction` — which in-lesson features are used?
`action`: `help_slower`, `help_explain`, `card_translate`, `card_speak`, `card_save`, `transcript_open`,
`topic_picker_open`, `topic_pick`, `interrupt`, `skip_request`, `language_switch`; plus `mode`, `item`
(topic id / language).

### 6. `practice_session` — words / quiz
`action` (`start`, `complete`, `exit`), `practice_type`, `word_count`, `correct`, `total`, `accuracy_pct`,
`duration_sec`, `entry_point`.

### 7. `language_action`
`action` (`sheet_open`, `add_start`, `add_complete`, `add_abandon`, `switch`, `ui_change`), `from_lang`,
`to_lang`, `entry_point`.

### 8. `screen_view` (GA4 recommended)
`screen_name`: `home`, `words`, `profile`, `lesson`, `paywall`, `learning_sheet`, `quiz`, `onboarding`.

## Key events (conversions)
- `purchase`
- `onboarding_complete` — GA4 "create event" rule: `onboarding_step` where `action = finish`
- `paywall_purchase` — rule: `paywall_action` where `action = purchase_success`
- `lesson_complete` — rule: `lesson_session` where `action = complete`

## Questions this answers
- **Onboarding funnel:** `onboarding_step` view → complete per `step`; time per step; native/target mix.
- **Paywall funnel:** `view` → `step_view(plans)` → `plan_select` → `purchase_start` → `purchase_success`,
  split by `entry_point`, `plan_period`, `has_trial`, `view_index`.
- **Paywall intent:** `time_on_paywall_sec`, `max_step`, `plan_switches` on `close` vs. on `purchase_success`.
- **Where lessons fail:** `connect_fail` by `error_code`/`via_relay`; `exit` by `stage` and `progress_pct`.
- **Learning quality:** `accuracy_pct`, `user_turns` per `mode`, `target_lang`, `level`.
- **Activation & retention:** first `lesson_session(complete)`; cohorts by `lessons_done`, `tier`.

## GA4 custom definitions to register
Event-scoped dimensions: `action`, `step`, `entry_point`, `paywall_step`, `plan_id`, `plan_period`, `mode`,
`lesson_id`, `stage`, `error_code`, `legal_doc`, `practice_type`, `item`, `from_lang`, `to_lang`, `screen_name`.
Metrics: `time_on_step_sec`, `time_on_paywall_sec`, `max_step`, `plan_switches`, `view_index`, `price`,
`duration_sec`, `user_turns`, `accuracy_pct`, `progress_pct`, `connect_ms`, `word_count`.
User-scoped: every user property above.
