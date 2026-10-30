package fr.local.voxelhome

import android.app.Activity
import android.os.Bundle
import android.content.Intent
import android.content.ActivityNotFoundException
import android.graphics.*
import android.graphics.drawable.Drawable
import android.view.*
import android.widget.*
import android.provider.Settings
import android.content.BroadcastReceiver
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

/** Accueil local : reception du demarrage uniquement, aucun service ni reseau. */
class MainActivity : Activity() {
    private val apps = listOf(
        "Stremio" to "com.stremio.one",
        "YouTube" to "com.amazon.firetv.youtube",
        "Crunchyroll" to "com.crunchyroll.crunchyroid",
        "ADN" to "fr.anidn"
    )
    private var landscape: Bitmap? = null
    private var selected = 0
    private val cards = mutableListOf<View>()
    private var status: TextView? = null
    private var leaves: LeavesView? = null
    private var resumed = false
    private val preferences by lazy { getSharedPreferences("voxel", MODE_PRIVATE) }
    private fun dp(value: Int) = (value * resources.displayMetrics.density + .5f).toInt()

    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        selected = state?.getInt("selection", 0) ?: 0
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        landscape = assets.open("voxel-forest.png").use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.RGB_565 })
        }
        val frame = FrameLayout(this)
        frame.addView(object : View(this) {
            private val paint = Paint().apply { isFilterBitmap = false }
            override fun onDraw(canvas: Canvas) {
                super.onDraw(canvas)
                landscape?.let { image ->
                    // CENTER_CROP sans deformer le paysage sur les ecrans non 16:9.
                    val scale = maxOf(width.toFloat()/image.width, height.toFloat()/image.height)
                    val w = image.width*scale; val h = image.height*scale
                    canvas.drawBitmap(image, null, RectF((width-w)/2, (height-h)/2, (width+w)/2, (height+h)/2), paint)
                }
                canvas.drawColor(0x240b1408)
            }
        }, FrameLayout.LayoutParams(-1, -1))
        leaves = LeavesView(this)
        frame.addView(leaves, FrameLayout.LayoutParams(-1, -1))
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(36), dp(24), dp(36), dp(24))
        }
        frame.addView(content, FrameLayout.LayoutParams(-1, -1))
        content.addView(PixelTitle(this), LinearLayout.LayoutParams(-1, dp(76)))
        content.addView(TextView(this).apply {
            text = "Ton petit monde, tes applications."; textSize = 16f; setTextColor(Color.WHITE)
            setShadowLayer(2f, 1f, 1f, Color.BLACK)
            gravity = Gravity.CENTER; setPadding(0, dp(4), 0, dp(24))
        })
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; clipChildren = false }
        content.addView(row, LinearLayout.LayoutParams(-1, dp(114)))
        apps.forEachIndexed { index, (label, pkg) ->
            val card = makeCard(label, pkg)
            card.id = 100 + index
            card.setOnClickListener { launchApp(pkg, label) }
            card.setOnFocusChangeListener { view, focus ->
                view.invalidate()
                if (focus) { selected = index; status?.text = "OK : ouvrir $label" }
            }
            card.nextFocusLeftId = 100 + maxOf(0,index-1)
            card.nextFocusRightId = 100 + minOf(3,index+1)
            card.nextFocusDownId = 200
            row.addView(card, LinearLayout.LayoutParams(0, -1, 1f).apply {
                if (index < apps.size-1) rightMargin = dp(12)
            })
            cards.add(card)
        }
        status = TextView(this).apply {
            text = "OK : ouvrir ${apps[selected.coerceIn(0,3)].first}"
            textSize = 14f; setTextColor(Color.WHITE)
            setShadowLayer(2f, 1f, 1f, Color.BLACK)
            setPadding(0, dp(12), 0, dp(22))
            gravity = Gravity.CENTER
        }
        content.addView(status)
        val footer = LinearLayout(this)
        content.addView(footer)
        val settings = makeButton("Paramètres Amazon", 200) {
            openSafely(Intent(Settings.ACTION_SETTINGS), "Impossible d’ouvrir les paramètres. Appuie sur Accueil puis ouvre les paramètres Amazon.")
        }
        val amazon = makeButton("Accueil Amazon", 201) { amazonHome() }
        settings.nextFocusRightId = 201; amazon.nextFocusLeftId = 200
        settings.nextFocusUpId = 100; amazon.nextFocusUpId = 103
        footer.addView(settings, LinearLayout.LayoutParams(dp(230), dp(48)).apply { rightMargin = dp(12) })
        footer.addView(amazon, LinearLayout.LayoutParams(dp(210), dp(48)))
        val options = LinearLayout(this).apply { setPadding(0, dp(10), 0, 0) }
        content.addView(options)
        lateinit var animation: TextView
        animation = makeButton(animationLabel(), 202) {
            val enabled = !preferences.getBoolean("leaves", true)
            preferences.edit().putBoolean("leaves", enabled).apply()
            animation.text = animationLabel(); updateAnimation()
        }
        lateinit var boot: TextView
        boot = makeButton(bootLabel(), 203) {
            if (homeHelperInstalled()) {
                packageManager.getLaunchIntentForPackage("io.github.toolicious.homeonfire")?.let {
                    openSafely(it, "Ouvre Home on Fire depuis les applications Amazon.")
                }
                return@makeButton
            }
            val enabled = !preferences.getBoolean("boot_start", true)
            preferences.edit().putBoolean("boot_start", enabled).apply()
            boot.text = bootLabel()
            showError(if (enabled) "Démarrage activé : à vérifier après un redémarrage complet du Stick." else "Démarrage automatique désactivé.")
        }
        animation.nextFocusRightId = 203; boot.nextFocusLeftId = 202
        animation.nextFocusUpId = 200; boot.nextFocusUpId = 201
        settings.nextFocusDownId = 202; amazon.nextFocusDownId = 203
        options.addView(animation, LinearLayout.LayoutParams(dp(230), dp(42)).apply { rightMargin = dp(12) })
        options.addView(boot, LinearLayout.LayoutParams(dp(210), dp(42)))
        setContentView(frame)
        cards[selected.coerceIn(0,3)].requestFocus()
    }

    private fun animationLabel() = "Feuilles : " + if (preferences.getBoolean("leaves", true)) "oui" else "non"
    private fun homeHelperInstalled(): Boolean = try {
        packageManager.getApplicationInfo("io.github.toolicious.homeonfire", 0).enabled
    } catch (_: android.content.pm.PackageManager.NameNotFoundException) { false }
    private fun bootLabel() = if (homeHelperInstalled()) "Maison / démarrage" else "Au démarrage : " + if (preferences.getBoolean("boot_start", true)) "oui" else "non"
    private fun updateAnimation() { leaves?.setRunning(resumed && hasWindowFocus() && preferences.getBoolean("leaves", true)) }
    override fun onResume() { super.onResume(); resumed = true; updateAnimation() }
    override fun onPause() { resumed = false; updateAnimation(); super.onPause() }
    override fun onWindowFocusChanged(hasFocus: Boolean) { super.onWindowFocusChanged(hasFocus); updateAnimation() }

    private fun makeCard(label: String, pkg: String): LinearLayout {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            isFocusable = true; isFocusableInTouchMode = true; isClickable = true
            descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
            setPadding(dp(10), dp(10), dp(10), dp(10))
            contentDescription = "Ouvrir $label"
        }
        card.background = PixelFrame(card)
        try {
            val icon = packageManager.getApplicationIcon(pkg)
            card.addView(ImageView(this).apply {
                setImageDrawable(icon); scaleType = ImageView.ScaleType.FIT_CENTER
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(dp(52), dp(52)))
        } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
            card.addView(TextView(this).apply { text = "—"; textSize = 28f; setTextColor(Color.WHITE) })
        }
        card.addView(TextView(this).apply {
            text = label; textSize = 17f; gravity = Gravity.CENTER
            setTextColor(Color.WHITE); typeface = Typeface.create("monospace", Typeface.BOLD)
            setShadowLayer(1f, 2f, 2f, Color.BLACK)
            setPadding(0, dp(10), 0, 0)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        })
        return card
    }

    private fun makeButton(label: String, viewId: Int, action: () -> Unit): TextView {
        val button = TextView(this).apply {
            id = viewId; text = label; textSize = 15f
            gravity = Gravity.CENTER; setTextColor(Color.WHITE)
            typeface = Typeface.create("monospace", Typeface.BOLD)
            setShadowLayer(1f, 1f, 1f, Color.BLACK)
            isFocusable = true; isClickable = true
            setOnClickListener { action() }
            setOnFocusChangeListener { view, _ -> view.invalidate() }
        }
        button.background = PixelFrame(button)
        return button
    }

    private fun launchApp(pkg: String, label: String) {
        // Requete TV explicite, puis repli sur l'activite standard si necessaire.
        val tv = Intent(Intent.ACTION_MAIN).addCategory("android.intent.category.LEANBACK_LAUNCHER").setPackage(pkg)
        val match = packageManager.queryIntentActivities(tv, 0).firstOrNull()
        val intent = if (match != null) {
            tv.setClassName(match.activityInfo.packageName, match.activityInfo.name)
        } else packageManager.getLaunchIntentForPackage(pkg)
        if (intent == null) { showError("$label est absent ou ne propose pas d’écran de lancement."); return }
        openSafely(intent, "Impossible d’ouvrir $label. Vérifie son installation dans les paramètres Amazon.")
    }
    private fun openSafely(intent: Intent, message: String) {
        try { startActivity(intent) }
        catch (_: ActivityNotFoundException) { showError(message) }
        catch (_: SecurityException) { showError(message) }
    }
    private fun showError(message: String) {
        status?.text = message
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }
    private fun amazonHome() {
        if (homeHelperInstalled()) {
            android.app.AlertDialog.Builder(this)
                .setTitle("Accueil Amazon")
                .setMessage("Appuie deux fois sur Maison en laissant une courte pause (environ une seconde) pour accéder à Amazon. Pour régler ou couper la redirection, ouvre Maison / démarrage.")
                .setPositiveButton("Compris") { dialog, _ -> dialog.dismiss() }
                .show()
            return
        }
        openSafely(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), "Appuie sur le bouton Accueil de la télécommande.")
    }
    override fun onBackPressed() {
        if (homeHelperInstalled()) cards[selected.coerceIn(0,3)].requestFocus() else amazonHome()
    }
    override fun onSaveInstanceState(outState: Bundle) {
        outState.putInt("selection", selected); super.onSaveInstanceState(outState)
    }
    override fun onDestroy() {
        // Le Bitmap n'est pas recycle de force pendant qu'une View peut encore le dessiner.
        leaves?.setRunning(false); leaves = null
        landscape = null; cards.clear(); status = null; super.onDestroy()
    }
    private inner class PixelFrame(private val owner: View) : Drawable() {
        private val paint = Paint()
        override fun draw(canvas: Canvas) {
            val w = bounds.width().toFloat(); val h = bounds.height().toFloat(); val edge = dp(3).toFloat()
            paint.color = 0xff171717.toInt()
            canvas.drawRect(0f, 0f, w, h, paint)
            paint.color = if (owner.hasFocus()) 0xffecf6b3.toInt() else 0xffb7b7b7.toInt()
            canvas.drawRect(edge, edge, w-edge, h-edge, paint)
            paint.color = if (owner.hasFocus()) 0xff3c4931.toInt() else 0xff373737.toInt()
            canvas.drawRect(edge, h-edge*3, w-edge, h-edge, paint)
            canvas.drawRect(w-edge*3, edge, w-edge, h-edge, paint)
            paint.color = if (owner.hasFocus()) 0xff657d49.toInt() else 0xff737373.toInt()
            canvas.drawRect(edge*2, edge*2, w-edge*3, h-edge*3, paint)
            val step = dp(8)
            var y = step
            while (y < h-edge*4) {
                var x = step
                while (x < w-edge*4) {
                    if ((x/step+y/step)%3 == 0) {
                        paint.color = if (owner.hasFocus()) 0xff6c8450.toInt() else 0xff7c7c7c.toInt()
                        canvas.drawRect(x.toFloat(),y.toFloat(),x+dp(3).toFloat(),y+dp(2).toFloat(),paint)
                    }
                    x += step
                }
                y += step
            }
        }
        override fun setAlpha(alpha: Int) { paint.alpha = alpha }
        override fun setColorFilter(filter: ColorFilter?) { paint.colorFilter = filter }
        @Deprecated("Required by Android")
        override fun getOpacity() = PixelFormat.OPAQUE
    }
}

