#!/bin/bash

# ============================================
# 人类参考基因组构建脚本
# 使用通用构建脚本构建人类参考基因组
# ============================================

set -e

GENERIC_SCRIPT="/home/chenglong.liu/RaD/build_ref/c4/build_reference_genome.sh"

# 检查通用脚本是否存在
if [[ ! -f "$GENERIC_SCRIPT" ]]; then
    echo "错误: 未找到通用构建脚本: $GENERIC_SCRIPT"
    exit 1
fi

# 人类参考基因组参数
SPECIES="Homo_sapiens"
DISPLAY_NAME="Human"
GENOME_VERSION="GRCh38"
THREADS=20

# 使用GENCODE的最新版本
# 注意: 可以根据需要修改版本号
FASTA_URL="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/GRCh38.p14.genome.fa.gz"
GTF_URL="http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.annotation.gtf.gz"

# 输出目录 - 可以根据需要修改
OUTPUT_DIR="/nas/database/scrna/c4-refdata/GRCh38-2024-A_C4/c4"

echo "============================================"
echo "开始构建人类参考基因组"
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
echo "人类参考基因组构建脚本执行完成"
echo "============================================"
echo "注意: 如果参考基因组已存在，脚本将跳过已有文件"
echo "如需强制重新构建，请先删除输出目录中的文件"
echo ""
echo "输出目录内容:"
ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "目录为空或不存在"
echo "============================================"
