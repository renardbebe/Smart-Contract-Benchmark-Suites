 

pragma solidity ^0.4.18;

 
 

 
contract Token {
    function balanceOf(address _owner) constant public returns (uint balance);
    function allowance(address _user, address _spender) constant public returns (uint amount);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

 
contract Owned {
    address public owner = msg.sender;
    bool public restricted = true;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
     
    modifier onlyCompliant {
        if (restricted) require(tx.origin == msg.sender);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function changeRestrictions() public onlyOwner {
        restricted = !restricted;
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}

 
contract Encoder {
    enum Algorithm { sha, keccak }

     
     
     
     
     
     
    function generateProofSet(
        string seed,
        address caller,
        address receiver,
        address tokenAddress,
        Algorithm algorithm
    ) pure public returns(bytes32 hash, bytes32 operator, bytes32 check, address check_receiver, address check_token) {
        (hash, operator, check) = _escrow(seed, caller, receiver, tokenAddress, algorithm);
        bytes32 key = hash_seed(seed, algorithm);
        check_receiver = address(hash_data(key, algorithm)^operator);
        if (check_receiver == 0) check_receiver = caller;
        if (tokenAddress != 0) check_token = address(check^key^blind(receiver, algorithm));
    }

     
    function _escrow(
        string seed, 
        address caller,
        address receiver,
        address tokenAddress,
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
        if (tokenAddress != 0) {
            check ^= bytes32(tokenAddress);
        }
    }
    
     
    function hash_seed(
        string seed, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(seed);
        else return keccak256(seed);
    }
    
    
    function hash_data(
        bytes32 key, 
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(key);
        else return keccak256(key);
    }
    
     
    function blind(
        address addr,
        Algorithm algorithm
    ) pure internal returns(bytes32) {
        if (algorithm == Algorithm.sha) return sha256(addr);
        else return keccak256(addr);
    }
    
}


contract BlackBox is Owned, Encoder {

     
    struct Proof {
        uint256 balance;
        bytes32 operator;
        bytes32 check;
    }
    
     
    mapping(bytes32 => Proof) public proofs;
    mapping(bytes32 => bool) public used;
    mapping(address => uint) private deposits;

     
    event ProofVerified(string _key, address _prover, uint _value);
    event Locked(bytes32 _hash, bytes32 _operator, bytes32 _check);
    event WithdrawTokens(address _token, address _to, uint _value);
    event ClearedDeposit(address _to, uint value);
    event TokenTransfer(address _token, address _from, address _to, uint _value);

     
     
     
     
    function lock(
        bytes32 _hash,
        bytes32 _operator,
        bytes32 _check
    ) public payable {
         
        if (msg.value > 0) {
            require(_hash != 0 && _operator != 0 && _check != 0);
        }
         
        require(!used[_hash]);
         
        proofs[_hash].balance = msg.value;
        proofs[_hash].operator = _operator;
        proofs[_hash].check = _check;
         
        used[_hash] = true;
        Locked(_hash, _operator, _check);
    }

     
     
     
     
    function unlock(
        string _seed,
        uint _value,
        Algorithm _algo
    ) public onlyCompliant {
        bytes32 hash = 0;
        bytes32 operator = 0;
        bytes32 check = 0;
         
        (hash, operator, check) = _escrow(_seed, msg.sender, 0, 0, _algo);
        require(used[hash]);
         
        uint balance = proofs[hash].balance;
        address receiver = address(proofs[hash].operator^operator);
        address _token = address(proofs[hash].check^hash_seed(_seed, _algo)^blind(receiver, _algo));
        delete proofs[hash];
        if (receiver == 0) receiver = msg.sender;
         
        clearDeposits(receiver, balance);
        ProofVerified(_seed, msg.sender, balance);

         
        if (_token != 0) {
            Token token = Token(_token);
            uint tokenBalance = token.balanceOf(msg.sender);
            uint allowance = token.allowance(msg.sender, this);
             
            if (_value == 0 || _value > tokenBalance) _value = tokenBalance;
            if (allowance > 0 && _value > 0) {
                if (_value > allowance) _value = allowance;
                TokenTransfer(_token, msg.sender, receiver, _value);
                require(token.transferFrom(msg.sender, receiver, _value));
            }
        }
    }
    
     
     
    function withdrawTokens(address _token) public onlyOwner {
        Token token = Token(_token);
        uint256 value = token.balanceOf(this);
        require(token.transfer(msg.sender, value));
        WithdrawTokens(_token, msg.sender, value);
    }
    
     
     
     
    function clearDeposits(address _for, uint _value) internal {
        uint deposit = deposits[msg.sender];
        if (deposit > 0) delete deposits[msg.sender];
        if (deposit + _value > 0) {
            if (!_for.send(deposit+_value)) {
                require(msg.sender.send(deposit+_value));
            }
            ClearedDeposit(_for, deposit+_value);
        }
    }
    
    function allowance(address _token, address _from) public view returns(uint _allowance) {
        Token token = Token(_token);
        _allowance = token.allowance(_from, this);
    }
    
     
    function() public payable {
        require(msg.value > 0);
        deposits[msg.sender] += msg.value;
    }
    
}