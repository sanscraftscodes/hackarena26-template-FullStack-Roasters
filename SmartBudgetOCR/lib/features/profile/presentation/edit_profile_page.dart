import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../models/user_profile.dart';
import '../data/profile_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _incomeController;
  late TextEditingController _budgetController;

  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _incomeController = TextEditingController();
    _budgetController = TextEditingController();

    // Initialize with existing data if available
    final existingProfileAsync = ref.read(userProfileProvider);
    final user = ServiceLocator.auth.currentUser;

    existingProfileAsync.whenData((profile) {
      if (profile != null) {
        _nameController.text = profile.fullName ?? user?.displayName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        _incomeController.text = profile.income?.toString() ?? '';
        _budgetController.text = profile.monthlyBudget?.toString() ?? '';
        _birthDate = profile.birthDate;
      } else {
        _nameController.text = user?.displayName ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _incomeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = ServiceLocator.auth.currentUser;

    if (user != null) {
      try {
        final profile = UserProfile(
          id: user.uid,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          birthDate: _birthDate,
          income: double.tryParse(_incomeController.text.trim()),
          monthlyBudget: double.tryParse(_budgetController.text.trim()),
        );

        // Save to Firestore
        await ServiceLocator.firestore.saveUserProfile(user.uid, profile);

        // Update Firebase Auth Display Name if changed
        if (user.displayName != profile.fullName && profile.fullName != null && profile.fullName!.isNotEmpty) {
           await user.updateDisplayName(profile.fullName);
        }

        // Provider will emit updated profile via Firestore stream automatically.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
          if (mounted) context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: $e')),
          );
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('Personal Information'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppTokens.s16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTokens.s16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birth Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Select Date'
                            : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s32),
                  _buildSectionHeader('Financial Information'),
                  TextFormField(
                    controller: _incomeController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Income',
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  TextFormField(
                    controller: _budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Budget Limit',
                      prefixIcon: Icon(Icons.savings_outlined),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppTokens.s32),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }
}
