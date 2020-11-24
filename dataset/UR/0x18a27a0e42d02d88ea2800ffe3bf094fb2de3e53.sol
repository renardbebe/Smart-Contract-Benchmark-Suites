 

pragma solidity 0.4.21;

 

 
interface ExchangeHandler {

     
     
     
     
     
     
     
     
    function getAvailableAmount(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

     
     
     
     
     
     
     
     
     
    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);

     
     
     
     
     
     
     
     
     
    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
}

 

 

 
 
 
 

 
 
 
 

 
 

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
interface AirSwapInterface {
     
    function fills(
        bytes32 hash
    ) external view returns (bool);

     
     
    function fill(
        address makerAddress,
        uint makerAmount,
        address makerToken,
        address takerAddress,
        uint takerAmount,
        address takerToken,
        uint256 expiration,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

 
contract AirSwapHandler is ExchangeHandler, Ownable {
     
    AirSwapInterface public airSwap;
    WETH9 public weth;
    address public totle;

    modifier onlyTotle() {
        require(msg.sender == totle);
        _;
    }

     
    function AirSwapHandler(
        address _airSwap,
        address _wethAddress,
        address _totle
    ) public {
        require(_airSwap != address(0x0));
        require(_wethAddress != address(0x0));
        require(_totle != address(0x0));

        airSwap = AirSwapInterface(_airSwap);
        weth = WETH9(_wethAddress);
        totle = _totle;
    }

     
     
     
    function getAvailableAmount(
        address[8],
        uint256[6] orderValues,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256) {
         
        return orderValues[0];
    }

     
     
     
     
     
     
     
     
    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    onlyTotle
    payable
    returns (uint256) {
        fillBuy(orderAddresses, orderValues, v, r, s);
        return amountToFill;
    }

     
     
     
     
     
     
     
     
    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    onlyTotle
    returns (uint256) {
        return fillSell(orderAddresses, orderValues, v, r, s);
    }

    function setTotle(address _totle)
    external
    onlyOwner {
        require(_totle != address(0));
        totle = _totle;
    }

     
     
    function withdrawToken(address _token, uint _amount)
    external
    onlyOwner
    returns (bool) {
        return ERC20(_token).transfer(owner, _amount);
    }

     
     
    function withdrawETH(uint _amount)
    external
    onlyOwner
    returns (bool) {
        owner.transfer(_amount);
    }

    function() public payable {
    }

     
    function validateOrder(
        address makerAddress,
        uint makerAmount,
        address makerToken,
        address takerAddress,
        uint takerAmount,
        address takerToken,
        uint256 expiration,
        uint256 nonce)
    public
    view
    returns (bool) {
         
        bytes32 hashV = keccak256(makerAddress, makerAmount, makerToken,
                                  takerAddress, takerAmount, takerToken,
                                  expiration, nonce);
        return airSwap.fills(hashV);
    }

     
     
     
     
     
     
     
     
    function fillBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        airSwap.fill.value(msg.value)(orderAddresses[0], orderValues[0], orderAddresses[1],
                                      address(this), orderValues[1], orderAddresses[3],
                                      orderValues[2], orderValues[3], v, r, s);

        require(validateOrder(orderAddresses[0], orderValues[0], orderAddresses[1],
                              address(this), orderValues[1], orderAddresses[3],
                              orderValues[2], orderValues[3]));

        require(ERC20(orderAddresses[1]).transfer(orderAddresses[2], orderValues[0]));
    }

     
     
     
     
     
     
     
     
    function fillSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private
    returns (uint)
    {
        assert(msg.sender == totle);

        require(orderAddresses[1] == address(weth));

        uint takerAmount = orderValues[1];

        require(ERC20(orderAddresses[3]).approve(address(airSwap), takerAmount));

        airSwap.fill(orderAddresses[0], orderValues[0], orderAddresses[1],
                     address(this), takerAmount, orderAddresses[3],
                     orderValues[2], orderValues[3], v, r, s);

        require(validateOrder(orderAddresses[0], orderValues[0], orderAddresses[1],
                              address(this), takerAmount, orderAddresses[3],
                              orderValues[2], orderValues[3]));

        weth.withdraw(orderValues[0]);
        msg.sender.transfer(orderValues[0]);

        return orderValues[0];
    }
}