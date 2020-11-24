 

pragma solidity 0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract ZTXInterface {
    function transferOwnership(address _newOwner) public;
    function mint(address _to, uint256 amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function unpause() public;
}

 

 
contract AirDropperCore is Ownable {
    using SafeMath for uint256;

    mapping (address => bool) public claimedAirdropTokens;

    uint256 public numOfCitizensWhoReceivedDrops;
    uint256 public tokenAmountPerUser;
    uint256 public airdropReceiversLimit;

    ZTXInterface public ztx;

    event TokenDrop(address indexed receiver, uint256 amount);

     
    constructor(uint256 _airdropReceiversLimit, uint256 _tokenAmountPerUser, ZTXInterface _ztx) public {
        require(
            _airdropReceiversLimit != 0 &&
            _tokenAmountPerUser != 0 &&
            _ztx != address(0),
            "constructor params cannot be empty"
        );
        airdropReceiversLimit = _airdropReceiversLimit;
        tokenAmountPerUser = _tokenAmountPerUser;
        ztx = ZTXInterface(_ztx);
    }

    function triggerAirDrops(address[] recipients)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            triggerAirDrop(recipients[i]);
        }
    }

     
    function triggerAirDrop(address recipient)
        public
        onlyOwner
    {
        numOfCitizensWhoReceivedDrops = numOfCitizensWhoReceivedDrops.add(1);

        require(
            numOfCitizensWhoReceivedDrops <= airdropReceiversLimit &&
            !claimedAirdropTokens[recipient],
            "Cannot give more tokens than airdropShare and cannot airdrop to an address that already receive tokens"
        );

        claimedAirdropTokens[recipient] = true;

         
        sendTokensToUser(recipient, tokenAmountPerUser);
        emit TokenDrop(recipient, tokenAmountPerUser);
    }

     
    function sendTokensToUser(address recipient, uint256 tokenAmount) internal {
    }
}

 

 
contract MintableAirDropper is AirDropperCore {
     
    constructor
        (
            uint256 _airdropReceiversLimit,
            uint256 _tokenAmountPerUser,
            ZTXInterface _ztx
        )
        public
        AirDropperCore(_airdropReceiversLimit, _tokenAmountPerUser, _ztx)
    {}

     
    function sendTokensToUser(address recipient, uint256 tokenAmount) internal {
        ztx.mint(recipient, tokenAmount);
        super.sendTokensToUser(recipient, tokenAmount);
    }

     
    function kill(address newZuluOwner) external onlyOwner {
        require(
            numOfCitizensWhoReceivedDrops >= airdropReceiversLimit,
            "only able to kill contract when numOfCitizensWhoReceivedDrops equals or is higher than airdropReceiversLimit"
        );

        ztx.unpause();
        ztx.transferOwnership(newZuluOwner);
        selfdestruct(owner);
    }
}