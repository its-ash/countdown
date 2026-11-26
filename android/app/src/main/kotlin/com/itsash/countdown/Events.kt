package com.itsash.countdown

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.Year
import java.time.temporal.ChronoUnit

/** One event as saved by Dart (lib/core/event.dart). */
data class Ev(
    val id: String,
    val title: String,
    val date: LocalDate,
    val minutes: Int?,
    val emoji: String,
    val color: Int,
    val yearly: Boolean,
)

/** An event resolved against a moment in time. */
data class Info(val ev: Ev, val state: Int, val days: Long, val target: LocalDateTime)

/**
 * Same rules as lib/core/countdown_math.dart: calendar days between dates, a yearly
 * event counts to its next occurrence (Feb 29 becomes Feb 28 in a common year),
 * a date is "today" all day long and "past" from the next midnight.
 */
object Calc {
    const val UPCOMING = 0
    const val TODAY = 1
    const val PAST = 2

    fun yearlyDate(base: LocalDate, year: Int): LocalDate =
        if (base.monthValue == 2 && base.dayOfMonth == 29 && !Year.isLeap(year.toLong())) LocalDate.of(year, 2, 28)
        else LocalDate.of(year, base.monthValue, base.dayOfMonth)

    fun of(e: Ev, now: LocalDateTime): Info {
        val today = now.toLocalDate()
        var day = e.date
        if (e.yearly) {
            day = yearlyDate(e.date, today.year)
            if (day.isBefore(today)) day = yearlyDate(e.date, today.year + 1)
        }
        val m = e.minutes ?: 0
        val target = day.atTime(m / 60, m % 60)
        val diff = ChronoUnit.DAYS.between(today, day)
        val state = if (diff > 0) UPCOMING else if (diff == 0L) TODAY else PAST
        return Info(e, state, Math.abs(diff), target)
    }

    fun sorted(events: List<Ev>, now: LocalDateTime): List<Info> {
        val cmp = Comparator<Info> { a, b ->
            val ap = a.state == PAST
            val bp = b.state == PAST
            when {
                ap != bp -> if (ap) 1 else -1
                else -> {
                    val c = if (ap) b.target.compareTo(a.target) else a.target.compareTo(b.target)
                    if (c != 0) c else a.ev.title.lowercase().compareTo(b.ev.title.lowercase())
                }
            }
        }
        return events.map { of(it, now) }.sortedWith(cmp)
    }

    /** Big number and its caption, e.g. "39" / "days left". */
    fun label(i: Info, now: LocalDateTime): Pair<String, String> {
        fun plural(n: Long, one: String, many: String) = if (n == 1L) one else many
        return when (i.state) {
            PAST -> Pair("${i.days}", plural(i.days, "day since", "days since"))
            TODAY -> {
                val left = Duration.between(now, i.target)
                if (i.ev.minutes != null && !left.isNegative && !left.isZero) {
                    val h = left.toHours()
                    if (h >= 1) Pair("$h", plural(h, "hour left", "hours left"))
                    else Pair("${left.toMinutes() + 1}", "min left")
                } else Pair("Today", "")
            }
            else -> Pair("${i.days}", plural(i.days, "day left", "days left"))
        }
    }

    /** One-line form for the list widget: "39 days", "Today", "4 hours", "10 days ago". */
    fun short(i: Info, now: LocalDateTime): String {
        val (v, u) = label(i, now)
        return when {
            u.isEmpty() -> v
            i.state == PAST -> "$v ${u.replace("since", "ago")}"
            else -> "$v ${u.replace(" left", "")}"
        }
    }

    // Palette indexes match context.colors.chart in the theme (light, then dark).
    private val LIGHT = intArrayOf(
        0xFFFF7E70.toInt(), 0xFF2BC9A0.toInt(), 0xFFF5A524.toInt(), 0xFFE5484D.toInt(),
        0xFF3B82F6.toInt(), 0xFFD65DB1.toInt(), 0xFF8BC34A.toInt(), 0xFF5E5B70.toInt(),
    )
    private val DARK = intArrayOf(
        0xFFFF7E70.toInt(), 0xFF4FD8B4.toInt(), 0xFFF7B955.toInt(), 0xFFF0656A.toInt(),
        0xFF60A0FA.toInt(), 0xFFE283C8.toInt(), 0xFFA5D46F.toInt(), 0xFFB9B6C8.toInt(),
    )

    fun color(index: Int, dark: Boolean): Int {
        val p = if (dark) DARK else LIGHT
        return p[((index % p.size) + p.size) % p.size]
    }
}

object Events {
    fun parse(raw: String?): List<Ev> {
        if (raw.isNullOrEmpty()) return emptyList()
        val out = ArrayList<Ev>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                try {
                    val o = arr.getJSONObject(i)
                    val p = o.getString("date").split("-").map { it.toInt() }
                    out.add(
                        Ev(
                            id = o.getString("id"),
                            title = o.optString("title", ""),
                            date = LocalDate.of(p[0], p[1], p[2]),
                            minutes = if (o.isNull("time")) null else o.getInt("time"),
                            emoji = o.optString("emoji", "🎉"),
                            color = o.optInt("color", 0),
                            yearly = o.optBoolean("yearly", false),
                        ),
                    )
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
        }
        return out
    }
}

/** SharedPreferences "countdown_prefs": the events JSON, the alerts JSON and per-widget choices. */
class CountdownPrefs(context: Context) {
    private val p: SharedPreferences = context.applicationContext.getSharedPreferences("countdown_prefs", Context.MODE_PRIVATE)

    var eventsJson: String?
        get() = p.getString("events", null)
        set(v) = p.edit().putString("events", v).apply()

    var alertsJson: String?
        get() = p.getString("alerts", null)
        set(v) = p.edit().putString("alerts", v).apply()

    /** Last processed wall-clock time (epoch ms), used to detect backward clock jumps. */
    var lastFired: Long
        get() = p.getLong("lastFired", 0L)
        set(v) = p.edit().putLong("lastFired", v).apply()

    val hasFiredAlerts: Boolean
        get() = p.contains("firedAlerts")

    /** Keys (`at|title|body`) of alerts already shown within the retention window. */
    var firedAlerts: Set<String>
        get() = p.getStringSet("firedAlerts", emptySet()) ?: emptySet()
        set(v) = p.edit().putStringSet("firedAlerts", HashSet(v)).apply()

    var askedNotifications: Boolean
        get() = p.getBoolean("askedNotifications", false)
        set(v) = p.edit().putBoolean("askedNotifications", v).apply()

    fun events(): List<Ev> = Events.parse(eventsJson)

    fun widgetEvent(widgetId: Int): String? = p.getString("w_$widgetId", null)

    fun setWidgetEvent(widgetId: Int, eventId: String) = p.edit().putString("w_$widgetId", eventId).apply()

    fun clearWidget(widgetId: Int) = p.edit().remove("w_$widgetId").apply()
}
