import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:isolate_json/isolate_json.dart';

enum IAPType {
  consumable,
  nonConsumable,
  subcriptionAutoRenew,
  subcriptionNonRenew
}

class FlutterInAppPurchase {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // bool _available = false;
  // List<ProductDetails> _products = [];
  // List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // void init({required List<String> productIds}) {
  //   final Stream<List<PurchaseDetails>> purchaseUpdated =
  //       _inAppPurchase.purchaseStream;

  //   _subscription =
  //       purchaseUpdated.listen((purchaseDetailsList) {}, onDone: () {
  //     _subscription?.cancel();
  //   }, onError: (error) {
  //     print('Purchase failed: ${error.toString()}');
  //     _subscription?.cancel();
  //   });
  // }

  Future<List<ProductDetails>?> _initialize(
      {required List<String> productIds}) async {
    bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('IAP is not available');
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition
          inAppPurchaseStoreKitPlatformAddition = _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await inAppPurchaseStoreKitPlatformAddition
          .setDelegate(IOSPaymentQueueDelegate());
    }

    ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds.toSet());
    if (response.error != null) {
      throw Exception(
          'Query Product Detail failed: ${response.error.toString()}');
    }

    return response.productDetails;
  }

  void _listenPurchaseProgress(String productId, IAPType iapType,
      Function(String productId) onSuccess, Function(String message) onError) {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      __listenToPurchaseUpdated(
          purchaseDetailsList, productId, iapType, onSuccess, onError);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      onError('Purchase failed: ${error.toString()}');
      _subscription?.cancel();
    });
  }

  void __listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList,
      String productId,
      IAPType iapType,
      Function(String productId) onSuccess,
      Function(String message) onError) async {
    final purchaseDetail = purchaseDetailsList
        .firstWhereOrNull((purchase) => purchase.productID == productId);
    if (purchaseDetail != null) {
      switch (purchaseDetail.status) {
        case PurchaseStatus.pending:
          print('Purchase pending');
          break;
        case PurchaseStatus.canceled:
          onError('Purchase is canceled');
          break;
        case PurchaseStatus.error:
          onError('Purchase failed: Unknow error');
          break;
        default: // purchased and restored
          final validPurchase = await _verifyPurchase(purchaseDetail, iapType);
          if (validPurchase) {
            onSuccess(productId);
          } else {
            onError('Purchase invalid');
          }
          if (Platform.isAndroid && iapType == IAPType.consumable) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                _inAppPurchase.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetail);
          }
          if (purchaseDetail.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetail);
          }
          break;
      }
    } else {
      onError('Purchase failed: Not found purchase');
    }
  }

  Future<bool> _verifyPurchase(
      PurchaseDetails purchaseDetail, IAPType iapType) async {
    final verificationData =
        purchaseDetail.verificationData.serverVerificationData;
    // print('Verification Data: $verificationData');

    final Dio dio = Dio();
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers['Content-Type'] = 'application/json';

    final Map<String, dynamic> data = {
      'receipt-data': verificationData,
      'password': '1092491634264995ab5aad63d6f53de7'
    };

    if (iapType == IAPType.subcriptionAutoRenew) {
      data['exclude-old-transactions'] = true;
    }

    final body = await JsonIsolate().encodeJson(data);

    final response = await dio
        .post('https://sandbox.itunes.apple.com/verifyReceipt', data: body);
    // Url Product : https://buy.itunes.apple.com/verifyReceipt

    /// Todo: parse data verify purchase

    return Future<bool>.value(true);
  }

  void buyProduct(
      {required IAPType iapType,
      required ProductDetails productDetails,
      required Function(String productId) onSuccess,
      required Function(String message) onError}) {
    late PurchaseParam purchaseParam;
    _listenPurchaseProgress(productDetails.id, iapType, onSuccess, onError);
    if (Platform.isAndroid) {
      // final GooglePlayPurchaseDetails? oldSubscription = _getOldSubscription(productDetails, purchases);
      GooglePlayPurchaseDetails? oldSubscription;
      purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          applicationUserName: null,
          changeSubscriptionParam: (oldSubscription != null)
              ? ChangeSubscriptionParam(
                  oldPurchaseDetails: oldSubscription,
                  prorationMode: ProrationMode.immediateWithTimeProration,
                )
              : null);
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
    }

    if (iapType == IAPType.consumable) {
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // GooglePlayPurchaseDetails? _getOldSubscription(
  //     ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
  //   // This is just to demonstrate a subscription upgrade or downgrade.
  //   // This method assumes that you have only 2 subscriptions under a group, 'subscription_silver' & 'subscription_gold'.
  //   // The 'subscription_silver' subscription can be upgraded to 'subscription_gold' and
  //   // the 'subscription_gold' subscription can be downgraded to 'subscription_silver'.
  //   // Please remember to replace the logic of finding the old subscription Id as per your app.
  //   // The old subscription is only required on Android since Apple handles this internally
  //   // by using the subscription group feature in iTunesConnect.
  //   GooglePlayPurchaseDetails? oldSubscription;
  //   if (productDetails.id == _kSilverSubscriptionId &&
  //       purchases[_kGoldSubscriptionId] != null) {
  //     oldSubscription =
  //         purchases[_kGoldSubscriptionId]! as GooglePlayPurchaseDetails;
  //   } else if (productDetails.id == _kGoldSubscriptionId &&
  //       purchases[_kSilverSubscriptionId] != null) {
  //     oldSubscription =
  //         purchases[_kSilverSubscriptionId]! as GooglePlayPurchaseDetails;
  //   }
  //   return oldSubscription;
  // }

  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription?.cancel();
  }
}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.
class IOSPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
