 

pragma solidity ^0.4.19;

 
contract Token {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender)
        public constant returns (uint256);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract CradTimeLock {
     
    function CradTimeLock (address _owner) public {
        owner = _owner;
    }

     
    function lock (
        Token _token, address _beneficiary, uint256 _amount,
        uint256 _unlockTime) public returns (uint256) {
        require (_amount > 0);
        require (msg.sender == owner);

        uint256 id = nextLockID++;

        TokenTimeLockInfo storage lockInfo = locks [id];

        lockInfo.token = _token;
        lockInfo.beneficiary = _beneficiary;
        lockInfo.amount = _amount;
        lockInfo.unlockTime = _unlockTime;

        emit Lock (id, _token, _beneficiary, _amount, _unlockTime);

        require (_token.transferFrom (msg.sender, this, _amount));

        return id;
    }

     
    function unlock (uint256 _id) public {
        TokenTimeLockInfo memory lockInfo = locks [_id];
        delete locks [_id];

        require (lockInfo.amount > 0);
        require (lockInfo.unlockTime <= block.timestamp);
        require (msg.sender == owner);

        emit Unlock (_id);

        require (
            lockInfo.token.transfer (
                lockInfo.beneficiary, lockInfo.amount));
    }

     
    address public owner;

     
    uint256 private nextLockID = 0;

     
    mapping (uint256 => TokenTimeLockInfo) public locks;

     
    struct TokenTimeLockInfo {
         
        Token token;

         
        address beneficiary;

         
        uint256 amount;

         
        uint256 unlockTime;
    }

     
    event Lock (
        uint256 indexed id, Token indexed token, address indexed beneficiary,
        uint256 amount, uint256 unlockTime);

     
    event Unlock (uint256 indexed id);
}