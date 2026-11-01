/// Dữ liệu khởi tạo cho Demo Mode.
///
/// Mọi map dùng key wire-format của REST API. [DemoBackendAdapter] tạo bản sao
/// mutable từ các fixture này, vì vậy thao tác tạo/sửa/xoá trong bản demo không
/// làm thay đổi dữ liệu gốc.
abstract final class DemoFixtures {
  static const String householdId = 'demo-household-0001';
  static const String ownerId = 'demo-user-0001';

  static const List<Map<String, dynamic>> allergens = <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'name': 'Đậu phộng'},
    <String, dynamic>{'id': 2, 'name': 'Sữa'},
    <String, dynamic>{'id': 3, 'name': 'Trứng'},
    <String, dynamic>{'id': 4, 'name': 'Hải sản có vỏ'},
    <String, dynamic>{'id': 5, 'name': 'Gluten'},
  ];

  static Map<String, dynamic> healthProfile() => <String, dynamic>{
        'userId': ownerId,
        'targetDailyCalories': 1800,
        'dietType': 'NONE',
        'heightCm': 165.0,
        'weightKg': 58.0,
        'updatedAt': '2026-09-20T08:00:00.000Z',
        'allergens': <Map<String, dynamic>>[allergens[0]],
      };

  static List<Map<String, dynamic>> inventory() => <Map<String, dynamic>>[
        _inventoryItem(
          id: 'demo-inventory-ca-loc',
          name: 'Cá lóc',
          quantity: 0.6,
          unit: 'KG',
          category: 'Thịt cá',
          expiryDate: '2026-10-22',
          lowStockThreshold: 0.3,
        ),
        _inventoryItem(
          id: 'demo-inventory-ca-chua',
          name: 'Cà chua',
          quantity: 4,
          unit: 'QUẢ',
          category: 'Rau củ',
          expiryDate: '2026-10-24',
          lowStockThreshold: 2,
        ),
        _inventoryItem(
          id: 'demo-inventory-gao',
          name: 'Gạo',
          quantity: 2,
          unit: 'KG',
          category: 'Thực phẩm khô',
          lowStockThreshold: 0.5,
        ),
        _inventoryItem(
          id: 'demo-inventory-trung-ga',
          name: 'Trứng gà',
          quantity: 10,
          unit: 'QUẢ',
          category: 'Trứng sữa',
          expiryDate: '2026-10-25',
          lowStockThreshold: 4,
        ),
        _inventoryItem(
          id: 'demo-inventory-hanh-la',
          name: 'Hành lá',
          quantity: 0.1,
          unit: 'KG',
          category: 'Rau củ',
          expiryDate: '2026-10-18',
          lowStockThreshold: 0.05,
        ),
        _inventoryItem(
          id: 'demo-inventory-nuoc-mam',
          name: 'Nước mắm',
          quantity: 0.5,
          unit: 'L',
          category: 'Gia vị',
          lowStockThreshold: 0.2,
        ),
        _inventoryItem(
          id: 'demo-inventory-thit-bo',
          name: 'Thịt bò',
          quantity: 0.5,
          unit: 'KG',
          category: 'Thịt cá',
          expiryDate: '2026-10-20',
          lowStockThreshold: 0.2,
        ),
        _inventoryItem(
          id: 'demo-inventory-dau-hu',
          name: 'Đậu hũ',
          quantity: 4,
          unit: 'MIẾNG',
          category: 'Thực phẩm khô',
          expiryDate: '2026-10-19',
          lowStockThreshold: 2,
        ),
      ];

  static List<Map<String, dynamic>> shoppingItems() => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'demo-shop-001',
          'shoppingListId': null,
          'name': 'Nước dừa',
          'quantity': 200.0,
          'unit': 'ML',
          'displayQuantity': 200.0,
          'displayUnit': 'ML',
          'category': 'Gia vị',
          'status': 'PENDING',
          'source': 'AUTO',
          'version': 1,
          'createdBy': ownerId,
          'createdAt': '2026-10-14T08:00:00.000Z',
          'updatedAt': '2026-10-14T08:00:00.000Z',
        },
        <String, dynamic>{
          'id': 'demo-shop-002',
          'shoppingListId': null,
          'name': 'Me chua',
          'quantity': 30.0,
          'unit': 'G',
          'displayQuantity': 30.0,
          'displayUnit': 'G',
          'category': 'Rau củ',
          'status': 'PENDING',
          'source': 'AUTO',
          'version': 1,
          'createdBy': ownerId,
          'createdAt': '2026-10-14T08:05:00.000Z',
          'updatedAt': '2026-10-14T08:05:00.000Z',
        },
        <String, dynamic>{
          'id': 'demo-shop-003',
          'shoppingListId': null,
          'name': 'Ức gà',
          'quantity': 400.0,
          'unit': 'G',
          'displayQuantity': 400.0,
          'displayUnit': 'G',
          'category': 'Thịt cá',
          'status': 'COMPLETED',
          'source': 'MANUAL',
          'version': 1,
          'createdBy': ownerId,
          'createdAt': '2026-10-13T09:00:00.000Z',
          'updatedAt': '2026-10-14T10:00:00.000Z',
        },
        <String, dynamic>{
          'id': 'demo-shop-004',
          'shoppingListId': null,
          'name': 'Trứng gà',
          'quantity': 6.0,
          'unit': 'QUẢ',
          'displayQuantity': 6.0,
          'displayUnit': 'QUẢ',
          'category': 'Trứng sữa',
          'status': 'PENDING',
          'source': 'MANUAL',
          'version': 1,
          'createdBy': ownerId,
          'createdAt': '2026-10-15T07:00:00.000Z',
          'updatedAt': '2026-10-15T07:00:00.000Z',
        },
      ];

  static Map<String, dynamic> budget() => <String, dynamic>{
        'householdId': householdId,
        'period': 'MONTHLY',
        'amount': 3000000.0,
        'currency': 'VND',
        'updatedBy': ownerId,
        'updatedAt': '2026-10-01T00:00:00.000Z',
      };

  static List<Map<String, dynamic>> dependents() => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'demo-dep-0001',
          'guardianUserId': ownerId,
          'guardianActive': true,
          'displayName': 'Bé An',
          'dateOfBirth': '2020-05-15',
          'dietType': 'NONE',
          'allergens': <Map<String, dynamic>>[allergens[2]],
        },
      ];

  static Map<String, dynamic> weeklyRecap() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final weekStart = _dateOnly(monday);
    final w1 = _dateOnly(monday.subtract(const Duration(days: 21)));
    final w2 = _dateOnly(monday.subtract(const Duration(days: 14)));
    final w3 = _dateOnly(monday.subtract(const Duration(days: 7)));

    return <String, dynamic>{
      'householdId': householdId,
      'weekStart': weekStart,
      'mealsLoggedCount': 18,
      'avgCaloriesKcal': 1820.0,
      'adherencePercent': 92.5,
      'householdSummary':
          'Gia đình bạn đã có một tuần ăn uống rất điều độ, giảm 40% lượng thức ăn thừa so với tuần trước!',
      'suggestedFocus':
          'Tăng cường thêm rau xanh và uống đủ nước vào các bữa trưa.',
      'isStale': false,
      'computedAt': now.toUtc().toIso8601String(),
      'wasteItemCount': 2,
      'wasteCauseBreakdown': <String, dynamic>{
        'OVERBOUGHT': 1,
        'EXPIRED_FORGOTTEN': 1,
        'SPOILED_EARLY': 0,
        'OTHER': 0,
      },
      'spendTotal': 1250000.0,
      'spendItemCount': 14,
      'shoppingCompletedItemCount': 14,
      'budgetAmount': 1500000.0,
      'budgetPeriod': 'WEEKLY',
      'budgetWeeklyAmount': 1500000.0,
      'spendByCategory': <String, dynamic>{
        'Rau củ': 250000.0,
        'Thịt cá': 650000.0,
        'Gia vị': 150000.0,
        'Khác': 200000.0,
      },
      'spendTrend': <Map<String, dynamic>>[
        <String, dynamic>{'weekStart': w1, 'spendTotal': 1400000.0},
        <String, dynamic>{'weekStart': w2, 'spendTotal': 1350000.0},
        <String, dynamic>{'weekStart': w3, 'spendTotal': 1480000.0},
        <String, dynamic>{'weekStart': weekStart, 'spendTotal': 1250000.0},
      ],
      'memberInsights': <Map<String, dynamic>>[
        <String, dynamic>{
          'memberId': ownerId,
          'calorieAvg': 1820.0,
          'calorieGoal': 1800.0,
          'compliancePct': 95.0,
          'badge': 'CONSISTENCY',
          'topNutrientGap': 'Chất xơ',
          'highlight': 'Duy trì năng lượng calo đạt 95% mục tiêu cả tuần',
          'tip': 'Nên ăn thêm hoa quả giàu vitamin C vào bữa phụ',
        },
        <String, dynamic>{
          'memberId': 'demo-user-0002',
          'calorieAvg': 1650.0,
          'calorieGoal': 1600.0,
          'compliancePct': 92.0,
          'badge': 'GREEN_WARRIOR',
          'topNutrientGap': 'Canxi',
          'highlight': 'Tích cực ăn các món luộc và thanh đạm lành mạnh',
          'tip': 'Bổ sung sữa tươi tiệt trùng hoặc sữa chua',
        },
      ],
    };
  }

  static Map<String, dynamic> householdStreak() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    return <String, dynamic>{
      'householdId': householdId,
      'currentStreak': 4,
      'bestStreak': 6,
      'lastComputedWeekStart': _dateOnly(monday),
    };
  }

  static List<Map<String, dynamic>> weeklyNutrition() => <Map<String, dynamic>>[
        <String, dynamic>{
          'memberId': ownerId,
          'avgCaloriesKcal': 1820.0,
          'loggedCount': 14,
        },
        <String, dynamic>{
          'memberId': 'demo-user-0002',
          'avgCaloriesKcal': 1650.0,
          'loggedCount': 12,
        },
      ];

  static List<Map<String, dynamic>> mealLogs() {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final d1 = _dateOnly(now.subtract(const Duration(days: 1)));
    final d2 = _dateOnly(now.subtract(const Duration(days: 2)));
    final d3 = _dateOnly(now.subtract(const Duration(days: 3)));
    final d4 = _dateOnly(now.subtract(const Duration(days: 4)));
    final d5 = _dateOnly(now.subtract(const Duration(days: 5)));
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'demo-meal-log-001',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa sáng] Phở bò tái nạm',
        'caloriesKcal': 520.0,
        'nutrition': <String, dynamic>{
          'proteinG': 28.0,
          'carbsG': 60.0,
          'fatG': 12.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Phở bò', 'quantity': 1.0, 'confidence': 0.98},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${today}T07:30:00.000Z',
        'confirmedAt': '${today}T07:35:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-002',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa trưa] Cơm gà áp chảo + Canh chua cá lóc',
        'caloriesKcal': 680.0,
        'nutrition': <String, dynamic>{
          'proteinG': 38.0,
          'carbsG': 75.0,
          'fatG': 18.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Cơm gà', 'quantity': 1.0, 'confidence': 0.95},
          <String, dynamic>{'name': 'Canh chua cá lóc', 'quantity': 1.0, 'confidence': 0.92},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${today}T12:15:00.000Z',
        'confirmedAt': '${today}T12:20:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-003',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa tối] Cá lóc kho tộ + Rau luộc',
        'caloriesKcal': 550.0,
        'nutrition': <String, dynamic>{
          'proteinG': 34.0,
          'carbsG': 55.0,
          'fatG': 14.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Cá lóc kho tộ', 'quantity': 1.0, 'confidence': 0.96},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${d1}T19:00:00.000Z',
        'confirmedAt': '${d1}T19:05:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-004',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa trưa] Bún chả Hà Nội',
        'caloriesKcal': 620.0,
        'nutrition': <String, dynamic>{
          'proteinG': 30.0,
          'carbsG': 72.0,
          'fatG': 16.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Bún chả', 'quantity': 1.0, 'confidence': 0.94},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${d2}T12:30:00.000Z',
        'confirmedAt': '${d2}T12:35:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-005',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa tối] Canh cải thịt băm + Thịt kho tàu',
        'caloriesKcal': 640.0,
        'nutrition': <String, dynamic>{
          'proteinG': 32.0,
          'carbsG': 60.0,
          'fatG': 20.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Thịt kho', 'quantity': 1.0, 'confidence': 0.93},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${d3}T19:15:00.000Z',
        'confirmedAt': '${d3}T19:20:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-006',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa trưa] Cơm sườn nướng mỡ hành',
        'caloriesKcal': 710.0,
        'nutrition': <String, dynamic>{
          'proteinG': 36.0,
          'carbsG': 80.0,
          'fatG': 22.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Cơm sườn', 'quantity': 1.0, 'confidence': 0.97},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${d4}T12:00:00.000Z',
        'confirmedAt': '${d4}T12:05:00.000Z',
      },
      <String, dynamic>{
        'id': 'demo-meal-log-007',
        'householdId': householdId,
        'memberId': ownerId,
        'loggedBy': ownerId,
        'sessionId': null,
        'description': '[Bữa trưa] Mì Quảng tôm thịt',
        'caloriesKcal': 590.0,
        'nutrition': <String, dynamic>{
          'proteinG': 29.0,
          'carbsG': 68.0,
          'fatG': 15.0,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Mì Quảng', 'quantity': 1.0, 'confidence': 0.95},
        ],
        'requiresConfirmation': false,
        'confirmedByUser': true,
        'loggedAt': '${d5}T12:45:00.000Z',
        'confirmedAt': '${d5}T12:50:00.000Z',
      },
    ];
  }

  static List<Map<String, dynamic>> suggestions() =>
      <Map<String, dynamic>>[
        <String, dynamic>{
          'recipeId': 'demo-recipe-ca-kho',
          'recipeName': 'Cá lóc kho tộ',
          'confidence': 0.93,
          'kbRecipeId': 'kb-ca-kho-to',
          'source': 'GENERATED',
          'rankReason':
              'Ưu tiên dùng cá lóc sắp đến hạn và phù hợp mục tiêu năng lượng của gia đình.',
          'tradeoffNote': 'Cần bổ sung nước dừa nếu trong kho chưa có.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Nước dừa',
              'quantity': 200.0,
              'unit': 'ML',
              'role': 'SECONDARY',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'INGREDIENT_RULE',
        },
        <String, dynamic>{
          'recipeId': 'demo-recipe-canh-chua',
          'recipeName': 'Canh chua cá lóc',
          'confidence': 0.88,
          'kbRecipeId': 'kb-canh-chua-ca-loc',
          'source': 'KB',
          'rankReason':
              'Dùng được cá lóc và cà chua sẵn có, món nhẹ phù hợp cho bữa trưa.',
          'tradeoffNote': 'Cần thêm me và giá đỗ để đủ vị.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Me chua',
              'quantity': 30.0,
              'unit': 'G',
              'role': 'SEASONING',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'INGREDIENT_RULE',
        },
        <String, dynamic>{
          'recipeId': 'demo-recipe-com-ga',
          'recipeName': 'Cơm gà áp chảo',
          'confidence': 0.75,
          'kbRecipeId': 'kb-com-ga-ap-chao',
          'source': 'KB',
          'rankReason':
              'Phương án nhanh khi cần một bữa no, có thể dùng gạo đang có trong kho.',
          'tradeoffNote': 'Chưa kiểm chứng đầy đủ dị ứng cho công thức này.',
          'missingIngredients': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Ức gà',
              'quantity': 400.0,
              'unit': 'G',
              'role': 'MAIN',
            },
          ],
          'allergenTags': <String>[],
          'allergenDerivation': 'UNVERIFIED',
        },
      ];

  static Map<String, dynamic> recipe(String recipeId) {
    final recipes = <String, Map<String, dynamic>>{
      'demo-recipe-ca-kho': <String, dynamic>{
        'id': 'demo-recipe-ca-kho',
        'recipeName': 'Cá lóc kho tộ',
        'description':
            'Món kho đậm đà, thơm nước dừa; phù hợp cho bữa cơm gia đình.',
        'ingredients': <String>[
          'Cá lóc',
          'Nước dừa',
          'Nước mắm',
          'Tiêu và hành lá',
        ],
        'prepTimeMinutes': 40,
        'calories': 430,
        'tags': <String>['Món Việt', 'Món kho'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25367356',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/3214d0fc638cc726/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Làm sạch cá lóc, cắt khúc và ướp với nước mắm, tiêu.',
            'duration_minutes': 10,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Thắng nước màu rồi cho cá vào đảo nhẹ.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Thêm nước dừa, kho lửa nhỏ đến khi nước sánh lại.',
            'duration_minutes': 25,
          },
        ],
      },
      'demo-recipe-canh-chua': <String, dynamic>{
        'id': 'demo-recipe-canh-chua',
        'recipeName': 'Canh chua cá lóc',
        'description':
            'Canh chua thanh nhẹ với cá, cà chua và vị me; dễ ăn trong bữa trưa.',
        'ingredients': <String>[
          'Cá lóc',
          'Cà chua',
          'Me chua',
          'Rau thơm',
        ],
        'prepTimeMinutes': 30,
        'calories': 280,
        'tags': <String>['Món Việt', 'Canh'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/26161349',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/4f2b81d272096273/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Đun nước, cho me chua vào dằm lấy vị.',
            'duration_minutes': 8,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Cho cá và cà chua vào nấu chín.',
            'duration_minutes': 12,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Nêm lại, thêm rau thơm rồi tắt bếp.',
            'duration_minutes': 3,
          },
        ],
      },
      'demo-recipe-com-ga': <String, dynamic>{
        'id': 'demo-recipe-com-ga',
        'recipeName': 'Cơm gà áp chảo',
        'description':
            'Bữa cơm nhanh gọn với gà áp chảo vàng thơm, dùng cùng cơm và rau.',
        'ingredients': <String>[
          'Ức gà',
          'Gạo',
          'Rau củ',
          'Muối và tiêu',
        ],
        'prepTimeMinutes': 25,
        'calories': 520,
        'tags': <String>['Món Việt', 'Nhanh gọn'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25641161',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/8ac54a782da2d5ce/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Ướp ức gà với một ít muối và tiêu.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Áp chảo gà vàng đều hai mặt.',
            'duration_minutes': 15,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction': 'Cắt gà, dùng cùng cơm nóng và rau.',
            'duration_minutes': 3,
          },
        ],
      },
      'demo-recipe-thit-chay': <String, dynamic>{
        'id': 'demo-recipe-thit-chay',
        'recipeName': 'Món chay: Thịt chiên chua ngọt',
        'description':
            'Món chay thanh đạm, thơm ngon dễ làm với sốt chua ngọt đậm đà.',
        'ingredients': <String>[
          'Thịt chay',
          'Ớt chuông xanh',
          'Ớt chuông đỏ',
          'Dưa leo',
          'Tương cà',
          'Dầu ăn',
        ],
        'prepTimeMinutes': 20,
        'calories': 310,
        'tags': <String>['Món chay', 'Chua ngọt'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/26503706',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/a5f75709052152b7/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction':
                'Thịt chay chiên sơ trước hoặc chiên nồi chiên không dầu 200 độ 8-10 phút.',
            'duration_minutes': 8,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Làm nóng dầu, cho sốt tương cà đường chanh xào sệt.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction':
                'Cho ớt chuông, dưa leo và thịt chay vào đảo đều thấm sốt, rắc mè rang.',
            'duration_minutes': 7,
          },
        ],
      },
      'demo-recipe-dau-hu': <String, dynamic>{
        'id': 'demo-recipe-dau-hu',
        'recipeName': 'Đậu hũ sốt nước mắm',
        'description':
            'Đậu hũ chiên giòn sốt nước mắm tỏi ớt thơm lừng, rất hao cơm.',
        'ingredients': <String>[
          'Đậu hũ chiên',
          'Tỏi băm',
          'Hành lá',
          'Nước mắm tỏi ớt',
          'Tương ớt',
        ],
        'prepTimeMinutes': 15,
        'calories': 260,
        'tags': <String>['Món Việt', 'Nhanh gọn', 'Món chay'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25768325',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/3214d0fc638cc726/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction': 'Đậu hũ cắt lát, chiên vàng giòn hai mặt.',
            'duration_minutes': 7,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction':
                'Phi thơm tỏi băm, cho nước mắm tỏi ớt và tương ớt vào nấu sôi nhẹ.',
            'duration_minutes': 3,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction':
                'Cho đậu hũ vào đảo đều cho thấm sốt, rắc hành lá và mè trắng.',
            'duration_minutes': 5,
          },
        ],
      },
      'demo-recipe-muc-chien': <String, dynamic>{
        'id': 'demo-recipe-muc-chien',
        'recipeName': 'Mực chiên giòn sốt chua ngọt',
        'description':
            'Mực chiên giòn rụm kết hợp với sốt cà chua thanh dịu và hành tây ngọt mềm.',
        'ingredients': <String>[
          'Mực tẩm bột',
          'Hành tây',
          'Cà chua',
          'Hành lá',
          'Gia vị',
        ],
        'prepTimeMinutes': 25,
        'calories': 380,
        'tags': <String>['Hải sản', 'Món chiên'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/25190148',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/8ac54a782da2d5ce/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction':
                'Mực chiên vàng hai mặt, vớt ra để ráo dầu. Cà chua cắt múi cau.',
            'duration_minutes': 10,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction':
                'Phi thơm đầu hành, xào cà chua rồi cho mực vào đảo cùng sốt chua ngọt.',
            'duration_minutes': 8,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction':
                'Thêm hành tây xào vừa chín tới, rắc hành lá cắt khúc và hạt tiêu.',
            'duration_minutes': 7,
          },
        ],
      },
      'demo-recipe-ech-xao': <String, dynamic>{
        'id': 'demo-recipe-ech-xao',
        'recipeName': 'Ếch xào sả ớt',
        'description':
            'Thịt ếch dai ngọt xào sả ớt nghệ cay nồng đậm vị dân dã.',
        'ingredients': <String>[
          'Thịt ếch',
          'Sả băm',
          'Ớt cay',
          'Tỏi',
          'Nước mắm',
          'Nghệ',
        ],
        'prepTimeMinutes': 30,
        'calories': 350,
        'tags': <String>['Món Việt', 'Đậm đà'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/26456606',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/31a3f80d22e4e54e/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction':
                'Ếch làm sạch, cắt miếng vừa ăn, ướp nước mắm khoảng 15 phút.',
            'duration_minutes': 10,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction': 'Chiên sơ thịt ếch cho hơi vàng rồi vớt ra.',
            'duration_minutes': 10,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction':
                'Phi thơm sả, ớt, tỏi, nghệ rồi cho ếch vào đảo đều ngấm gia vị.',
            'duration_minutes': 10,
          },
        ],
      },
      'demo-recipe-canh-muc': <String, dynamic>{
        'id': 'demo-recipe-canh-muc',
        'recipeName': 'Canh Mực Nấu Lá É',
        'description':
            'Canh mực thanh mát mang đậm vị miền Trung, mực giòn ngọt cùng hương lá é thơm nồng đặc trưng.',
        'ingredients': <String>[
          'Mực sữa',
          'Lá é',
          'Cà chua',
          'Thơm',
          'Nước mắm',
          'Hành tím',
        ],
        'prepTimeMinutes': 20,
        'calories': 220,
        'tags': <String>['Canh', 'Hải sản', 'Món Việt'],
        'guideUrl': 'https://cookpad.com/vn/cong-thuc/24944014',
        'thumbnailUrl':
            'https://img-global.cpcdn.com/recipes/4f2b81d272096273/1200x630cq80/photo.jpg',
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'step_number': 1,
            'instruction':
                'Mực rửa sạch, cắt vừa ăn. Cà chua cắt múi cau, thơm cắt lát mỏng.',
            'duration_minutes': 5,
          },
          <String, dynamic>{
            'step_number': 2,
            'instruction':
                'Đun sôi nước, cho cà chua và thơm vào tạo vị chua thanh dịu.',
            'duration_minutes': 8,
          },
          <String, dynamic>{
            'step_number': 3,
            'instruction':
                'Thả mực vào nấu sôi chín tới, tắt bếp rồi cho lá é vò nhẹ vào.',
            'duration_minutes': 7,
          },
        ],
      },
    };
    return Map<String, dynamic>.from(
      recipes[recipeId] ?? recipes['demo-recipe-ca-kho']!,
    );
  }

  static Map<String, dynamic> mealPlan(String weekStart) {
    final monday = DateTime.parse('${weekStart}T00:00:00Z');
    final slots = <Map<String, dynamic>>[];
    for (var day = 0; day < 7; day++) {
      final date = monday.add(Duration(days: day));
      final dateText = _dateOnly(date);
      for (final mealTime in <String>['BREAKFAST', 'LUNCH', 'DINNER']) {
        final dishes = <Map<String, dynamic>>[];
        if (day == 0 && mealTime == 'LUNCH') {
          dishes.add(<String, dynamic>{
            'id': 'demo-dish-1',
            'slotId': 'demo-slot-$dateText-LUNCH',
            'sortOrder': 0,
            'status': 'CONFIRMED',
            'recipe': <String, dynamic>{
              'recipeId': 'demo-recipe-ca-kho',
              'recipeName': 'Cá lóc kho tộ',
              'source': 'GENERATED',
            },
          });
        } else if (day == 0 && mealTime == 'DINNER') {
          dishes.add(<String, dynamic>{
            'id': 'demo-dish-2',
            'slotId': 'demo-slot-$dateText-DINNER',
            'sortOrder': 0,
            'status': 'CONFIRMED',
            'recipe': <String, dynamic>{
              'recipeId': 'demo-recipe-canh-chua',
              'recipeName': 'Canh chua cá lóc',
              'source': 'KB',
            },
          });
        } else if (day == 1 && mealTime == 'LUNCH') {
          dishes.add(<String, dynamic>{
            'id': 'demo-dish-3',
            'slotId': 'demo-slot-$dateText-LUNCH',
            'sortOrder': 0,
            'status': 'VOTING',
            'recipe': <String, dynamic>{
              'recipeId': 'demo-recipe-com-ga',
              'recipeName': 'Cơm gà áp chảo',
              'source': 'KB',
            },
          });
        } else if (day == 2 && mealTime == 'DINNER') {
          dishes.add(<String, dynamic>{
            'id': 'demo-dish-4',
            'slotId': 'demo-slot-$dateText-DINNER',
            'sortOrder': 0,
            'status': 'SUGGESTED',
            'recipe': <String, dynamic>{
              'recipeId': 'demo-recipe-ech-xao',
              'recipeName': 'Ếch xào sả ớt',
              'source': 'AI',
            },
          });
        }

        slots.add(<String, dynamic>{
          'id': 'demo-slot-$dateText-$mealTime',
          'slotDate': dateText,
          'mealTime': mealTime,
          'dishes': dishes,
        });
      }
    }
    return <String, dynamic>{
      'id': 'demo-plan-$weekStart',
      'householdId': householdId,
      'weekStart': weekStart,
      'slots': slots,
    };
  }

  static Map<String, dynamic> _inventoryItem({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    String? category,
    String? expiryDate,
    double? lowStockThreshold,
  }) =>
      <String, dynamic>{
        'id': id,
        'householdId': householdId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'displayQuantity': quantity,
        'displayUnit': unit,
        'lowStockThreshold': lowStockThreshold,
        'expiryDate': expiryDate,
        'note': null,
        'version': 1,
        'isLowStock': lowStockThreshold != null && quantity <= lowStockThreshold,
        'isExpiringSoon': expiryDate == '2026-09-22',
        'createdBy': ownerId,
        'createdAt': '2026-09-20T08:00:00.000Z',
        'updatedAt': '2026-09-20T08:00:00.000Z',
      };

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
