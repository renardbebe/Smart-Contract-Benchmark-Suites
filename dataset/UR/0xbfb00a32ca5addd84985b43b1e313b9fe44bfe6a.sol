 

 
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

contract FiatContract {
  function ETH(uint _id) constant returns (uint256);
  function USD(uint _id) constant returns (uint256);
  function EUR(uint _id) constant returns (uint256);
  function GBP(uint _id) constant returns (uint256);
  function updatedAt(uint _id) constant returns (uint);
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

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

 
contract SafeGuard is Ownable {

    event Transaction(address indexed destination, uint value, bytes data);

     
    function executeTransaction(address destination, uint value, bytes data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

     
    function externalCall(address destination, uint value, uint dataLength, bytes data)
    private
    returns (bool) {
        bool result;
        assembly {  
            let x := mload(0x40)    
         
            let d := add(data, 32)  
            result := call(
            sub(gas, 34710),  
             
             
            destination,
            value,
            d,
            dataLength,  
            x,
            0                   
            )
        }
        return result;
    }
}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
         
    }

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
         
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

     
    constructor(uint256 _openingTime, uint256 _closingTime) public {
         
        require(_openingTime >= block.timestamp);
        require(_closingTime >= _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > closingTime;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}

 
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;

    address public tokenWallet;

     
    constructor(address _tokenWallet) public {
        require(_tokenWallet != address(0));
        tokenWallet = _tokenWallet;
    }

     
    function remainingTokens() public view returns (uint256) {
        return token.allowance(tokenWallet, this);
    }

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
    }
}

 
contract PADVTCrowdsale is AllowanceCrowdsale, TimedCrowdsale, SafeGuard {
    
    FiatContract fContract;

     
    constructor(uint256 _rate, address _wallet, ERC20 _token, address _tokenWallet, uint256 _openingTime, uint256 _closingTime)
    Crowdsale(_rate, _wallet, _token)
    AllowanceCrowdsale(_tokenWallet)
    TimedCrowdsale(_openingTime, _closingTime)
    public
    {
        fContract = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
    }

     
    function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
    {
         
        uint256 ethCent = fContract.USD(0) * rate;
        return _weiAmount.div(ethCent);
    }
}