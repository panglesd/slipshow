import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import { terser } from 'rollup-plugin-terser';
import babel from 'rollup-plugin-babel';

// `npm run build` -> `production` is true
// `npm run dev` -> `production` is false
const production = !process.env.ROLLUP_WATCH;

export default [
    {
	input: 'src/slip-lib.js',
	output: {
	    file: 'dist/slipshow.cdn.js',
	    name: 'Slipshow',
	    format: 'iife', // immediately-invoked function expression — suitable for <script> tags
	    sourcemap: true,
	    plugins: [
		
	    ]
	},
	plugins: [
	    resolve(), // tells Rollup how to find date-fns in node_modules
	    commonjs(), // converts date-fns to ES modules
	    babel(),
	    // production && terser() // minify, but only in production
	]
    },
    {
	input: 'src/slip-lib.js',
	output: {
	    file: 'dist/slipshow.cdn.min.js',
	    name: 'Slipshow',
	    format: 'iife', // immediately-invoked function expression — suitable for <script> tags
	    sourcemap: true,
	    plugins: [
		
	    ]
	},
	plugins: [
	    resolve(), // tells Rollup how to find date-fns in node_modules
	    commonjs(), // converts date-fns to ES modules
	    babel(),
	    production && terser() // minify, but only in production
	]
    },    {
	input: 'src/slip-lib.js',
	output: {
	    file: 'dist/slipshow.js',
	    format: 'es', 
	    sourcemap: true
	},
	plugins: [
	    resolve(), // tells Rollup how to find date-fns in node_modules
	    commonjs(), // converts date-fns to ES modules
	]
    },
];
