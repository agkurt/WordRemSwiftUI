package app.wordrem.android

import android.app.Application
import app.wordrem.android.billing.Billing
import app.wordrem.android.data.Content
import app.wordrem.android.data.Store

class WordRemApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Store.init(this)
        Content.load(this)
        Billing.configure(this)
    }
}
