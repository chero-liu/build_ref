#!/bin/bash

# ============================================
# 小鼠参考基因组构建脚本
# 使用通用构建脚本构建小鼠参考基因组
# ============================================

set -e

# 脚本目录
GENERIC_SCRIPT="/home/chenglong.liu/RaD/build_ref/c4/build_reference_genome.sh"

# 检查通用脚本是否存在
if [[ ! -f "$GENERIC_SCRIPT" ]]; then
    echo "错误: 未找到通用构建脚本: $GENERIC_SCRIPT"
    exit 1
fi

# 小鼠参考基因组参数
SPECIES="Mus_musculus"
DISPLAY_NAME="Mouse"
GENOME_VERSION="GRCm39"
THREADS=20

# 使用GENCODE的M33版本（根据用户提供的URL）
FASTA_URL="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M33/GRCm39.genome.fa.gz"
GTF_URL="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M33/gencode.vM33.annotation.gtf.gz"

# 输出目录（根据任务要求）
OUTPUT_DIR="/nas/database/scrna/c4-refdata/GRCm39-2024-A_C4/c4"

echo "============================================"
echo "开始构建小鼠参考基因组"
echo "============================================"
echo "使用通用构建脚本: $GENERIC_SCRIPT"
echo "输出目录: $OUTPUT_DIR"
echo "============================================"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 运行通用构建脚本
"$GENERIC_SCRIPT" \
    -s "$SPECIES" \
    -n "$DISPLAY_NAME" \
    -v "$GENOME_VERSION" \
    -f "$FASTA_URL" \
    -g "$GTF_URL" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS"

echo "============================================"
echo "小鼠参考基因组构建脚本执行完成"
echo "============================================"
echo "注意: 如果参考基因组已存在，脚本将跳过已有文件"
echo "如需强制重新构建，请先删除输出目录中的文件"
echo ""
echo "输出目录内容:"
ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "目录为空或不存在"
echo "============================================"
