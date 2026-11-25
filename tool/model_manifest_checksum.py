"""Tính checksumSha256 cho manifest model on-device (on-device-ai-runtime.md §5.4.2).

Cách dùng:
    python tool/model_manifest_checksum.py assets/models/<task>/v<N>/metadata.json [--write]

- runtime == "mlkit-bundled": SHA-256 của metadata chuẩn hoá (bỏ `checksumSha256` ở cấp gốc,
  sort_keys, không khoảng trắng, UTF-8) — khớp `ModelManifest.canonicalManifestJson` (Dart là
  nguồn sự thật; test `model_packaging_test.dart` khoá hash cố định).
- runtime khác + payload đã có trong thư mục: SHA-256 của bytes file `payloadFile`.
- payload chưa ship: in ra "null" (không ghi checksum).

`--write` ghi lại checksum vào metadata.json (indent 2, LF). KHÔNG dùng `--write` để chuyển một
version từ "chưa ship" sang "đã ship" — §5.4.5 bắt tạo `v<N+1>`; tool từ chối trường hợp này.
"""
import hashlib
import json
import os
import sys


def canonical(meta):
    body = {k: v for k, v in meta.items() if k != 'checksumSha256'}
    return json.dumps(body, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')


def checksum(path):
    with open(path, encoding='utf-8') as f:
        meta = json.load(f)
    if meta.get('runtime') == 'mlkit-bundled':
        return meta, hashlib.sha256(canonical(meta)).hexdigest()
    if not meta.get('payloadFile'):
        sys.exit('payloadFile is required for runtime %r' % meta.get('runtime'))
    payload = os.path.join(os.path.dirname(path), meta['payloadFile'])
    if not os.path.exists(payload):
        return meta, None
    with open(payload, 'rb') as f:
        return meta, hashlib.sha256(f.read()).hexdigest()


def main():
    path = sys.argv[1]
    meta, value = checksum(path)
    print(value if value is not None else 'null')
    if '--write' in sys.argv:
        if meta.get('runtime') != 'mlkit-bundled' and meta.get('checksumSha256') is None and value is not None:
            sys.exit('payload chưa ship ở version này — tạo v<N+1> thay vì sửa tại chỗ (§5.4.5)')
        meta['checksumSha256'] = value
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(meta, f, indent=2, ensure_ascii=False)
            f.write('\n')


if __name__ == '__main__':
    main()
