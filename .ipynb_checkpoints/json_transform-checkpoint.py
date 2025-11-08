#!/usr/bin/env python3
# fitness_csv_to_json_format2.py
# Converts fitness program CSV data to JSON(Object with Program IDs as keys)

import pandas as pd
import json
import re
import sys
import os

def clean_markdown(text):
    """Clean up markdown text for better JSON formatting"""
    if not isinstance(text, str):
        return ""
    # Replace tabs with spaces
    text = text.replace("\t", "    ")
    # Ensure consistent line breaks
    text = text.replace("\r\n", "\n")
    return text

def convert_csv_to_json_format2(csv_path, json_path):
    """Convert CSV to JSON Format 2 (Object with Program IDs as Keys)"""
    print(f"Loading CSV from {csv_path}")
    df = pd.read_csv(csv_path)
    print(f"Loaded {len(df)} records")
    
    # Convert level and goal columns from string to actual JSON arrays
    for col in ['level', 'goal']:
        if col in df.columns:
            df[col] = df[col].apply(
                lambda x: json.loads(x) if isinstance(x, str) and x.startswith('[') else 
                          [x] if isinstance(x, str) else x
            )
    
    # Clean up markdown fields
    if 'exercise_guidance' in df.columns:
        df['exercise_guidance'] = df['exercise_guidance'].apply(clean_markdown)
    if 'description' in df.columns:
        df['description'] = df['description'].apply(clean_markdown)
    
    # Create dictionary with program_id as key
    print("Converting to JSON Format 2...")
    format2 = {}
    for _, row in df.iterrows():
        program_id = row['program_id']
        # Remove program_id from the record since it's used as the key
        program_data = row.drop('program_id').to_dict()
        format2[program_id] = program_data
    
    # Save to JSON file with pretty formatting
    print(f"Saving to {json_path}")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(format2, f, indent=2, ensure_ascii=False)
    
    print(f"Successfully converted {len(format2)} programs to JSON Format 2")
    print(f"File saved to: {json_path}")
    
    return format2

# Main execution
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fitness_csv_to_json_format2.py <csv_file> [output_file]")
        print("If output_file is not specified, it will use the same name with .json extension")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    if len(sys.argv) >= 3:
        json_file = sys.argv[2]
    else:
        # Use same filename but with .json extension
        base_name = os.path.splitext(csv_file)[0]
        json_file = f"{base_name}_format2.json"
    
    convert_csv_to_json_format2(csv_file, json_file)
