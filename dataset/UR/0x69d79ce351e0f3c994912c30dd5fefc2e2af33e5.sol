 

pragma solidity 0.4.24;

 
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

library Utils {

    uint  constant PRECISION = (10**18);
    uint  constant MAX_DECIMALS = 18;

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        if( dstDecimals >= srcDecimals ) {
            require((dstDecimals-srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals-srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals-dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals-dstDecimals)));
        }
    }

     
     
     
     
     
     
     
     
     
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Extended is ERC20 {
    uint256 public decimals;
    string public name;
    string public symbol;

}

contract ComponentInterface {
    string public name;
    string public description;
    string public category;
    string public version;
}

contract ExchangeInterface is ComponentInterface {
     
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId)
        external view returns(bool supported);

     
    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

     
    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract KyberNetworkInterface {

    function getExpectedRate(ERC20Extended src, ERC20Extended dest, uint srcQty)
        external view returns (uint expectedRate, uint slippageRate);

    function trade(
        ERC20Extended source,
        uint srcAmount,
        ERC20Extended dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId)
        external payable returns(uint);
}

 
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

contract OlympusExchangeAdapterInterface is Ownable {

    function supportsTradingPair(address _srcAddress, address _destAddress)
        external view returns(bool supported);

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount)
        external view returns(uint expectedRate, uint slippageRate);

    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external returns(bool success);

    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external payable returns(bool success);

    function enable() external returns(bool);
    function disable() external returns(bool);
    function isEnabled() external view returns (bool success);

    function setExchangeDetails(bytes32 _id, bytes32 _name) external returns(bool success);
    function getExchangeDetails() external view returns(bytes32 _name, bool _enabled);

}

