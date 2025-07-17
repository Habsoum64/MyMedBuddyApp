import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/appointment.dart';

class CustomFormField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;

  const CustomFormField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
          ),
        ),
      ],
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T) getDisplayText;
  final String? hintText;

  const CustomDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    required this.getDisplayText,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(getDisplayText(item)),
          )).toList(),
        ),
      ],
    );
  }
}

class MedicationForm extends StatefulWidget {
  final Medication? medication;
  final Function(Medication) onSave;

  const MedicationForm({
    super.key,
    this.medication,
    required this.onSave,
  });

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;
  
  String _frequency = 'Once daily';
  String _category = 'General';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

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
    _nameController = TextEditingController(text: widget.medication?.name ?? '');
    _dosageController = TextEditingController(text: widget.medication?.dosage ?? '');
    _instructionsController = TextEditingController(text: widget.medication?.instructions ?? '');
    
    if (widget.medication != null) {
      _frequency = widget.medication!.frequency;
      _category = widget.medication!.category;
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _times = widget.medication!.times.map((timeString) {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomFormField(
            label: 'Medication Name',
            controller: _nameController,
            hintText: 'Enter medication name',
            validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Dosage',
            controller: _dosageController,
            hintText: 'e.g., 100mg, 2 tablets',
            validator: (value) => value?.isEmpty ?? true ? 'Dosage is required' : null,
          ),
          const SizedBox(height: 16),
          
          CustomDropdownField<String>(
            label: 'Frequency',
            value: _frequency,
            items: _frequencies,
            onChanged: (value) => setState(() => _frequency = value!),
            getDisplayText: (item) => item,
          ),
          const SizedBox(height: 16),
          
          CustomDropdownField<String>(
            label: 'Category',
            value: _category,
            items: _categories,
            onChanged: (value) => setState(() => _category = value!),
            getDisplayText: (item) => item,
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Instructions',
            controller: _instructionsController,
            hintText: 'Special instructions for taking this medication',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Times section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Times',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTime,
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
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Text(time.format(context)),
                          ),
                        ),
                      ),
                      if (_times.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _removeTime(index),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.medication == null ? 'Add Medication' : 'Update Medication',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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
    final time = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (time != null) {
      setState(() {
        _times[index] = time;
      });
    }
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final medication = Medication(
        id: widget.medication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        instructions: _instructionsController.text,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        times: _times.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList(),
      );
      
      widget.onSave(medication);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

class AppointmentForm extends StatefulWidget {
  final Appointment? appointment;
  final Function(Appointment) onSave;

  const AppointmentForm({
    super.key,
    this.appointment,
    required this.onSave,
  });

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _doctorController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  
  String _type = 'Checkup';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _appointmentTypes = [
    'Checkup',
    'Consultation',
    'Follow-up',
    'Surgery',
    'Test',
    'Vaccination',
    'Dental',
    'Eye Exam',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.appointment?.title ?? '');
    _descriptionController = TextEditingController(text: widget.appointment?.description ?? '');
    _doctorController = TextEditingController(text: widget.appointment?.doctorName ?? '');
    _locationController = TextEditingController(text: widget.appointment?.location ?? '');
    _notesController = TextEditingController(text: widget.appointment?.notes ?? '');
    
    if (widget.appointment != null) {
      _type = widget.appointment!.type;
      _selectedDate = DateTime(
        widget.appointment!.dateTime.year,
        widget.appointment!.dateTime.month,
        widget.appointment!.dateTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: widget.appointment!.dateTime.hour,
        minute: widget.appointment!.dateTime.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomFormField(
            label: 'Title',
            controller: _titleController,
            hintText: 'Enter appointment title',
            validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Description',
            controller: _descriptionController,
            hintText: 'Brief description of the appointment',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Doctor Name',
            controller: _doctorController,
            hintText: 'Enter doctor\'s name',
            validator: (value) => value?.isEmpty ?? true ? 'Doctor name is required' : null,
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Location',
            controller: _locationController,
            hintText: 'Hospital, clinic, or address',
            validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
          ),
          const SizedBox(height: 16),
          
          CustomDropdownField<String>(
            label: 'Type',
            value: _type,
            items: _appointmentTypes,
            onChanged: (value) => setState(() => _type = value!),
            getDisplayText: (item) => item,
          ),
          const SizedBox(height: 16),
          
          // Date and Time selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        width: double.infinity,
                        child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        width: double.infinity,
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomFormField(
            label: 'Notes (Optional)',
            controller: _notesController,
            hintText: 'Additional notes about the appointment',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.appointment == null ? 'Add Appointment' : 'Update Appointment',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      final appointment = Appointment(
        id: widget.appointment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        doctorName: _doctorController.text,
        location: _locationController.text,
        type: _type,
        dateTime: dateTime,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      widget.onSave(appointment);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
