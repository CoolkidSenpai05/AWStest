const path = require("path");
const { BlobServiceClient } = require("@azure/storage-blob");

const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
const containerName =
  process.env.AZURE_STORAGE_CONTAINER || "socialecho-user-avatars";

const isAzureStorageConfigured =
  Boolean(connectionString) && Boolean(containerName);

let blobServiceClient = null;
if (isAzureStorageConfigured) {
  blobServiceClient = BlobServiceClient.fromConnectionString(
    connectionString
  );
}

const ensureContainerExists = async (containerClient) => {
  await containerClient.createIfNotExists({
    access: "blob",
  });
};

const uploadAvatarToAzure = async (file) => {
  if (!isAzureStorageConfigured || !blobServiceClient) {
    throw new Error("Azure Blob Storage is not configured");
  }

  const containerClient = blobServiceClient.getContainerClient(containerName);
  await ensureContainerExists(containerClient);

  const ext = path.extname(file.originalname) || ".png";
  const blobName = `${file.fieldname || "avatar"}-${Date.now()}-${Math.round(
    Math.random() * 1e9
  )}${ext}`;

  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(file.buffer, {
    blobHTTPHeaders: {
      blobContentType: file.mimetype || "application/octet-stream",
    },
  });

  return {
    url: blockBlobClient.url,
    blobName,
  };
};

const deleteAvatarFromAzure = async (blobName) => {
  if (!isAzureStorageConfigured || !blobServiceClient || !blobName) {
    return;
  }

  const containerClient = blobServiceClient.getContainerClient(containerName);
  try {
    await containerClient.deleteBlob(blobName);
  } catch (err) {
    // Ignore 404s to keep middleware idempotent
    if (err.statusCode !== 404) {
      throw err;
    }
  }
};

module.exports = {
  uploadAvatarToAzure,
  deleteAvatarFromAzure,
  isAzureStorageConfigured,
};

