import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class RedeemCoupon extends StatefulWidget {
  final String uid;

  const RedeemCoupon({Key? key, required this.uid}) : super(key: key);

  @override
  _RedeemCouponState createState() => _RedeemCouponState();
}

class _RedeemCouponState extends State<RedeemCoupon> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _couponCodeController = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  List<Map<String, dynamic>> _deals = [];
  String? _selectedDealId;
  Barcode? result;
  QRViewController? _controller;

  @override
  void initState() {
    super.initState();
    fetchDeals();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> fetchDeals() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Deals')
          .where('uid', isEqualTo: widget.uid)
          .get();

      setState(() {
        _deals = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'data': doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching deals: $e');
    }
  }

  Future<void> redeemCoupon(String couponCode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Coupons')
          .where('Coupon Code', isEqualTo: couponCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot couponDoc = snapshot.docs.first;

        await couponDoc.reference.update({'Status': 'redeemed'});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon redeemed successfully!')),
        );

        _couponCodeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coupon code.')),
        );
      }
    } catch (e) {
      print('Error redeeming coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to redeem coupon: $e')),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _couponCodeController.text = result!.code!;
        controller.pauseCamera();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Redeem Coupon', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_deals.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Select a Deal'),
                value: _selectedDealId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDealId = newValue;
                  });
                },
                items: _deals.map<DropdownMenuItem<String>>((Map<String, dynamic> deal) {
                  return DropdownMenuItem<String>(
                    value: deal['id'],
                    child: Text(deal['data']['Coupon Name']), // Display the deal name in the combo box
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Coupon Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Redeem Coupon', style: TextStyle(color: Colors.white)),
              onPressed: () {
                redeemCoupon(_couponCodeController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SizedBox(
                    height: 300,
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                  ),
                ).whenComplete(() => _controller?.resumeCamera());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
