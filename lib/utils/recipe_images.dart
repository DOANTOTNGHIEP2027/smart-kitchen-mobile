// Ảnh minh họa được chọn từ ai-native/data/recipes.json.
// Chỉ bổ sung ảnh trình bày; không thay đổi công thức, nguyên liệu hay dữ liệu BE.
// URL backend luôn được ưu tiên. Không fuzzy-match tên món lúc chạy.
String? recipeImageUrl(
    {required String recipeId,
    required String recipeName,
    String? thumbnailUrl}) {
  if (thumbnailUrl != null && thumbnailUrl.trim().isNotEmpty) {
    return thumbnailUrl;
  }
  return _seedImages[recipeId] ?? _nameImages[recipeName.trim().toLowerCase()];
}

const _seedImages = <String, String>{
  // Minh họa nhóm cơm từ Cơm gạo lứt rang rau củ (dataset không có cơm trắng).
  'de300000-0000-4000-8000-000000001024':
      'https://img-global.cpcdn.com/recipes/0cf106bdeec15dac/1200x630cq80/photo.jpg',
  // Phở Sườn Bò
  'de300000-0000-4000-8000-000000001001':
      'https://img-global.cpcdn.com/recipes/b16118a3e3258d1d/1200x630cq80/photo.jpg',
  // Cơm thịt nướng
  'de300000-0000-4000-8000-000000001002':
      'https://img-global.cpcdn.com/recipes/785f5dc523c79d88/1200x630cq80/photo.jpg',
  // Canh chua tôm
  'de300000-0000-4000-8000-000000001003':
      'https://img-global.cpcdn.com/recipes/4f7b7c4b7ac6fc19/1200x630cq80/photo.jpg',
  // Thịt Heo Rừng Kho Trứng
  'de300000-0000-4000-8000-000000001004':
      'https://img-global.cpcdn.com/recipes/43156874663f475b/1200x630cq80/photo.jpg',
  // Cơm nhà với vai heo nướng sốt đào, thăn trâu xào cải bó xôi, rau muống xào tỏi, canh cà chua trứng
  'de300000-0000-4000-8000-000000001005':
      'https://img-global.cpcdn.com/recipes/3c910aff723d61c0/1200x630cq80/photo.jpg',
  // Gà kho lá quế
  'de300000-0000-4000-8000-000000001006':
      'https://img-global.cpcdn.com/recipes/143bc5e602bdfc6f/1200x630cq80/photo.jpg',
  // Đậu phụ sốt cà chua (món chay)
  'de300000-0000-4000-8000-000000001007':
      'https://img-global.cpcdn.com/recipes/1f8aa5e2a494553a/1200x630cq80/photo.jpg',
  // Nem nướng bánh hỏi miền Tây
  'de300000-0000-4000-8000-000000001008':
      'https://img-global.cpcdn.com/recipes/eb26c753f00499b9/1200x630cq80/photo.jpg',
  // Tôm thịt kho thơm chua ngọt hấp dẫn
  'de300000-0000-4000-8000-000000001009':
      'https://img-global.cpcdn.com/recipes/bc50aeb70f14c0b1/1200x630cq80/photo.jpg',
  // Canh bí đỏ nấu xương heo
  'de300000-0000-4000-8000-000000001010':
      'https://img-global.cpcdn.com/recipes/47ebae2606491273/1200x630cq80/photo.jpg',
  // Cá basa kho
  'de300000-0000-4000-8000-000000001011':
      'https://img-global.cpcdn.com/recipes/5ddb8bded31ae574/1200x630cq80/photo.jpg',
  // Gỏi cuốn tôm và thịt nướng
  'de300000-0000-4000-8000-000000001012':
      'https://img-global.cpcdn.com/recipes/e6bc3976c27b159a/1200x630cq80/photo.jpg',
  // Trứng chiên lá lốt
  'de300000-0000-4000-8000-000000001013':
      'https://img-global.cpcdn.com/recipes/ae814ada3ba9f1c3/1200x630cq80/photo.jpg',
  // Cơm nhà với salad tôm bông cải trứng, cà tím xào thịt băm, bánh bí đỏ phomai, canh rong biển nạm bò
  'de300000-0000-4000-8000-000000001014':
      'https://img-global.cpcdn.com/recipes/5f804fab341ca30d/1200x630cq80/photo.jpg',
  // Mâm cơm EatWell: Bò xào, trứng ốp, cải chíp xào
  'de300000-0000-4000-8000-000000001015':
      'https://img-global.cpcdn.com/recipes/06ea63b8f0f7c64a/1200x630cq80/photo.jpg',
  // Cháo gà + gỏi Gà
  'de300000-0000-4000-8000-000000001016':
      'https://img-global.cpcdn.com/recipes/b6874cd8a1965d3d/1200x630cq80/photo.jpg',
  // Mì Xào Nấm Cải Ngọt Chay
  'de300000-0000-4000-8000-000000001017':
      'https://img-global.cpcdn.com/recipes/eb79f43366c03197/1200x630cq80/photo.jpg',
  // Cơm nhà với cút lộn sốt me, giò bò giò nấm xào bông cải xanh, canh rau ngót đậu phụ thịt băm
  'de300000-0000-4000-8000-000000001019':
      'https://img-global.cpcdn.com/recipes/15cb99711ea80c57/1200x630cq80/photo.jpg',
  // Trứng chần không dùng giấm
  'de300000-0000-4000-8000-000000001020':
      'https://img-global.cpcdn.com/recipes/15a174b229d723ed/1200x630cq80/photo.jpg',
  // Bún riêu tôm thịt đơn giản
  'de300000-0000-4000-8000-000000001021':
      'https://img-global.cpcdn.com/recipes/1ae554cfb5ec4b6e/1200x630cq80/photo.jpg',
  // Cá Hồi Nướng Muối Tiêu
  'de300000-0000-4000-8000-000000001022':
      'https://img-global.cpcdn.com/recipes/396d31e1c5eb5996/1200x630cq80/photo.jpg',
  // Mâm cơm chay mùa Lễ Vu Lan
  'de300000-0000-4000-8000-000000001023':
      'https://img-global.cpcdn.com/recipes/675d498380dc0eeb/1200x630cq80/photo.jpg',
  // Canh kiểm chay
  'de300000-0000-4000-8000-000000001025':
      'https://img-global.cpcdn.com/recipes/8392a27c06a6012a/1200x630cq80/photo.jpg',
  // Nấm Rơm Kho Đậu Hũ
  'de300000-0000-4000-8000-000000001026':
      'https://img-global.cpcdn.com/recipes/8b0dd51ae50cafb4/1200x630cq80/photo.jpg',
  // Rau Củ Xào Ngũ Sắc
  'de300000-0000-4000-8000-000000001027':
      'https://img-global.cpcdn.com/recipes/be379b81d5be3150/1200x630cq80/photo.jpg',
};

