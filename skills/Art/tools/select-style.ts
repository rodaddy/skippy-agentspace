#!/usr/bin/env bun
/**
 * Style Selection Helper
 *
 * Reads user preferences and returns ranked style options
 * Used by PAI to present smart style choices
 *
 * Usage: bun select-style.ts [--json]
 */

import { readFile } from 'fs/promises';
import { join } from 'path';
import { homedir } from 'os';

const PREFERENCES_FILE = join(homedir(), '.config/pai/preferences/image-styles.json');

interface StylePreferences {
  styles: {
    [key: string]: {
      rating: number;
      count: number;
      last_used: string | null;
      description: string;
      tags: string[];
    };
  };
  metadata: {
    version: string;
    last_updated: string | null;
    total_ratings: number;
  };
}

interface RankedStyle {
  name: string;
  rating: number;
  count: number;
  stars: string;
  description: string;
  isRecommended: boolean;
}

const STYLE_DESCRIPTIONS: { [key: string]: string } = {
  'minimalist-flat': 'Clean geometric shapes, solid colors, Dribbble-style minimal flat illustration',
  'isometric-3d': 'Depth and perspective, professional corporate aesthetic like Slack or Notion',
  'blueprint': 'White/cyan lines on blue background, engineering schematic, technical drawing style',
  'glassmorphism': 'Frosted glass panels, blur effects, vibrant gradients, iOS-style premium design',
  'cyberpunk': 'Neon colors, dark background, Blade Runner aesthetic, futuristic tech',
  'retro-synthwave': '80s gradients, grid patterns, vaporwave aesthetic, nostalgic tech',
  'hand-drawn': 'Whiteboard marker style, sketch aesthetic, informal and approachable',
  'neumorphism': 'Soft shadows, embossed look, subtle depth, minimalist modern'
};

async function loadPreferences(): Promise<StylePreferences> {
  try {
    const data = await readFile(PREFERENCES_FILE, 'utf-8');
    return JSON.parse(data);
  } catch {
    return {
      styles: {},
      metadata: {
        version: '1.0',
        last_updated: null,
        total_ratings: 0
      }
    };
  }
}

function generateStars(rating: number, count: number): string {
  if (count === 0) return '☆☆☆☆☆ (Not rated yet)';

  const filled = Math.round(rating);
  const stars = '★'.repeat(filled) + '☆'.repeat(5 - filled);
  return `${stars} (${rating.toFixed(1)}/5, ${count} ratings)`;
}

async function getRankedStyles(): Promise<RankedStyle[]> {
  const prefs = await loadPreferences();
  const styles: RankedStyle[] = [];

  // Add rated styles
  for (const [name, data] of Object.entries(prefs.styles)) {
    if (data.count > 0) {
      styles.push({
        name,
        rating: data.rating,
        count: data.count,
        stars: generateStars(data.rating, data.count),
        description: data.description || STYLE_DESCRIPTIONS[name] || '',
        isRecommended: data.rating >= 4 && data.count >= 2
      });
    }
  }

  // Add unrated styles
  for (const [name, desc] of Object.entries(STYLE_DESCRIPTIONS)) {
    if (!prefs.styles[name] || prefs.styles[name].count === 0) {
      styles.push({
        name,
        rating: 0,
        count: 0,
        stars: generateStars(0, 0),
        description: desc,
        isRecommended: false
      });
    }
  }

  // Sort by rating (desc), then count (desc)
  return styles.sort((a, b) => {
    if (b.rating !== a.rating) return b.rating - a.rating;
    return b.count - a.count;
  });
}

async function main() {
  const args = process.argv.slice(2);
  const jsonOutput = args.includes('--json');

  const ranked = await getRankedStyles();

  if (jsonOutput) {
    console.log(JSON.stringify(ranked, null, 2));
  } else {
    console.log('📊 Your Image Style Preferences (Ranked)\n');

    ranked.forEach((style, index) => {
      const badge = index === 0 && style.isRecommended ? ' 🏆 RECOMMENDED' : '';
      console.log(`${index + 1}. ${style.name}${badge}`);
      console.log(`   ${style.stars}`);
      console.log(`   ${style.description}`);
      console.log('');
    });

    if (ranked.length === 0) {
      console.log('No styles rated yet. Generate some images and rate them!');
    }
  }
}

main();
