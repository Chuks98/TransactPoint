import 'package:flutter/material.dart';
import 'package:transact_point/services/admin-api-services.dart';
import '../models/saving-plan.dart';

class AdminSavingsPlanForm extends StatefulWidget {
  final Plan? existing;
  final void Function(bool ok) onSaved;
  const AdminSavingsPlanForm({super.key, this.existing, required this.onSaved});

  @override
  State<AdminSavingsPlanForm> createState() => _AdminSavingsPlanFormState();
}

class _AdminSavingsPlanFormState extends State<AdminSavingsPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final AdminService api = AdminService();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _rateCtrl;

  String _interestType = "simple";
  bool _withInterest = false;
  bool _isLocked = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? "");
    _descCtrl = TextEditingController(text: e?.description ?? "");
    _minCtrl = TextEditingController(text: e?.minAmount.toString() ?? "");
    _maxCtrl = TextEditingController(text: e?.maxAmount?.toString() ?? "");
    _durationCtrl = TextEditingController(
      text: e?.durationMonths.toString() ?? "",
    );
    _rateCtrl = TextEditingController(text: e?.interestRate.toString() ?? "");
    _interestType = e?.interestType ?? "simple";
    _withInterest = e?.withInterest ?? true;
    _isLocked = e?.isLocked ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "name": _nameCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "min_amount": double.tryParse(_minCtrl.text) ?? 0,
      "max_amount":
          _maxCtrl.text.isNotEmpty ? double.tryParse(_maxCtrl.text) : null,
      "duration_months": int.tryParse(_durationCtrl.text) ?? 0,
      "interest_rate": double.tryParse(_rateCtrl.text) ?? 0,
      "interest_type": _interestType,
      "with_interest": _withInterest,
      "is_locked": _isLocked,
    };

    setState(() => _loading = true);

    bool ok;
    if (widget.existing == null) {
      ok = await api.createPlan(context, body);
    } else {
      ok = await api.updatePlan(context, widget.existing!.id, body);
    }

    setState(() => _loading = false);
    widget.onSaved(ok);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Basic Info ----------
            SizedBox(height: 30),
            const Text(
              "Basic Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Plan Name",
                prefixIcon: Icon(Icons.title),
              ),
              validator:
                  (v) => v == null || v.isEmpty ? "Enter plan name" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Description",
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // ---------- Amounts ----------
            const Text(
              "Amounts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Min Amount",
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Max Amount",
                      prefixIcon: Icon(Icons.arrow_upward),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Duration (months, 0 = flexible)",
                prefixIcon: Icon(Icons.calendar_month),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- Interest ----------
            const Text(
              "Interest Options",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("With Interest"),
              value: _withInterest,
              onChanged: (v) => setState(() => _withInterest = v),
            ),
            if (_withInterest) ...[
              TextFormField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Interest Rate (%)",
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _interestType,
                decoration: const InputDecoration(
                  labelText: "Interest Type",
                  prefixIcon: Icon(Icons.timeline),
                ),
                items: const [
                  DropdownMenuItem(value: "simple", child: Text("Simple")),
                  DropdownMenuItem(value: "compound", child: Text("Compound")),
                ],
                onChanged: (v) => setState(() => _interestType = v!),
              ),
            ],

            const SizedBox(height: 20),

            // ---------- Restrictions ----------
            const Text(
              "Restrictions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Locked Plan (no early withdrawal)"),
              value: _isLocked,
              onChanged: (v) => setState(() => _isLocked = v),
            ),

            const SizedBox(height: 30),

            // ---------- Save Button ----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _loading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(
                  widget.existing == null ? "Create Plan" : "Update Plan",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _save,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
