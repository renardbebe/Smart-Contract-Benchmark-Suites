 

contract StakeProver {

    struct info_pair {
        address publisher;
        uint stake;  
        uint burned;  
        uint timestamp;
    }

    mapping(bytes32 => info_pair) public hash_db;

    function publish(bytes32 hashed_val) {
        if (hash_db[hashed_val].publisher != address(0)) {
             
            throw;
        }
        hash_db[hashed_val].publisher = msg.sender;
        hash_db[hashed_val].stake = msg.sender.balance;
        hash_db[hashed_val].burned = msg.value;
        hash_db[hashed_val].timestamp = now;
    }

   function get_publisher(bytes32 hashed_val) constant returns (address) {
        return hash_db[hashed_val].publisher;
    }

    function get_stake(bytes32 hashed_val) constant returns (uint) {
        return hash_db[hashed_val].stake;
    }

    function get_timestamp(bytes32 hashed_val) constant returns (uint) {
        return hash_db[hashed_val].timestamp;
    }

    function get_burned(bytes32 hashed_val) constant returns (uint) {
        return hash_db[hashed_val].burned;
    }
}