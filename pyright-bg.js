// Launches Mason's pyright-langserver with a background analysis worker that
// actually runs. See the Python LSP block in init.lua for the whole picture.
//
// pyright spawns its worker with Worker(__filename). In the npm build (what
// Mason installs) that code lives in the webpack chunk dist/pyright-internal.js,
// so __filename is the chunk. Loading the chunk alone runs nothing, so the worker
// exits at once and diagnostics stop. This file redirects the worker to itself,
// which boots the real entry point (it detects it's a worker and runs the
// analysis loop).
//
// If a pyright update renames that chunk, the redirect does nothing, the
// worker dies again and diagnostics stop. bench/run.sh checks for exactly that.
const wt = require('worker_threads');
const root = process.env.PYRIGHT_DIR;

if (wt.isMainThread) {
  const Worker = wt.Worker;
  wt.Worker = class extends Worker {
    constructor(file, opts) {
      if (typeof file === 'string' && file.endsWith('pyright-internal.js')) file = __filename;
      super(file, opts);
    }
  };
}

require(root + '/langserver.index.js');
