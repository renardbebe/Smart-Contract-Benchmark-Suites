 

pragma solidity ^0.4.24;


 
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
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
  
contract standardToken is EIP20Interface, Ownable {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    uint8 public constant decimals = 18;  

    string public name;                    
    string public symbol;                
    uint public totalSupply;

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

     
    function increaseApproval(address _spender, uint _addedValue) public returns(bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        return true;
    }
}

 
 
 
 
contract pairToken is standardToken {
    using SafeMath for uint;

    address public pairAddress;

    bool public pairInitialized = false;

     
    function initPair(address _pairAddress) public onlyOwner() {
        require(!pairInitialized, "Pair already initialized");
        pairAddress = _pairAddress;
        pairInitialized = true;
    }

     
     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        if (_to == pairAddress || _to == address(this)) {
            balances[address(this)] = balances[address(this)].add(_value);
            pairToken(pairAddress).pairTransfer(msg.sender, _value);
            emit Exchange(msg.sender, address(this), _value);
            emit Transfer(msg.sender, _to, _value);
        } else {
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }
        return true;
    } 

     
    function pairTransfer(address _to, uint _value) external returns (bool success) {
        require(msg.sender == pairAddress, "Only token pairs can transfer");
        balances[address(this)] = balances[address(this)].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }

    event Exchange(address indexed _from, address _tokenAddress, uint _value);
}

 
 
 
 
contract CryptojoyToken is pairToken {
    using SafeMath for uint;

    string public name = "cryptojoy token";                    
    string public symbol = "CJT";                
    uint public totalSupply = 10**10 * 10**18;  
    uint public miningSupply;  

    uint constant MAGNITUDE = 10**6;
    uint constant LOG1DOT5 = 405465;  
    uint constant THREE_SECOND= 15 * MAGNITUDE / 10;  
    uint constant MINING_INTERVAL = 365;  

    uint public a;  
    uint public b;  
    uint public blockInterval;  
    uint public startBlockNumber;  

    address public platform;
    uint public lowerBoundaryETH;  
    uint public upperBoundaryETH;  

    uint public supplyPerInterval;  
    uint public tokenMint = 0;

    bool paraInitialized = false;

     
     
    constructor(
        address _beneficiary, 
        uint _miningSupply)
        public {
        require(_miningSupply < totalSupply, "Insufficient total supply");
        miningSupply = _miningSupply;
        uint _amount = totalSupply.sub(_miningSupply);
        balances[address(this)] = miningSupply;
        balances[_beneficiary] = _amount;
        supplyPerInterval = miningSupply / MINING_INTERVAL;
    }


     
     
    modifier isWithinLimits(uint _eth) {
        require(_eth >= lowerBoundaryETH, "pocket lint: not a valid currency");
        require(_eth <= upperBoundaryETH, "no vitalik, no");
        _;
    }

     
     
    function initPara(
        uint _a, 
        uint _b, 
        uint _blockInterval, 
        uint _startBlockNumber,
        address _platform,
        uint _lowerBoundaryETH,
        uint _upperBoundaryETH) 
        public 
        onlyOwner {
        require(!paraInitialized, "Parameters are already set");
        require(_lowerBoundaryETH < _upperBoundaryETH, "Lower boundary is larger than upper boundary!");
        a = _a;
        b = _b;
        blockInterval = _blockInterval;
        startBlockNumber = _startBlockNumber;

        platform = _platform;
        lowerBoundaryETH = _lowerBoundaryETH;
        upperBoundaryETH = _upperBoundaryETH;

        paraInitialized = true;
    }

    function changeWithdraw(address _platform) public onlyOwner {
        platform = _platform;
    }

     
     
    function buy() public isWithinLimits(msg.value) payable {
        uint currentStage = getCurrentStage();  
        require(tokenMint < currentStage.mul(supplyPerInterval), "No token avaiable");
        uint currentPrice = calculatePrice(currentStage);  
        uint amountToBuy = msg.value.mul(10**uint(decimals)).div(currentPrice);
        
        if(tokenMint.add(amountToBuy) > currentStage.mul(supplyPerInterval)) {
            amountToBuy = currentStage.mul(supplyPerInterval).sub(tokenMint);
            balances[address(this)] = balances[address(this)].sub(amountToBuy);
            balances[msg.sender] = balances[msg.sender].add(amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            uint refund = msg.value.sub(amountToBuy.mul(currentPrice).div(10**uint(decimals)));
            msg.sender.transfer(refund);          
            platform.transfer(msg.value.sub(refund)); 
        } else {
            balances[address(this)] = balances[address(this)].sub(amountToBuy);
            balances[msg.sender] = balances[msg.sender].add(amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            platform.transfer(msg.value);
        }
        emit Buy(msg.sender, amountToBuy);
    }

    function() public payable {
        buy();
    }

     
    function tokenRemain() public view returns (uint) {
        uint currentStage = getCurrentStage();
        return currentStage * supplyPerInterval - tokenMint;
    }

     
    function getCurrentStage() public view returns (uint) {
        require(block.number >= startBlockNumber, "Not started yet");
        uint currentStage = (block.number.sub(startBlockNumber)).div(blockInterval) + 1;
        if (currentStage <= MINING_INTERVAL) {
            return currentStage;
        } else {
            return MINING_INTERVAL;
        }
    }

     
     
     
    function calculatePrice(uint stage) public view returns (uint) {
        return a.mul(log(stage.mul(MAGNITUDE))).div(MAGNITUDE).add(b);
    }

     
     
     
    function log(uint input) internal pure returns (uint) {
        uint x = input;
        require(x >= MAGNITUDE);
        if (x == MAGNITUDE) {
            return 0;
        }
        uint result = 0;
        while (x >= THREE_SECOND) {
            result += LOG1DOT5;
            x = x * 2 / 3;
        }
        
        x = x - MAGNITUDE;
        uint y = x;
        uint i = 1;
        while (i < 10) {
            result = result + (y / i);
            i += 1;
            y = y * x / MAGNITUDE;
            result = result - (y / i);
            i += 1;
            y = y * x / MAGNITUDE;
        }
        
        return result;
    }

    event Buy(address indexed _buyer, uint _value);
}

contract CryptojoyStock is pairToken {


    string public name = "cryptojoy stock";                    
    string public symbol = "CJS";                
    uint public totalSupply = 10**10 * 10**18;

    constructor() public {
        balances[address(this)] = totalSupply;
    } 

}