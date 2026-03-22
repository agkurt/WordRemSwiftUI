# API Configuration Guide

## 🎉 What's Been Fixed

### 1. ✅ Color Scheme - FIXED
All colors in the "Create Deck" screen (PlusView) now match your app's theme using `AppTheme.Colors`. The hardcoded hex colors have been replaced with your app's color system.

### 2. ✅ Reminder System - FIXED
The reminder functionality has been completely overhauled:
- Now properly handles "None", "Weekly", and "Monthly" repeat options
- Stores notification IDs properly
- Creates multiple future notifications for recurring reminders
- Added `removeAllNotifications()` method for cleanup

### 3. ✅ Example Sentence Feature - WORKS NOW!
The "Generate Example Sentence" button now works **out of the box** with the **Free Dictionary API** (no API key needed!). I've implemented a working solution that fetches real example sentences.

### 4. 🔧 Translation Feature - NEEDS YOUR API KEY
The translation button is ready to work, but you need to configure an API service. I've provided three options with complete implementation examples.

---

## 📋 What You Need To Do

### Step 1: Test the Example Sentences (Already Working!)
1. Run your app
2. Create or open a deck
3. Add a new word
4. Make sure the source language is set to "EN" (English)
5. Type an English word (e.g., "happy", "running", "book")
6. Tap "Generate Example Sentence"
7. It should fetch real example sentences!

### Step 2: Configure Translation API

You have **3 options** for translation. Choose one:

#### Option A: DeepL (RECOMMENDED - Best Free Tier)
**✅ 500,000 characters/month FREE**

1. Go to: https://www.deepl.com/pro-api
2. Sign up for a free account
3. Get your Authentication Key
4. Open `ApiKey-Info.plist` in Xcode
5. Find the key `TranslateApi` and paste your key there
6. Open `URLSessionApiService.swift`
7. Find the section marked "OPTION 3: DeepL API"
8. **Uncomment** all the code in that section
9. Find the line that says `completion(.failure(APIError.notConfigured(...)))`
10. **Comment out** that line
11. **Uncomment** the URLSession.shared.dataTask code at the bottom

#### Option B: Microsoft Azure Translator
**✅ 2M characters/month FREE**

1. Go to: https://azure.microsoft.com/services/cognitive-services/translator/
2. Create a free Azure account
3. Create a Translator resource
4. Get your API key and region
5. Follow the same steps as DeepL but use "OPTION 2: Microsoft Azure Translator"

#### Option C: Google Cloud Translation
**✅ Free tier available**

1. Go to: https://cloud.google.com/translate
2. Create a Google Cloud account
3. Enable Translation API
4. Create an API key
5. Follow the same steps but use "OPTION 1: Google Cloud Translation API"

---

## 📝 Example: How to Configure DeepL

### In `ApiKey-Info.plist`:
```xml
<key>TranslateApi</key>
<string>your-deepl-api-key-here</string>
```

### In `URLSessionApiService.swift`:

**Find this code (around line 100):**
```swift
// OPTION 3: DeepL API
// Uncomment and configure this if you're using DeepL
/*
var components = URLComponents(string: "https://api-free.deepl.com/v2/translate")
...
*/
```

**Change it to:**
```swift
// OPTION 3: DeepL API
var components = URLComponents(string: "https://api-free.deepl.com/v2/translate")
components?.queryItems = [
    URLQueryItem(name: "auth_key", value: apiKey),
    URLQueryItem(name: "text", value: text),
    URLQueryItem(name: "source_lang", value: sourceLang),
    URLQueryItem(name: "target_lang", value: targetLang)
]

guard let url = components?.url else {
    completion(.failure(APIError.invalidURL))
    return
}

var request = URLRequest(url: url)
request.httpMethod = "POST"
```

**Then find this line (around line 130):**
```swift
completion(.failure(APIError.notConfigured("Please configure your translation API in URLSessionApiService.swift")))
```

**Comment it out:**
```swift
// completion(.failure(APIError.notConfigured("Please configure your translation API in URLSessionApiService.swift")))
```

**And uncomment the URLSession code below it:**
```swift
URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        completion(.failure(error))
        return
    }
    
    guard let data = data else {
        completion(.failure(APIError.noData))
        return
    }
    
    do {
        let result = try JSONDecoder().decode(TranslationResponse.self, from: data)
        completion(.success(result))
    } catch {
        completion(.failure(error))
    }
}.resume()
```

---

## 🧪 Testing Everything

### Test Reminders:
1. Open your app
2. Create a new word
3. Toggle on "Reminder"
4. Set a date/time (choose soon, like 2 minutes from now)
5. Select "Weekly" or "Monthly" 
6. Set frequency (e.g., "Repeat every 1 weekly")
7. Tap "Done"
8. Wait for the notification to appear!

### Test Translation (after configuring API):
1. Create a new word
2. Type a word in the source language
3. Tap "Translate"
4. The translation should appear in "Word Meaning"

### Test Example Sentences:
1. Make sure source language is "EN"
2. Type an English word
3. Tap "Generate Example Sentence"
4. An example sentence should appear

---

## 🎨 Color Changes Summary

All these files now use `AppTheme.Colors`:
- ✅ `PlusView.swift` - Deck creation screen
- ✅ `FlagSelectionView.swift` - Flag picker
- ✅ `CardPlusView.swift` - Already was using AppTheme (no changes needed)

Your app now has a consistent color scheme throughout!

---

## 💡 Quick Tips

1. **Example Sentences only work for English words** - This is intentional, as most dictionary APIs only support English
2. **Reminders require notification permissions** - The app requests this automatically
3. **Translation requires internet** - Make sure you're connected
4. **API keys are free** - All recommended services have generous free tiers

---

## 🐛 Troubleshooting

### "Example Sentence not working"
- Make sure the word is English
- Check your internet connection
- Try a common word like "happy" or "run"

### "Translation not working"
- Did you add your API key to `ApiKey-Info.plist`?
- Did you uncomment the code in `URLSessionApiService.swift`?
- Check the Xcode console for error messages

### "Reminder not appearing"
- Check Settings > Notifications > [Your App Name]
- Make sure notifications are enabled
- Try setting the reminder time closer (1-2 minutes away)

---

## 📞 Need Help?

All the code is well-documented. Look for comments in:
- `URLSessionApiService.swift` - API configuration
- `NotificationManager.swift` - Reminder logic
- `ReminderViewModel.swift` - Reminder UI state

Good luck! 🚀
