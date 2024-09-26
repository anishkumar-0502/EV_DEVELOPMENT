const database = require('../db');
const logger = require('../logger');

// USER_ROLE Functions
//FetchUserRole
async function FetchUserRole() {
    try {
        const db = await database.connectToDatabase();
        const usersCollection = db.collection("user_roles");
        
        // Query to fetch all roles from usersCollection
        const user_roles = await usersCollection.find().toArray();

        // Return the role data
        return user_roles;
    } catch (error) {
        logger.error(`Error fetching user roles: ${error}`);
        throw new Error('Error fetching user roles');
    }
}
//FetchSpecificUserRole
async function FetchSpecificUserRole() {
    try {
        const db = await database.connectToDatabase();
        const usersCollection = db.collection("user_roles");
        
        // Query to fetch roles with role_name either "superadmin" or "reselleradmin"
        const user_roles = await usersCollection.find({ 
            role_id: { $in: [1,2] } 
        }).toArray();

        // Return the role data
        return user_roles;
    } catch (error) {
        logger.error(`Error fetching user roles: ${error}`);
        throw new Error('Error fetching user roles');
    }
}
// Create UserRole
async function CreateUserRole(req, res, next) {
    try {
        const { created_by, rolename } = req.body;

        // Validate the input
        if (!created_by || !rolename) {
            return res.status(400).json({ message: 'Username and Role Name are required' });
        }

        const db = await database.connectToDatabase();
        const UserRole = db.collection("user_roles");

        // Use aggregation to check for existing role name and fetch the highest role_id
        const aggregationResult = await UserRole.aggregate([
            {
                $facet: {
                    existingRole: [
                        { $match: { role_name: rolename } },
                        { $limit: 1 }
                    ],
                    lastRole: [
                        { $sort: { role_id: -1 } },
                        { $limit: 1 }
                    ]
                }
            }
        ]).toArray();

        const existingRole = aggregationResult[0].existingRole[0];
        const lastRole = aggregationResult[0].lastRole[0];

        // Check if the role name already exists
        if (existingRole) {
            return res.status(400).json({ message: 'Role Name already exists' });
        }

        // Determine the new role_id
        let newRoleId = 1; // Default role_id if no roles exist
        if (lastRole) {
            newRoleId = lastRole.role_id + 1;
        }

        // Insert the new user role
        await UserRole.insertOne({
            role_id: newRoleId,
            role_name: rolename,
            created_date: new Date(),
            created_by: created_by, 
            modified_by: null, 
            modified_date: null,
            status: true
        });

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}
// UpdateUserRole
async function UpdateUserRole(req, res, next) {
    try {
        const { role_id, role_name, modified_by } = req.body;
        console.log(req.body)

        // Validate the input
        if (!role_id || !role_name || !modified_by) {
            return res.status(400).json({ message: 'Role ID, new role name, and modified by are required' });
        }

        const db = await database.connectToDatabase();
        const UserRole = db.collection("user_roles");

        // Check if the role exists
        const existingRole = await UserRole.findOne({ role_id: role_id });
        if (!existingRole) {
            return res.status(404).json({ message: 'Role ID not found' });
        }

        // Check if the new role name already exists
        const existingRoleName = await UserRole.findOne({ role_name: role_name });
        if (existingRoleName && existingRoleName.role_id !== role_id) {
            return res.status(400).json({ message: 'New role name already exists' });
        }

        // Update the role name
        const updateResult = await UserRole.updateOne(
            { role_id: role_id },
            {
                $set: {
                    role_name: role_name,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update role' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

//DeActivateOrActivate UserRole
async function DeActivateOrActivateUserRole(req, res, next) {
    try {
        const { modified_by, role_id, status } = req.body;

        // Validate the input
        if (!modified_by || !role_id || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'Username, Role Name, and Status (boolean) are required' });
        }

        const db = await database.connectToDatabase();
        const UserRole = db.collection("user_roles");

        // Check if the role exists
        const existingRole = await UserRole.findOne({ role_id: role_id });
        if (!existingRole) {
            return res.status(404).json({ message: 'Role not found' });
        }

        // Update existing role
        const updateResult = await UserRole.updateOne(
            { role_id: role_id },
            {
                $set: {
                    status: status,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update user role' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

// USER Functions
//FetchUser
// async function FetchUser() {
//     try {
//         const db = await database.connectToDatabase();
//         const usersCollection = db.collection("users");
//         const UserRole = db.collection("user_roles");
        
//         // Query to fetch all users
//         const users = await usersCollection.find().toArray();
//         const role = await UserRole.findOne({ role_id: users.role_id });

//         console.log(users);

//         // Return the users data
//         return users;
//     } catch (error) {
//         logger.error(`Error fetching users: ${error}`);
//         throw new Error('Error fetching users');
//     }
// }
async function FetchUser() {
    try {
        const db = await database.connectToDatabase();
        const usersCollection = db.collection("users");
        const rolesCollection = db.collection("user_roles");
        const resellerCollection = db.collection("reseller_details");
        const clientCollection = db.collection("client_details");
        const associationCollection = db.collection("association_details");
        
        // Query to fetch all users
        const users = await usersCollection.find().toArray();
        
        // Extract all unique role_ids, reseller_ids, client_ids, and association_ids from users
        const roleIds = [...new Set(users.map(user => user.role_id))];
        const resellerIds = [...new Set(users.map(user => user.reseller_id))];
        const clientIds = [...new Set(users.map(user => user.client_id))];
        const associationIds = [...new Set(users.map(user => user.association_id))];
        
        // Fetch roles based on role_ids
        const roles = await rolesCollection.find({ role_id: { $in: roleIds } }).toArray();
        const roleMap = new Map(roles.map(role => [role.role_id, role.role_name]));
        
        // Fetch resellers based on reseller_ids
        let resellers,resellerMap;
        if(resellerIds){
            resellers = await resellerCollection.find({ reseller_id: { $in: resellerIds } }).toArray();
            resellerMap = new Map(resellers.map(reseller => [reseller.reseller_id, reseller.reseller_name]));
        }
        
        // Fetch clients based on client_ids
        let clients,clientMap;
        if(clientIds){
            clients = await clientCollection.find({ client_id: { $in: clientIds } }).toArray();
            clientMap = new Map(clients.map(client => [client.client_id, client.client_name]));
        }
        
        // Fetch associations based on association_ids
        let associations,associationMap;
        if(associationIds){
            associations = await associationCollection.find({ association_id: { $in: associationIds } }).toArray();
            associationMap = new Map(associations.map(association => [association.association_id, association.association_name]));
        }
        
        // Attach additional details to each user
        const usersWithDetails = users.map(user => ({
            ...user,
            role_name: roleMap.get(user.role_id) || 'Unknown',
            reseller_name: resellerMap.get(user.reseller_id) || null,
            client_name: clientMap.get(user.client_id) || null,
            association_name: associationMap.get(user.association_id) || null
        }));
        
        // Return the users with all details
        return usersWithDetails;
    } catch (error) {
        logger.error(`Error fetching users: ${error}`);
        throw new Error('Error fetching users');
    }
}

//FetchSpecificUserRoleForSelection
async function FetchSpecificUserRoleForSelection() {
    try {
        const db = await database.connectToDatabase();
        const usersCollection = db.collection("user_roles");

           // Query to fetch all reseller_id and reseller_name
           const roles = await usersCollection.find(
            { role_id: { $in: [1, 2] }, status: true }, // Filter to fetch role_id 1 and 2
            {
                projection: {
                    role_id: 1,
                    role_name: 1,
                    _id: 0 // Exclude _id from the result
                }
            }
        ).toArray();
        // Return the users data
        return roles;
    } catch (error) {
        logger.error(`Error fetching users: ${error}`);
        throw new Error('Error fetching users');
    }
}
// FetchResellerForSelection
async function FetchResellerForSelection() {
    try {
        // Connect to the database
        const db = await database.connectToDatabase();
        const resellersCollection = db.collection("reseller_details");
        const usersCollection = db.collection("users");

        // Fetch all reseller_id from the users table
        const userResellerIds = await usersCollection.distinct("reseller_id");

        // Query to fetch resellers not present in the users table
        const resellers = await resellersCollection.find(
            { 
                status: true, 
                reseller_id: { $nin: userResellerIds } // Exclude resellers already present in users table
            },
            {
                projection: {
                    reseller_id: 1,
                    reseller_name: 1,
                    _id: 0 // Exclude _id from the result
                }
            }
        ).toArray();

        // Return the filtered resellers data
        return resellers;
    } catch (error) {
        logger.error(`Error fetching resellers: ${error}`);
        throw new Error('Error fetching resellers');
    }
}

// Create User
async function CreateUser(req, res, next) {
    try {
        const { role_id, reseller_id,username, email_id, password, phone_no, wallet_bal, created_by } = req.body;

        // Validate the input
        if (!username || !role_id || !email_id || !password || !created_by) {
            return res.status(400).json({ message: 'Username, Role ID, Email id ,Password, and Created By are required' });
        }

        const db = await database.connectToDatabase();
        const Users = db.collection("users");
        const UserRole = db.collection("user_roles");

        // Check if the role ID exists
        const existingRole = await UserRole.findOne({ role_id: role_id });
        if (!existingRole) {
            return res.status(400).json({ message: 'Invalid Role ID' });
        }
        
        // Check if the email_id already exists
        const existingUser = await Users.findOne({ 
            $or: [
                { username: username },
                { email_id: email_id }
            ]
         });
         if (existingUser) {
            if (existingUser.email_id === email_id) {
                return res.status(400).json({ message: 'Email ID already exists' });
            } else if (existingUser.username === username) {
                return res.status(400).json({ message: 'Username already exists' });
            }
        }

        // Use aggregation to fetch the highest user_id
        const lastUser = await Users.find().sort({ user_id: -1 }).limit(1).toArray();
        let newUserId = 1; // Default user_id if no users exist
        if (lastUser.length > 0) {
            newUserId = lastUser[0].user_id + 1;
        }

        // Insert the new user
        await Users.insertOne({
            role_id: role_id,
            reseller_id: reseller_id, // Default value, adjust if necessary
            client_id: null, // Default value, adjust if necessary
            association_id: null, // Default value, adjust if necessary
            user_id: newUserId,
            tag_id: null,
            assigned_association: null,
            username: username,
            email_id: email_id,
            password: parseInt(password),
            phone_no: phone_no,
            wallet_bal: wallet_bal || 0,
            autostop_time: null,
            autostop_unit: null,
            autostop_price: null,
            autostop_time_is_checked: null,
            autostop_unit_is_checked: null,
            autostop_price_is_checked: null,
            created_by: created_by,
            created_date: new Date(),
            modified_by: null,
            modified_date: null,
            status: true
        });

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}
// Update User
async function UpdateUser(req, res, next) {
    try {
        const { user_id, username, phone_no, password, wallet_bal, modified_by, status } = req.body;

        // Validate the input
        if (!user_id || !username || !password || !modified_by ){
            return res.status(400).json({ message: 'User ID, Username and Modified By are required' });
        }

        const db = await database.connectToDatabase();
        const Users = db.collection("users");

        // Check if the user exists
        const existingUser = await Users.findOne({ user_id: user_id });
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Update the user document
        const updateResult = await Users.updateOne(
            { user_id: user_id },
            {
                $set: {
                    username: username,
                    phone_no: phone_no,
                    wallet_bal: parseFloat(wallet_bal) || parseFloat(existingUser.wallet_bal), 
                    modified_date: new Date(),
                    password: parseInt(password),
                    modified_by: modified_by,
                    status: status,
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update user' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}
//DeActivate User
async function DeActivateUser(req, res, next) {
    try {
        const { user_id, modified_by, status } = req.body;

        // Validate the input
        if (!modified_by || !user_id || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'User ID, Modified By, and Status (boolean) are required' });
        }

        const db = await database.connectToDatabase();
        const Users = db.collection("users");

        // Check if the user exists
        const existingUser = await Users.findOne({ user_id: user_id });
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Update user status
        const updateResult = await Users.updateOne(
            { user_id: user_id },
            {
                $set: {
                    status: status,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update user status' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

// PROFILE Functions
//FetchUserProfile
async function FetchUserProfile(req, res) {
    const { user_id } = req.body;

    try {
        const db = await database.connectToDatabase();
        const usersCollection = db.collection("users");
        
        // Query to fetch the user by user_id
        const user = await usersCollection.findOne({ user_id: user_id });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        return user;
        
    } catch (error) {
        logger.error(`Error fetching user: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}
// UpdateUserProfile
async function UpdateUserProfile(req, res,next) {
    const { user_id, username, phone_no, password, modified_by, status } = req.body;

    try {
        // Validate the input
        if (!user_id || !username || !phone_no || !password || !modified_by || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'User ID, Username, Phone Number, Password, Modified By, and Status are required' });
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection("users");

        // Check if the user exists
        const existingUser = await usersCollection.findOne({ user_id: user_id });
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Update the user profile
        const updateResult = await usersCollection.updateOne(
            { user_id: user_id },
            {
                $set: {
                    username: username,
                    phone_no: phone_no,
                    password: password,
                    modified_by: modified_by,
                    modified_date: new Date(),
                    status: status
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update user profile' });
        }
        next();        
    } catch (error) {
        console.error(error);
        logger.error(`Error updating user profile: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

//CHARGER Function
//FetchCharger(Which are un-allocated to reseller)
async function FetchCharger() {
    try {
        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");
        const configCollection = db.collection("socket_gun_config");

        // Fetch all chargers where assigned_reseller_id is null
        const chargers = await devicesCollection.find({ assigned_reseller_id: null }).toArray();

        const results = [];

        for (let charger of chargers) {
            const chargerID = charger.charger_id;

            // Fetch corresponding socket/gun configuration
            const config = await configCollection.findOne({ charger_id: chargerID });

            let connectorDetails = []; // Initialize as an array

            if (config) {
                // Loop over connector configurations dynamically
                let connectorIndex = 1;
                while (config[`connector_${connectorIndex}_type`] !== undefined) {
                    // Map connector types: 1 -> "Socket", 2 -> "Gun"
                    let connectorTypeValue;
                    if (config[`connector_${connectorIndex}_type`] === 1) {
                        connectorTypeValue = "Socket";
                    } else if (config[`connector_${connectorIndex}_type`] === 2) {
                        connectorTypeValue = "Gun";
                    }

                    // Push connector details to the array
                    connectorDetails.push({
                        connector_type: connectorTypeValue || config[`connector_${connectorIndex}_type`],
                        connector_type_name: config[`connector_${connectorIndex}_type_name`]
                    });

                    connectorIndex++; // Move to the next connector
                }
            }

            // If there are no connector details, the charger will have an empty connector_details array
            results.push({
                ...charger,
                connector_details: connectorDetails.length > 0 ? connectorDetails : null
            });
        }

        return results;
    } catch (error) {
        console.error(`Error fetching chargers: ${error}`);
        throw new Error('Failed to fetch chargers with connector details');
    }
}

// insert / update socket configurations
const insertORupdateSocketGunConfig = async (chargerID, connectors) => {
    try {
        const connectorTypes = {};
        let socketCount = 0;
        let gunCount = 0;

        // Loop through the connectors array and assign the connector type and increment the counters
        connectors.forEach((connector) => {
            const { connector_id, connector_type, type_name } = connector;

            // Map incoming connector_type to database values (1 for Socket, 2 for Gun)
            if (connector_type === 'Socket') {
                connectorTypes[`connector_${connector_id}_type`] = 1;
                socketCount++;
            } else if (connector_type === 'Gun') {
                connectorTypes[`connector_${connector_id}_type`] = 2;
                gunCount++;
            }

            // Add the type_name as connector_X_type_name
            connectorTypes[`connector_${connector_id}_type_name`] = type_name;
        });

        const db = await database.connectToDatabase();
        const configCollection = db.collection('socket_gun_config');
        const existingConfig = await configCollection.findOne({ charger_id: chargerID });

        if (existingConfig) {
            // Prepare fields to update and unset
            let updateFields = {};
            let unsetFields = {};

            // Iterate through existing connector fields to find which ones to remove
            Object.keys(existingConfig).forEach((field) => {
                const match = field.match(/connector_(\d+)_type/);
                if (match) {
                    const connectorIndex = match[1];
                    const connectorExists = connectors.some(connector => connector.connector_id == connectorIndex);

                    if (!connectorExists) {
                        // Mark for deletion if the connector does not exist in the new input
                        unsetFields[`connector_${connectorIndex}_type`] = "";
                        unsetFields[`connector_${connectorIndex}_type_name`] = "";
                    }
                }
            });

            // Update fields that are in the new connectors array
            updateFields = {
                ...connectorTypes,
                modified_date: new Date(),
                socket_count: socketCount,
                gun_connector: gunCount
            };

            // Perform the update operation
            await configCollection.updateOne(
                { charger_id: chargerID },
                {
                    $set: updateFields,
                    $unset: unsetFields // This will remove unwanted fields
                }
            );

        } else {
            // If no existing config, insert a new one
            const socketGunConfig = {
                charger_id: chargerID,
                ...connectorTypes,
                created_date: new Date(),
                modified_date: null,
                socket_count: socketCount,
                gun_connector: gunCount
            };

            await configCollection.insertOne(socketGunConfig);
        }

        // Update or insert charger details in the `charger_details` collection as needed
        const chargerDetails = {
            charger_id: chargerID,
            created_date: new Date(),
        };

        const chargerDetailsCollection = db.collection('charger_details');
        const existingChargerDetails = await chargerDetailsCollection.findOne({ charger_id: chargerID });

        // Logic to unset unwanted fields in charger_details
        let unsetChargerFields = {};

        // Iterate through existing fields to find which ones to unset
        Object.keys(existingChargerDetails || {}).forEach((field) => {
            const match = field.match(/tag_id_for_connector_(\d+)/);
            if (match) {
                const connectorIndex = match[1];
                const connectorExists = connectors.some(connector => connector.connector_id == connectorIndex);

                if (!connectorExists) {
                    // Mark for deletion if the connector does not exist in the new input
                    unsetChargerFields[`tag_id_for_connector_${connectorIndex}`] = "";
                    unsetChargerFields[`tag_id_for_connector_${connectorIndex}_in_use`] = "";
                    unsetChargerFields[`transaction_id_for_connector_${connectorIndex}`] = "";
                    unsetChargerFields[`current_or_active_user_for_connector_${connectorIndex}`] = "";
                }
            }
        });

        // Initialize missing fields in existingChargerDetails
        const updateFields = {};
        const totalConnectors = connectors.length;

        for (let i = 1; i <= totalConnectors; i++) {
            if (!existingChargerDetails || !existingChargerDetails.hasOwnProperty(`tag_id_for_connector_${i}`) || existingChargerDetails[`tag_id_for_connector_${i}`] === null) {
                updateFields[`tag_id_for_connector_${i}`] = null;
            }

            if (!existingChargerDetails || !existingChargerDetails.hasOwnProperty(`tag_id_for_connector_${i}_in_use`) || existingChargerDetails[`tag_id_for_connector_${i}_in_use`] === null) {
                updateFields[`tag_id_for_connector_${i}_in_use`] = null;
            }

            if (!existingChargerDetails || !existingChargerDetails.hasOwnProperty(`transaction_id_for_connector_${i}`) || existingChargerDetails[`transaction_id_for_connector_${i}`] === null) {
                updateFields[`transaction_id_for_connector_${i}`] = null;
            }

            if (!existingChargerDetails || !existingChargerDetails.hasOwnProperty(`current_or_active_user_for_connector_${i}`) || existingChargerDetails[`current_or_active_user_for_connector_${i}`] === null) {
                updateFields[`current_or_active_user_for_connector_${i}`] = null;
            }
        }

        updateFields['socket_count'] = socketCount;
        updateFields['gun_connector'] = gunCount;

        if (existingChargerDetails) {
            if (Object.keys(updateFields).length > 0 || Object.keys(unsetChargerFields).length > 0) {
                await chargerDetailsCollection.updateOne(
                    { charger_id: chargerID },
                    {
                        $set: updateFields,
                        $unset: unsetChargerFields // This will remove unwanted fields
                    }
                );
            }
        } else {
            // If no existing charger details, insert new details
            for (let i = 1; i <= totalConnectors; i++) {
                chargerDetails[`tag_id_for_connector_${i}`] = null;
                chargerDetails[`tag_id_for_connector_${i}_in_use`] = null;
                chargerDetails[`transaction_id_for_connector_${i}`] = null;
                chargerDetails[`current_or_active_user_for_connector_${i}`] = null;
            }

            chargerDetails['socket_count'] = socketCount;
            chargerDetails['gun_connector'] = gunCount;

            await chargerDetailsCollection.insertOne(chargerDetails);
        }

        // Return true if the operation was successful
        return true;

    } catch (error) {
        console.error(`Error processing ChargerID: ${chargerID} - ${error.message}`);
        return false; // Return false in case of error
    }
};

//CreateCharger
async function CreateCharger(req, res) {
    try {
        const { charger_id, charger_model,charger_type, max_current, max_power, created_by, vendor, connectors } = req.body;

        // Validate the input
        if (!charger_id ||!charger_model || !charger_type || !max_current ||
            !max_power ||  !created_by || !vendor || !connectors) {
            return res.status(400).json({ message: 'Charger ID, charger_model, charger_type, Max Current, Max Power, connectors and Created By are required' });
        }

        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");

        // Check if charger with the same charger_id already exists
        const existingCharger = await devicesCollection.findOne({ charger_id });
        if (existingCharger) {
            return res.status(409).json({ message: `Charger with ID ${charger_id} already exists` });
        }

        // Insert the new device
        const insertResult = await devicesCollection.insertOne({
            charger_id,
            model: null,
            type: null,
            vendor,
            charger_model,
            charger_type,
            gun_connector: null,
            max_current,
            max_power,
            socket_count: null,
            ip: null,
            lat: null,
            long: null,
            short_description: null,
            charger_accessibility: 1,
            superadmin_commission:null,
            reseller_commission: null,
            client_commission: null,
            assigned_reseller_id: null,
            assigned_reseller_date: null,
            assigned_client_id: null,
            assigned_client_date: null,
            assigned_association_id: null,
            assigned_association_date: null,
            finance_id: null,
            wifi_username:null,
            wifi_password: null,
            created_by,
            created_date: new Date(),
            modified_by: null,
            modified_date: null,
            status: true
        });

        if(insertResult.acknowledged){
            const insertSocketResult = await insertORupdateSocketGunConfig(charger_id, connectors);
            if(insertSocketResult){
                return res.status(200).json({ status: 'Success', message: 'Charger created successfully' });
            }else{
                return res.status(200).json({ status: 'Success', message: 'Charger created successfully, but connectors details not inserted' });
            }
        }else{
            return res.status(400).json({ status: 'Failed', message: 'Charger creation failed' });
        }

    } catch (error) {
        console.error(error);
        logger.error(`Error creating device: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

async function UpdateCharger(req, res) {
    try {
        const { charger_id, charger_model, charger_type, vendor, max_current, max_power, modified_by, connectors } = req.body;

        // Validate the input - ensure charger_id and other required fields are provided
        if (!charger_id || !vendor || !max_current || !charger_model || !charger_type || !max_power || !modified_by) {
            return res.status(400).json({ message: 'Charger ID, charger_model, charger_type, Vendor, Max Current, Max Power and Created By are required' });
        }

        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");

        // Check if the charger exists
        const existingCharger = await devicesCollection.findOne({ charger_id });

        if (!existingCharger) {
            return res.status(404).json({ message: 'Charger not found' });
        }

        // Update the charger document
        const updateResult = await devicesCollection.updateOne(
            { charger_id },
            {
                $set: {
                    charger_model,
                    charger_type,
                    vendor,
                    max_current,
                    max_power,
                    modified_by,
                    modified_date: new Date(),
                }
            }
        );

        if (updateResult.modifiedCount === 0) {
            return res.status(500).json({ message: 'Failed to update charger' });
        }        
        
        //update the socket/gun configuration
        const success = await insertORupdateSocketGunConfig(charger_id, connectors);

        if (success) {
            return res.status(200).json({ status: 'Success', message: 'Charger and connectors updated successfully' });
        } else {
            return res.status(500).json({ message: 'Failed to update charger connectors' });
        }

    } catch (error) {
        console.error(error);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

//DeActivateOrActivate 
async function DeActivateOrActivateCharger(req, res, next) {
    try {
        const { modified_by, charger_id, status } = req.body;
        // Validate the input
        if (!modified_by || !charger_id || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'Username, chargerID, and Status (boolean) are required' });
        }

        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");

        // Check if the charger exists
        const existingRole = await devicesCollection.findOne({ charger_id: charger_id });
        if (!existingRole) {
            return res.status(404).json({ message: 'chargerID not found' });
        }

        // Update existing role
        const updateResult = await devicesCollection.updateOne(
            { charger_id: charger_id },
            {
                $set: {
                    status: status,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update charger' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

//RESELLER Function
//FetchResellers
async function FetchResellers(req, res) {
    try {
        const db = await database.connectToDatabase();
        const resellerCollection = db.collection("reseller_details");

        // Query to fetch all resellers
        const resellers = await resellerCollection.find({}).toArray();

        if (!resellers || resellers.length === 0) {
            return res.status(200).json({ message: 'No resellers found' });
        }

        // Return the reseller data
        return res.status(200).json({ status: 'Success', data: resellers });

    } catch (error) {
        console.error(error);
        logger.error(`Error fetching resellers: ${error}`);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}
//FetchAssignedClients
async function FetchAssignedClients(req, res) {
    try {
        const { reseller_id } = req.body;
        // Validate reseller_id
        if (!reseller_id) {
            return res.status(400).json({ message: 'Reseller ID is required' });
        }

        const db = await database.connectToDatabase();
        const clientCollection = db.collection("client_details");

        // Query to fetch clients for the specific reseller_id
        const clients = await clientCollection.find({ reseller_id: reseller_id }).toArray();

        if (!clients || clients.length === 0) {
            return res.status(404).json({ message: 'No client details found for the specified reseller_id' });
        }

        // Return the client data
        return res.status(200).json({ status: 'Success', data: clients });

    } catch (error) {
        console.error(error);
        logger.error(`Error fetching clients: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}
// FetchChargerDetailsWithSession
async function FetchChargerDetailsWithSession(req) {
    try {
        const { reseller_id } = req.body;

        // Validate reseller_id
        if (!reseller_id) {
            throw new Error('Reseller ID is required');
        }

        const db = await database.connectToDatabase();
        const chargerCollection = db.collection("charger_details");

        // Aggregation pipeline to fetch charger details with sorted session data
        const result = await chargerCollection.aggregate([
            {
                $match: { assigned_reseller_id: reseller_id }
            },
            {
                $lookup: {
                    from: "device_session_details",
                    localField: "charger_id",
                    foreignField: "charger_id",
                    as: "sessions"
                }
            },
            {
                $addFields: {
                    chargerID: "$charger_id",
                    sessiondata: {
                        $cond: {
                            if: { $gt: [{ $size: "$sessions" }, 0] },
                            then: {
                                $map: {
                                    input: {
                                        $sortArray: {
                                            input: "$sessions",
                                            sortBy: { stop_time: -1 }
                                        }
                                    },
                                    as: "session",
                                    in: "$$session"
                                }
                            },
                            else: ["No session found"]
                        }
                    }
                }
            },
            {
                $project: {
                    _id: 0,
                    chargerID: 1,
                    status: 1,
                    sessiondata: 1
                }
            }
        ]).toArray();


        if (!result || result.length === 0) {
            throw new Error('No chargers found for the specified reseller_id');
        }

        // Sort sessiondata within each chargerID based on the first session's stop_time
        result.forEach(charger => {
            if (charger.sessiondata.length > 1) {
                charger.sessiondata.sort((a, b) => new Date(b.stop_time) - new Date(a.stop_time));
            }
        });

        return result;

    } catch (error) {
        console.error(error);
        logger.error(`Error fetching charger details: ${error.message}`);
        throw error;
    }
}

// CreateReseller 
async function CreateReseller(req, res) {
    try {
        const {
            reseller_name,
            reseller_phone_no,
            reseller_email_id,
            reseller_address,
            created_by
        } = req.body;

        // Validate required fields
        if (!reseller_name || !reseller_phone_no || !reseller_email_id || !reseller_address || !created_by ) {
            return res.status(400).json({ message: 'Reseller Name, Phone Number, Email ID, Address, and Created By are required' });
        }

        const db = await database.connectToDatabase();
        const resellerCollection = db.collection("reseller_details");

        // Check if a reseller with the same user name or email ID already exists
        const existingReseller = await resellerCollection.findOne({
            $or: [
                {reseller_email_id: reseller_email_id},
                {reseller_name: reseller_name}
            ]
        });

        if (existingReseller) {
            return res.status(400).json({ message: 'Reseller name / Mail ID already exists' });
        }

        // Use aggregation to fetch the highest reseller_id
        const lastReseller = await resellerCollection.find().sort({ reseller_id: -1 }).limit(1).toArray();
        let newResellerId = 1; // Default reseller_id if no resellers exist
        if (lastReseller.length > 0) {
            newResellerId = lastReseller[0].reseller_id + 1;
        }

        // Insert the new reseller
        await resellerCollection.insertOne({
            reseller_id: newResellerId,
            reseller_name,
            reseller_phone_no,
            reseller_email_id,
            reseller_address,
            reseller_wallet: 0.00,
            created_date: new Date(),
            modified_date: null,
            created_by,
            modified_by: null, 
            status: true
        });

        return res.status(200).json({ message: 'Reseller created successfully' });

    } catch (error) {
        console.error(error);
        logger.error(`Error creating reseller: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}
//UpdateReseller 
async function UpdateReseller(req, res) {
    try {
        const {
            reseller_id,
            reseller_phone_no,
            reseller_address,
            reseller_wallet,
            modified_by,
            status
        } = req.body;

        // Validate required fields
        if (!reseller_id  || !reseller_phone_no || !reseller_address || !reseller_wallet ||!modified_by || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'Reseller ID, Name, Phone Number,reseller_wallet,  status, Email ID, Address, and Modified By are required' });
        }

        const db = await database.connectToDatabase();
        const resellerCollection = db.collection("reseller_details");

        // Check if the reseller exists
        const existingReseller = await resellerCollection.findOne({ reseller_id: reseller_id });

        if (!existingReseller) {
            return res.status(404).json({ message: 'Reseller not found' });
        }

        // Update the reseller details
        const result = await resellerCollection.updateOne(
            { reseller_id: reseller_id },
            {
                $set: {
                    reseller_phone_no,
                    reseller_address,
                    reseller_wallet: parseFloat(reseller_wallet),
                    modified_date: new Date(),
                    modified_by,
                    status
                }
            }
        );

        if (result.modifiedCount === 0) {
            throw new Error('Failed to update reseller');
        }

        return res.status(200).json({ message: 'Reseller updated successfully' });

    } catch (error) {
        console.error(error);
        logger.error(`Error updating reseller: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}
//DeActivateOrActivate 
async function DeActivateOrActivateReseller(req, res, next) {
    try {
        const { modified_by, reseller_id, status } = req.body;

        // Validate the input
        if (!modified_by || !reseller_id || typeof status !== 'boolean') {
            return res.status(400).json({ message: 'Username, reseller_id, and Status (boolean) are required' });
        }

        const db = await database.connectToDatabase();
        const UserRole = db.collection("reseller_details");

        // Check if the role exists
        const existingRole = await UserRole.findOne({ reseller_id: reseller_id });
        if (!existingRole) {
            return res.status(404).json({ message: 'reseller not found' });
        }

        // Update existing role
        const updateResult = await UserRole.updateOne(
            { reseller_id: reseller_id },
            {
                $set: {
                    status: status,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        if (updateResult.matchedCount === 0) {
            return res.status(500).json({ message: 'Failed to update reseller' });
        }

        next();
    } catch (error) {
        console.error(error);
        logger.error(error);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

//ASSIGN_CHARGER_TO_RESELLER
//FetchUnAllocatedChargerToAssgin
async function FetchUnAllocatedChargerToAssgin(req, res) {
    try {
        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");

        // Query to fetch chargers where assigned_reseller_id is null
        const chargers = await devicesCollection.find({ assigned_reseller_id: null , status: true}).toArray();

        return chargers; // Only return data, don't send response
    } catch (error) {
        console.error(`Error fetching chargers: ${error}`);
        throw new Error('Failed to fetch chargers'); // Throw error, handle in route
    }
}
//FetchResellersToAssgin
async function FetchResellersToAssgin(req, res) {
    try {
        const db = await database.connectToDatabase();
        const resellerCollection = db.collection("reseller_details");

        // Query to fetch all resellers
        const resellers = await resellerCollection.find({status:true}).toArray();

        if (!resellers || resellers.length === 0) {
            return res.status(404).json({ message: 'No resellers found' });
        }

        // Return the reseller data
        return res.status(200).json({ status: 'Success', data: resellers });

    } catch (error) {
        console.error(error);
        logger.error(`Error fetching resellers: ${error}`);
        res.status(500).json({ message: 'Internal Server Error' });
    }
}

// AssignChargerToReseller
async function AssignChargerToReseller(req, res) {
    try {
        const { reseller_id, charger_ids, modified_by } = req.body;
        
        // Validate required fields
        if (!reseller_id || !charger_ids || !modified_by) {
            return res.status(400).json({ message: 'Reseller ID, Charger IDs, and Modified By are required' });
        }

        const db = await database.connectToDatabase();
        const devicesCollection = db.collection("charger_details");

        // Ensure charger_ids is an array
        let chargerIdsArray = Array.isArray(charger_ids) ? charger_ids : [charger_ids];

        // Check if all the chargers exist
        const existingChargers = await devicesCollection.find({ charger_id: { $in: chargerIdsArray } }).toArray();

        if (existingChargers.length !== chargerIdsArray.length) {
            return res.status(404).json({ message: 'One or more chargers not found' });
        }

        // Update the reseller details for all chargers
        const result = await devicesCollection.updateMany(
            { charger_id: { $in: chargerIdsArray } },
            {
                $set: {
                    assigned_reseller_id: reseller_id,
                    charger_accessibility: 2,
                    superadmin_commission: "0",
                    assigned_reseller_date: new Date(),
                    modified_date: new Date(),
                    modified_by
                }
            }
        );

        if (result.matchedCount === 0) {
            throw new Error('Failed to assign chargers to reseller');
        }

        return res.status(200).json({ message: 'Chargers Successfully Assigned' });

    } catch (error) {
        console.error(`Error assigning chargers to reseller: ${error}`);
        logger.error(`Error assigning chargers to reseller: ${error}`);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

// fetch Output Type details
async function fetchOutputType(req){
    try{   
        let id;
        let fetchResult;

        // Check if req and req.body exist
        if (req && req.body) {
            // Destructure id from req.body if it exists
            ({ id } = req.body);
        }

        const db = await database.connectToDatabase();
        const OutputTypeCollection = db.collection('output-type_config');

        if(id){
            fetchResult = await OutputTypeCollection.findOne({ id: id});

        }else{
            fetchResult = await OutputTypeCollection.find().toArray();
        }
        
        if(!fetchResult){
            console.error(`No details found`);
            return { error: true, status: 401, message: 'No details found' };
        }

        return { error: false, status: 200, message: fetchResult };

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// update Output Type details
async function updateOutputType(req){
    try{   
        const { id, output_type_name, modified_by} = req.body;

        if(!id || !output_type_name || !modified_by){
            console.error(`All fields are required`);
            return { error: true, status: 401, message: 'All fields are required' };
        }

        const db = await database.connectToDatabase();
        const OutputTypeCollection = db.collection('output-type_config');

        // Check if the output type with the same name exists, excluding the current record being updated
        const existingType = await OutputTypeCollection.findOne({
            output_type_name: output_type_name,
            id: { $ne: id } // Exclude the current record
        });

        if (existingType) {
            return { error: true, status: 400, message: 'Output type with this name already exists' };
        }

        const updateResult = await OutputTypeCollection.updateOne(
            {id: id},
            {
                $set: {
                    output_type_name: output_type_name,
                    modified_by: modified_by,
                    modified_date: new Date()
                }
            }
        );

        // Check if the update was successful
        if (updateResult.matchedCount === 0) {
            return { error: true, status: 404, message: 'Output type not found' };
        }

        if (updateResult.modifiedCount === 1) {
            return { error: false, status: 200, message: 'Updated successfully' };
        }else{
            console.error(`Updation Failed, Please try again`);
            return { error: true, status: 500, message: 'Failed to update output type' };
        }

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// De activate Output Type details
async function DeActivateOutputType(req) {
    try{
        const { id, modified_by, status } = req.body;
        if(!id || !modified_by || status === undefined){
            console.error(`All fields are required`);
            return { error: true, status: 401, message: 'All fields are required' };
        }

        const db = await database.connectToDatabase();
        const OutputTypeCollection = db.collection('output-type_config');

        const updateResult = await OutputTypeCollection.updateOne(
            {id: id},
            {
                $set: {
                    status: status,
                    modified_by: modified_by,
                    modified_date: new Date(),
                }
            }
        );

        if (updateResult.modifiedCount === 1) {
            return { error: false, status: 200, message: 'De-Activated/Activated successfully' };
        }else{
            console.error(`De-Activated Failed, Please try again`);
            return { error: true, status: 401, message: 'Something went wrong, Please try again !' }; 
        }
    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// create Output type details
async function createOutputType(req) {
    try{
        const { output_type ,output_type_name, created_by } = req.body;

        if( !output_type || !output_type_name || !created_by){
            console.error(`All fields are required`);
            return { error: true, status: 401, message: 'All fields are required' };
        }

        const db = await database.connectToDatabase();
        const OutputTypeCollection = db.collection('output-type_config');

        const existingType = await OutputTypeCollection.findOne({ output_type: output_type , output_type_name: output_type_name });
        if (existingType) {
            return { error: true, status: 400, message: 'Output type already exists' };
        }

        // Fetch the highest current ID and increment by 1
        const lastId = await OutputTypeCollection.find().sort({ id: -1 }).limit(1).toArray();
        const newId = lastId.length > 0 ? lastId[0].id + 1 : 1;

        const insertResult = await OutputTypeCollection.insertOne({ 
            id: newId,
            output_type: output_type,
            output_type_name: output_type_name, 
            created_by: created_by,
            created_date: new Date(),
            status: true
        });

        // Check if the insert was successful
        if (insertResult.acknowledged === true) {
            return { error: false, status: 200, message: 'Output type created successfully'};
        } else {
            return { error: true, status: 500, message: 'Failed to create output type' };
        }

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// fetch connector type name
async function fetchConnectorTypeName(req){
    try{
        const {connector_type} = req.body;

        if(!connector_type){
            console.error(`All fields are required`);
            return { error: true, status: 401, message: 'All fields are required' };
        }

        const db = await database.connectToDatabase();
        const OutputTypeCollection = db.collection('output-type_config');

        const fetchResults = await OutputTypeCollection.find({
            output_type: connector_type 
        }).toArray();

        if(!fetchResults || fetchResults.length === 0){
            console.error(`No details found for provided connector types`);
            return { error: true, status: 401, message: 'No details were found' };
        }

        // Map results to an array of output_type_names
        const outputTypeNames = fetchResults.map(result => ({
            output_type_name: result.output_type_name
        }));

        return { error: false, status: 200, message: outputTypeNames };

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

module.exports = { 
    //USER_ROLE 
    CreateUserRole,
    UpdateUserRole,
    FetchUserRole,
    FetchSpecificUserRole,
    DeActivateOrActivateUserRole,
    //USER
    FetchUser,
    FetchSpecificUserRoleForSelection,
    FetchResellerForSelection,
    CreateUser,
    UpdateUser,
    DeActivateUser,
    //PROFILE
    FetchUserProfile,
    UpdateUserProfile,
    //MANAGE CHARGER
    FetchCharger,
    CreateCharger,
    UpdateCharger,
    DeActivateOrActivateCharger,
    fetchConnectorTypeName,
    //MANAGE RESELLER
    FetchResellers,
    FetchAssignedClients,
    FetchChargerDetailsWithSession,
    CreateReseller,
    UpdateReseller,
    DeActivateOrActivateReseller,
    //ASSIGN TO RESELLER
    AssignChargerToReseller,
    FetchResellersToAssgin,
    FetchUnAllocatedChargerToAssgin,
    // output type config
    createOutputType,
    fetchOutputType,
    updateOutputType,
    DeActivateOutputType,
};