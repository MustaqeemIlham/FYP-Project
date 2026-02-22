import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController soilphController = TextEditingController();
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phophorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();

  int? _selectedCrop;
  String? _selectedState;
  // String? _selectedState1;
  String? docId;

  bool _obscurePassword = true; // 🔑 to toggle visibility

  // final List<int> _cropValues = [1, 2, 3];
  final List<String> _stateValues = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Melaka",
    "Negeri Sembilan",
    "Pahang",
    "Pulau Pinang",
    "Perak",
    "Perlis",
    "Sabah",
    "Sarawak",
    "Selangor",
    "Terengganu",
    "Kuala Lumpur",
    "Labuan",
    "Putrajaya",
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _districtController.dispose();
    soilphController.dispose();
    nitrogenController.dispose();
    phophorusController.dispose();
    potassiumController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (docId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'farmname': _farmNameController.text.trim(),
      'farmsize ': _farmSizeController.text.trim(),
      'district': _districtController.text.trim(),
      'croppreference': _selectedCrop,
      'state': _selectedState,
      'phsoil': double.tryParse(soilphController.text),
      'nitrogen': int.tryParse(nitrogenController.text),
      'phosphorus': int.tryParse(phophorusController.text),
      'potassium': int.tryParse(potassiumController.text),
    });

    print(_selectedState);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.go('/profile');
            }),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userid', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No user profile found"));
          }

          var userDoc = snapshot.data!.docs.first;
          docId = userDoc.id;

          // preload values safely
          _passwordController.text = (userDoc['password'] ?? '');
          _usernameController.text = (userDoc['username'] ?? '');
          _emailController.text = (userDoc['email'] ?? '');
          _farmNameController.text = (userDoc['farmname'] ?? '');
          _farmSizeController.text = (userDoc['farmsize '] ?? '');
          _districtController.text = (userDoc['district'] ?? '');
          soilphController.text = (userDoc['phsoil']).toString();
          nitrogenController.text = (userDoc['nitrogen']).toString();
          phophorusController.text = (userDoc['phosphorus']).toString();
          potassiumController.text = (userDoc['potassium']).toString();
          // _selectedState = userDoc['state'] ?? _selectedState;
          // fix dropdown values
          if (_selectedCrop == null) {
              _selectedCrop = userDoc['croppreference'];
            }
            if (_selectedState == null) {
              _selectedState = userDoc['state'];
            }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Account Information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: const Icon(Icons.person, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter new password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                 const Text(
                  "Soil Properties",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                 Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.agriculture, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "To get accurate soil values, please use a sensor or online service: ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "- For NPK values: use an NPK Sensor Detector device.\n- For Soil pH: use a Soil pH Sensor Detector, or retrieve the data online from SoilGrids by entering your location’s latitude and longitude.",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

                const SizedBox(height: 12),

                 TextField(
                  controller: soilphController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "ph Soil",
                    hintText: "3.000245",
                    prefixIcon:
                        const Icon(Icons.landscape, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                TextField(
                  controller: nitrogenController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Nitrogen (ratio unit)",
                    hintText: "42",
                    prefixIcon:
                        const Icon(Icons.landscape, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                 const SizedBox(height: 12),
                
                TextField(
                  controller: phophorusController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Phophorus (ratio unit)",
                    hintText: "12",
                    prefixIcon:
                        const Icon(Icons.landscape, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                TextField(
                  controller: potassiumController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Potassium (ratio unit)",
                    hintText: "20",
                    prefixIcon:
                        const Icon(Icons.landscape, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        

                const SizedBox(height: 28),

                const Text(
                  "Farm Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

DropdownButtonFormField<int>(
  initialValue: _selectedCrop, // ✅ use initialValue instead of value
  items: const [
    DropdownMenuItem(value: 1, child: Text("Rice")),
    DropdownMenuItem(value: 2, child: Text("Corn")),
    DropdownMenuItem(value: 3, child: Text("Wheat")),
  ],
  onChanged: (value) {
    setState(() {
      _selectedCrop = value;
    });
  },
  decoration: InputDecoration(
    labelText: "Primary Crop",
    prefixIcon: const Icon(Icons.agriculture, color: Colors.green),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),
                const SizedBox(height: 16),

                TextField(
                  controller: _farmNameController,
                  decoration: InputDecoration(
                    labelText: "Farm Name",
                    prefixIcon:
                        const Icon(Icons.landscape, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _farmSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Farm Size (in acres)",
                    prefixIcon:
                        const Icon(Icons.square_foot, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 16),


DropdownButtonFormField<String>(
  
  initialValue: _selectedState, // ✅ updated here too
  items: _stateValues
      .map((s) => DropdownMenuItem(
            value: s,
            child: Text(s),
          ))
      .toList(),
  onChanged: (value) {
    
    setState(() {
      _selectedState = value;
      
    });
  },
  decoration: InputDecoration(
    labelText: "State",
    prefixIcon: const Icon(Icons.map, color: Colors.green),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),



                const SizedBox(height: 16),

                TextField(
                  controller: _districtController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "District",
                    hintText: "e.g. Hulu Langat",
                    prefixIcon:
                        const Icon(Icons.location_city, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

