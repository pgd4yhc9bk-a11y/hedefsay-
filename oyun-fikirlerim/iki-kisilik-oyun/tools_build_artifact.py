"""prototip-sis/index.html -> tek dosyalık artifact (sprite'lar data URI olarak gömülür).
Kullanım: python3 tools_build_artifact.py <cikti.html>"""
import re, sys, base64, os
HERE = os.path.dirname(os.path.abspath(__file__)); D = f'{HERE}/prototip-sis'
s = open(f'{D}/index.html', encoding='utf-8').read()
for m in set(re.findall(r"'(sprites/[a-z_]+\.png)'", s)):
    b = base64.b64encode(open(f'{D}/{m}', 'rb').read()).decode()
    s = s.replace(f"'{m}'", f"'data:image/png;base64,{b}'")
style = re.search(r'<style>(.*?)</style>', s, re.S).group(1); body = re.search(r'<body>(.*?)</body>', s, re.S).group(1)
open(sys.argv[1], 'w', encoding='utf-8').write('<title>Sis</title>\n<meta name="claude:viewport-fit-sides" content="cover">\n<style>' + style + '</style>\n' + body)
print(len(s) // 1024, 'KB')
