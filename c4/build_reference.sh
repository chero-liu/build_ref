#!/bin/bash

# DNBC4tools 参考基因组构建脚本
# 用法: ./build_reference.sh <物种名称> <FASTA文件> <GTF文件> [type参数] [输出目录]
# 示例: ./build_reference.sh Homo_sapiens /path/to/genome.fa /path/to/genes.gtf.gz gene_type /path/to/output
# 输入文件:
#   FASTA: 参考基因组FASTA文件（支持 .fa, .fa.gz, .fasta, .fasta.gz）
#   GTF: 基因注释GTF文件（支持 .gtf, .gtf.gz）
# 软件路径: /opt/dnbc4tools2.1.3/dnbc4tools

set -e  # 遇到错误时退出

# 检查参数
if [ $# -lt 3 ]; then
    echo "错误: 需要提供至少3个参数"
    echo "用法: $0 <物种名称> <FASTA文件> <GTF文件> [type参数] [输出目录]"
    echo "示例: $0 Homo_sapiens /nas/database/scrna/10x-refdata/GRCh38-2024-A/fasta/genome.fa /nas/database/scrna/10x-refdata/GRCh38-2024-A/genes/genes.gtf.gz gene_type ./output"
    echo "支持的物种: Homo_sapiens, Human, Mus_musculus, Mouse"
    echo "type参数: 用于过滤GTF的基因类型属性，默认: gene_type"
    echo "输出目录: 参考基因组索引输出目录，默认: 当前目录"
    exit 1
fi

SPECIES="$1"
FASTA="$2"
GTF_GZ="$3"

# 处理可选参数
if [ $# -ge 4 ]; then
    TYPE="$4"
else
    TYPE="gene_type"
fi

if [ $# -ge 5 ]; then
    WORKDIR="$5"
    mkdir -p "$WORKDIR"
    mkdir -p "$WORKDIR/star"
else
    WORKDIR=$(pwd)
fi

DNBC4TOOLS="/opt/dnbc4tools2.1.3/dnbc4tools"

# 将输入文件路径转换为绝对路径（如果它们是相对路径）
if [[ "$FASTA" != /* ]]; then
    FASTA="$(cd "$(dirname "$FASTA")" && pwd)/$(basename "$FASTA")"
fi

if [[ "$GTF_GZ" != /* ]]; then
    GTF_GZ="$(cd "$(dirname "$GTF_GZ")" && pwd)/$(basename "$GTF_GZ")"
fi

# 保存原始目录并切换到工作目录
ORIGINAL_DIR=$(pwd)
cd "$WORKDIR"
WORKDIR=$(pwd)  # 获取绝对路径

echo "=========================================="
echo "开始构建参考基因组"
echo "物种: $SPECIES"
echo "FASTA 文件: $FASTA"
echo "GTF 文件: $GTF_GZ"
echo "基因类型属性: $TYPE"
echo "工作目录: $WORKDIR"
echo "=========================================="

# 步骤1: 处理 FASTA 文件（如果是压缩文件则解压）
echo "步骤1: 处理 FASTA 文件..."
FASTA_EXT="${FASTA##*.}"
if [[ "$FASTA_EXT" == "gz" ]]; then
    # 如果是压缩文件，解压到工作目录
    FASTA_BASENAME=$(basename "$FASTA" .gz)
    FASTA_BASENAME=$(basename "$FASTA_BASENAME" .fa)
    FASTA_BASENAME=$(basename "$FASTA_BASENAME" .fasta)
    FASTA_UNZIPPED="${WORKDIR}/${FASTA_BASENAME}.fa"
    
    if [ -f "$FASTA_UNZIPPED" ]; then
        echo "解压后的 FASTA 文件已存在，跳过解压: $FASTA_UNZIPPED"
        FASTA_TO_USE="$FASTA_UNZIPPED"
    else
        echo "解压 $FASTA 到 $FASTA_UNZIPPED..."
        gunzip -c "$FASTA" > "$FASTA_UNZIPPED"
        echo "解压完成"
        FASTA_TO_USE="$FASTA_UNZIPPED"
    fi
else
    # 如果不是压缩文件，直接使用
    echo "FASTA 文件未压缩，直接使用"
    FASTA_TO_USE="$FASTA"
fi

# 步骤2: 处理 GTF 文件（如果是压缩文件则解压）
echo "步骤2: 处理 GTF 文件..."
GTF_EXT="${GTF_GZ##*.}"
if [[ "$GTF_EXT" == "gz" ]]; then
    # 如果是压缩文件，解压到工作目录
    GTF="${WORKDIR}/genes.gtf"
    if [ -f "$GTF" ]; then
        echo "解压后的 GTF 文件已存在，跳过解压: $GTF"
    else
        echo "解压 $GTF_GZ 到 $GTF..."
        gunzip -c "$GTF_GZ" > "$GTF"
        echo "解压完成"
    fi
else
    # 如果不是压缩文件，直接使用
    echo "GTF 文件未压缩，直接使用"
    GTF="$GTF_GZ"
fi

# 步骤3: 过滤 GTF 文件
echo "步骤3: 过滤 GTF 文件..."
FILTERED_GTF="${WORKDIR}/genes.filter.gtf"
if [ -f "$FILTERED_GTF" ]; then
    echo "过滤后的 GTF 文件已存在，跳过过滤"
else
    echo "过滤 GTF 文件..."
    $DNBC4TOOLS tools mkgtf \
        --ingtf "$GTF" \
        --output "$FILTERED_GTF" \
        --type "$TYPE"
    echo "过滤完成"
fi

# 步骤4: 构建基因组索引
echo "步骤4: 构建基因组索引..."
echo "使用以下命令构建索引:"
echo "  $DNBC4TOOLS rna mkref \\"
echo "    --fasta $FASTA_TO_USE \\"
echo "    --ingtf $FILTERED_GTF \\"
echo "    --species $SPECIES \\"
echo "    --threads 10 \\"
echo "    --genomeDir $WORKDIR/star"

$DNBC4TOOLS rna mkref \
    --fasta "$FASTA_TO_USE" \
    --ingtf "$FILTERED_GTF" \
    --species "$SPECIES" \
    --threads 10 \
    --genomeDir "$WORKDIR/star"

echo "=========================================="
echo "参考基因组构建完成！"
echo "输出文件在: $WORKDIR/star"
echo "=========================================="

# 列出生成的文件
echo "生成的文件:"
ls -la | grep -E '\.(fa|gtf|json|list|txt)$' || true
echo "参考基因组索引文件:"
find . -name "*.genome" -o -name "*.sa" -o -name "*.bwt" 2>/dev/null | head -20
