/// Generates an OpenAPI 3.1 JSON specification for the backend API.
///
/// Only includes endpoints for enabled modules (auth providers, email
/// verification, etc.).
library;

import 'dart:convert';
import 'backend_config.dart';

class OpenApiGenerator {
  OpenApiGenerator();

  String generate(BackendConfig config) {
    final spec = <String, dynamic>{
      'openapi': '3.1.0',
      'info': {
        'title': '${config.projectName} API',
        'version': '1.0.0',
        'description': 'Auto-generated API for ${config.projectName}',
      },
      'servers': [
        {
          'url': 'http://localhost:3000',
          'description': 'Development server',
        },
      ],
      'components': {
        'securitySchemes': {
          'bearerAuth': {
            'type': 'http',
            'scheme': 'bearer',
            'bearerFormat': 'JWT',
          }
        },
        'schemas': {
          'Error': {
            'type': 'object',
            'properties': {
              'error': {'type': 'string'},
              'details': {'type': 'object'},
            },
            'required': ['error'],
          },
          'User': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
              'email': {'type': 'string', 'format': 'email'},
              'displayName': {'type': 'string', 'nullable': true},
              'avatarUrl': {'type': 'string', 'nullable': true},
              'emailVerified': {'type': 'string', 'format': 'date-time', 'nullable': true},
              'createdAt': {'type': 'string', 'format': 'date-time'},
            },
            'required': ['id', 'email'],
          },
          'AuthResponse': {
            'type': 'object',
            'properties': {
              'user': {'\$ref': '#/components/schemas/User'},
              'accessToken': {'type': 'string'},
              'refreshToken': {'type': 'string'},
              'expiresIn': {'type': 'integer'},
            },
          },
          'Project': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
              'name': {'type': 'string'},
              'description': {'type': 'string', 'nullable': true},
              'ownerId': {'type': 'string'},
              'createdAt': {'type': 'string', 'format': 'date-time'},
              'updatedAt': {'type': 'string', 'format': 'date-time'},
            },
            'required': ['id', 'name', 'ownerId'],
          },
        },
      },
    };

    final paths = <String, dynamic>{};

    // Auth endpoints
    if (config.hasAnyAuthProvider) {
      if (config.hasEmailPassword) {
        paths['/api/auth/register'] = {
          'post': {
            'tags': ['auth'],
            'summary': 'Register a new user',
            'security': [],
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'email': {'type': 'string', 'format': 'email'},
                      'password': {'type': 'string', 'minLength': 8},
                      'displayName': {'type': 'string'},
                    },
                    'required': ['email', 'password'],
                  },
                },
              },
            },
            'responses': {
              '201': {
                'description': 'User registered',
                'content': {
                  'application/json': {
                    'schema': {'\$ref': '#/components/schemas/AuthResponse'},
                  },
                },
              },
              '400': {'description': 'Validation error', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
              '409': {'description': 'User already exists', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
            },
          },
        };

        paths['/api/auth/login'] = {
          'post': {
            'tags': ['auth'],
            'summary': 'Login',
            'security': [],
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'email': {'type': 'string', 'format': 'email'},
                      'password': {'type': 'string'},
                    },
                    'required': ['email', 'password'],
                  },
                },
              },
            },
            'responses': {
              '200': {
                'description': 'Login successful',
                'content': {
                  'application/json': {
                    'schema': {'\$ref': '#/components/schemas/AuthResponse'},
                  },
                },
              },
              '401': {'description': 'Invalid credentials', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
            },
          },
        };
      }

      paths['/api/auth/refresh'] = {
        'post': {
          'tags': ['auth'],
          'summary': 'Refresh access token',
          'security': [],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'refreshToken': {'type': 'string'},
                  },
                  'required': ['refreshToken'],
                },
              },
            },
          },
          'responses': {
            '200': {
              'description': 'New token pair',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'accessToken': {'type': 'string'},
                      'refreshToken': {'type': 'string'},
                      'expiresIn': {'type': 'integer'},
                    },
                  },
                },
              },
            },
            '401': {'description': 'Invalid refresh token', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
          },
        },
      };

      paths['/api/auth/logout'] = {
        'post': {
          'tags': ['auth'],
          'summary': 'Logout (revoke session)',
          'security': [],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'refreshToken': {'type': 'string'},
                  },
                  'required': ['refreshToken'],
                },
              },
            },
          },
          'responses': {
            '200': {'description': 'Logged out'},
          },
        },
      };

      paths['/api/auth/me'] = {
        'get': {
          'tags': ['auth'],
          'summary': 'Get current user',
          'security': [{'bearerAuth': []}],
          'responses': {
            '200': {
              'description': 'Current user',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'user': {'\$ref': '#/components/schemas/User'},
                    },
                  },
                },
              },
            },
            '401': {'description': 'Unauthorized', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
          },
        },
      };

      if (config.enableEmailVerification) {
        paths['/api/auth/verify-email'] = {
          'post': {
            'tags': ['auth'],
            'summary': 'Verify email with token',
            'security': [],
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'token': {'type': 'string'},
                    },
                    'required': ['token'],
                  },
                },
              },
            },
            'responses': {
              '200': {'description': 'Email verified'},
              '400': {'description': 'Invalid token', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
            },
          },
        };
      }

      paths['/api/auth/forgot-password'] = {
        'post': {
          'tags': ['auth'],
          'summary': 'Request password reset',
          'security': [],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'email': {'type': 'string', 'format': 'email'},
                  },
                  'required': ['email'],
                },
              },
            },
          },
          'responses': {
            '200': {'description': 'Reset email sent (if account exists)'},
          },
        },
      };

      paths['/api/auth/reset-password'] = {
        'post': {
          'tags': ['auth'],
          'summary': 'Reset password with token',
          'security': [],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'token': {'type': 'string'},
                    'newPassword': {'type': 'string', 'minLength': 8},
                  },
                  'required': ['token', 'newPassword'],
                },
              },
            },
          },
          'responses': {
            '200': {'description': 'Password reset successful'},
            '400': {'description': 'Invalid token', 'content': {'application/json': {'schema': {'\$ref': '#/components/schemas/Error'}}}},
          },
        },
      };
    }

    // User endpoints
    paths['/api/users/me'] = {
      'get': {
        'tags': ['users'],
        'summary': 'Get current user profile',
        'security': [{'bearerAuth': []}],
        'responses': {
          '200': {
            'description': 'User profile',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'user': {'\$ref': '#/components/schemas/User'},
                  },
                },
              },
            },
          },
        },
      },
      'put': {
        'tags': ['users'],
        'summary': 'Update user profile',
        'security': [{'bearerAuth': []}],
        'requestBody': {
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'displayName': {'type': 'string'},
                  'avatarUrl': {'type': 'string', 'format': 'uri'},
                },
              },
            },
          },
        },
        'responses': {
          '200': {
            'description': 'Updated user',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'user': {'\$ref': '#/components/schemas/User'},
                  },
                },
              },
            },
          },
        },
      },
    };

    // Project endpoints
    paths['/api/projects'] = {
      'get': {
        'tags': ['projects'],
        'summary': 'List projects',
        'security': [{'bearerAuth': []}],
        'responses': {
          '200': {
            'description': 'List of projects',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'projects': {
                      'type': 'array',
                      'items': {'\$ref': '#/components/schemas/Project'},
                    },
                  },
                },
              },
            },
          },
        },
      },
      'post': {
        'tags': ['projects'],
        'summary': 'Create project',
        'security': [{'bearerAuth': []}],
        'requestBody': {
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                  'description': {'type': 'string'},
                  'metadata': {'type': 'object'},
                },
                'required': ['name'],
              },
            },
          },
        },
        'responses': {
          '201': {
            'description': 'Project created',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'project': {'\$ref': '#/components/schemas/Project'},
                  },
                },
              },
            },
          },
        },
      },
    };

    spec['paths'] = paths;

    return const JsonEncoder.withIndent('  ').convert(spec);
  }
}
