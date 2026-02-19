import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RobustAdminCodeGenerator {
  static Future<Map<String, dynamic>?> generateCodes({
    required int count,
    String? expiresAt,
  }) async {
    try {
      // 1. Check current session
      final session = Supabase.instance.client.auth.currentSession;
      print('Current session exists: ${session != null}');
      
      if (session == null) {
        print('No active session found');
        return {
          'success': false,
          'error': 'No active session. Please login again.',
          'requires_login': true,
        };
      }

      // 2. Check access token
      final accessToken = session.accessToken;
      print('Access token length: ${accessToken.length}');
      print('Access token starts with eyJ: ${accessToken.startsWith('eyJ')}');
      
      if (accessToken.isEmpty) {
        print('Access token is empty');
        return {
          'success': false,
          'error': 'Invalid session. Please login again.',
          'requires_login': true,
        };
      }

      // 3. Try function call
      print('Calling Edge Function...');
      final response = await Supabase.instance.client.functions.invoke(
        'generate_lifetime_codes',
        body: {
          'count': count,
          if (expiresAt != null) 'expires_at': expiresAt,
          'max_redemptions': 1,
        },
      );

      print('Function response status: ${response.status}');
      print('Function response data: ${response.data}');

      // 4. Handle response
      if (response.data == null) {
        return {
          'success': false,
          'error': 'No response from server',
        };
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['ok'] == true) {
        return {
          'success': true,
          'data': data,
          'count': data['count'] ?? 0,
        };
      } else {
        // Handle different error types
        if (response.status == 401) {
          // Try refreshing session once
          print('Got 401, trying to refresh session...');
          try {
            await Supabase.instance.client.auth.refreshSession();
            print('Session refreshed, retrying function call...');
            
            // Retry the function call
            final retryResponse = await Supabase.instance.client.functions.invoke(
              'generate_lifetime_codes',
              body: {
                'count': count,
                if (expiresAt != null) 'expires_at': expiresAt,
                'max_redemptions': 1,
              },
            );

            if (retryResponse.data != null && retryResponse.data['ok'] == true) {
              return {
                'success': true,
                'data': retryResponse.data,
                'count': retryResponse.data['count'] ?? 0,
                'retried': true,
              };
            } else {
              return {
                'success': false,
                'error': retryResponse.data?['message'] ?? 'Authentication failed after refresh',
                'requires_login': true,
              };
            }
          } catch (refreshError) {
            print('Session refresh failed: $refreshError');
            return {
              'success': false,
              'error': 'Session expired. Please login again.',
              'requires_login': true,
            };
          }
        } else if (response.status == 403) {
          return {
            'success': false,
            'error': 'Access denied. Admin access required.',
            'details': data['message'],
            'admin_emails': data['adminEmails'],
            'user_email': data['userEmail'],
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Unknown error occurred',
            'details': data['details'],
          };
        }
      }

    } on FunctionException catch (e) {
      print('FunctionException: ${e.code} - ${e.message}');
      print('Details: ${e.details}');
      
      // Handle specific JWT errors
      final message = e.message.toLowerCase();
      final isAuth401 = e.code == 401 ||
          e.code.toString() == '401' ||
          message.contains('invalid jwt') ||
          message.contains('invalid or missing jwt');
      if (isAuth401) {
        return {
          'success': false,
          'error': 'Authentication failed. Your session may have expired.',
          'requires_login': true,
          'function_error': {
            'code': e.code,
            'message': e.message,
            'details': e.details,
          },
        };
      }
      
      return {
        'success': false,
        'error': e.message,
        'function_error': {
          'code': e.code,
          'message': e.message,
          'details': e.details,
        },
      };
    } catch (e) {
      print('Unexpected error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }
}

// Example usage in your Flutter widget:
class AdminGenerateCodesButton extends StatefulWidget {
  const AdminGenerateCodesButton({super.key});

  @override
  State<AdminGenerateCodesButton> createState() => _AdminGenerateCodesButtonState();
}

class _AdminGenerateCodesButtonState extends State<AdminGenerateCodesButton> {
  bool _isLoading = false;
  String? _error;

  Future<void> _generateCodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RobustAdminCodeGenerator.generateCodes(count: 10);
      
      if (!mounted) return;

      if (result!['success'] == true) {
        final data = result['data'];
        final count = result['count'];
        final retried = result['retried'] ?? false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully generated $count codes${retried ? ' (after session refresh)' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Handle the generated codes
        print('Generated codes: ${data['codes']}');
        
      } else {
        final error = result['error'];
        final requiresLogin = result['requires_login'] ?? false;
        
        if (requiresLogin) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Session Required'),
              content: Text(error),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Navigate to login screen
                    // context.go('/login');
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Unknown error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateCodes,
          icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.generating_tokens),
          label: Text(_isLoading ? 'Generating...' : 'Generate Codes'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
      ],
    );
  }
}
