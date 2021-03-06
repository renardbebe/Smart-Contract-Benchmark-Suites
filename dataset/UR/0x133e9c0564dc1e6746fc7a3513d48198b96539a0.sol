 

pragma solidity 0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

 
contract CTF15Token is StandardToken, BurnableToken, Ownable {
        address public owner;
        address public pricingBot;
        string public constant name = "CTF15Token";  
        string public constant symbol = "C15";  
        uint8 public constant decimals = 5;  

        uint256 public constant INITIAL_SUPPLY = 0 * (10 ** uint256(decimals));

         
        constructor() public {
                owner = msg.sender;
                pricingBot = msg.sender;
                coinNumber = 15;
                 
                coinPrices = new uint64[](coinNumber);
                 
                coinShares = new uint64[](coinNumber);
        }

         
        uint8 public coinNumber;
        uint64 public buyBackPrice;
        uint64[] public coinPrices;
        uint64[] public coinShares;
        uint64 public indexValue;

         
        bool public mintingFinished = false;

         
        event BuyAssets(
                uint256[] assetsToBuy
        );
        event SellAssets(
                uint256[] assetsToSell
        );
        event Mint(
                address indexed to,
                uint256 amount
        );
        event MintFinished();

        modifier canMint() {
                require(!mintingFinished);
                _;
        }

        modifier hasMintPermission() {
                require(msg.sender == owner);
                _;
        }

         
        function mint(
                address _to,
                uint256 _amount
        )
        hasMintPermission
        canMint
        public
        returns (bool) {
                totalSupply_ = totalSupply_.add(_amount);
                balances[_to] = balances[_to].add(_amount);
                emit Mint(_to, _amount);
                emit Transfer(address(0), _to, _amount);
                return true;
        }

         
        function finishMinting() onlyOwner canMint public returns (bool) {
                mintingFinished = true;
                emit MintFinished();
                return true;
        }

         
        function UpdatePricingBot(address newBotAddress) onlyOwner public {
                pricingBot = newBotAddress;
        }

        function UpdateCoinShares(uint64[] _shares) public {
                require(msg.sender == pricingBot);
                require(_shares.length >= coinNumber);

                for (uint8 i = 0; i < coinNumber; i++) {
                        coinShares[i] = _shares[i];
                }
        }

        function UpdateCoinPrices(uint64[] _prices) public {
                require(msg.sender == pricingBot);
                require(_prices.length >= coinNumber);

                for (uint8 i = 0; i < coinNumber; i++) {
                        coinPrices[i] = _prices[i];
                }
        }

         
        function GenerateNewTokens(uint ethIndex, uint totalAmount) public returns(bool) {
                 
                mint(msg.sender, totalAmount);

                 
                uint256[] memory buyOrders = new uint256[](coinNumber);
                for (uint8 i = 0; i < coinNumber; i++) {
                        buyOrders[i] = (coinShares[i] * totalAmount * coinPrices[ethIndex]) / (1e16 * 1000);
                }
                emit BuyAssets(buyOrders);
                return true;
        }

        function SellTokens(uint ethIndex, uint amount) public returns(bool) {
                 
                require(amount <= balances[msg.sender]);

                 
                _burn(msg.sender, amount);

                 
                uint256[] memory sellOrders = new uint256[](coinNumber);
                for (uint8 i = 0; i < coinNumber; i++) {
                        sellOrders[i] = (coinShares[i] * amount * coinPrices[ethIndex]) / (1e16 * 1000);
                }
                emit SellAssets(sellOrders);
                return true;
        }

        function SetBuyBackPrice(uint64 newPrice) public onlyOwner {
                buyBackPrice = newPrice;
        }

        function SetCoinNumber(uint8 newNumber) public onlyOwner {
                coinNumber = newNumber;
                coinPrices = new uint64[](coinNumber);
                coinShares = new uint64[](coinNumber);
        }

        function SetIndexValue(uint64 newValue) public onlyOwner {
                indexValue = newValue;
        }
}