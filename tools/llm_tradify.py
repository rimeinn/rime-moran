"""
調用 DeepSeek-v3 將詞庫轉換成繁體。

注意，LLM 輸出爲臺標，最後需用 opencc 轉爲 opencc 標。
"""

import requests
import json
import sys
import os
import time
import argparse

def read_input_file(filename):
    """Read the input file and return list of (word, pinyin) tuples"""
    words = []
    with open(filename, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and '\t' in line:
                word, pinyin = line.split('\t', 1)
                words.append((word, pinyin))
    return words

def create_batch_prompt(words):
    """Create a batch prompt with header and word list"""
    header = """請幫我判斷以下詞語中歧義字的正確繁體寫法。
每個詞我會提供：原詞、拼音。
語境是詞庫，大部分難以判斷具體意義者爲人名（而且多數可能是日語名），請根據語境和拼音提示選擇最合適的繁體字。

輸出格式：<正確繁體>	<拼音>
例如：
你好	ni hao

必須嚴格遵守此格式，只輸出結果，不輸出解釋說明。詞語和拼音間使用 tab 符號分割。

需要判斷的詞：

"""
    
    word_list = []
    for word, pinyin in words:
        word_list.append(f"{word}\t{pinyin}")
    
    return header + "\n".join(word_list)

def call_deepseek_api(prompt, api_key):
    """Call OpenRouter's DeepSeek V3 API"""
    url = "https://openrouter.ai/api/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/your-repo",  # Optional
        "X-Title": "Pinyin Traditional Converter"  # Optional
    }
    
    data = {
        "model": "deepseek/deepseek-chat",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,
        "max_tokens": 10000
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        result = response.json()
        return result['choices'][0]['message']['content']
    except requests.exceptions.RequestException as e:
        print(f"API request failed: {e}")
        return None
    except KeyError as e:
        print(f"Unexpected API response format: {e}")
        return None

def save_batch_files(batch_num, prompt, response, base_filename):
    """Save batch prompt and response to separate files"""
    base = os.path.splitext(base_filename)[0]
    
    # Save prompt
    prompt_file = f"{base}_batch{batch_num}.in"
    with open(prompt_file, 'w', encoding='utf-8') as f:
        f.write(prompt)
    
    # Save response
    response_file = f"{base}_batch{batch_num}.out"
    with open(response_file, 'w', encoding='utf-8') as f:
        f.write(response)
    
    return prompt_file, response_file

def process_in_batches(words, api_key, base_filename, batch_size):
    """Process words in batches and save each batch to separate files"""
    total_batches = (len(words) + batch_size - 1) // batch_size
    successful_batches = []
    
    for i in range(0, len(words), batch_size):
        batch = words[i:i + batch_size]
        batch_num = i // batch_size + 1
        
        print(f"Processing batch {batch_num}/{total_batches} ({len(batch)} words)...")
        
        # Create prompt for this batch
        prompt = create_batch_prompt(batch)
        
        # Save prompt to file
        prompt_file = f"{os.path.splitext(base_filename)[0]}_batch{batch_num}.in"
        with open(prompt_file, 'w', encoding='utf-8') as f:
            f.write(prompt)
        print(f"  Saved prompt to: {prompt_file}")
        
        # Call API
        response = call_deepseek_api(prompt, api_key)
        
        if response is None:
            print(f"  Failed to get response for batch {batch_num}")
            continue
        
        # Save response to file
        response_file = f"{os.path.splitext(base_filename)[0]}_batch{batch_num}.out"
        with open(response_file, 'w', encoding='utf-8') as f:
            f.write(response)
        print(f"  Saved response to: {response_file}")
        
        successful_batches.append(batch_num)
        
        # Add delay between requests to be respectful to the API
        if i + batch_size < len(words):  # Not the last batch
            print("  Waiting 2 seconds before next batch...")
            time.sleep(2)
    
    return successful_batches

def main():
    parser = argparse.ArgumentParser(description='Convert dictionary to traditional Chinese using DeepSeek-v3')
    parser.add_argument('input_file', help='Input file containing word-pinyin pairs')
    parser.add_argument('-b', '--batch-size', type=int, default=100, 
                       help='Number of words to process in each batch (default: 100)')
    
    args = parser.parse_args()
    
    # Get API key from environment variable
    api_key = os.getenv('OPENROUTER_API_KEY')
    if not api_key:
        print("Error: Please set OPENROUTER_API_KEY environment variable")
        sys.exit(1)
    
    # Check if input file exists
    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' not found")
        sys.exit(1)
    
    # Validate batch size
    if args.batch_size <= 0:
        print("Error: Batch size must be a positive integer")
        sys.exit(1)
    
    # Read input file
    words = read_input_file(args.input_file)
    if not words:
        print("Error: No valid words found in input file")
        sys.exit(1)
    
    print(f"Processing {len(words)} words in batches of {args.batch_size}...")
    print(f"Each batch will be saved as separate .in and .out files")
    
    # Process in batches
    successful_batches = process_in_batches(words, api_key, args.input_file, args.batch_size)
    
    if not successful_batches:
        print("Failed to process any batches successfully")
        sys.exit(1)
    
    print(f"\nCompleted processing {len(successful_batches)} batches successfully:")
    base = os.path.splitext(args.input_file)[0]
    for batch_num in successful_batches:
        print(f"  {base}_batch{batch_num}.in")
        print(f"  {base}_batch{batch_num}.out")

if __name__ == "__main__":
    main()
