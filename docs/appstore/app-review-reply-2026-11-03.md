# Reply to App Review — submission 77ee3bd5-4abe-45bd-ac07-604bc8b8c4ee

Send as a reply on the rejected submission in App Store Connect (App Review → the submission → Reply to App Review).
Do **not** resubmit with it; the new build goes in only after Apple answers.
Optional attachment: a screenshot of the consent screen in English (build 63).

Plain text, ~3100 characters (App Store Connect limit: 4000).

---

Hello App Review team,

Thank you for the detailed feedback on WordRem AI 2.0 (62). Before submitting a new build, we would like to explain our changes for both issues and ask you to confirm they resolve them.

1. Guideline 4.3(a) - Spam

WordRem AI (Apple ID 6474321549) has been on the App Store since December 2023 (version 1.1). Version 2.0 is a full redesign of the same app, an AI voice tutor for speaking practice.

While building 2.0, we mistakenly created a second app record, "WordRem AI: Language Learning" (later "WordRem AI Archive", Apple ID 6478985459, bundle ID com.twinflare.WordRemSwiftUI). It was never approved or released and was the duplicate you identified.

What we did:
- We removed that record from all storefronts and then deleted it from our account. It no longer appears in our Apps list.
- 6474321549 (com.twinflare.reminderToWords) is now the only record for this app, and we will not create another one.
- The app is not distributed or submitted from any other developer account.
- The other apps on our account (Kumbi, SocialHive, TwinFlareMark-1) are unrelated products.

Question: Is removing the duplicate record enough to resolve 4.3(a), or should we change anything else?

2. Guidelines 5.1.1(i) and 5.1.2(i) - Data Collection and Use

The app does send user data to third-party AI services. Our next build, 2.0 (63), adds an explicit consent step:

- When: a full-screen consent page appears before the first conversation with the voice tutor (Lupa), in onboarding and before any lesson or free chat. Nothing is sent before the user agrees.
- What is sent (shown on screen): the user's voice (only while holding the mic button), the conversation text, what the user tells the tutor about themselves, their name, native language, learning language and level.
- Who receives it (shown on screen): OpenAI and Google (Gemini), the AI services that understand the user's speech and generate the tutor's replies, through our server.
- Why (shown on screen): to understand the user, reply by voice and correct mistakes. We do not store recordings, and the data is not used for advertising.
- Permission: the user must tap "I agree, continue". With "Not now", the tutor does not connect and nothing is sent.
- Withdrawal: anytime in Profile > Settings > AI conversation permission; the tutor stops until the user agrees again.
- The page is localized in all 8 app languages.

Our privacy policy (https://api.wordremai.app/privacy) now says permission is asked first, lists the same data, names OpenAI and Google, explains the purpose, and confirms these providers give the data equal protection and do not use it to train their models.

Question: Do this consent flow and privacy policy meet 5.1.1(i) and 5.1.2(i)? If you would like changes to the wording or timing, we will make them before submitting.

3. Guideline 5 - China

As noted earlier, the app is no longer available on the China mainland storefront.

Once you confirm, we will submit build 2.0 (63) and add these details to the App Review notes.

Thank you for your help.

Best regards,
Ahmet Göktürk Kurt
WordRem AI
