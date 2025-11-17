const express = require('express');
const cors = require('cors');
const { execFile } = require('child_process');
const { promisify } = require('util');

const execFileAsync = promisify(execFile);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'ichiran-api' });
});

// Parse ichiran-cli output with -i flag
function parseIchiranOutput(output) {
  const lines = output.trim().split('\n');
  
  if (lines.length === 0) {
    return { romanized: '', words: [] };
  }
  
  // First line is the romanized text
  const romanized = lines[0];
  
  // Parse word entries
  const words = [];
  let currentWord = null;
  
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    
    if (line.startsWith('* ')) {
      // Save previous word if exists
      if (currentWord) {
        words.push(currentWord);
      }
      
      // Parse word header: "* romaji  kanji 【kana】"
      const headerMatch = line.match(/^\*\s+(\S+)\s+(.*?)(?:\s+【(.*?)】)?$/);
      if (headerMatch) {
        currentWord = {
          word: headerMatch[1],
          text: headerMatch[2] ? headerMatch[2].trim() : headerMatch[1],
          kana: headerMatch[3] || '',
          glosses: []
        };
      }
    } else if (line && currentWord && line.match(/^\d+\./)) {
      // Parse gloss line: "1. [pos] definition"
      const glossMatch = line.match(/^\d+\.\s+(?:\[(.*?)\]\s+)?(?:《(.*?)》\s+)?(.*)/);
      if (glossMatch) {
        currentWord.glosses.push({
          pos: glossMatch[1] || '',
          info: glossMatch[2] || '',
          definition: glossMatch[3] || ''
        });
      }
    }
  }
  
  // Add last word
  if (currentWord) {
    words.push(currentWord);
  }
  
  return { romanized, words };
}

// Main romanize endpoint
app.post('/api/romanize', async (req, res) => {
  try {
    const { text } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text field is required' });
    }
    
    // Execute ichiran-cli with -i flag
    const { stdout, stderr } = await execFileAsync('ichiran-cli', ['-i', text], {
      timeout: 30000, // 30 second timeout
      maxBuffer: 1024 * 1024 // 1MB buffer
    });
    
    if (stderr) {
      console.error('ichiran-cli stderr:', stderr);
    }
    
    // Parse the output
    const result = parseIchiranOutput(stdout);
    
    res.json(result);
    
  } catch (error) {
    console.error('Error executing ichiran-cli:', error);
    
    if (error.code === 'ETIMEDOUT') {
      return res.status(504).json({ error: 'Request timeout' });
    }
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Alternative endpoint for full JSON output
app.post('/api/romanize/full', async (req, res) => {
  try {
    const { text, limit = 1 } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text field is required' });
    }
    
    // Execute ichiran-cli with -f flag for full JSON output
    const args = ['-f', '-l', String(limit), text];
    const { stdout, stderr } = await execFileAsync('ichiran-cli', args, {
      timeout: 30000,
      maxBuffer: 1024 * 1024
    });
    
    if (stderr) {
      console.error('ichiran-cli stderr:', stderr);
    }
    
    // Parse JSON output
    const result = JSON.parse(stdout);
    
    res.json(result);
    
  } catch (error) {
    console.error('Error executing ichiran-cli:', error);
    
    if (error.code === 'ETIMEDOUT') {
      return res.status(504).json({ error: 'Request timeout' });
    }
    
    if (error instanceof SyntaxError) {
      return res.status(500).json({ 
        error: 'Failed to parse ichiran-cli output',
        message: error.message 
      });
    }
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Ichiran API server listening on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API endpoint: http://localhost:${PORT}/api/romanize`);
});