/** Une tentative au demarrage complet, sans service, alarme ni boucle. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        // Home on Fire gere le boot et la sortie de veille lorsqu'il est installe.
        // Eviter de lancer deux fois la meme interface.
        try {
            if (context.packageManager.getApplicationInfo("io.github.toolicious.homeonfire", 0).enabled) return
        } catch (_: android.content.pm.PackageManager.NameNotFoundException) { }
        val prefs = context.getSharedPreferences("voxel", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("boot_start", true)) return
        if (Build.VERSION.SDK_INT > 28) {
            prefs.edit().putString("boot_result", "Version Android non prise en charge pour ce lancement au boot").apply()
            return
        }
        val pending = goAsync()
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                if (prefs.getBoolean("boot_start", true)) {
                    context.startActivity(Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
                    prefs.edit().putString("boot_result", "Lancement demande; affichage a verifier sur la TV")
                        .putLong("boot_time", System.currentTimeMillis()).apply()
                }
            } catch (e: RuntimeException) {
                prefs.edit().putString("boot_result", "Lancement refuse : " + e.javaClass.simpleName).apply()
            } finally { pending.finish() }
        }, 3000L)
    }
}

/** 14 feuilles, 20 images/s au plus, aucun callback quand l'accueil est masque. */
class LeavesView(context: Context) : View(context) {
    private val paint = Paint().apply { isAntiAlias = false }
    private var running = false
    private var started = SystemClock.uptimeMillis()
    private val palette = intArrayOf(0xffb1c356.toInt(), 0xff759d39.toInt(), 0xffc29c46.toInt(), 0xff88ae43.toInt())
    private val tick = object : Runnable {
        override fun run() { if (running) { invalidate(); postDelayed(this, 50L) } }
    }
    init { importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO; isFocusable = false }
    fun setRunning(value: Boolean) {
        if (running == value) return
        running = value; removeCallbacks(tick)
        if (value) { started = SystemClock.uptimeMillis(); post(tick) }
        invalidate()
    }
    override fun onDetachedFromWindow() { running = false; removeCallbacks(tick); super.onDetachedFromWindow() }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (!running || width == 0 || height == 0) return
        val seconds = (SystemClock.uptimeMillis()-started)/1000.0
        val unit = maxOf(1f, width/960f)
        for (i in 0 until 14) {
            val fall = (seconds*(.018+i%4*.004)+i*.137)%1.0
            val anchor = ((i*73)%101)/100f
            val x = anchor*width + (kotlin.math.sin(seconds*.7+i)*width*.025).toFloat()
            val y = (fall*(height+30)-15).toFloat()
            val size = unit*(2+i%3)
            canvas.save(); canvas.translate(x,y)
            canvas.rotate((kotlin.math.sin(seconds+i)*28).toFloat())
            paint.color = palette[i%palette.size]
            canvas.drawRect(-size,-size/2,size,size/2,paint)
            canvas.drawRect(-size/2,-size,size/2,size,paint)
            paint.color = 0xff4d6928.toInt()
            canvas.drawRect(-unit,0f,unit,size,paint)
            canvas.restore()
        }
    }
}

