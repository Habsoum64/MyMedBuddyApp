import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';

class MedicationSelectionForm extends StatefulWidget {
  final Medication? medication;
  final Function(Medication medication, String? catalogId) onSave;

  const MedicationSelectionForm({
    super.key,
    this.medication,
    required this.onSave,
  });

  @override
  State<MedicationSelectionForm> createState() => _MedicationSelectionFormState();
}

class _MedicationSelectionFormState extends State<MedicationSelectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  // Selection mode: 'catalog' or 'custom'
  String _selectionMode = 'catalog';
  
  // Selected medication from catalog
  Map<String, dynamic>? _selectedCatalogMedication;
  
  // Custom medication fields
  final _customNameController = TextEditingController();
  String _customCategory = 'General';
  
  // Common fields
  String _frequency = 'Once daily';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  
  // Search results for catalog
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchTimer;

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'As needed',
  ];

  final List<String> _categories = [
    'General',
    'Pain Relief',
    'Diabetes',
    'Blood Pressure',
    'Heart',
    'Mental Health',
    'Supplement',
    'Antibiotic',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _dosageController.text = widget.medication?.dosage ?? '';
    _instructionsController.text = widget.medication?.instructions ?? '';
    
    if (widget.medication != null) {
      _frequency = widget.medication!.frequency;
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _times = widget.medication!.times.map((timeString) {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
    
    // Load catalog when form initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<MedicationProvider>().loadMedicationCatalog();
        // Initialize search results with full catalog
        if (mounted) {
          setState(() {
            _searchResults = context.read<MedicationProvider>().medicationCatalog;
          });
        }
      } catch (e) {
        print('Error loading medication catalog: $e');
      }
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _searchCatalog(String query) async {
    // Cancel previous search timer
    _searchTimer?.cancel();
    
    // If query is empty, show all catalog items
    if (query.isEmpty) {
      setState(() {
        _searchResults = context.read<MedicationProvider>().medicationCatalog;
        _isSearching = false;
      });
      return;
    }
    
    // Show loading indicator immediately
    setState(() {
      _isSearching = true;
    });
    
    // Debounce search with 300ms delay
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await context.read<MedicationProvider>().searchMedicationsCatalog(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _selectCatalogMedication(Map<String, dynamic> medication) {
    setState(() {
      _selectedCatalogMedication = medication;
      _searchController.text = medication['name'];
    });
  }

  void _addTime() {
    setState(() {
      _times.add(const TimeOfDay(hour: 8, minute: 0));
    });
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (newTime != null) {
      setState(() {
        _times[index] = newTime;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      String medicationName;
      String category;
      String? medicationId;
      
      if (_selectionMode == 'catalog' && _selectedCatalogMedication != null) {
        medicationName = _selectedCatalogMedication!['name'];
        category = _selectedCatalogMedication!['category'] ?? 'General';
        medicationId = _selectedCatalogMedication!['id'];
      } else {
        medicationName = _customNameController.text;
        category = _customCategory;
        medicationId = null;
      }
      
      final medication = Medication(
        id: widget.medication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: medicationName,
        dosage: _dosageController.text,
        frequency: _frequency,
        category: category,
        instructions: _instructionsController.text,
        startDate: _startDate,
        endDate: _endDate,
        times: _times.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList(),
        isActive: true,
      );
      
      // Pass medicationId as additional data to the save callback
      widget.onSave(medication, medicationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection mode toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Medication Source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<String>(
                          title: const Text(
                            'From Catalog',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            'Select from our medication database',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          value: 'catalog',
                          groupValue: _selectionMode,
                          onChanged: (value) {
                            setState(() {
                              _selectionMode = value!;
                              _selectedCatalogMedication = null;
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<String>(
                          title: const Text(
                            'Custom Medication',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text(
                            'Add unlisted medication manually',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          value: 'custom',
                          groupValue: _selectionMode,
                          onChanged: (value) {
                            setState(() {
                              _selectionMode = value!;
                              _selectedCatalogMedication = null;
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Medication selection/input
          if (_selectionMode == 'catalog') ...[
            // Catalog search
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Medications',
                hintText: 'Type medication name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching) 
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchCatalog,
              validator: (value) {
                if (_selectedCatalogMedication == null) {
                  return 'Please select a medication from the catalog';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            // Search results or initial catalog display
            if (_searchResults.isNotEmpty || _searchController.text.isEmpty) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _searchResults.isEmpty && _searchController.text.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSearching) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text('Loading medications...'),
                          ] else ...[
                            const Icon(Icons.medication, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('Start typing to search medications'),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final medication = _searchResults[index];
                        final isSelected = _selectedCatalogMedication?['id'] == medication['id'];
                        
                        return ListTile(
                          title: Text(medication['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${medication['type']} • ${medication['category']}'),
                              if (medication['description']?.isNotEmpty == true)
                                Text(
                                  medication['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          selected: isSelected,
                          onTap: () => _selectCatalogMedication(medication),
                        );
                      },
                    ),
              ),
            ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
              // No results message
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No medications found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Selected medication details
            if (_selectedCatalogMedication != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedCatalogMedication!['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Type: ${_selectedCatalogMedication!['type']}'),
                      Text('Category: ${_selectedCatalogMedication!['category']}'),
                      if (_selectedCatalogMedication!['description']?.isNotEmpty == true)
                        Text('Description: ${_selectedCatalogMedication!['description']}'),
                      if (_selectedCatalogMedication!['sideEffects']?.isNotEmpty == true)
                        Text('Side Effects: ${_selectedCatalogMedication!['sideEffects']}'),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            // Custom medication input
            TextFormField(
              controller: _customNameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'Enter medication name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _customCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _customCategory = value!;
                });
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Common fields
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Dosage',
              hintText: 'e.g., 500mg, 1 tablet',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter dosage';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(
              labelText: 'Frequency',
              border: OutlineInputBorder(),
            ),
            items: _frequencies.map((frequency) {
              return DropdownMenuItem<String>(
                value: frequency,
                child: Text(frequency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _frequency = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Times section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medication Times',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addTime,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._times.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(index),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  time.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          if (_times.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeTime(index),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              labelText: 'Instructions',
              hintText: 'e.g., Take with food, Take before bed',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Date selection
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    setState(() {
                      _endDate = date;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'No end date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Save Medication'),
            ),
          ),
        ],
      ),
    );
  }
}
