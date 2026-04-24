// BUAT PROCESS UNTUK GENERATE QR CODE BERIKUT

// importing the qrcode Module
const { default: qrcode } = await import ("qrcode");

// library specific options
const code = qrcode(0, 'L');

code.addData(apex.env.P5_URL);

code.make();

// saving the base64 result into a page item of type Display Image
apex.env.P5_QRCODE = code.createDataURL(4);