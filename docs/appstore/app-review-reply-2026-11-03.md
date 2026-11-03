# Reply to App Review — submission 77ee3bd5-4abe-45bd-ac07-604bc8b8c4ee

Send as a reply on the rejected submission in App Store Connect (App Review → the submission → Reply to App Review).
Do **not** resubmit with it; the new build goes in only after Apple answers.
Optional attachment: a screenshot of the consent screen in English (build 63).

---

Hello App Review team,

Thank you for the detailed feedback on WordRem AI 2.0 (62). Before we submit a new build, we would like to explain the changes we have made for both issues and ask you to confirm that they resolve them, so that our next submission fully complies with the guidelines.

**1. Guideline 4.3(a) – Design – Spam**

WordRem AI (Apple ID 6474321549) is a long-standing app: version 1.1 has been available on the App Store since December 2023, and version 2.0 is a complete redesign of the same app (an AI voice tutor for speaking practice).

While building version 2.0, we mistakenly created a second app record on our account, "WordRem AI: Language Learning" (later renamed "WordRem AI Archive", Apple ID 6478985459, bundle ID com.twinflare.WordRemSwiftUI). It was never approved or released, and it was the duplicate you identified.

What we have done:
- We first removed that record from all storefronts (Country or Region Availability: 0) and then removed the app record from our account entirely. It no longer appears in our Apps list.
- WordRem AI (6474321549, bundle ID com.twinflare.reminderToWords) is now the only record for this app, and we will not create any other record for it.
- This app is not distributed, or submitted for review, from any other developer account.
- The other apps on our account (Kumbi, SocialHive, TwinFlareMark-1) are unrelated products with different content and functionality.

Question: Is removing the duplicate record sufficient to resolve Guideline 4.3(a), or is there anything else you would like us to change?

**2. Guidelines 5.1.1(i) and 5.1.2(i) – Data Collection and Data Use**

You are right that the app sends user data to third-party AI services. In our next build (2.0 (63)) we added an explicit consent step that meets all four requirements:

- **When it appears:** a full-screen consent page appears before the user's first conversation with the voice tutor (Lupa), in onboarding and before any lesson or free chat. Nothing is sent to an AI service before the user agrees.
- **What is sent (shown on the screen):** the user's voice (only while they hold the microphone button), the conversation text, what the user tells the tutor about themselves, the user's name, native language, the language they are learning and their level.
- **Who receives it (shown on the screen):** OpenAI and Google (Gemini), the third-party AI services that understand the user's speech and generate the tutor's replies. The data passes through our server.
- **Why (shown on the screen):** to understand what the user says, reply by voice and correct mistakes. We do not store recordings on our servers, and the data is not used for advertising.
- **Permission:** the user must tap "I agree, continue". If they tap "Not now", the voice tutor does not connect and no data is sent.
- **Withdrawing consent:** the user can withdraw consent at any time in Profile › Settings › AI conversation permission. The voice tutor then stops working until they agree again.
- **Localization:** the consent page is available in all 8 languages of the app (English, Turkish, German, French, Spanish, Italian, Russian and Chinese).

We also updated our privacy policy (https://api.wordremai.app/privacy). It now states that permission is asked first, lists the same data, names OpenAI and Google as recipients, explains the purpose, and confirms that these providers process the data under API data-processing terms that give it protection equal to our policy and do not use it to train their models.

Question: Does this consent flow and privacy policy meet Guidelines 5.1.1(i) and 5.1.2(i)? If you would prefer any change, for example in the wording or in when the consent page appears, we will make it before submitting.

**3. Earlier issue (Guideline 5 – China)**

As discussed in our previous reply, the app is no longer available on the China mainland storefront.

As soon as you confirm, we will submit build 2.0 (63) with these changes and add the same details to the App Review notes.

Thank you for your help.

Best regards,
Ahmet Göktürk Kurt
WordRem AI
