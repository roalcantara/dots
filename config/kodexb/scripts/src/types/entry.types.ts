export type Entry = {
  desc: string;
  tags: string[];
  links?: string[] | Record<string, string>[];
  notes?: string | string[] | Record<string, string>[];
};

export type Bookmark = Record<string, Entry>;
export type Command = Record<string, Entry>;
export type Cheat = Record<string, Entry>;

export type SourceFile = {
  bookmarks?: Bookmark[];
  commands?: Command[];
  cheats?: Cheat[];
};