final _nameImages = <String, String>{
  'cơm trắng': _seedImages['de300000-0000-4000-8000-000000001024']!,
  'xôi đậu xanh': _seedImages['de300000-0000-4000-8000-000000001024']!,
  'đậu hũ sốt nấm': _seedImages['de300000-0000-4000-8000-000000001026']!,
  'canh bí đỏ chay': _seedImages['de300000-0000-4000-8000-000000001025']!,
  'phở bò': _seedImages['de300000-0000-4000-8000-000000001001']!,
  'cơm tấm sườn nướng': _seedImages['de300000-0000-4000-8000-000000001002']!,
  'canh chua cá lóc': _seedImages['de300000-0000-4000-8000-000000001003']!,
  'thịt kho trứng': _seedImages['de300000-0000-4000-8000-000000001004']!,
  'rau muống xào tỏi': _seedImages['de300000-0000-4000-8000-000000001005']!,
  'gà kho gừng': _seedImages['de300000-0000-4000-8000-000000001006']!,
  'đậu hũ sốt cà chua': _seedImages['de300000-0000-4000-8000-000000001007']!,
  'bún chả hà nội': _seedImages['de300000-0000-4000-8000-000000001008']!,
  'tôm rim mặn ngọt': _seedImages['de300000-0000-4000-8000-000000001009']!,
  'canh bí đỏ thịt bằm': _seedImages['de300000-0000-4000-8000-000000001010']!,
  'cá kho tộ': _seedImages['de300000-0000-4000-8000-000000001011']!,
  'gỏi cuốn tôm thịt': _seedImages['de300000-0000-4000-8000-000000001012']!,
  'trứng chiên cà chua': _seedImages['de300000-0000-4000-8000-000000001013']!,
  'salad bơ trứng': _seedImages['de300000-0000-4000-8000-000000001014']!,
  'bò xào bông cải': _seedImages['de300000-0000-4000-8000-000000001015']!,
  'cháo gà': _seedImages['de300000-0000-4000-8000-000000001016']!,
  'mì xào chay': _seedImages['de300000-0000-4000-8000-000000001017']!,
  'canh rau ngót thịt bằm':
      _seedImages['de300000-0000-4000-8000-000000001019']!,
  'bánh mì trứng ốp la': _seedImages['de300000-0000-4000-8000-000000001020']!,
  'bún riêu nhà làm': _seedImages['de300000-0000-4000-8000-000000001021']!,
  'cá hồi áp chảo': _seedImages['de300000-0000-4000-8000-000000001022']!,
  'lẩu nấm chay': _seedImages['de300000-0000-4000-8000-000000001023']!,
  'canh bí đỏ nấu chay': _seedImages['de300000-0000-4000-8000-000000001025']!,
  'đậu hũ non sốt nấm': _seedImages['de300000-0000-4000-8000-000000001026']!,
  'cải ngọt xào tỏi': _seedImages['de300000-0000-4000-8000-000000001027']!,
};
