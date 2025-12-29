#!/usr/bin/env node
/**
 * AIDD Log Cleaner
 *
 * Cleans up `.aidd/iterations` (or legacy `.autok/iterations`) logs by removing:
 * - ANSI escape sequences and terminal control characters
 * - Duplicate progress indicators
 * - Empty lines and excessive whitespace
 * - Terminal UI artifacts
 * - Verbose tool output while preserving meaningful content
 */
import fs from 'fs';
import path from 'path';

function cleanLogContent(content) {
	let cleaned = content;

	// Remove ALL ANSI escape sequences (comprehensive)
	cleaned = cleaned.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, '');
	cleaned = cleaned.replace(/\x1b\[?\d*[hl]/g, '');
	cleaned = cleaned.replace(/\x1b[=>]/g, '');
	cleaned = cleaned.replace(/\x1b(B|[\x40-\x5F])/g, '');
	cleaned = cleaned.replace(/\x07/g, ''); // Bell character

	// Remove terminal title changes more aggressively
	cleaned = cleaned.replace(/\]0;[^\x07\n]*[\x07\n]/g, '');
	cleaned = cleaned.replace(/0;[^-\n]*-\s*/g, ''); // Remaining title fragments

	// Remove tool availability table and other UI artifacts
	cleaned = cleaned.replace(/^[┌│└┘├┤┬┴┼─\s]*$/gm, '');
	cleaned = cleaned.replace(
		/^Group\s+\|\s+Tools[\s\S]*?└──────────┴───────────────────────────────────────────────────────────────────┘$/gm,
		''
	);

	cleaned = cleaned.replace(
		/   ┌────────────────────────────────────────────────────────────────────────┐/g,
		''
	);
	cleaned = cleaned.replace(/   │/g, '');

	// Remove any remaining standalone border lines
	cleaned = cleaned.replace(/^[┌│└┘├┤┬┴┼─]+$/gm, '');

	// Remove duplicate consecutive lines
	cleaned = cleaned.replace(/(.+\r?\n)\1+/g, '$1');

	// Remove lines with only whitespace
	cleaned = cleaned.replace(/^\s*\n?/gm, '');

	// Clean up whitespace
	cleaned = cleaned.replace(/[ \t]+$/gm, '');

	// Remove excessive consecutive empty lines
	cleaned = cleaned.replace(/\n{3,}/g, '\n\n');

	// Clean up beginning and end
	cleaned = cleaned.trim();

	return cleaned;
}

function processLogFile(filePath, options = {}) {
	const { backup = true, outputDir = null } = options;

	console.error(`Processing: ${filePath}`);

	try {
		const content = fs.readFileSync(filePath, 'utf8');
		const cleaned = cleanLogContent(content);

		// Determine output path
		let outputPath;
		if (outputDir) {
			const filename = path.basename(filePath);
			outputPath = path.join(outputDir, filename);
		} else if (backup) {
			outputPath = filePath;
			// Create backup
			const backupPath = filePath + '.backup';
			fs.writeFileSync(backupPath, content);
			console.error(`  Created backup: ${backupPath}`);
		} else {
			outputPath = filePath;
		}

		// Write cleaned content
		fs.writeFileSync(outputPath, cleaned);

		const originalSize = Buffer.byteLength(content, 'utf8');
		const cleanedSize = Buffer.byteLength(cleaned, 'utf8');
		const reduction = (((originalSize - cleanedSize) / originalSize) * 100).toFixed(1);

		console.error(`  Cleaned: ${outputPath}`);
		console.error(
			`  Size reduction: ${originalSize} → ${cleanedSize} bytes (${reduction}% smaller)`
		);
	} catch (error) {
		console.error(`  Error processing ${filePath}:`, error.message);
	}
}

function processDirectory(dirPath, options = {}) {
	if (!fs.existsSync(dirPath)) {
		console.error(`Directory not found: ${dirPath}`);
		process.exit(1);
	}

	const { backup = true, outputDir = null } = options;

	console.error(`Scanning directory: ${dirPath}`);

	const files = fs
		.readdirSync(dirPath)
		.filter((file) => file.endsWith('.log'))
		.sort();

	if (files.length === 0) {
		console.error('No .log files found.');
		return;
	}

	console.error(`Found ${files.length} log files`);

	// Create output directory if specified
	if (outputDir) {
		fs.mkdirSync(outputDir, { recursive: true });
		console.error(`Output directory: ${outputDir}`);
	}

	// Process each file
	files.forEach((file) => {
		const filePath = path.join(dirPath, file);
		processLogFile(filePath, options);
	});
}

function main() {
	const args = process.argv.slice(2);

	if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
		console.error(`
AIDD Log Cleaner

Usage:
  node clean-logs.js <directory-or-file> [options]

Options:
  --no-backup     Overwrite original files without creating backups
  --output-dir    Write cleaned files to a different directory
  --help, -h      Show this help message

Examples:
  # Clean all logs in a directory (with backups)
  node clean-logs.js D:\\\\applications\\\\aidd-todo\\\\.aidd\\\\iterations

  # Clean a single log file (with backup)
  node clean-logs.js D:\\\\applications\\\\aidd-todo\\\\.aidd\\\\iterations\\\\001.log

  # Clean logs without backups
  node clean-logs.js D:\\\\applications\\\\aidd-todo\\\\.aidd\\\\iterations --no-backup

  # Write cleaned logs to a new directory
  node clean-logs.js D:\\\\applications\\\\aidd-todo\\\\.aidd\\\\iterations --output-dir cleaned-logs
`);
		process.exit(0);
	}

	const inputPath = args[0];
	const options = {
		backup: !args.includes('--no-backup'),
		outputDir: null,
	};

	// Parse output directory
	const outputDirIndex = args.indexOf('--output-dir');
	if (outputDirIndex !== -1 && args[outputDirIndex + 1]) {
		options.outputDir = args[outputDirIndex + 1];
	}

	// Check if input is a file or directory
	const stat = fs.statSync(inputPath);
	if (stat.isDirectory()) {
		processDirectory(inputPath, options);
	} else if (stat.isFile() && inputPath.endsWith('.log')) {
		// Create output directory if specified for single file
		if (options.outputDir) {
			fs.mkdirSync(options.outputDir, { recursive: true });
		}
		processLogFile(inputPath, options);
	} else {
		console.error(`Error: ${inputPath} is not a .log file or directory`);
		process.exit(1);
	}
}

// Run the script
main();
