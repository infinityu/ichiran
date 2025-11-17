# Ichiran API Examples

## Quick Examples

### Using cURL

#### Basic Romanization
```bash
curl -X POST https://your-app.railway.app/api/romanize \
  -H "Content-Type: application/json" \
  -d '{"text":"一覧は最高だぞ"}'
```

#### Full JSON Output
```bash
curl -X POST https://your-app.railway.app/api/romanize/full \
  -H "Content-Type: application/json" \
  -d '{"text":"一覧は最高だぞ", "limit": 3}'
```

### Using JavaScript/Node.js

```javascript
const axios = require('axios');

async function romanize(text) {
  const response = await axios.post('https://your-app.railway.app/api/romanize', {
    text: text
  });
  return response.data;
}

// Usage
romanize('一覧は最高だぞ').then(result => {
  console.log('Romanized:', result.romanized);
  console.log('Words:', result.words);
});
```

### Using Python

```python
import requests

def romanize(text):
    response = requests.post(
        'https://your-app.railway.app/api/romanize',
        json={'text': text}
    )
    return response.json()

# Usage
result = romanize('一覧は最高だぞ')
print(f"Romanized: {result['romanized']}")
for word in result['words']:
    print(f"- {word['word']}: {word['text']} ({word['kana']})")
```

### Using Go

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
)

type RomanizeRequest struct {
    Text string `json:"text"`
}

type RomanizeResponse struct {
    Romanized string `json:"romanized"`
    Words     []Word `json:"words"`
}

type Word struct {
    Word    string   `json:"word"`
    Text    string   `json:"text"`
    Kana    string   `json:"kana"`
    Glosses []Gloss  `json:"glosses"`
}

type Gloss struct {
    Pos        string `json:"pos"`
    Info       string `json:"info"`
    Definition string `json:"definition"`
}

func romanize(text string) (*RomanizeResponse, error) {
    reqBody, _ := json.Marshal(RomanizeRequest{Text: text})
    
    resp, err := http.Post(
        "https://your-app.railway.app/api/romanize",
        "application/json",
        bytes.NewBuffer(reqBody),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var result RomanizeResponse
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    return &result, nil
}

func main() {
    result, err := romanize("一覧は最高だぞ")
    if err != nil {
        panic(err)
    }
    
    fmt.Println("Romanized:", result.Romanized)
    for _, word := range result.Words {
        fmt.Printf("- %s: %s (%s)\n", word.Word, word.Text, word.Kana)
    }
}
```

### Using Ruby

```ruby
require 'net/http'
require 'json'
require 'uri'

def romanize(text)
  uri = URI.parse('https://your-app.railway.app/api/romanize')
  request = Net::HTTP::Post.new(uri)
  request.content_type = 'application/json'
  request.body = JSON.dump({ 'text' => text })
  
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  
  JSON.parse(response.body)
end

# Usage
result = romanize('一覧は最高だぞ')
puts "Romanized: #{result['romanized']}"
result['words'].each do |word|
  puts "- #{word['word']}: #{word['text']} (#{word['kana']})"
end
```

## Response Format

### Basic Romanization Response

```json
{
  "romanized": "ichiran wa saikō da zo",
  "words": [
    {
      "word": "ichiran",
      "text": "一覧",
      "kana": "いちらん",
      "glosses": [
        {
          "pos": "n,vs",
          "info": "",
          "definition": "look; glance; sight; inspection"
        },
        {
          "pos": "n",
          "info": "",
          "definition": "summary; list; table; catalog; catalogue"
        }
      ]
    },
    {
      "word": "wa",
      "text": "は",
      "kana": "",
      "glosses": [
        {
          "pos": "prt",
          "info": "pronounced わ in modern Japanese",
          "definition": "indicates sentence topic"
        }
      ]
    }
  ]
}
```

### Error Response

```json
{
  "error": "Text field is required"
}
```

or

```json
{
  "error": "Internal server error",
  "message": "Command failed: ..."
}
```

## Common Use Cases

### Furigana Generator
Extract kana readings for kanji text:

```javascript
function extractFurigana(text) {
  return romanize(text).then(result => {
    return result.words.map(word => ({
      kanji: word.text,
      reading: word.kana || word.word
    }));
  });
}
```

### Learning Flashcards
Create vocabulary flashcards:

```python
def create_flashcard(text):
    result = romanize(text)
    cards = []
    for word in result['words']:
        if word['kana']:  # Only words with kanji
            card = {
                'front': word['text'],
                'back': word['kana'],
                'meaning': [g['definition'] for g in word['glosses']],
                'pos': [g['pos'] for g in word['glosses']]
            }
            cards.append(card)
    return cards
```

### Text-to-Speech Preparation
Convert Japanese text to romanized form for TTS systems:

```javascript
async function prepareForTTS(text) {
  const result = await romanize(text);
  return result.romanized; // "ichiran wa saikō da zo"
}
```

## Rate Limiting

Currently, there is no built-in rate limiting. If you're making high-volume requests, please:
1. Implement client-side rate limiting
2. Cache results when possible
3. Consider running your own instance

## Error Handling

Always implement proper error handling:

```javascript
async function safeRomanize(text) {
  try {
    const response = await axios.post(API_URL, { text });
    return { success: true, data: response.data };
  } catch (error) {
    if (error.response) {
      // Server responded with error
      return { 
        success: false, 
        error: error.response.data.error,
        status: error.response.status 
      };
    } else if (error.request) {
      // No response received
      return { 
        success: false, 
        error: 'No response from server' 
      };
    } else {
      // Request setup error
      return { 
        success: false, 
        error: error.message 
      };
    }
  }
}
```

## Testing

Health check to verify the API is running:

```bash
curl https://your-app.railway.app/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "ichiran-api"
}
```

