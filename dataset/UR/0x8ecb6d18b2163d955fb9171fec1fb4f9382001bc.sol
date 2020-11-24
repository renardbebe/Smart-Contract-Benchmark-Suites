 

 

pragma solidity ^0.5.0;

 
 
 library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address payable public owner;
    address payable public updater;
    address payable public captain;

    event UpdaterTransferred(address indexed previousUpdater, address indexed newUpdater);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
      
    modifier onlyUpdater() {
        require(msg.sender == updater);
        _;
    }

     
    function transferUpdater(address payable newUpdater) public onlyOwner {
        require(newUpdater != address(0));
        emit UpdaterTransferred(updater, newUpdater);
        updater = newUpdater;
    }
    
     
     
    function setCaptain(address payable _newCaptain) external onlyOwner {
        require(_newCaptain != address(0));

        captain = _newCaptain;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused {
        require(_paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        _paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() public onlyOwner whenPaused returns (bool) {
        _paused = false;
        emit Unpause();
        return true;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SalePO8 is Pausable {
    using SafeMath for uint256;
    ERC20 public po8Token;

    uint256 public exchangeRate;  
    uint256 public cut;
    
    event ExchangeRateUpdated(uint256 newExchangeRate);
    event PO8Bought(address indexed buyer, uint256 ethValue, uint256 po8Receive);
    
     
    constructor(uint256 _exchangeRate, uint256 _cut, address po8Address, address payable captainAddress) public {
        exchangeRate = _exchangeRate;
        ERC20 po8 = ERC20(po8Address);
        po8Token = po8;
        cut = _cut;
        captain = captainAddress;
    }
    
    function setPO8TokenContractAdress(address po8Address) external onlyOwner returns (bool) {
        ERC20 po8 = ERC20(po8Address);
        po8Token = po8;
        return true;
    }
    
     
    function setExchangeRate(uint256 _newExchangeRate) external onlyUpdater returns (uint256) {
        exchangeRate = _newExchangeRate;

        emit ExchangeRateUpdated(_newExchangeRate);

        return _newExchangeRate;
    }
    
    function buyPO8() external payable whenNotPaused {
        require(msg.value >= 1e4 wei);
        
        uint256 totalTokenTransfer = msg.value.mul(exchangeRate);
        
        po8Token.transferFrom(owner, msg.sender, totalTokenTransfer);
        captain.transfer(msg.value*cut/1e4);  
        
        emit PO8Bought(msg.sender, msg.value, totalTokenTransfer);
    }
    
     
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;

        owner.transfer(balance);
    }
    
     
    function () external {
        revert();
    }
    
    function getBackERC20Token(address tokenAddress) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
}