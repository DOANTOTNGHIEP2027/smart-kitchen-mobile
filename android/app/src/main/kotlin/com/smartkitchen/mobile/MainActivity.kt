package com.smartkitchen.mobile

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Deep link mời vào Nhà (fe-onboarding.md §12b, D9).
     *
     * Khi app mở nguội từ link, engine đưa **nguyên URI** làm initial route
     * (vd. `https://app.smartkitchen.vn/join/ABC12345`). GetX không khớp được
     * chuỗi đó với `/join/:code` và crash. Chỉ trả path (+query) để route
     * thành `/join/ABC12345` — giống hệt cách framework xử lý link lúc app
     * đang chạy (`didPushRouteInformation` dùng `uri.path`).
     */
    override fun getInitialRoute(): String? {
        val current = intent
        if (current?.action != Intent.ACTION_VIEW) return super.getInitialRoute()
        val data = current.data ?: return super.getInitialRoute()
        val path = data.path ?: return SPLASH_ROUTE
        // Chỉ nhận đúng `/join/<code>`; path lạ (thêm segment, `%2F` đã bị
        // decode...) về splash thay vì để GetX không khớp route và ra màn
        // trắng. Không trả `super` vì nó sẽ đưa lại nguyên URI.
        if (!JOIN_PATH.matches(path)) return SPLASH_ROUTE
        val query = data.encodedQuery
        return if (query.isNullOrEmpty()) path else "$path?$query"
    }

    /**
     * App đang chạy: Flutter đẩy `uri.path` lên Navigator. Path lạ (vd.
     * `/join/A/B`) làm GetX ném lỗi null-check — bỏ `data` để engine không
     * đẩy route nào, plugin vẫn nhận intent (code review #28 HIGH-1).
     */
    override fun onNewIntent(intent: Intent) {
        val data = intent.data
        if (intent.action != Intent.ACTION_VIEW || data == null) {
            super.onNewIntent(intent)
            return
        }
        val path = data.path
        if (path == null || !JOIN_PATH.matches(path)) {
            super.onNewIntent(Intent(intent).setData(null))
            return
        }
        // Engine đẩy nguyên URI (cả fragment); GetX không parse được `#…`
        // → bỏ fragment, giữ path + query (code review #28 v2 NEW-1).
        if (data.fragment != null) {
            super.onNewIntent(Intent(intent).setData(data.buildUpon().fragment(null).build()))
            return
        }
        super.onNewIntent(intent)
    }

    private companion object {
        const val SPLASH_ROUTE = "/splash"
        // Chỉ ký tự mà mã mời và GetX đều nhận được; path đã decode nên
        // khoảng trắng, `#`, chữ có dấu… đều bị loại.
        val JOIN_PATH = Regex("^/join/[A-Za-z0-9-]+/?$")
    }
}
