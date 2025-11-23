# SocialEcho

A social networking platform with automated content moderation and context-based authentication system.

![UI-community](https://raw.githubusercontent.com/nz-m/SocialEcho/main/resources/UI-community.png)

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Technologies](#technologies)
- [Schema Diagram](#schema-diagram)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [License](#license)

## Project Overview

The project is a social networking platform built using the MERN (MongoDB, Express.js, React.js, Node.js) stack. It incorporates two major features: an automated content moderation system and context-based authentication. These features are accompanied by common functionalities found in social media applications, such as profile creation, post creation and sharing, liking and commenting on posts, and following/unfollowing users.

### Automated Content Moderation

The platform's automated content moderation system utilizes various NLP (Natural Language Processing) APIs. These APIs include:

- Perspective API: Used for filtering spam, profanity, toxicity, harassment etc.
- TextRazor API: Integrated for content categorization.
- Hugging Face Interface API: Utilized with BART Large MNLI for content categorization.

A Flask application has been developed to provide similar functionality as the Hugging Face Interface API's classifier. The Flask app utilizes the BART Large MNLI model. It operates as a zero-shot classification pipeline with a PyTorch framework.

The system allows flexibility in choosing different services for API usage or disabling them without affecting overall functionality by using a common interface for interacting with the APIs.

When a user posts content, it undergoes a thorough filtering process to ensure compliance with the community guidelines. Additionally, users have the ability to report posts that they find inappropriate, which triggers a manual review process.

### Context-Based Authentication

The platform implements context-based authentication to enhance user account security. It takes into consideration user location, IP address, and device information for authentication purposes. Users can conveniently manage their devices directly from the platform. To ensure data privacy, this information is encrypted using the AES algorithm and securely stored in the database.

In case of a suspicious login attempt, users are promptly notified via email and are required to confirm their identity to protect against unauthorized access.

### User Roles

There are three distinct user roles within the system:

1. Admin: The admin role manages the overall system, including moderator management, community management, content moderation, monitoring user activity, and more.
2. Moderators: Moderators manage communities, manually review reported posts, and perform other moderation-related tasks.
3. General Users: General users have the ability to make posts, like comments, and perform other actions within the platform.



## Features

- [x] User authentication and authorization (JWT)
- [x] User profile creation and management
- [x] Post creation and management
- [x] Commenting on posts
- [x] Liking posts and comments
- [x] Following/unfollowing users
- [x] Reporting posts
- [x] Content moderation
- [x] Context-based authentication
- [x] Device management
- [x] Admin dashboard
- [x] Moderator dashboard
- [x] Email notifications


## Technologies

- React.js
- Redux
- Node.js
- Express.js
- MongoDB
- Tailwind CSS
- JWT Authentication
- Passport.js
- Nodemailer
- Crypto-js
- Azure Blob Storage
- Flask
- Hugging Face Transformers


## Schema Diagram

![Schema Diagram](https://raw.githubusercontent.com/nz-m/SocialEcho/main/resources/Schema-Diagram.png)



## Getting Started

### Prerequisites

Before running the application, make sure you have the following installed:

- Node.js
- MongoDB, MongoDB Atlas, or Azure Cosmos DB account

### Installation

1. Clone the repository

```bash
git clone https://github.com/CoolkidSenpai05/AWStest.git
```
2. Go to the project directory and install dependencies for both the client and server

```bash
cd client
npm install
```

```bash
cd server
npm install
```

3. Create a `.env` file in both the `client` and `server` directories and add the environment variables as shown in the `.env.example` files.
4. Start the server

```bash
cd server
npm start
```

5. Start the client

```bash
cd client
npm start
```


### Configuration

Run the `admin_tool.sh` script from the server directory with permissions for executing the script. This script is used for configuring the admin account, creating the initial communities, and other settings.
```bash
./admin_tool.sh
``` 

#### `.env` Variables

For email service of context-based authentication, the following variables are required:

```bash
EMAIL=
PASSWORD=
EMAIL_SERVICE=
```

For content moderation, you need the `PERSPECTIVE_API_KEY` and either the `INTERFACE_API_KEY` or `TEXTRAZOR_API_KEY`. Visit the following links to obtain the API keys:

- [Perspective API](https://developers.perspectiveapi.com/s/docs-get-started)
- [TextRazor API](https://www.textrazor.com/)
- [Hugging Face Interface API](https://huggingface.co/facebook/bart-large-mnli)

If you prefer, the Flask server can be run locally as an alternative to using the Hugging Face Interface API or TextRazor API. Refer to the `classifier_server` directory for more information.

#### Azure Blob Storage (User Avatars)

To store uploaded avatars in Azure Blob Storage (recommended for production), create a Storage Account and add the following variables to `server/.env`:

```bash
AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=..."
AZURE_STORAGE_CONTAINER="socialecho-user-avatars"
```

- The container will be created automatically if it does not exist and will default to `socialecho-user-avatars` when the variable is not set.
- If these variables are omitted, avatars fall back to being stored on the application server under `server/assets/userAvatars`.

#### Azure Cosmos DB (Database)

The application supports Azure Cosmos DB with MongoDB API for production deployments. To use Azure Cosmos DB:

1. **Create an Azure Cosmos DB Account:**
   - Go to [Azure Portal](https://portal.azure.com/)
   - Create a new Azure Cosmos DB account
   - Select API: **Azure Cosmos DB for MongoDB**
   - Choose your preferred region and pricing tier

2. **Get Connection String:**
   - Navigate to your Cosmos DB account in Azure Portal
   - Go to **Connection String** or **Keys** section
   - Copy the **Primary Connection String** (or Secondary Connection String)

3. **Configure in `.env` file:**
   
   Add the following variable to `server/.env`:
   
   ```bash
   # Option 1: Use MONGODB_URI (supports both MongoDB and Azure Cosmos DB)
   MONGODB_URI="mongodb://your-account-name:your-key@your-account-name.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@your-account-name@"
   
   # Option 2: Use dedicated Azure Cosmos DB variable (recommended)
   AZURE_COSMOS_DB_CONNECTION_STRING="mongodb://your-account-name:your-key@your-account-name.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@your-account-name@"
   ```

   **Important Notes:**
   - Ensure `retrywrites=false` is in the connection string (automatically handled by the application)
   - Replace `your-account-name` and `your-key` with your actual Cosmos DB credentials
   - If using `AZURE_COSMOS_DB_CONNECTION_STRING`, it will take precedence over `MONGODB_URI`

4. **Database Name:**
   - The database name is specified in the connection string or can be set via MongoDB URI
   - Example: `mongodb://.../socialecho?ssl=true...` where `socialecho` is your database name

5. **Firewall Configuration:**
   - By default, Azure Cosmos DB has IP restrictions
   - Go to **Firewall and virtual networks** in Azure Portal
   - Add your application server's IP address or enable **Allow access from Azure portal** for testing
   - For production, consider using Azure Private Link or VPN

**Features:**
- Fully compatible with MongoDB API - no code changes required
- Automatic retry configuration for Azure Cosmos DB
- Seamless migration from MongoDB/MongoDB Atlas
- Support for global distribution and multi-region writes
- Built-in high availability and automatic scaling

**Fallback:**
- If neither `MONGODB_URI` nor `AZURE_COSMOS_DB_CONNECTION_STRING` is set, the application will fail to start (database connection is required)
- For local development, you can still use local MongoDB or MongoDB Atlas


>**Note:** Configuration for context-based authentication and content moderation features are **_not mandatory_** to run the application. However, these features will not be available if the configuration is not provided.


## Usage

### Admin

The admin dashboard can be accessed at the `/admin` route. Use the `admin_tool.sh` script to configure the admin account. The admin account can be used to manage moderators, communities, and perform other admin-related tasks. You can also enable/disable or switch API services using the admin dashboard.

### Moderator

Moderators have specific email domain (`@mod.socialecho.com`). When registering with an email from this domain, the user is automatically assigned the moderator role. Moderators can be assigned to different communities from the admin dashboard.

