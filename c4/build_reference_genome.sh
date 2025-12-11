#!/bin/bash

# ============================================
# 通用参考基因组构建脚本
# 用于构建DNBC4tools兼容的参考基因组索引
# ============================================

set -e  # 遇到错误时退出

# 显示用法
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -s, --species <物种名>          物种名称（如：Mus_musculus, Homo_sapiens）"
    echo "  -n, --name <显示名称>           显示名称（如：Mouse, Human）"
    echo "  -v, --version <版本号>          基因组版本（如：GRCm39, GRCh38）"
    echo "  -f, --fasta <FASTA_URL>         FASTA文件下载URL"
    echo "  -g, --gtf <GTF_URL>             GTF文件下载URL"
    echo "  -o, --output <输出目录>         输出目录（默认：当前目录）"
    echo "  -t, --threads <线程数>          构建线程数（默认：10）"
    echo "  -h, --help                      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -s Mus_musculus -n Mouse -v GRCm39 \\"
    echo "     -f http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M31/GRCm39.primary_assembly.genome.fa.gz \\"
    echo "     -g http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M31/gencode.vM31.primary_assembly.annotation.gtf.gz \\"
    echo "     -o /nas/database/scrna/c4-refdata/mouse"
    echo ""
}

# 默认参数
SPECIES=""
DISPLAY_NAME=""
GENOME_VERSION=""
FASTA_URL=""
GTF_URL=""
OUTPUT_DIR="$(pwd)"
THREADS=10

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--species)
            SPECIES="$2"
            shift 2
            ;;
        -n|--name)
            DISPLAY_NAME="$2"
            shift 2
            ;;
        -v|--version)
            GENOME_VERSION="$2"
            shift 2
            ;;
        -f|--fasta)
            FASTA_URL="$2"
            shift 2
            ;;
        -g|--gtf)
            GTF_URL="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "错误: 未知选项 $1"
            usage
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$SPECIES" || -z "$FASTA_URL" || -z "$GTF_URL" ]]; then
    echo "错误: 缺少必需参数！"
    usage
    exit 1
fi

# 如果显示名称未指定，使用物种名
if [[ -z "$DISPLAY_NAME" ]]; then
    DISPLAY_NAME="$SPECIES"
fi

# 如果版本未指定，尝试从URL中提取
if [[ -z "$GENOME_VERSION" ]]; then
    echo "警告: 未指定基因组版本，将尝试从URL中提取"
    GENOME_VERSION="unknown"
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "============================================"
echo "开始构建参考基因组"
echo "============================================"
echo "物种: $SPECIES ($DISPLAY_NAME)"
echo "基因组版本: $GENOME_VERSION"
echo "输出目录: $OUTPUT_DIR"
echo "线程数: $THREADS"
echo "FASTA URL: $FASTA_URL"
echo "GTF URL: $GTF_URL"
echo "============================================"

# 步骤1: 下载参考基因组文件
echo "步骤1: 下载参考基因组文件..."

# 最终使用的标准文件名
FINAL_FASTA="genome.fa"
FINAL_GTF="annotation.gtf"

# 函数：下载并处理文件
download_and_process() {
    local url="$1"
    local expected_keyword="$2"  # "genome" 或 "annotation"
    local final_name="$3"        # "genome.fa" 或 "annotation.gtf"
    
    local filename=$(basename "$url")
    local base_name="${filename%.gz}"
    
    # 检查最终文件是否已存在
    if [[ -f "$final_name" ]]; then
        echo "文件 $final_name 已存在，跳过处理"
        return 0
    fi
    
    # 检查是否已存在压缩文件（可能来自之前的下载或手动放置）
    local found_compressed_file=""
    
    # 查找包含关键词的.gz文件
    for gz_file in *.gz; do
        if [[ -f "$gz_file" ]] && echo "$gz_file" | grep -qi "$expected_keyword"; then
            found_compressed_file="$gz_file"
            echo "发现已存在的压缩文件: $gz_file"
            break
        fi
    done
    
    # 如果找到已存在的压缩文件，使用它
    if [[ -n "$found_compressed_file" ]]; then
        echo "使用已存在的文件: $found_compressed_file"
        filename="$found_compressed_file"
        base_name="${filename%.gz}"
    else
        # 否则下载文件
        echo "下载文件: $filename (从: $(echo "$url" | cut -d'/' -f1-3)...)"
        
        # 使用wget下载文件，使用-O指定输出文件名
        # 先尝试--show-progress，如果失败则使用普通模式
        if wget --show-progress -O "$filename" "$url" 2>/dev/null; then
            echo "下载成功: $filename"
            show_file_size "$filename"
        elif wget -O "$filename" "$url"; then
            echo "下载成功: $filename"
            show_file_size "$filename"
        else
            echo "错误: 下载文件失败: $url"
            exit 1
        fi
    fi
    
    local input_file="$filename"
    
    # 如果文件是.gz压缩文件，解压它
    if [[ "$filename" == *.gz ]]; then
        echo "解压文件: $filename"
        gunzip -c "$filename" > "$base_name"
        # 注意：不删除原始压缩文件，以便后续使用
        input_file="$base_name"
        echo "解压完成: $input_file"
        show_file_size "$input_file"
    fi
    
    # 检查文件名是否包含关键词
    if echo "$input_file" | grep -qi "$expected_keyword"; then
        # 如果文件名已包含关键词，检查是否需要重命名
        if [[ "$input_file" != "$final_name" ]]; then
            echo "重命名 $input_file 为 $final_name"
            mv "$input_file" "$final_name"
        fi
    else
        # 如果文件名不包含关键词，仍然重命名为标准名称
        echo "重命名 $input_file 为 $final_name"
        mv "$input_file" "$final_name"
    fi
    
    echo "文件处理完成: $final_name"
}

