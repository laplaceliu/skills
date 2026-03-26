#!/usr/bin/env python3
"""
Kroki 图片渲染脚本
将 Mermaid 等图表定义渲染为 PNG 图片

依赖: requests, urllib3
安装: pip install requests urllib3

Usage:
    # 单个图表渲染
    python kroki_render.py --type mermaid --output output.png --content "graph TD; A[开始] --> B[结束]"

    # 从文件读取图表定义
    python kroki_render.py --type mermaid --output output.png --input diagram.mmd

    # 批量渲染 (YAML 配置文件)
    python kroki_render.py --output ./diagrams/ --config diagrams.yml
"""

import argparse
import base64
import json
import os
import sys
import urllib.parse
from pathlib import Path
from typing import Optional

try:
    import requests
except ImportError:
    print("错误: 需要安装 requests 库")
    print("执行: pip install requests")
    sys.exit(1)

DEFAULT_KROKI_HOST = "localhost"
DEFAULT_KROKI_PORT = 8080
DEFAULT_KROKI_URL = f"http://{DEFAULT_KROKI_HOST}:{DEFAULT_KROKI_PORT}"


def encode_diagram(content: str, diagram_type: str) -> str:
    """
    将图表定义编码为 URL 安全的 base64 字符串
    """
    # 清理内容
    content = content.strip()

    # 统一使用 utf-8 编码后 base64
    encoded = base64.urlsafe_b64encode(content.encode('utf-8')).decode('ascii')
    return encoded


def render_to_bytes(diagram_content: str, diagram_type: str,
                    output_format: str = "png",
                    kroki_url: str = DEFAULT_KROKI_URL) -> bytes:
    """
    直接通过 Kroki API 获取图片字节流

    Args:
        diagram_content: Mermaid 图表定义
        diagram_type: 图表类型 (mermaid, plantuml, graphviz 等)
        output_format: 输出格式 (png, svg, pdf)
        kroki_url: Kroki 服务地址

    Returns:
        图片二进制数据
    """
    encoded = encode_diagram(diagram_content, diagram_type)
    url = f"{kroki_url}/{diagram_type}/{output_format}/{encoded}"

    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.content
    except requests.exceptions.ConnectionError:
        raise ConnectionError(
            f"无法连接到 Kroki 服务 ({kroki_url})。"
            f"请确保已启动 Docker Compose 服务:\n"
            f"  docker compose -f docker-compose.kroki.yml up -d"
        )
    except requests.exceptions.HTTPError as e:
        raise RuntimeError(f"Kroki 服务返回错误: {e}\n响应内容: {response.text}")


def render_to_file(diagram_content: str, diagram_type: str,
                   output_path: str,
                   output_format: str = "png",
                   kroki_url: str = DEFAULT_KROKI_URL) -> None:
    """
    将图表渲染并保存为图片文件
    """
    # 确保输出目录存在
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # 渲染图片
    image_bytes = render_to_bytes(diagram_content, diagram_type, output_format, kroki_url)

    # 写入文件
    with open(output_path, 'wb') as f:
        f.write(image_bytes)

    print(f"✓ 已生成: {output_path} ({len(image_bytes)} bytes)")


def render_from_file(input_path: str, diagram_type: str,
                    output_path: str,
                    output_format: str = "png",
                    kroki_url: str = DEFAULT_KROKI_URL) -> None:
    """
    从文件读取图表定义并渲染
    """
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    render_to_file(content, diagram_type, output_path, output_format, kroki_url)


def render_batch(config_path: str, output_dir: str,
                 output_format: str = "png",
                 kroki_url: str = DEFAULT_KROKI_URL) -> None:
    """
    批量渲染图表（从 YAML 配置文件）

    YAML 格式:
    diagrams:
      - name: flowchart1
        type: mermaid
        input: diagrams/flow.mmd
        output: output/flow.png

      - name: sequence1
        type: mermaid
        content: |
          sequenceDiagram
            A->>B: Hello
    """
    import yaml

    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    diagrams = config.get('diagrams', [])

    for diagram in diagrams:
        name = diagram.get('name', 'unnamed')
        diagram_type = diagram.get('type', 'mermaid')

        # 支持两种输入方式: input (文件) 或 content (直接内容)
        if 'input' in diagram:
            input_path = diagram['input']
            output_path = diagram.get('output', str(output_dir / f"{name}.png"))
            print(f"\n渲染 [{name}] from file: {input_path}")
            render_from_file(input_path, diagram_type, output_path, output_format, kroki_url)
        elif 'content' in diagram:
            content = diagram['content']
            output_path = diagram.get('output', str(output_dir / f"{name}.png"))
            print(f"\n渲染 [{name}] from content")
            render_to_file(content, diagram_type, output_path, output_format, kroki_url)
        else:
            print(f"警告: [{name}] 缺少 input 或 content 字段，跳过")


def main():
    parser = argparse.ArgumentParser(
        description="Kroki 图片渲染工具 - 将 Mermaid 等图表渲染为 PNG",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 渲染单个图表
  python kroki_render.py --type mermaid --output output.png --content "graph TD; A --> B"

  # 从文件读取
  python kroki_render.py --type mermaid --input diagram.mmd --output output.png

  # 批量渲染
  python kroki_render.py --config diagrams.yml --output ./output/

  # 指定 Kroki 服务地址
  python kroki_render.py --type mermaid --output out.png --content "..." --kroki-url http://192.168.1.100:8080
"""
    )

    # 输入方式 (互斥)
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('--content', '-c', help='图表定义内容 (直接指定)')
    input_group.add_argument('--input', '-i', help='图表定义文件路径')
    input_group.add_argument('--config', help='批量渲染配置文件 (YAML)')

    parser.add_argument('--type', '-t', default='mermaid',
                       help='图表类型: mermaid, plantuml, graphviz, waveDrom, 等 (默认: mermaid)')
    parser.add_argument('--output', '-o', help='输出文件路径或目录')
    parser.add_argument('--format', '-f', default='png',
                       help='输出格式: png, svg, pdf (默认: png)')
    parser.add_argument('--kroki-url', default=DEFAULT_KROKI_URL,
                       help=f'Kroki 服务地址 (默认: {DEFAULT_KROKI_URL})')

    args = parser.parse_args()

    # 批量模式
    if args.config:
        if not args.output:
            parser.error("批量渲染模式需要指定 --output 输出目录")
        render_batch(args.config, args.output, args.format, args.kroki_url)
        return

    # 单个渲染模式
    if not args.output:
        parser.error("需要指定 --output 输出文件路径")

    if args.content:
        render_to_file(args.content, args.type, args.output, args.format, args.kroki_url)
    elif args.input:
        render_from_file(args.input, args.type, args.output, args.format, args.kroki_url)


if __name__ == '__main__':
    main()