contract BancorConverterInterface {
    string public converterType;
    ERC20Extended[] public quickBuyPath;
     
    function getQuickBuyPathLength() public view returns (uint256);
     
    function getReturn(ERC20Extended _fromToken, ERC20Extended _toToken, uint256 _amount) public view returns (uint256);
     
    function quickConvert(ERC20Extended[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        returns (uint256);

}

contract ERC20NoReturn {
    uint256 public decimals;
    string public name;
    string public symbol;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address from, address to, uint tokens) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BancorNetworkAdapter is OlympusExchangeAdapterInterface {
    using SafeMath for uint256;

    address public exchangeAdapterManager;
    bytes32 public exchangeId;
    bytes32 public name;
    ERC20Extended public constant ETH_TOKEN_ADDRESS = ERC20Extended(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ERC20Extended public constant bancorToken = ERC20Extended(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    ERC20Extended public constant bancorETHToken = ERC20Extended(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    mapping(address => BancorConverterInterface) public tokenToConverter;
    mapping(address => address) public tokenToRelay;

    bool public adapterEnabled;

    modifier checkArrayLengths(address[] tokenAddresses, BancorConverterInterface[] converterAddresses, address[] relayAddresses) {
        require(tokenAddresses.length == converterAddresses.length && relayAddresses.length == converterAddresses.length);
        _;
    }

    modifier checkTokenSupported(address _token) {
        BancorConverterInterface bancorConverter = tokenToConverter[_token];
        require(address(bancorConverter) != 0x0, "Token not supported");
        _;
    }

    constructor (address _exchangeAdapterManager, address[] _tokenAddresses,
    BancorConverterInterface[] _converterAddresses, address[] _relayAddresses)
    checkArrayLengths(_tokenAddresses, _converterAddresses, _relayAddresses) public {
        updateSupportedTokenList(_tokenAddresses, _converterAddresses, _relayAddresses);
        exchangeAdapterManager = _exchangeAdapterManager;
        adapterEnabled = true;
    }

    modifier onlyExchangeAdapterManager() {
        require(msg.sender == address(exchangeAdapterManager));
        _;
    }

    function updateSupportedTokenList(address[] _tokenAddresses, BancorConverterInterface[] _converterAddresses, address[] _relayAddresses)
    checkArrayLengths(_tokenAddresses, _converterAddresses, _relayAddresses)
    public onlyOwner returns (bool success) {
        for(uint i = 0; i < _tokenAddresses.length; i++){
            tokenToConverter[_tokenAddresses[i]] = _converterAddresses[i];
            tokenToRelay[_tokenAddresses[i]] = _relayAddresses[i];
        }
        return true;
    }

    function supportsTradingPair(address _srcAddress, address _destAddress) external view returns(bool supported){
        address _tokenAddress = ETH_TOKEN_ADDRESS == _srcAddress ? _destAddress : _srcAddress;
        BancorConverterInterface bancorConverter = tokenToConverter[_tokenAddress];
        return address(bancorConverter) != 0x0;
    }

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount)
    external view returns(uint expectedRate, uint slippageRate) {
        require(_amount > 0);
        bool isBuying = _sourceAddress == ETH_TOKEN_ADDRESS;
        ERC20Extended targetToken = isBuying ? _destAddress : _sourceAddress;
        BancorConverterInterface BNTConverter = tokenToConverter[address(bancorToken)];

        uint rate;
        BancorConverterInterface targetTokenConverter = tokenToConverter[address(targetToken)];

        uint ETHToBNTRate = BNTConverter.getReturn(bancorETHToken, bancorToken, _amount);


         
        if (targetToken == bancorToken){
            if(isBuying) {
                rate = ((ETHToBNTRate * 10**18) / _amount);
            } else {
                rate = BNTConverter.getReturn(bancorToken, bancorETHToken, _amount);
                rate = ((rate * 10**_sourceAddress.decimals()) / _amount);
            }
        } else {
            if(isBuying){
                 
                rate = targetTokenConverter.getReturn(bancorToken, targetToken, ETHToBNTRate);
                 
                rate = ((rate * 10**18) / _amount);
            } else {
                uint targetTokenToBNTRate = targetTokenConverter.getReturn(targetToken, bancorToken, 10**targetToken.decimals());
                rate = BNTConverter.getReturn(bancorToken, bancorETHToken, targetTokenToBNTRate);
                 
                rate = ((rate * 10**_sourceAddress.decimals()) / _amount);
            }
        }

         
        return (rate,0);
    }

     
    function getPath(ERC20Extended _token, bool isBuying) public view returns(ERC20Extended[] tokenPath, uint resultPathLength) {
        BancorConverterInterface bancorConverter = tokenToConverter[_token];
        uint pathLength;
        ERC20Extended[] memory path;

         
        if(isBuying){
            pathLength = bancorConverter.getQuickBuyPathLength();
            require(pathLength > 0, "Error with pathLength");
            path = new ERC20Extended[](pathLength);

            for (uint i = 0; i < pathLength; i++) {
                path[i] = bancorConverter.quickBuyPath(i);
            }
            return (path, pathLength);
        }

         

        address relayAddress = tokenToRelay[_token];

        if(relayAddress == 0x0){
             
            if(_token == bancorToken){
                path = new ERC20Extended[](3);
                path[0] = _token;
                path[1] = _token;
                path[2] = bancorETHToken;
                return (path, 3);
            }
             
            path = new ERC20Extended[](5);
            path[0] = _token;
            path[1] = _token;
            path[2] = bancorToken;
            path[3] = bancorToken;
            path[4] = bancorETHToken;
            return (path, 5);
        }

         
        path = new ERC20Extended[](5);
        path[0] = _token;                               
        path[1] = ERC20Extended(relayAddress);          
        path[2] = bancorToken;                          
        path[3] = bancorToken;                          
        path[4] = bancorETHToken;                       

        return (path, 5);
    }

     
    function convertMinimumRateToMinimumReturn(ERC20Extended _token, uint _minimumRate, uint _amount, bool isBuying)
    private view returns(uint minimumReturn) {
        if(_minimumRate == 0){
            return 1;
        }

        if(isBuying){
            return (_amount * 10**18) / _minimumRate;
        }

        return (_amount * 10**_token.decimals()) / _minimumRate;
    }

    function sellToken
    (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
    ) checkTokenSupported(_token) external returns(bool success) {
        require(_token.balanceOf(address(this)) >= _amount, "Balance of token is not sufficient in adapter");
        ERC20Extended[] memory internalPath;
        ERC20Extended[] memory path;
        uint pathLength;
        (internalPath,pathLength) = getPath(_token, false);

        path = new ERC20Extended[](pathLength);
        for(uint i = 0; i < pathLength; i++) {
            path[i] = internalPath[i];
        }

        BancorConverterInterface bancorConverter = tokenToConverter[_token];

        ERC20NoReturn(_token).approve(address(bancorConverter), 0);
        ERC20NoReturn(_token).approve(address(bancorConverter), _amount);
        uint minimumReturn = convertMinimumRateToMinimumReturn(_token,_amount,_minimumRate, false);
        uint returnedAmountOfETH = bancorConverter.quickConvert(path,_amount,minimumReturn);
        require(returnedAmountOfETH > 0, "BancorConverter did not return any ETH");
        _depositAddress.transfer(returnedAmountOfETH);
        return true;
    }

    function buyToken (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
    ) checkTokenSupported(_token) external payable returns(bool success){
        require(msg.value == _amount, "Amount of Ether sent is not the same as the amount parameter");
        ERC20Extended[] memory internalPath;
        ERC20Extended[] memory path;
        uint pathLength;
        (internalPath,pathLength) = getPath(_token, true);
        path = new ERC20Extended[](pathLength);
        for(uint i = 0; i < pathLength; i++) {
            path[i] = internalPath[i];
        }

        uint minimumReturn = convertMinimumRateToMinimumReturn(_token,_amount,_minimumRate, true);
        uint returnedAmountOfTokens = tokenToConverter[address(bancorToken)].quickConvert.value(_amount)(path,_amount,minimumReturn);
        require(returnedAmountOfTokens > 0, "BancorConverter did not return any tokens");
        ERC20NoReturn(_token).transfer(_depositAddress, returnedAmountOfTokens);
        return true;
    }

    function enable() external onlyOwner returns(bool){
        adapterEnabled = true;
        return true;
    }

    function disable() external onlyOwner returns(bool){
        adapterEnabled = false;
        return true;
    }

    function isEnabled() external view returns (bool success) {
        return adapterEnabled;
    }

    function setExchangeAdapterManager(address _exchangeAdapterManager) external onlyOwner {
        exchangeAdapterManager = _exchangeAdapterManager;
    }

    function setExchangeDetails(bytes32 _id, bytes32 _name)
    external onlyExchangeAdapterManager returns(bool)
    {
        exchangeId = _id;
        name = _name;
        return true;
    }

    function getExchangeDetails()
    external view returns(bytes32 _name, bool _enabled)
    {
        return (name, adapterEnabled);
    }
}