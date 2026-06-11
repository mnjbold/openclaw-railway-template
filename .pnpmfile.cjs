module.exports = {
  hooks: {
    readPackageJson: async (pkg, context) => {
      // Allow node-pty to build its native module
      if (pkg.name === 'node-pty') {
        pkg.scripts = pkg.scripts || {};
        // Don't block the build script
      }
      return pkg;
    }
  }
}
