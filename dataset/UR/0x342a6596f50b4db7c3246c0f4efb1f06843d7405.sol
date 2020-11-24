 

 

pragma solidity 0.5.11;

 
interface ICERC20 {
    function balanceOf(address who) external view returns (uint256);

    function isCToken() external view returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity 0.5.11;



 
contract OwnableWithoutRenounce is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

 

pragma solidity 0.5.11;

 
interface ICTokenManager {
     
    event DiscardCToken(address indexed tokenAddress);

     
    event WhitelistCToken(address indexed tokenAddress);

    function whitelistCToken(address tokenAddress) external;

    function discardCToken(address tokenAddress) external;

    function isCToken(address tokenAddress) external view returns (bool);
}

 

pragma solidity 0.5.11;




 
contract CTokenManager is ICTokenManager, OwnableWithoutRenounce {
     

     
    mapping(address => bool) private cTokens;

     

    constructor() public {
        OwnableWithoutRenounce.initialize(msg.sender);
    }

     

     
    function whitelistCToken(address tokenAddress) external onlyOwner {
        require(!isCToken(tokenAddress), "cToken is whitelisted");
        require(ICERC20(tokenAddress).isCToken(), "token is not cToken");
        cTokens[tokenAddress] = true;
        emit WhitelistCToken(tokenAddress);
    }

     
    function discardCToken(address tokenAddress) external onlyOwner {
        require(isCToken(tokenAddress), "cToken is not whitelisted");
        cTokens[tokenAddress] = false;
        emit DiscardCToken(tokenAddress);
    }

     
     
    function isCToken(address tokenAddress) public view returns (bool) {
        return cTokens[tokenAddress];
    }
}