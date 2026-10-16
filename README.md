# TokTik

App estilo TikTok hecha sobre el proyecto del curso. Tiene cuenta con correo y contraseña, un feed compartido, likes y subida de videos. El feed pagina de 5 en 5 y los 8 videos locales quedan al final, como contenido inicial.

## Videos locales

`assets/videos` está vacía a propósito: los mp4 no van en git.

Descargá **8 videos verticales** (9:16) desde [Pexels](https://www.pexels.com/search/videos/vertical/). Cualquier clip corto sirve. Renombralos exactamente así y dejalos en `assets/videos/`:

```text
assets/videos/1.mp4
assets/videos/2.mp4
assets/videos/3.mp4
assets/videos/4.mp4
assets/videos/5.mp4
assets/videos/6.mp4
assets/videos/7.mp4
assets/videos/8.mp4
```

Las descripciones del código, por si querés clips parecidos: escaleras, una planta, algo borroso, trigo, un barbijo, alguien que no quiere trabajar, limpieza, un viaje. No subas esos archivos.

## Qué ya quedó hecho en Firebase

El proyecto **TokTik clase 23** (`toktik-clase23-s8`) está creado en la cuenta de Google con la que el CLI ya estaba logueado. `flutterfire configure` registró la app Android `com.example.toktik` y generó, solo en esta máquina:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Esos archivos están en `.gitignore`. No los subas. Tampoco subas un JSON de cuenta de servicio ni el API Secret de Cloudinary. `.firebaserc` solo guarda el id del proyecto.

Si en una terminal nueva `firebase` o `flutterfire` no se reconocen, agregá al PATH `%APPDATA%\npm` y `%LOCALAPPDATA%\Pub\Cache\bin`.

La app tiene que correr en un **emulador Android**. En Windows de escritorio Firebase no está configurado.

## Lo que tenés que hacer vos en la consola

La API de Firestore está apagada y el CLI no puede encenderla ni activar el login con correo sin una confirmación tuya en el navegador.

1. Activá Cloud Firestore: [habilitar la API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=toktik-clase23-s8). Apretá **Enable** y esperá un minuto.
2. Creá la base. En [Firestore](https://console.firebase.google.com/project/toktik-clase23-s8/firestore) elegí **Create database**, modo producción y la región `southamerica-east1`. No la cambies después.
3. Activá el correo. En [Authentication → Sign-in method](https://console.firebase.google.com/project/toktik-clase23-s8/authentication/providers) abrí **Email/Password**, activalo y guardá. Sin esto el registro dice que el método no está habilitado.
4. No actives Storage si seguís en el plan Spark. Más abajo está el porqué.
5. Cuando la base exista, en `tiktok_clase23` publicá las reglas:

```powershell
firebase deploy --only firestore:rules
```

Si preferís crear la base desde la terminal, después del paso 1:

```powershell
firebase firestore:databases:create "(default)" --location southamerica-east1 --project toktik-clase23-s8
firebase deploy --only firestore:rules
```

### Storage pide el plan Blaze

En un proyecto nuevo, **Firebase Storage no está en el plan gratis (Spark)**. Hace falta pasar a **Blaze** (pago por uso, con una cuota gratuita, pero pide tarjeta).

Por eso la subida activa es **Cloudinary**, que tiene un plan gratis. El código de Firebase Storage ya está: `FirebaseVideoStorage` sube a `videos/{uid}/{archivo}` con la barra de progreso. Si más adelante pasás a Blaze:

1. En la consola: **Upgrade → Blaze**, después **Build → Storage → Get started**.
2. En `lib/config/upload_settings.dart` cambiá el backend a `VideoUploadBackend.firebaseStorage`.
3. Publicá también las reglas del bucket:

```powershell
firebase deploy --only storage
```

## Cloudinary (plan gratis, es lo que usa la app ahora)

1. Creá una cuenta en [cloudinary.com/users/register_free](https://cloudinary.com/users/register_free).
2. En el dashboard copiá el **Cloud name**.
3. **Settings → Upload → Add upload preset**.
   - Signing mode: **Unsigned**.
   - Preset name: `toktik_unsigned` (u otro; anotalo).
   - Resource type: **Video** o **Auto**.
4. No copies el **API Secret** a la app ni al repositorio. El preset unsigned está pensado para el cliente; el secret no.
5. Copiá el ejemplo y completá tus valores:

```powershell
copy dart_defines.example.json dart_defines.json
```

`dart_defines.json` también está en `.gitignore`.

## Cómo correrla

Desde `tiktok_clase23`, con un emulador Android encendido:

```powershell
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

Sin ese archivo la app abre, pero al publicar un video avisa que falta Cloudinary.

Comprobaciones de código:

```powershell
flutter analyze
flutter test
```

## Qué probar con dos cuentas

Un emulador alcanza: cerrás sesión y entrás con la otra. Si querés verlas a la vez, abrí dos emuladores.

1. Registrate como `ana@test.com` (contraseña de al menos 6 caracteres). El teclado debe pasar de correo a contraseña con **Next** y enviar con **Done**. Probá dejar los campos vacíos: el formulario muestra el error y no llama a Firebase.
2. Subí un video corto desde la **galería** (en el emulador la cámara suele fallar). Poné una descripción. Tiene que verse la barra de progreso y, al terminar, el video al inicio del feed.
3. Deslizá. Los videos de Firestore van primero, los más nuevos arriba. Cuando faltan unos 2, se pide la página siguiente (de 5 en 5) y aparece un indicador. No debería disparar dos cargas juntas. Al final de todo lo remoto están los 8 clips locales, si los copiaste.
4. Tocá el corazón. Se pone rojo y el contador sube. Volvé a tocarlo: se quita. En un video local (`TokTik`) el corazón avisa que ese ejemplo no se puede likear.
5. Cerrá sesión. Entrá como `bruno@test.com`. El video de Ana tiene que estar. Bruno puede darle like; el número cambia para los dos.
6. Salí y volvé a entrar como Ana. El like de Bruno sigue. Cada cuenta solo crea el like con su propio uid (`videos/{id}/likes/{uid}`).
7. Probá sin red (modo avión): la carga o el like deben mostrar un mensaje claro, no una pantalla congelada.

El corazón de un video remoto usa una transacción: crea o borra `videos/{id}/likes/{uid}` y suma o resta `likes` en el mismo paso.

## Reglas

- Firestore: solo un usuario autenticado lee. Solo el dueño crea o borra su video, y solo puede editar caption y nombre. El contador de likes cambia de a uno y únicamente si existe (o se borró) el like de esa persona.
- Storage (cuando uses Blaze): solo autenticados leen. Solo el dueño escribe en `videos/{su uid}/...`, videos de hasta 100 MB.

## Qué no subir

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `dart_defines.json` y cualquier `.env`
- los `.mp4` de `assets/videos`
- el API Secret de Cloudinary o una cuenta de servicio de Firebase
