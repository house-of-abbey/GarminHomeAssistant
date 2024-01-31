declare namespace json {
  export function parse(text: string): import('json-ast-comments').JsonDocument;
}

declare module 'https://cdn.jsdelivr.net/npm/monaco-yaml@5.1.1/+esm' {
  export * from 'monaco-yaml';
}