/** Lettres 5x7 originales, sans police ou logo extrait d'un jeu. */
class PixelTitle(context: Context) : View(context) {
    private val paint = Paint().apply { isAntiAlias = false }
    private val alphabet = mapOf(
        'C' to arrayOf("01111","10000","10000","10000","10000","10000","01111"),
        'i' to arrayOf("00100","00000","01100","00100","00100","00100","01110"),
        's' to arrayOf("00000","00000","01111","10000","01110","00001","11110"),
        'o' to arrayOf("00000","00000","01110","10001","10001","10001","01110"),
        'u' to arrayOf("00000","00000","10001","10001","10001","10011","01101"),
        '\'' to arrayOf("00100","00100","00000","00000","00000","00000","00000"),
        ' ' to arrayOf("00000","00000","00000","00000","00000","00000","00000"),
        'T' to arrayOf("11111","00100","00100","00100","00100","00100","00100"),
        'V' to arrayOf("10001","10001","10001","10001","10001","01010","00100")
    )
    private val title = "Cissou's TV"
    private val glyphs = title.map { alphabet.getValue(it) }
    init { contentDescription = title; importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES }
    override fun onDraw(canvas: Canvas) {
        val columns = glyphs.size*6-1
        val pixel = minOf(width/(columns+8f),height/10f)
        val left = (width-pixel*columns)/2f; val top = pixel/2
        for (layer in 2 downTo 0) {
            glyphs.forEachIndexed { index, glyph ->
                glyph.forEachIndexed { y, line -> line.forEachIndexed { x, value ->
                    if (value == '1') {
                        paint.color = when (layer) { 2 -> 0xff171b17.toInt(); 1 -> 0xff52594e.toInt(); else -> if ((x+y)%3 == 0) 0xffd1d5ca.toInt() else 0xffb7bfaf.toInt() }
                        val px = left+(index*6+x)*pixel+layer*pixel*.36f
                        val py = top+y*pixel+layer*pixel*.48f
                        canvas.drawRect(px,py,px+pixel+.3f,py+pixel+.3f,paint)
                    }
                } }
            }
        }
    }
}
