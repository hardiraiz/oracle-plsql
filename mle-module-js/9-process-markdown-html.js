// BUAT PROCESS UNTUK CONVERT TEXT MENJADI TAG HTML
const { marked } = await import('marked');

// library-specific options
marked.setOptions({
    headerIds: false
});

apex.env.P5_PROJECT_DETAILS_HTML = marked(apex.env.P5_PROJECT_DETAILS);