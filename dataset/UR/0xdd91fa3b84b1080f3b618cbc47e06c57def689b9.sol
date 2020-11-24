 

pragma solidity ^0.4.19;
contract TrustWallet {

    struct User {
         
         
         
        uint delay;

        address added_by;
        uint time_added;

        address removed_by;
        uint time_removed;

         
         
        uint time_added_another_user;
    }

    struct Transaction {
        address destination;
        uint value;
        bytes data;

        address initiated_by;
        uint time_initiated;

        address finalized_by;
        uint time_finalized;

         
        bool is_executed;
    }

    Transaction[] public transactions;
    mapping (address => User) public users;
    address[] public userAddresses;

    modifier onlyActiveUsersAllowed() {
        require(users[msg.sender].time_added != 0);
        require(users[msg.sender].time_removed == 0);
        _;
    }

    modifier transactionMustBePending() {
        require(isTransactionPending());
        _;
    }

    modifier transactionMustNotBePending() {
        require(!isTransactionPending());
        _;
    }

     
    function isTransactionPending() internal constant returns (bool) {
        if (transactions.length == 0) return false;
        return transactions[transactions.length - 1].time_initiated > 0 &&
            transactions[transactions.length - 1].time_finalized == 0;
    }

     
    function TrustWallet(address first_user) public {
        users[first_user] = User({
            delay: 0,
            time_added: now,
            added_by: 0x0,
            time_removed: 0,
            removed_by: 0x0,
            time_added_another_user: now
        });
        userAddresses.push(first_user);
    }

    function () public payable {}

     
    function initiateTransaction(address _destination, uint _value, bytes _data)
        public
        onlyActiveUsersAllowed()
        transactionMustNotBePending()
    {
        transactions.push(Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            initiated_by: msg.sender,
            time_initiated: now,
            finalized_by: 0x0,
            time_finalized: 0,
            is_executed: false
        }));
    }

     
     
     
    function executeTransaction()
        public
        onlyActiveUsersAllowed()
        transactionMustBePending()
    {
        Transaction storage transaction = transactions[transactions.length - 1];
        require(now > transaction.time_initiated + users[transaction.initiated_by].delay);
        transaction.is_executed = true;
        transaction.time_finalized = now;
        transaction.finalized_by = msg.sender;
        require(transaction.destination.call.value(transaction.value)(transaction.data));
    }

     
     
     
    function cancelTransaction()
        public
        onlyActiveUsersAllowed()
        transactionMustBePending()
    {
        Transaction storage transaction = transactions[transactions.length - 1];
         
         
         
        require(users[msg.sender].delay <= users[transaction.initiated_by].delay ||
            now - transaction.time_initiated > users[msg.sender].delay * 2);
        transaction.time_finalized = now;
        transaction.finalized_by = msg.sender;
    }

     
     
     
     
    function addUser(address new_user, uint new_user_time)
        public
        onlyActiveUsersAllowed()
    {
        require(users[new_user].time_added == 0);
        require(users[new_user].time_removed == 0);

        User storage sender = users[msg.sender];
        require(now > sender.delay + sender.time_added_another_user);
        require(new_user_time >= sender.delay);

        sender.time_added_another_user = now;
        users[new_user] = User({
            delay: new_user_time,
            time_added: now,
            added_by: msg.sender,
            time_removed: 0,
            removed_by: 0x0,
             
             
            time_added_another_user: now
        });
        userAddresses.push(new_user);
    }

     
     
    function removeUser(address userAddr)
        public
        onlyActiveUsersAllowed()
    {
        require(users[userAddr].time_added != 0);
        require(users[userAddr].time_removed == 0);

        User storage sender = users[msg.sender];
        require(sender.delay <= users[userAddr].delay);

        users[userAddr].removed_by = msg.sender;
        users[userAddr].time_removed = now;
    }
}