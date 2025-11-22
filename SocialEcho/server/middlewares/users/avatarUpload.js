const fs = require("fs");
const path = require("path");
const multer = require("multer");
const {
  uploadAvatarToAzure,
  isAzureStorageConfigured,
} = require("../../services/azureBlobService");

const uploadFolder = path.join(__dirname, "../../assets/userAvatars");

const diskStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(uploadFolder)) {
      fs.mkdirSync(uploadFolder, { recursive: true });
    }
    cb(null, uploadFolder);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + "-" + uniqueSuffix + ext);
  },
});

const storage = isAzureStorageConfigured
  ? multer.memoryStorage()
  : diskStorage;

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 20 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype === "image/jpeg" ||
      file.mimetype === "image/jpg" ||
      file.mimetype === "image/png"
    ) {
      cb(null, true);
    } else {
      cb(null, false);
    }
  },
});

async function processAzureUploads(files) {
  if (!isAzureStorageConfigured || !files?.length) {
    return;
  }

  const uploadedResults = await Promise.all(
    files.map((file) => uploadAvatarToAzure(file))
  );

  uploadedResults.forEach((result, index) => {
    files[index].azureBlobUrl = result.url;
    files[index].azureBlobName = result.blobName;
  });
}

function avatarUpload(req, res, next) {
  upload.any()(req, res, async (err) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: "Error uploading file",
        error: err.message,
      });
    }

    try {
      await processAzureUploads(req.files);
      return next();
    } catch (azureError) {
      return res.status(500).json({
        success: false,
        message: "Failed to upload avatar to Azure Blob Storage",
        error: azureError.message,
      });
    }
  });
}

module.exports = avatarUpload;