# 函数：显示文件大小
show_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local size=$(du -h "$file" | cut -f1)
        echo "文件大小: $size"
    fi
}

# 下载并处理FASTA文件
download_and_process "$FASTA_URL" "genome" "$FINAL_FASTA"

# 下载并处理GTF文件
download_and_process "$GTF_URL" "annotation" "$FINAL_GTF"

# 步骤2: 过滤GTF文件（过滤non-polyA基因）
echo "步骤2: 过滤GTF文件..."
FILTERED_GTF="genes.filter.gtf"

if [[ ! -f "$FILTERED_GTF" ]]; then
    echo "过滤non-polyA基因..."
    dnbc4tools tools mkgtf \
        --ingtf annotation.gtf \
        --output "$FILTERED_GTF" \
        --type gene_type
else
    echo "过滤后的GTF文件已存在，跳过过滤"
fi

# 步骤3: 构建基因组索引
echo "步骤3: 构建基因组索引..."
echo "使用dnbc4tools构建索引，这可能需要较长时间..."

dnbc4tools rna mkref \
    --ingtf "$FILTERED_GTF" \
    --fasta genome.fa \
    --threads "$THREADS" \
    --species "$SPECIES"

# 步骤4: 创建配置文件
echo "步骤4: 创建配置文件..."
CONFIG_FILE="ref.json"

# 确定线粒体染色体名称
# 常见物种的线粒体染色体名称
declare -A MT_CHROMOSOMES
MT_CHROMOSOMES["Mus_musculus"]="chrM"
MT_CHROMOSOMES["Homo_sapiens"]="chrM"
MT_CHROMOSOMES["Rattus_norvegicus"]="chrM"
MT_CHROMOSOMES["Danio_rerio"]="chrM"
MT_CHROMOSOMES["Drosophila_melanogaster"]="chrM"
MT_CHROMOSOMES["Caenorhabditis_elegans"]="chrM"

MT_CHR="${MT_CHROMOSOMES[$SPECIES]}"
if [[ -z "$MT_CHR" ]]; then
    MT_CHR="chrM"  # 默认值
    echo "警告: 未知物种 $SPECIES，使用默认线粒体染色体名称: $MT_CHR"
fi

# 创建线粒体基因列表
echo "提取线粒体基因..."
MT_GENE_LIST="mtgene.list"
if [[ -f "$FILTERED_GTF" ]]; then
    grep "$MT_CHR" "$FILTERED_GTF" | grep -w "gene" | awk -F'\t' '{print $9}' | awk -F'gene_name "' '{print $2}' | awk -F'"' '{print $1}' | sort -u > "$MT_GENE_LIST" || true
fi

cat > "$CONFIG_FILE" << EOF
{
    "species": "$SPECIES",
    "display_name": "$DISPLAY_NAME",
    "genome_version": "$GENOME_VERSION",
    "genome": "$OUTPUT_DIR/genome.fa",
    "gtf": "$OUTPUT_DIR/annotation.gtf",
    "filtered_gtf": "$OUTPUT_DIR/$FILTERED_GTF",
    "genomeDir": "$OUTPUT_DIR",
    "chrmt": "$MT_CHR",
    "mtgenes": "$OUTPUT_DIR/$MT_GENE_LIST",
    "build_date": "$(date -I)",
    "build_tool": "DNBC4tools",
    "threads_used": $THREADS
}
EOF

# 步骤5: 清理中间文件（可选）
echo "步骤5: 清理中间文件..."
# 保留原始文件，只删除压缩文件
rm -f *.gz 2>/dev/null || true

echo "============================================"
echo "参考基因组构建完成！"
echo "============================================"
echo "输出目录: $OUTPUT_DIR"
echo "核心文件:"
echo "  - genome.fa (FASTA序列)"
echo "  - annotation.gtf (原始注释)"
echo "  - $FILTERED_GTF (过滤后注释)"
echo "  - Genome (STAR索引)"
echo "  - SAindex (STAR索引)"
echo "  - $CONFIG_FILE (配置文件)"
echo ""
echo "配置文件内容:"
cat "$CONFIG_FILE"
echo ""
echo "使用以下命令验证构建:"
echo "  ls -lh $OUTPUT_DIR"
echo ""
echo "构建日志已保存到: build.log"
echo "============================================"

# 保存构建日志
{
    echo "构建时间: $(date)"
    echo "物种: $SPECIES"
    echo "显示名称: $DISPLAY_NAME"
    echo "基因组版本: $GENOME_VERSION"
    echo "输出目录: $OUTPUT_DIR"
    echo "线程数: $THREADS"
    echo "FASTA URL: $FASTA_URL"
    echo "GTF URL: $GTF_URL"
    echo "构建状态: 成功"
} > "build.log"
