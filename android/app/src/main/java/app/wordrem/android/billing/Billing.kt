package app.wordrem.android.billing

import android.app.Activity
import android.content.Context
import android.util.Log
import app.wordrem.android.BuildConfig
import app.wordrem.android.data.Store
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PackageType
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesException
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore

/**
 * RevenueCat + Google Play Billing. iOS ile aynı proje ve aynı entitlement'lar ("premium", eski "pro"):
 * ses sunucusu Pro hakkını RevenueCat'e bu kullanıcı kimliğiyle sorar, platform fark etmez.
 * Anahtar yoksa (henüz RevenueCat'te Android uygulaması açılmadıysa) uygulama ücretsiz modda çalışır.
 */
object Billing {
    private val entitlements = setOf(BuildConfig.RC_ENTITLEMENT, "premium", "pro")
    /** iOS'taki ürünler; Play'de aynı kimliklerle açılırsa sıralama aynı olur */
    private val order = listOf(PackageType.ANNUAL, PackageType.MONTHLY, PackageType.WEEKLY)

    val isConfigured: Boolean get() = Purchases.isConfigured

    val appUserId: String? get() = if (Purchases.isConfigured) Purchases.sharedInstance.appUserID else null

    fun configure(context: Context) {
        val key = BuildConfig.REVENUECAT_API_KEY
        if (key.isEmpty()) { Log.w("WordRemBilling", "RevenueCat key missing: paywall disabled"); return }
        Purchases.configure(PurchasesConfiguration.Builder(context, key).build())
        Purchases.sharedInstance.updatedCustomerInfoListener = com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener { apply(it) }
    }

    private fun apply(info: CustomerInfo): Boolean {
        val active = info.entitlements.active.keys.any { it in entitlements } || info.activeSubscriptions.isNotEmpty()
        Store.savePremium(active)
        return active
    }

    suspend fun refresh(): Boolean {
        if (!isConfigured) return Store.isPremium
        return runCatching { apply(Purchases.sharedInstance.awaitCustomerInfo()) }.getOrDefault(Store.isPremium)
    }

    /** Teklifteki paketler: yıllık, aylık (varsa haftalık gizlenir), haftalık */
    suspend fun packages(): List<Package> {
        if (!isConfigured) return emptyList()
        val offering = runCatching { Purchases.sharedInstance.awaitOfferings().current }.getOrNull() ?: return emptyList()
        val list = offering.availablePackages.sortedBy { order.indexOf(it.packageType).let { i -> if (i < 0) 99 else i } }
        val hasMonthly = list.any { it.packageType == PackageType.MONTHLY }
        return list.filter { !(hasMonthly && it.packageType == PackageType.WEEKLY) }
    }

    /** true: satın alındı · false: kullanıcı vazgeçti · hata fırlatır */
    suspend fun purchase(activity: Activity, pkg: Package): Boolean = try {
        apply(Purchases.sharedInstance.awaitPurchase(PurchaseParams.Builder(activity, pkg).build()).customerInfo)
    } catch (e: PurchasesException) {
        if (e.error.code == com.revenuecat.purchases.PurchasesErrorCode.PurchaseCancelledError) false else throw e
    }

    suspend fun restore(): Boolean {
        if (!isConfigured) return false
        return apply(Purchases.sharedInstance.awaitRestore())
    }
}
