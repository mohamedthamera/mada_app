import 'package:supabase_flutter/supabase_flutter.dart';

// Test function for debugging the Edge Function
Future<void> testGenerateCodes() async {
  try {
    print('=== Testing Edge Function ===');
    
    final response = await Supabase.instance.client.functions.invoke(
      'generate_lifetime_codes',
      body: {
        'count': 5,
        'max_redemptions': 1,
      },
    );

    print('Status: ${response.status}');
    print('Data: ${response.data}');
    
    if (response.data == null) {
      print('Error: No response data');
      return;
    }
    
    if (response.data['error'] != null) {
      print('Function returned error:');
      print('- Error: ${response.data['error']}');
      print('- Details: ${response.data['details']}');
      if (response.data['adminEmails'] != null) {
        print('- Admin emails: ${response.data['adminEmails']}');
      }
      if (response.data['userEmail'] != null) {
        print('- User email: ${response.data['userEmail']}');
      }
    } else {
      print('Success! Generated ${response.data['count'] ?? 0} codes');
      final codes = response.data['codes'] as List?;
      if (codes != null) {
        for (int i = 0; i < codes.length; i++) {
          print('Code ${i + 1}: ${codes[i]['code']}');
        }
      }
    }
    
  } catch (e) {
    print('Exception occurred: $e');
  }
}

// How to call this from your Flutter widget:
// In your _generateCodes() method, add this line for debugging:
// await testGenerateCodes();
