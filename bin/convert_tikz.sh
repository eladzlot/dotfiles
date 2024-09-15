#!/bin/bash

# Function to display the help message
function display_help() {
    echo "Usage: $0 <TikZ file>"
    echo
    echo "This script converts a TikZ file (with .tikz extension) into a PNG image."
    echo "The TikZ file should be in a standalone LaTeX document format."
    echo
    echo "Example:"
    echo "  $0 figure.tikz"
    exit 1
}

# Check if the input file is provided
if [ -z "$1" ]; then
    display_help
fi

input_file=$1

# Check if the file has a .tikz extension
if [[ $input_file != *.tikz ]]; then
    echo "Error: The input file must have a .tikz extension."
    display_help
fi

# Check if the file exists
if [ ! -f "$input_file" ]; then
    echo "Error: The file '$input_file' does not exist."
    exit 1
fi

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo "Error: pdflatex is not installed. Please install TeX Live."
    echo "You can install it using: sudo apt-get install texlive-full"
    exit 1
fi

# Check if pdftoppm is installed
if ! command -v pdftoppm &> /dev/null; then
    echo "Error: pdftoppm is not installed. Please install it."
    echo "You can install it using: sudo apt-get install poppler-utils"
    exit 1
fi

# Get the base name of the file (without extension)
base_name=$(basename "$input_file" .tikz)

# Create a LaTeX document from the TikZ file
cat <<EOF > "$base_name.tex"
\documentclass{standalone}
\usepackage{tikz}

\begin{document}
\input{$base_name.tikz}
\end{document}
EOF

# Compile the LaTeX document to PDF
pdflatex "$base_name.tex"

# Check if pdflatex command was successful
if [ $? -ne 0 ]; then
    echo "Error: pdflatex compilation failed."
    exit 1
fi

# Convert the PDF to PNG using pdftoppm
pdftoppm "$base_name.pdf" "$base_name" -png -singlefile

# Check if pdftoppm command was successful
if [ $? -ne 0 ]; then
    echo "Error: PDF to PNG conversion failed."
    exit 1
fi

# Optional: Remove intermediate files
rm "$base_name.aux" "$base_name.log" "$base_name.tex" "$base_name.pdf"

echo "Conversion complete: $base_name.png"
