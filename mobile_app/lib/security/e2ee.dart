import 'dart:typed_data';

import 'package:webcrypto/webcrypto.dart';

class End2EndEncryption {
  static final Uint8List iv =
      Uint8List.fromList('Initialization Vector'.codeUnits);
  static Future<List<Map<String, dynamic>>> generateKeys() async {
    //1. Generate keys
    KeyPair<EcdhPrivateKey, EcdhPublicKey> keyPair =
        await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    Map<String, dynamic> publicKeyJwk =
        await keyPair.publicKey.exportJsonWebKey();
    Map<String, dynamic> privateKeyJwk =
        await keyPair.privateKey.exportJsonWebKey();

    return [publicKeyJwk, privateKeyJwk];
  }

  static Future<Uint8List> returnDerivedBits(Map<String, dynamic> peerPublicKey,
      Map<String, dynamic> privateKeyJwk) async {
    EcdhPublicKey ecdhPublicKey =
        await EcdhPublicKey.importJsonWebKey(peerPublicKey, EllipticCurve.p256);

    EcdhPrivateKey ecdhPrivateKey = await EcdhPrivateKey.importJsonWebKey(
        privateKeyJwk, EllipticCurve.p256);

    Uint8List derivedBits = await ecdhPrivateKey.deriveBits(256, ecdhPublicKey);

    return derivedBits;
  }

  static Future<String> encryption(
      List<int> derivedBits, String message) async {
    List<int> list = message.codeUnits;
    Uint8List data = Uint8List.fromList(list);
    var aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits);
    Uint8List encryptedBytes = await aesGcmSecretKey.encryptBytes(data, iv);

    String encryptedString = String.fromCharCodes(encryptedBytes);
    print('encryptedString $encryptedString');
    return encryptedString;
  }

  static Future<String> decryption(
      AesGcmSecretKey aesGcmSecretKey, String encryptedMessage) async {
   

    List<int> message = Uint8List.fromList(encryptedMessage.codeUnits);

    Uint8List decryptdBytes = await aesGcmSecretKey.decryptBytes(message, iv);

    String decryptdString = String.fromCharCodes(decryptdBytes);
    print('decryptdString $decryptdString');
    return decryptdString;
  }
}
