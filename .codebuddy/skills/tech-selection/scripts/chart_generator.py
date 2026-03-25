#!/usr/bin/env python3
# chart_generator.py - 技术选型图表生成器
#
# 依赖安装: pip install matplotlib numpy
#
# 使用方法:
#   python chart_generator.py --radar <data.json>
#   python chart_generator.py --bar <data.json>
#   python chart_generator.py --footprint <data.json>
#   python chart_generator.py --grouped <data.json>

import json
import sys
import os
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib
import numpy as np

# 设置中文字体支持（如果系统有中文字体）
matplotlib.rcParams['font.sans-serif'] = ['SF Pro Display', 'Arial', 'DejaVu Sans']
matplotlib.rcParams['axes.unicode_minus'] = False


class TechSelectionCharts:
    """技术选型图表生成器"""

    def __init__(self, output_dir="charts"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_radar_chart(self, data: dict, output_file: str = "radar_chart.png"):
        """
        生成雷达图

        data 格式:
        {
            "categories": ["序列化速度", "反序列化速度", ...],
            "series": [
                {"name": "方案 A", "values": [72, 68, ...]},
                {"name": "方案 B", "values": [95, 92, ...]}
            ]
        }
        """
        categories = data["categories"]
        N = len(categories)

        # 计算角度
        angles = [n / float(N) * 2 * np.pi for n in range(N)]
        angles += angles[:1]  # 闭合

        fig, ax = plt.subplots(figsize=(8, 8), subplot_kw=dict(polar=True))

        # 绘制每个系列
        colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd']
        for idx, series in enumerate(data["series"]):
            values = series["values"]
            values += values[:1]  # 闭合

            ax.plot(angles, values, 'o-', linewidth=2,
                   label=series["name"], color=colors[idx % len(colors)])
            ax.fill(angles, values, alpha=0.15, color=colors[idx % len(colors)])

        # 设置标签
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(categories, size=11)

        # 设置 y 轴范围
        ax.set_ylim(0, 100)
        ax.set_yticks([20, 40, 60, 80, 100])
        ax.set_yticklabels(["20", "40", "60", "80", "100"], size=9)

        ax.grid(True, linestyle='--', alpha=0.7)

        plt.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1))
        plt.title(data.get("title", "性能对比雷达图"), size=14, pad=20)

        output_path = self.output_dir / output_file
        plt.savefig(output_path, dpi=150, bbox_inches='tight',
                   facecolor='white', edgecolor='none')
        plt.close()
        print(f"Radar chart saved: {output_path}")
        return str(output_path)

    def generate_bar_chart(self, data: dict, output_file: str = "bar_chart.png"):
        """
        生成柱状图（综合得分对比）

        data 格式:
        {
            "title": "综合得分对比",
            "categories": ["方案 A", "方案 B", "方案 C"],
            "scores": [63.5, 72.0, 58.1],
            "best": "方案 B"
        }
        """
        categories = data["categories"]
        scores = data["scores"]

        # 确定最佳方案的颜色
        colors = ['#1f77b4'] * len(categories)
        best_idx = categories.index(data["best"]) if "best" in data and data["best"] in categories else -1
        if best_idx >= 0:
            colors[best_idx] = '#2ca02c'  # 绿色标注最佳

        fig, ax = plt.subplots(figsize=(10, 6))

        x = np.arange(len(categories))
        bars = ax.bar(x, scores, width=0.6, color=colors, edgecolor='black', linewidth=0.8)

        # 在柱子上方显示数值
        for bar, score in zip(bars, scores):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 1,
                   f'{score:.1f}',
                   ha='center', va='bottom', fontsize=12, fontweight='bold')

        ax.set_xlabel('方案', fontsize=12)
        ax.set_ylabel('综合得分', fontsize=12)
        ax.set_title(data.get("title", "综合得分对比"), fontsize=14, pad=15)
        ax.set_xticks(x)
        ax.set_xticklabels(categories, fontsize=11)
        ax.set_ylim(0, max(scores) * 1.15)
        ax.grid(axis='y', linestyle='--', alpha=0.7)

        # 添加图例
        from matplotlib.patches import Patch
        legend_elements = [
            Patch(facecolor='#2ca02c', label=f'推荐: {data["best"]}'),
            Patch(facecolor='#1f77b4', label='其他方案')
        ]
        ax.legend(handles=legend_elements, loc='upper right')

        plt.tight_layout()

        output_path = self.output_dir / output_file
        plt.savefig(output_path, dpi=150, bbox_inches='tight',
                   facecolor='white', edgecolor='none')
        plt.close()
        print(f"Bar chart saved: {output_path}")
        return str(output_path)

    def generate_footprint_chart(self, data: dict, output_file: str = "footprint_chart.png"):
        """
        生成 Footprint 对比柱状图

        data 格式:
        {
            "title": "内存占用对比 (MB)",
            "items": ["空载", "10K数据", "100K数据"],
            "series": [
                {"name": "方案 A", "values": [1.2, 3.5, 18.2]},
                {"name": "方案 B", "values": [0.8, 2.1, 12.5]}
            ]
        }
        """
        items = data["items"]
        n_items = len(items)
        n_series = len(data["series"])

        fig, ax = plt.subplots(figsize=(12, 6))

        bar_width = 0.8 / n_series
        x = np.arange(n_items)

        colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
        for idx, series in enumerate(data["series"]):
            offset = (idx - n_series/2 + 0.5) * bar_width
            bars = ax.bar(x + offset, series["values"], bar_width,
                         label=series["name"], color=colors[idx % len(colors)],
                         edgecolor='black', linewidth=0.5)

            # 数值标签
            for bar, val in zip(bars, series["values"]):
                ax.text(bar.get_x() + bar.get_width()/2., bar.get_height() + 0.3,
                       f'{val:.1f}', ha='center', va='bottom', fontsize=9)

        ax.set_xlabel('测试场景', fontsize=12)
        ax.set_ylabel(data.get("unit", "MB"), fontsize=12)
        ax.set_title(data.get("title", "内存占用对比"), fontsize=14, pad=15)
        ax.set_xticks(x)
        ax.set_xticklabels(items, fontsize=11)
        ax.legend(loc='upper left')
        ax.grid(axis='y', linestyle='--', alpha=0.7)

        plt.tight_layout()

        output_path = self.output_dir / output_file
        plt.savefig(output_path, dpi=150, bbox_inches='tight',
                   facecolor='white', edgecolor='none')
        plt.close()
        print(f"Footprint chart saved: {output_path}")
        return str(output_path)

    def generate_grouped_bar_chart(self, data: dict, output_file: str = "grouped_bar.png"):
        """
        生成分组柱状图（性能/易用性等多项对比）

        data 格式:
        {
            "title": "多维度对比",
            "dimensions": ["性能", "Footprint", "易用性", "Qt集成"],
            "series": [
                {"name": "方案 A", "values": [72, 75, 83, 100]},
                {"name": "方案 B", "values": [95, 85, 87, 60]},
                {"name": "方案 C", "values": [85, 60, 73, 40]}
            ]
        }
        """
        dimensions = data["dimensions"]
        n_dims = len(dimensions)
        n_series = len(data["series"])

        fig, ax = plt.subplots(figsize=(12, 7))

        bar_width = 0.8 / n_series
        x = np.arange(n_dims)

        colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']
        for idx, series in enumerate(data["series"]):
            offset = (idx - n_series/2 + 0.5) * bar_width
            ax.bar(x + offset, series["values"], bar_width,
                  label=series["name"], color=colors[idx % len(colors)],
                  edgecolor='black', linewidth=0.5)

        ax.set_xlabel('评估维度', fontsize=12)
        ax.set_ylabel('得分', fontsize=12)
        ax.set_title(data.get("title", "多维度对比"), fontsize=14, pad=15)
        ax.set_xticks(x)
        ax.set_xticklabels(dimensions, fontsize=11)
        ax.set_ylim(0, 110)
        ax.legend(loc='upper right')
        ax.grid(axis='y', linestyle='--', alpha=0.7)

        plt.tight_layout()

        output_path = self.output_dir / output_file
        plt.savefig(output_path, dpi=150, bbox_inches='tight',
                   facecolor='white', edgecolor='none')
        plt.close()
        print(f"Grouped bar chart saved: {output_path}")
        return str(output_path)


