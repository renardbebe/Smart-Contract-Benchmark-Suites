 

pragma solidity ^0.5.10;

 

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TimeLock {

    using SafeMath for uint;

    struct Deposit {
        address tokenAddress;
        uint depositTime;
        uint tokenAmount;
        uint freezeDuration;
    }

    mapping (address => uint) public tokensFrozen;
    mapping (address => Deposit[]) public deposits;

    uint defaultFreezeDuration = 5 minutes;

    event TokensFrozen (
        address indexed userAddress,
        address indexed tokenAddress,
        uint freezeIndex,
        uint depositTime,
        uint tokenAmount,
        uint freezeDuration
	);

    event TokensUnfrozen (
        address indexed userAddress,
        address indexed tokenAddress,
        uint freezeIndex,
        uint depositTime,
        uint tokenAmount,
        uint freezeDuration
	);

    constructor() public {

    }

     
     
     
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes memory _extraData) public {
        require(_value > 0, "Error: Value must be > 0");

         
        uint _oldBalance = ERC20Interface(_tokenContract).balanceOf(address(this));
        require(ERC20Interface(_tokenContract).transferFrom(_sender, address(this), _value), "Could not transfer tokens to Time Lock contract address.");
        uint _newBalance = ERC20Interface(_tokenContract).balanceOf(address(this));
        uint _balanceDiff = _newBalance.sub(_oldBalance); 
        uint _tokenAmount = _balanceDiff;  
        
        uint _freezeDuration = defaultFreezeDuration;
        uint _freezeIndex = deposits[_sender].length;

        if(deposits[_sender].length < 1) deposits[_sender];
        
        Deposit memory deposit;
        deposit.tokenAddress = _tokenContract;
        deposit.depositTime = now;
        deposit.tokenAmount = _tokenAmount;
        deposit.freezeDuration = _freezeDuration;
        deposits[_sender].push(deposit);
        
        tokensFrozen[_tokenContract] += _tokenAmount;  

        emit TokensFrozen(_sender, _tokenContract, _freezeIndex, now, _tokenAmount, _freezeDuration);
    }

    function addFreezeTime(uint _freezeIndex, uint _timeToAdd) public {
        require(deposits[msg.sender][_freezeIndex].tokenAmount > 0, "You do not have enough tokens!");
        deposits[msg.sender][_freezeIndex].freezeDuration += _timeToAdd;
 
    }

    function unfreeze(uint _freezeIndex) public {
        Deposit memory deposit = deposits[msg.sender][_freezeIndex];
         
        require(deposit.tokenAmount > 0, "You do not have enough tokens!");
        require(now >= deposit.depositTime.add(deposit.freezeDuration), "Tokens are locked!");
        require(_freezeIndex < deposits[msg.sender].length, "Could not find any freeze at index provided during. Aborting removal of index.");
        require(tokensFrozen[deposit.tokenAddress] >= deposit.tokenAmount);
        require(ERC20Interface(deposit.tokenAddress).transfer(msg.sender, deposit.tokenAmount), "Could not withdraw token!");

        tokensFrozen[deposit.tokenAddress] -= deposit.tokenAmount;  
        
        for (uint i = _freezeIndex; i<deposits[msg.sender].length-1; i++){
            deposits[msg.sender][i] = deposits[msg.sender][i+1];
        }
        deposits[msg.sender].length--;
    
        emit TokensUnfrozen(msg.sender, deposit.tokenAddress, _freezeIndex, now, deposit.tokenAmount, deposit.freezeDuration);
    }
    
    function getDepositCount(address _addr) public view returns (uint256 _freezeCount) {
        return deposits[_addr].length;
    }

    function getDepositByID(address _addr, uint _freezeIndex) public view returns (
        address _userAddress,
        address _tokenAddress,
        uint _depositTime,
        uint _tokenAmount,
        uint _freezeDuration
    ) {
        Deposit memory deposit = deposits[_addr][_freezeIndex];
        
        return (_addr,
            deposit.tokenAddress,
            deposit.depositTime,
            deposit.tokenAmount,
            deposit.freezeDuration
        );
    }

    function getTokenCount(address _tokenAddr) public view returns (uint256 _freezeCount) {
        return tokensFrozen[_tokenAddr];
    }
    
}