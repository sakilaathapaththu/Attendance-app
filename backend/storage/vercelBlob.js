// backend/storage/vercelBlob.js
// Works on Vercel and locally (needs BLOB_READ_WRITE_TOKEN when local)
async function putBlob(key, buffer, contentType) {
  const { put } = await import('@vercel/blob');
  const { url } = await put(key, buffer, {
    access: 'public',
    contentType,
    token: process.env.BLOB_READ_WRITE_TOKEN, // ignored on Vercel, used locally
  });
  return url;
}
module.exports = { putBlob };