def main():
    if len(sys.argv) < 2:
        print("Usage: python chart_generator.py <data_file.json> [output_dir]")
        print("  or:  python chart_generator.py --radar <data.json>")
        print("  or:  python chart_generator.py --bar <data.json>")
        print("  or:  python chart_generator.py --footprint <data.json>")
        print("  or:  python chart_generator.py --grouped <data.json>")
        sys.exit(1)

    generator = TechSelectionCharts()

    if sys.argv[1] == "--radar" and len(sys.argv) >= 3:
        with open(sys.argv[2]) as f:
            data = json.load(f)
        generator.generate_radar_chart(data)
    elif sys.argv[1] == "--bar" and len(sys.argv) >= 3:
        with open(sys.argv[2]) as f:
            data = json.load(f)
        generator.generate_bar_chart(data)
    elif sys.argv[1] == "--footprint" and len(sys.argv) >= 3:
        with open(sys.argv[2]) as f:
            data = json.load(f)
        generator.generate_footprint_chart(data)
    elif sys.argv[1] == "--grouped" and len(sys.argv) >= 3:
        with open(sys.argv[2]) as f:
            data = json.load(f)
        generator.generate_grouped_bar_chart(data)
    else:
        # 假设是 JSON 文件，自动识别类型生成所有图表
        data_file = sys.argv[1]
        output_dir = sys.argv[2] if len(sys.argv) >= 3 else "charts"
        generator = TechSelectionCharts(output_dir)

        with open(data_file) as f:
            data = json.load(f)

        if "categories" in data and "series" in data:
            if "scores" in data.get("series", [{}])[0]:
                generator.generate_bar_chart(data)
            else:
                generator.generate_radar_chart(data)

        print(f"\nAll charts generated in: {generator.output_dir}")


if __name__ == "__main__":
    main()
