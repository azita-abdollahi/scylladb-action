const assert = require('assert');
const scylla = require('express-cassandra');

const {
    SCYLLA_HOSTNAME = 'localhost',
    SCYLLA_PORT = '9042',
    SCYLLA_USERNAME = 'admin',
    SCYLLA_PASSWORD = 'admin',
    SCYLLA_KEYSPACE = 'test',
    SCYLLA_DATACENTER = 'datacenter1',
} = process.env;

const dbOptions = {
    clientOptions: {
        contactPoints: [SCYLLA_HOSTNAME],
        localDataCenter: SCYLLA_DATACENTER,
        protocolOptions: { port: parseInt(SCYLLA_PORT, 10) },
        queryOptions: {  consistency: scylla.consistencies['QUORUM'] },
        socketOptions: { readTimeout: 60000 },
        authProvider: new scylla.driver.auth.PlainTextAuthProvider(
            SCYLLA_USERNAME,
            SCYLLA_PASSWORD,
        ),
        keyspace: SCYLLA_KEYSPACE,
    },
    ormOptions: {
        defaultReplicationStrategy: {
            class: 'NetworkTopologyStrategy',
            replication_factor: 1,
        },
        migration: 'safe',
    },
};

const UserModel = {
    fields: {
        id: 'uuid',
        name: 'text',
        email: 'text',
    },
    key: ['id'],
};

jest.setTimeout(30000);

describe('ScyllaDB Action Tests', function () {
    let models;
    let User;

    beforeAll(async function () {
        models = scylla.createClient(dbOptions);
        await new Promise((resolve, reject) => {
            models.initAsync((err) => (err ? reject(err) : resolve()));
        });

        User = models.loadSchema('users', UserModel);
        await new Promise((resolve, reject) => {
            User.syncDB((err) => (err ? reject(err) : resolve()));
        });
    });

    afterAll(async function () {
        try {
            if (models) {
                await models.closeAsync();
                await new Promise((resolve) => setTimeout(resolve, 500));
            }
        } catch (err) {
            console.error('Cleanup error:', err);
        }
    });

    it('should save a user to the database', async function () {
        const user = new User({
            id: models.uuid(),
            name: 'John Doe',
            email: 'john@example.com',
        });
        await user.saveAsync();
    });

    it('should retrieve a user from the database', async function () {
        const result = await User.findOneAsync(
            { name: 'John Doe' },
            { raw: true, allow_filtering: true },
        );
        assert.strictEqual(result.name, 'John Doe', 'Failed to retrieve user');
    });

    it('should update a user in the database', async function () {
        const { id } = await User.findOneAsync(
            { name: 'John Doe' },
            { raw: true, allow_filtering: true },
        );
        await User.updateAsync({ id }, { email: 'john.doe@example.com' }, { if_exists: true });

        const [updated] = await User.findAsync({ id }, { raw: true, allow_filtering: true });
        assert.strictEqual(updated.email, 'john.doe@example.com', 'Failed to update user');
    });

    it('should delete a user from the database', async function () {
        const { id } = await User.findOneAsync(
            { name: 'John Doe' },
            { raw: true, allow_filtering: true },
        );
        await User.deleteAsync({ id });

        const deleted = await User.findOneAsync({ id }, { raw: true, allow_filtering: true });
        assert.strictEqual(deleted, undefined, 'Failed to delete user');
    });
});