 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

 



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
     
     

     
     
     
     

      
     
     

     
     
     
     

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
     
     
     
     
}

 

 



 
contract CocosTokenLock is Ownable {
    ERC20 public token;

     
     
     
     
     
     
     
    uint8 public constant CONTRIBUTOR = 0;   
    uint8 public constant TEAM = 1;  
    uint8 public constant ADIVISORS = 2;  
    uint8 public constant USER_INCENTIVE = 3;  
    uint8 public constant PARTNER_INCENTIE = 4;  
    uint8 public constant DPOS_REWARD = 5;  
    uint8 public constant TOKEN_TREASURY = 6;  
    uint8 public constant TOTAL_LOCK_TYPES = 7;

    uint256 public constant DV = (10 ** 18);


    uint256[TOTAL_LOCK_TYPES] public tokenDistribution = [
        22396452170 * DV,
        17000000000 * DV,
        4000000000 * DV,
        7603547830 * DV,
        10000000000 * DV,
        30000000000 * DV,
        9000000000 * DV
    ];


    uint[TOTAL_LOCK_TYPES] public startTimes = [0, 365 days, 30 days, 0, 0, 90 days, 0];   
     
    uint[TOTAL_LOCK_TYPES] public lockIntervalTimes = [180 days, 365 days, 90 days, 90 days, 90 days, 30 days, 90 days];
     
     

    uint public constant ADIVISORS_SECOND_AHEAD_TIME = 30 days;
     
    uint public constant PARTNER_INCENTIE_SECOND_DELAY_TIME = 30 days;
     

     
    address[TOTAL_LOCK_TYPES] public tokenAddresses = [
        0xf9948BD195a7Aa64FbBc461B8D1286873C364721,
        0xf18E50748AC2882E7F4b87A147F31453ef69C08B,
        0x5E401eB4E132B17A3217401c9b0e51EA1B608e28,
        0x82d54E42b88522b936E4139A758d5fA3D4Bb35c1,
        0x8da5569f3831CAB8Fc6439AF4bC4fcAa7C729250,
        0x6eD0885ec149d8c8504a4cBcD5067F7fb011cc0c,
        0x6a5d6692d847c83d047bFCaC293FAF02e1488a64
    ];

    uint256[][TOTAL_LOCK_TYPES] public lockTokenMatrix;

    uint[TOTAL_LOCK_TYPES] public lastUnlockTimes= [0, 0, 0, 0, 0, 0, 0];
    uint[TOTAL_LOCK_TYPES] public currentLockSteps = [0, 0, 0, 0, 0, 0, 0];

    uint public lockedAt = 0;

    event UnlockToken(uint8 tokenType, uint currentStep, uint steps, uint256 tokens, uint lockTime, address addr);
    event CheckTokenDistribution(uint tokenType, uint256 distribution);
    event RecoverFailedLock(uint256 token);
    event SetAddress(uint8 tokenType, address addr);

     
    modifier notLocked {
        require(lockedAt == 0, "not locked");
        _;
    }

    modifier locked {
        require(lockedAt > 0, "has locked");
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0), "address is 0x00");
        require(addr != address(this), "address is myself");
        _;
    }

    modifier validTokenType(uint8 tokenType ){
        require(0 <= tokenType && tokenType < TOTAL_LOCK_TYPES, "tokenType must in [0,6]");
        _;
    }

    constructor(address payable _cocosToken)
        public
        validAddress(_cocosToken){
        token = ERC20(_cocosToken);

        lockTokenMatrix[CONTRIBUTOR] = [
            12025214795 * DV,
            5353626719 * DV,
            4582828047 * DV,
            434782609 * DV
        ];
        lockTokenMatrix[TEAM] = [
            5692583331 * DV,
            5691833331 * DV,
            5615583338 * DV
        ];
        lockTokenMatrix[ADIVISORS] = [
            350000000 * DV,
            433333332 * DV,
            577833332 * DV,
            83333332 * DV,
            577833332 * DV,
            83333332 * DV,
            577833332 * DV,
            83333332 * DV,
            899833332 * DV,
            83333332 * DV,
            83333332 * DV,
            83333332 * DV,
            83333348 * DV
        ];
    }

    function setAddress(uint8 tokenType, address addr) public
        onlyOwner
        validAddress(addr)
        validTokenType(tokenType) {
            tokenAddresses[tokenType] = addr;
            emit SetAddress(tokenType, addr);
        }


     
     
    function recoverFailedLock() public
        notLocked
        onlyOwner{
         
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "transfer error");
        emit RecoverFailedLock(balance);
    }

    function lock() public
        notLocked
        onlyOwner{
        uint256 totalSupply = token.totalSupply();
        require(token.balanceOf(address(this)) == totalSupply, "can't enough token");

        lockTokenMatrix[USER_INCENTIVE] = new uint256[](41);
        for(uint256 i = 0; i < 40; i++){
            lockTokenMatrix[USER_INCENTIVE][i] = 190000000 * DV;
        }
        lockTokenMatrix[USER_INCENTIVE][40] = 3547830 * DV;  

        lockTokenMatrix[PARTNER_INCENTIE] = new uint256[](21);
        lockTokenMatrix[PARTNER_INCENTIE][0] = 2000000000 * DV;
        for(uint256 i = 1; i < 21; i++){
            lockTokenMatrix[PARTNER_INCENTIE][i] = 400000000 * DV;
        }

        lockTokenMatrix[DPOS_REWARD] = new uint256[](120);
        for(uint256 i = 0; i < 120; i++){
            lockTokenMatrix[DPOS_REWARD][i] = 250000000 * DV;
        }

        lockTokenMatrix[TOKEN_TREASURY] = new uint256[](21);
        lockTokenMatrix[TOKEN_TREASURY][0] = 1500000000 * DV;
        for(uint256 i = 1; i < 21; i++){
            lockTokenMatrix[TOKEN_TREASURY][i] = 375000000 * DV;
        }

         
        uint tokenCount = 0;
        for(uint i = 0; i < tokenDistribution.length; i++){
            tokenCount = tokenCount + tokenDistribution[i];
        }
        require(tokenCount == totalSupply, "error lock rate, please check it again");

         
        for(uint i = 0; i < TOTAL_LOCK_TYPES; i++){
            uint256 tokens = tokenDistribution[i];
            uint256 count = 0;
            for(uint j = 0; j < lockTokenMatrix[i].length; j++ ){
                count = count + lockTokenMatrix[i][j];
            }
            require(tokens == count, "error token set");
            emit CheckTokenDistribution(i, tokens);
        }

        lockedAt = block.timestamp;
    }

     
    function unlock(uint8 tokenType) public
        locked
        onlyOwner
        validTokenType(tokenType){
        require(currentLockSteps[tokenType] < lockTokenMatrix[tokenType].length, "unlock finish");

        uint currentTime = block.timestamp;

        uint steps = 0;
        bool isFirst = false;
        if(lastUnlockTimes[tokenType] == 0){   
            uint interval = currentTime - lockedAt;
            if( interval > startTimes[tokenType]){
                steps = 1;
                isFirst = true;
            }
        }else{
            require(lastUnlockTimes[tokenType] <= currentTime, "subtraction overflow");
            uint dt = currentTime - lastUnlockTimes[tokenType];
            steps = dt/lockIntervalTimes[tokenType];
        }

        require(steps > 0, "can't unlock");

        uint256 unlockToken = 0;
        uint oldStep = currentLockSteps[tokenType];
        uint totalLockStep = lockTokenMatrix[tokenType].length;
        for(uint i = currentLockSteps[tokenType]; i < (currentLockSteps[tokenType] + steps) && i < totalLockStep; i++ ){
            unlockToken = unlockToken + lockTokenMatrix[tokenType][i];
        }
        lastUnlockTimes[tokenType] = lastUnlockTimes[tokenType] + steps * lockIntervalTimes[tokenType];
 
         
        if(isFirst){
            lastUnlockTimes[tokenType] = lockedAt + startTimes[tokenType];

            if( tokenType == ADIVISORS){
                lastUnlockTimes[tokenType] = lastUnlockTimes[tokenType] - ADIVISORS_SECOND_AHEAD_TIME;
            }else if(tokenType == PARTNER_INCENTIE ) {
                lastUnlockTimes[tokenType] = lastUnlockTimes[tokenType] + PARTNER_INCENTIE_SECOND_DELAY_TIME;
            }
        }

        currentLockSteps[tokenType] = currentLockSteps[tokenType] + steps;

        uint256 amount = token.balanceOf(address(this));
        require(amount >= unlockToken, 'not enough token');

        emit UnlockToken(tokenType, oldStep, steps, unlockToken, lastUnlockTimes[tokenType], tokenAddresses[tokenType]);

        token.transfer(tokenAddresses[tokenType], unlockToken);
    }
}