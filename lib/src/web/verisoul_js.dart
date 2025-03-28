import 'dart:js_interop';

@JS('Verisoul') // Assuming the JS SDK exposes a global `Verisoul` object
@staticInterop
class VerisoulJS {
  external static JSPromise<JSObject>? session();
  external static JSPromise<JSAny> reinitialize();
  external static JSPromise<JSAny> account(JSObject account);
}
