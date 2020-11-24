 

 

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

 

pragma solidity ^0.5.0;


 
contract Context is Initializable {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;



 
contract Ownable is Initializable, Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

    uint256[50] private ______gap;
}

 

pragma solidity 0.5.12;



 
interface ERC20 {
  function totalSupply() external view returns (uint supply);
  function balanceOf(address _owner) external view returns (uint balance);
  function transfer(address _to, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function approve(address _spender, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function decimals() external view returns(uint digits);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
interface IChai {
  function join(address dst, uint wad) external;
}

 
interface IKyberNetworkProxy {
  function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
  function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
  function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) external returns(uint);
}

contract Forwarder is Initializable, Ownable {

   

   
   
   

   
  address public floatify;

   
  address public daiAddress;
  ERC20 public daiContract;

  address public chaiAddress;
  IChai public chaiContract;

  address public knpAddress;
  IKyberNetworkProxy public knpContract;

  ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

   
   
   

   
  event ChaiSent(uint256 indexed amountInDai);

   
  event SwapEther(uint256 indexed amountInDai, uint256 indexed amountInEther);

   
  event FloatifyAddressChanged(address indexed previosAddress, address indexed newAddress);


   
   
   

   
  function initialize(
    address _owner,
    address _floatify,
    address _dai,
    address _chai,
    address _kyber
  ) public initializer {
     
    Ownable.initialize(_owner);
     

     
    floatify = _floatify;

     
    daiAddress = _dai;
    daiContract = ERC20(daiAddress);
    chaiAddress = _chai;
    chaiContract = IChai(chaiAddress);
    knpAddress = _kyber;
    knpContract = IKyberNetworkProxy(knpAddress);

     
    bool approvalResult = daiContract.approve(chaiAddress, uint256(-1));
    require(approvalResult, "Failed to approve Chai contract to spend DAI");
  }


   
   
   

   
  modifier onlyFloatify() {
    require(_msgSender() == floatify, "Forwarder: caller is not the floatify address");
    _;
  }

   
  function updateFloatifyAddress(address _newAddress) public onlyFloatify {
     
    require(_newAddress != address(0), "Forwarder: new floatify address is the zero address");
     
    emit FloatifyAddressChanged(floatify, _newAddress);
    floatify = _newAddress;
  }

   
  function updateDaiAddress(address _newAddress) public onlyFloatify {
    daiAddress = _newAddress;
    daiContract = ERC20(daiAddress);
  }

   
  function updateChaiAddress(address _newAddress) public onlyFloatify {
    chaiAddress = _newAddress;
    chaiContract = IChai(chaiAddress);
  }

   
  function updateKyberAddress(address _newAddress) public onlyFloatify {
    knpAddress = _newAddress;
    knpContract = IKyberNetworkProxy(knpAddress);
  }


   
   
   

   
  function mintAndSendChai() public {
     
    uint256 _daiBalance = daiContract.balanceOf(address(this));
     
    emit ChaiSent(_daiBalance);
    address _owner = owner();
    chaiContract.join(_owner, _daiBalance);
  }


   
  function convertAndSendToken(address _srcTokenAddress) public {
     
     
     

     
    ERC20 _srcTokenContract = ERC20(_srcTokenAddress);
    uint256 _srcTokenBalance = _srcTokenContract.balanceOf(address(this));

     
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(_srcTokenContract, daiContract, _srcTokenBalance);

     
     

     
    require(_srcTokenContract.approve(knpAddress, 0));

     
    _srcTokenContract.approve(knpAddress, _srcTokenBalance);
    uint _destAmount = knpContract.swapTokenToToken(_srcTokenContract, _srcTokenBalance, daiContract, minRate);
    require(_destAmount == _srcTokenContract.balanceOf(address(this)), "Token balaces not equal");

     
    mintAndSendChai();
  }

   
  function() external payable {
     
     
     

     
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(ETH_TOKEN_ADDRESS, daiContract, msg.value);

     
    uint256 _destAmount = knpContract.swapEtherToToken.value(msg.value)(daiContract, minRate);
    require(_destAmount == daiContract.balanceOf(address(this)), "Balaces not equallll");

    uint256 daiBalance = daiContract.balanceOf(address(this));

    emit SwapEther(daiBalance, address(this).balance);

     
    mintAndSendChai();
  }
}