import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryScreen extends StatefulWidget {
  final String region;
  const InventoryScreen({Key? key, required this.region}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regionController = TextEditingController();
  final _itemController = TextEditingController();
  final _serviceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  List<dynamic> _inventory = [];
  Map<String, dynamic>? _serviceDetails;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showInventory = true;
  String? _checkoutRequestId;

  static const String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _regionController.text = widget.region;
  }

  @override
  void dispose() {
    _regionController.dispose();
    _itemController.dispose();
    _serviceController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_showInventory) {
        await _fetchInventory();
      } else {
        await _fetchService();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInventory() async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/inventory'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (_regionController.text.isNotEmpty)
              'region': _regionController.text,
            if (_itemController.text.isNotEmpty) 'item': _itemController.text,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      if (decodedResponse is Map<String, dynamic> &&
          decodedResponse.containsKey('inventory')) {
        setState(() {
          _inventory = decodedResponse['inventory'] as List<dynamic>;
          _serviceDetails = null;
          _isLoading = false;
        });
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load inventory: ${response.statusCode}');
    }
  }

  Future<void> _fetchService() async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/services'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'region': _regionController.text,
            'service': _serviceController.text,
            if (_categoryController.text.isNotEmpty)
              'category': _categoryController.text,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      setState(() {
        _serviceDetails = decodedResponse;
        _inventory = [];
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load service: ${response.statusCode}');
    }
  }

  void _initiatePayment(String name, double cost, [int? availableStock]) {
    _phoneController.clear();
    if (_showInventory) _quantityController.text = '1';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Purchase ${_showInventory ? 'Item' : 'Service'}'),
            content: SingleChildScrollView(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showInventory ? 'Item: $name' : 'Service: $name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: KES ${cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (_showInventory && availableStock != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Available Stock: $availableStock',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (!_showInventory && _serviceDetails != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Insurance Copay: KES ${(_serviceDetails!['insurance_copay_kes'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NHIF Covered: ${_serviceDetails!['nhif_covered'] == true ? 'Yes' : 'No'}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_showInventory)
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter quantity',
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.shopping_cart),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Please enter a valid quantity';
                          }
                          if (availableStock != null && qty > availableStock) {
                            return 'Quantity exceeds available stock ($availableStock)';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '254712345678',
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (!value.startsWith('254') || value.length != 12) {
                          return 'Enter a valid Kenyan number (e.g., 254712345678)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _quantityController,
                      builder: (context, value, child) {
                        final qty =
                            _showInventory
                                ? (int.tryParse(value.text) ?? 1)
                                : 1;
                        final totalCost = qty * cost;
                        return Text(
                          'Total Cost: KES ${totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (Form.of(context).validate()) {
                    final qty =
                        _showInventory
                            ? int.parse(_quantityController.text)
                            : 1;
                    Navigator.pop(context);
                    _processPayment(name, cost * qty, _phoneController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pay with M-Pesa'),
              ),
            ],
          ),
    );
  }

  Future<void> _processPayment(
    String name,
    double totalCost,
    String phone,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initiating M-Pesa payment...'),
              ],
            ),
          ),
    );

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/mpesa/stk-push'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': phone,
              'amount': totalCost.toInt(),
              'item_name': name,
              'reference': 'INV-${DateTime.now().millisecondsSinceEpoch}',
            }),
          )
          .timeout(const Duration(seconds: 30));

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            _checkoutRequestId = responseData['checkout_request_id'];
          });
          _showPaymentStatusDialog(
            'Payment Initiated',
            'Please check your phone for M-Pesa prompt and enter your PIN to complete the payment.',
            Icons.phone_android,
            Colors.green,
            _checkoutRequestId,
          );
        } else {
          _showPaymentStatusDialog(
            'Payment Failed',
            responseData['message'] ?? 'Failed to initiate payment',
            Icons.error,
            Colors.red,
            null,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showPaymentStatusDialog(
          'Payment Failed',
          errorData['error'] ?? 'Failed to process payment',
          Icons.error,
          Colors.red,
          null,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showPaymentStatusDialog(
        'Connection Error',
        'Failed to connect to payment service: $e',
        Icons.wifi_off,
        Colors.red,
        null,
      );
    }
  }

  void _showPaymentStatusDialog(
    String title,
    String message,
    IconData icon,
    Color color,
    String? checkoutRequestId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (checkoutRequestId != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Transaction ID: $checkoutRequestId',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              if (checkoutRequestId != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _checkPaymentStatus(checkoutRequestId);
                  },
                  child: const Text('Check Status'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _checkPaymentStatus(String checkoutRequestId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking payment status...'),
              ],
            ),
          ),
    );

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/mpesa/check-status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'checkout_request_id': checkoutRequestId}),
          )
          .timeout(const Duration(seconds: 15));

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        String statusTitle;
        String statusMessage;
        IconData statusIcon;
        Color statusColor;

        switch (responseData['status']) {
          case 'SUCCESS':
            statusTitle = 'Payment Successful';
            statusMessage =
                'Your payment has been completed successfully!\nTransaction ID: ${responseData['mpesa_receipt_number']}';
            statusIcon = Icons.check_circle;
            statusColor = Colors.green;
            break;
          case 'FAILED':
            statusTitle = 'Payment Failed';
            statusMessage =
                responseData['message'] ?? 'Payment was not completed';
            statusIcon = Icons.error;
            statusColor = Colors.red;
            break;
          case 'PENDING':
            statusTitle = 'Payment Pending';
            statusMessage =
                'Payment is still being processed. Please wait or check again later.';
            statusIcon = Icons.pending;
            statusColor = Colors.orange;
            break;
          default:
            statusTitle = 'Unknown Status';
            statusMessage = 'Could not determine payment status';
            statusIcon = Icons.help;
            statusColor = Colors.grey;
        }

        _showPaymentStatusDialog(
          statusTitle,
          statusMessage,
          statusIcon,
          statusColor,
          null,
        );
      } else {
        _showPaymentStatusDialog(
          'Status Check Failed',
          'Could not check payment status. Please try again.',
          Icons.error,
          Colors.red,
          null,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showPaymentStatusDialog(
        'Connection Error',
        'Failed to check payment status: $e',
        Icons.wifi_off,
        Colors.red,
        null,
      );
    }
  }

  Widget _buildInventoryList() {
    return _inventory.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No inventory data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter search criteria and tap "Fetch Data"',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _inventory.length,
          itemBuilder: (context, index) {
            final item = _inventory[index];
            final availableStock =
                item['Available Stock'] != null
                    ? int.tryParse(item['Available Stock'].toString()) ?? 0
                    : 0;
            final cost =
                item['Cost (KES)'] != null
                    ? double.tryParse(item['Cost (KES)'].toString()) ?? 0.0
                    : 0.0;
            final itemName = item['Item']?.toString() ?? 'Unknown Item';
            final region = item['Region']?.toString() ?? 'N/A';
            final facility = item['Facility']?.toString() ?? '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('Stock: $availableStock'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('KES ${cost.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(facility),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.map, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(region),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed:
                            availableStock > 0
                                ? () => _initiatePayment(
                                  itemName,
                                  cost,
                                  availableStock,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff6b9d),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Purchase'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildServiceDetails() {
    return _serviceDetails == null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No service data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter service details and tap "Fetch Data"',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        )
        : Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _serviceDetails!['service'] ?? 'Service',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceDetailRow(
                    Icons.location_city,
                    'Facility',
                    _serviceDetails!['facility'],
                  ),
                  _buildServiceDetailRow(
                    Icons.map,
                    'Region',
                    _serviceDetails!['region'],
                  ),
                  _buildServiceDetailRow(
                    Icons.category,
                    'Category',
                    _serviceDetails!['category'],
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildServiceDetailRow(
                    Icons.attach_money,
                    'Base Cost',
                    'KES ${(_serviceDetails!['base_cost_kes'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                  ),
                  _buildServiceDetailRow(
                    Icons.payment,
                    'Out of Pocket',
                    'KES ${(_serviceDetails!['out_of_pocket_kes'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                  ),
                  _buildServiceDetailRow(
                    Icons.health_and_safety,
                    'Insurance Copay',
                    'KES ${(_serviceDetails!['insurance_copay_kes'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                  ),
                  _buildServiceDetailRow(
                    Icons.verified_user,
                    'NHIF Covered',
                    _serviceDetails!['nhif_covered'] == true ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => _initiatePayment(
                            _serviceDetails!['service'],
                            (_serviceDetails!['out_of_pocket_kes'] as num)
                                .toDouble(),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFff6b9d),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Pay for Service',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildServiceDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(value ?? 'N/A', style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '23:33',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: ToggleButtons(
              isSelected: [_showInventory, !_showInventory],
              onPressed: (index) {
                setState(() {
                  _showInventory = index == 0;
                  _inventory = [];
                  _serviceDetails = null;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Inventory'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Services'),
                ),
              ],
              borderRadius: BorderRadius.circular(20),
              selectedColor: Colors.white,
              fillColor: const Color(0xFFff6b9d),
              color: const Color(0xFFff6b9d),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
            ),
          ),
          const Text(
            '🔋 100%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showInventory ? 'Search Inventory' : 'Search Services',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regionController,
                  decoration: InputDecoration(
                    labelText: 'Region',
                    hintText: 'e.g., ${widget.region}',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    prefixIcon: const Icon(Icons.location_city),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a region';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_showInventory)
                  TextFormField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'Item Name (Optional)',
                      hintText: 'e.g., Pap Smear Kit',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      prefixIcon: const Icon(Icons.inventory),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  )
                else
                  Column(
                    children: [
                      TextFormField(
                        controller: _serviceController,
                        decoration: InputDecoration(
                          labelText: 'Service',
                          hintText: 'e.g., Referral Specialist Visit',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: const Icon(Icons.medical_services),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a service';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category (Optional)',
                          hintText: 'e.g., Consultation',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: const Icon(Icons.category),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff6b9d),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _showInventory
                                  ? 'Fetch Inventory'
                                  : 'Find Service',
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
          ),
        ),
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () => setState(() => _errorMessage = null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFff6b9d),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          _buildForm(),
                          Expanded(
                            child:
                                _showInventory
                                    ? _buildInventoryList()
                                    : _buildServiceDetails(),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
