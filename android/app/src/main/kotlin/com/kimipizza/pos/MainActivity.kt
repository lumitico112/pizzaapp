package com.kimipizza.pos

import io.flutter.embedding.android.FlutterFragmentActivity

// FS-11: el acceso rápido con huella (local_auth) exige que la actividad sea
// una FlutterFragmentActivity y que su tema derive de Theme.AppCompat
// (ver android/app/src/main/res/values/styles.xml).
class MainActivity : FlutterFragmentActivity()
