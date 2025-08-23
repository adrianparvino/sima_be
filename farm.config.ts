import { defineConfig } from "@farmfe/core";
import farmPluginPostcss from "@farmfe/js-plugin-postcss";

export default defineConfig({
  compilation: {
    output: {
      targetEnv: 'browser-esnext',
      format: 'esm',
    },
  },
  // Additional plugins
  plugins: [farmPluginPostcss()],
});
