import { describe, it, expect, beforeEach, mock, spyOn } from 'bun:test';
import type { PathOrFileDescriptor } from 'fs';
import type { RequestOptions } from 'http';
import { join } from 'path';

// Define types for our keybindings
type VSCodeKeybinding = {
  key?: string;
  command?: string;
  when?: string;
}

// Define types for our mocked response
interface MockedResponse {
  on(event: 'data' | 'end', cb: (data?: string) => void): MockedResponse;
}

const mockedReadFileSync = mock((path: PathOrFileDescriptor, options?: { encoding: BufferEncoding }) => '');
const mockedGet = mock((url: string | URL | RequestOptions, callback?: (res: MockedResponse) => void) => ({ on: () => ({}) }));

import {
  vscode_keybindings_extractor_helper,
  extract_vscode_keybindings,
} from './extract_vscode_keybindings.js';

describe('VS Code Keybindings Extractor', () => {
  const mockedFetchJson = spyOn(vscode_keybindings_extractor_helper, 'fetchJson')
  const mockedFindVscodeKeybindings = spyOn(vscode_keybindings_extractor_helper, 'find_vscode_keybindings')

  beforeEach(() => {
    mock.restore();
  });

  describe('vscode_keybindings_extractor_helper', () => {
    describe('find_vscode_keybindings_file', () => {
      it('returns correct path for macOS', () => {
        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings_file('darwin', '/Users/testuser'))
          .toBe('/Users/testuser/Library/Application Support/Code/User/keybindings.json');
      });

      it('returns correct path for Linux', () => {
        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings_file('linux', '/home/testuser'))
          .toBe('/home/testuser/.config/Code/User/keybindings.json');
      });

      it('returns correct path for Windows', () => {
        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings_file('win32', 'C:\\Users\\testuser'))
          .toBe('C:\\Users\\testuser\\AppData\\Roaming\\Code\\User\\keybindings.json');
      });
    });

    describe('find_vscode_keybindings', () => {
      it('returns empty array for empty file', () => {
        mockedReadFileSync.mockImplementationOnce(() => '');
        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings('test.json')).toEqual([]);
      });

      it('parses JSON and removes comments', () => {
        mockedReadFileSync.mockImplementationOnce(() => `
          // This is a comment
          [
            /* Multi-line
              comment */
            {
              "key": "cmd+c",
              "command": "copy"
            }
          ]
        `);
        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings('test.json')).toEqual([{
          key: 'cmd+c',
          command: 'copy'
        }]);
      });

      it('handles file read errors gracefully', () => {
        mockedFindVscodeKeybindings.mockImplementationOnce(() => {
          throw new Error('File not found');
        });

        expect(vscode_keybindings_extractor_helper.find_vscode_keybindings('nonexistent.json')).toEqual([]);
      });
    });

    describe('get_default_vscode_keybindings', () => {
      it('fetches and merges keybindings for the selected platform', async () => {
        const mockMainKeybindings: VSCodeKeybinding[] = [{ key: 'cmd+c', command: 'copy' }];
        const mockNegativeKeybindings: VSCodeKeybinding[] = [{ key: 'cmd+v', command: 'paste' }];
        mockedFetchJson.mockResolvedValueOnce(() => JSON.stringify(mockMainKeybindings));

        expect(await vscode_keybindings_extractor_helper.get_default_vscode_keybindings('darwin')).toEqual([...mockMainKeybindings, ...mockNegativeKeybindings]);
      });

      it('handles fetch errors gracefully', async () => {
        mockedFetchJson.mockRejectedValueOnce(() => {
          throw new Error('Network error');
        });
        expect(await vscode_keybindings_extractor_helper.get_default_vscode_keybindings('darwin')).toEqual([]);
      });
    });
  });

  describe('extract_vscode_keybindings', () => {
    let mockKeybindings: VSCodeKeybinding[];
    let mockDefaultKeybindings: VSCodeKeybinding[];

    it('exports to format JSON', async () => {
      mockKeybindings = [{ key: 'cmd+c', command: 'copy', when: 'editorTextFocus' }];
      mockDefaultKeybindings = [{ key: 'cmd+v', command: 'paste', when: 'editorTextFocus' }];
      spyOn(vscode_keybindings_extractor_helper, 'get_default_vscode_keybindings').mockResolvedValueOnce(mockDefaultKeybindings);
      mockedFindVscodeKeybindings.mockImplementation(() => mockKeybindings);

      expect(JSON.stringify(await extract_vscode_keybindings('json', 'darwin', '/Users/testuser'), null, 2)).toEqual(JSON.stringify([...mockKeybindings, ...mockDefaultKeybindings], null, 2));
    });

    it('exports to format CSV', async () => {
      mockKeybindings = [{ key: 'cmd+c', command: 'copy', when: 'editorTextFocus' }];
      mockDefaultKeybindings = [{ key: 'cmd+v', command: 'paste', when: 'editorTextFocus' }];
      mockedFetchJson.mockResolvedValueOnce(() => JSON.stringify(mockDefaultKeybindings));

      expect(await extract_vscode_keybindings('csv', 'darwin', '/Users/testuser')).toContain('key,command,when');
      expect(await extract_vscode_keybindings('csv', 'darwin', '/Users/testuser')).toContain('"cmd+c","copy","editorTextFocus"');
    });
  });
});

// vi: set ft=typescript
