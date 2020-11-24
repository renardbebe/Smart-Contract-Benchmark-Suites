 

pragma solidity ^0.4.18;

  

contract Secure {
    enum Algorithm { sha, keccak }

     
     
     
    function generateProof(
        string seed,
        address caller, 
        address receiver,
        Algorithm algorithm
    ) pure public returns(bytes32 hash, bytes32 operator, bytes32 check, address check_receiver, bool valid) {
        (hash, operator, check) = _escrow(seed, caller, receiver, algorithm);
        check_receiver = address(hash_data(hash_seed(seed, algorithm), algorithm)^operator);
        valid = (receiver == check_receiver);
        if (check_receiver == 0) check_receiver = caller;
    }

    function _escrow(
        string seed, 
        address caller, 
        address receiver,
        Algorithm algorithm
    ) pure internal returns(bytes32 index, bytes32 operator, bytes32 check) {
        require(caller != receiver && caller != 0);
        bytes32 x = hash_seed(seed, algorithm);
        if (algorithm == Algorithm.sha) {
            index = sha256(x, caller);
            operator = sha256(x)^bytes32(receiver);
            check = x^sha256(receiver);
        } else {
            index = keccak256(x, caller);
            operator = keccak256(x)^bytes32(receiver);
            check = x^keccak256(receiver);
        }
    }
    
     
    function hash_seed(
        string seed, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) {
            return sha256(seed);
        } else {
            return keccak256(seed);
        }
    }
    
    
    function hash_data(
        bytes32 key, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) {
            return sha256(key);
        } else {
            return keccak256(key);
        }
    }
    
     
    function blind(
        address addr,
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) {
            return sha256(addr);
        } else {
            return keccak256(addr);
        }
    }
    
}


contract BlackBox is Secure {
    address public owner;

     
    struct Proof {
        uint256 balance;
        bytes32 operator;
        bytes32 check;
    }
    
    mapping(bytes32 => Proof) public proofs;
    mapping(bytes32 => bool) public used;
    mapping(address => uint256) private donations;

     
    event Unlocked(string _key, bytes32 _hash, address _receiver);
    event Locked(bytes32 _hash, bytes32 _operator, bytes32 _check);
    event Donation(address _from, uint256 value);
    
    function BlackBox() public {
        owner = msg.sender;
    }

     
     
     
     
    function lockAmount(
        bytes32 hash,
        bytes32 operator,
        bytes32 check
    ) public payable {
         
        if (msg.value > 0) {
            require(hash != 0 && operator != 0 && check != 0);
        }
         
        require(!used[hash]);
         
        proofs[hash].balance = msg.value;
        proofs[hash].operator = operator;
        proofs[hash].check = check;
         
        used[hash] = true;
        Locked(hash, operator, check);
    }

     
     
     
    function unlockAmount(
        string seed,
        Algorithm algorithm
    ) public payable {
        require(msg.value == 0);
        bytes32 hash = 0x0;
        bytes32 operator = 0x0;
        bytes32 check = 0x0;
         
        (hash, operator, check) = _escrow(seed, msg.sender, 0, algorithm);
         
        require(used[hash]);
         
        address receiver = address(proofs[hash].operator^operator);
         
        require(proofs[hash].check^hash_seed(seed, algorithm) == blind(receiver, algorithm));
         
        if (receiver == address(this) || receiver == 0) receiver = msg.sender;
         
        uint bal = proofs[hash].balance;
         
        if (donations[msg.sender] > 0) {
            bal += donations[msg.sender];
            delete donations[msg.sender];
        }
         
        delete proofs[hash];
         
        if (bal <= this.balance && bal > 0) {
             
             
            if(!receiver.send(bal)){
                require(msg.sender.send(bal));
            }
        }
        Unlocked(seed, hash, receiver);
    }
    
     
    function() public payable {
        require(msg.value > 0);
        donations[owner] += msg.value;
        Donation(msg.sender, msg.value);
    }
    
}