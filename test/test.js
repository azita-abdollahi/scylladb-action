const scylla = require('express-cassandra');
const assert = require('assert');
const {
    SCYLLA_HOSTNAME,
    SCYLLA_PORT,
    SCYLLA_USERNAME,
    SCYLLA_PASSWORD,
    SCYLLA_KEYSPACE,
    SCYLLA_REPLICATION,
    SCYLLA_DATACENTER,
    CONSISTENCY_LEVEL,
} = process.env;

const dbOptions = {
    clientOptions: {
        contactPoints: [SCYLLA_HOSTNAME],
        localDataCenter: SCYLLA_DATACENTER,
        protocolOptions: { port: parseInt(SCYLLA_PORT, 10) },
        queryOptions: { consistency: scylla.consistencies[CONSISTENCY_LEVEL.toUpperCase()] },
        socketOptions: { readTimeout: 60000 },
        authProvider: new scylla.driver.auth.PlainTextAuthProvider(SCYLLA_USERNAME, SCYLLA_PASSWORD),
        keyspace: SCYLLA_KEYSPACE,
    },
    ormOptions: {
        defaultReplicationStrategy: JSON.parse(SCYLLA_REPLICATION),
        migration: 'safe',
    },
};

const UserModel = {
    fields: {
        id: "uuid",
        name: "text",
        email: "text",
    },
    key: ["id"],
};
describe('ScyllaDB Action Tests', function () {
    let models;
    let User;

    beforeAll(async function() {
        models = scylla.createClient(dbOptions);
        
        await new Promise((resolve, reject) => {
            models.initAsync(err => err ? reject(err) : resolve());
        });

        User = models.loadSchema('users', UserModel);
        await new Promise((resolve, reject) => {
            User.syncDB(err => err ? reject(err) : resolve());
        });
    });

    afterAll(async function() {
        try {
            if (models) {
                await models.closeAsync();
                await new Promise(resolve => setTimeout(resolve, 500));
            }
        } catch (err) {
            console.error('Cleanup error:', err);
        }
    });

    it('should save a user to the database', async function () {
        const userId = models.uuid();
        const user = new User({ id: userId, name: "John Doe", email: "john@example.com" });
        await user.saveAsync();
    });

    it('should retrieve a user from the database', async function () {
        const result = await User.findOneAsync({ name: "John Doe" }, { raw: true, allow_filtering: true });
        assert(result.name === "John Doe", 'Failed to retrieve user');
    });

    it('should update a user in the database', async function () {
        const user = await User.findOneAsync({ name: "John Doe" }, { raw: true, allow_filtering: true })
        const userId = user.id;
        await User.updateAsync({ id: userId }, {email: "john.doe@example.com"}, {if_exists: true, })
        
        const updatedResult = await User.findAsync({ id: userId }, { raw: true, allow_filtering: true });
        
        assert(updatedResult[0].email === "john.doe@example.com", 'Failed to update user');
    });

    it('should delete a user from the database', async function () {
        const user = await User.findOneAsync({ name: "John Doe" }, { raw: true, allow_filtering: true })
        const userId = user.id;
        await User.deleteAsync({ id: userId });

        const deletedResult = await User.findOneAsync({ id: userId }, { raw: true, allow_filtering: true });

        assert(deletedResult === undefined, 'Failed to delete user');
    });
});
