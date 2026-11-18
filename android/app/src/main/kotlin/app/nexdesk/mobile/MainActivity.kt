package app.nexdesk.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    // The API names one of these on every push (android.notification.channel_id): ticket activity, and SLA
    // warnings and breaches, which people may want louder or quieter than the rest.
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannels(
            listOf(
                NotificationChannel("tickets", getString(R.string.channel_tickets), NotificationManager.IMPORTANCE_DEFAULT),
                NotificationChannel("sla", getString(R.string.channel_sla), NotificationManager.IMPORTANCE_HIGH),
            ),
        )
    }
}
