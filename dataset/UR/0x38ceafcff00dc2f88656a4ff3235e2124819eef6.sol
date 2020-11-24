 

pragma solidity ^0.4.24;



 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b,"");

        return c;
    }
  
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0,"");  
        uint256 c = a / b;
         
  
        return c;
    }
  
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"");
        uint256 c = a - b;

        return c;
    }
  
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"");

        return c;
    }
  
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"");
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
        require(isOwner(),"owner required");
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
        require(newOwner != address(0),"");
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


contract CryptojoyTokenSeller is Ownable {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    
    uint public miningSupply;  

    uint constant MAGNITUDE = 10**6;
    uint constant LOG1DOT5 = 405465;  
    uint constant THREE_SECOND= 15 * MAGNITUDE / 10;  

    uint public a;  
    uint public b;  
    uint public c;  
    uint public blockInterval;  
    uint public startBlockNumber;  

    address public platform;
    uint public lowerBoundaryETH;  
    uint public upperBoundaryETH;  

    uint public supplyPerInterval;  
    uint public miningInterval;
    uint public tokenMint = 0;


    EIP20Interface public token;


     
     
    modifier isWithinLimits(uint _eth) {
        require(_eth >= lowerBoundaryETH, "pocket lint: not a valid currency");
        require(_eth <= upperBoundaryETH, "no vitalik, no");
        _;
    }

     
     
    constructor(
        address tokenAddress, 
        uint _miningInterval,
        uint _supplyPerInterval,
        uint _a, 
        uint _b, 
        uint _c,
        uint _blockInterval, 
        uint _startBlockNumber,
        address _platform,
        uint _lowerBoundaryETH,
        uint _upperBoundaryETH) 
        public {
        
        require(_lowerBoundaryETH < _upperBoundaryETH, "Lower boundary is larger than upper boundary!");

        token = EIP20Interface(tokenAddress);

        a = _a;
        b = _b;
        c = _c;
        blockInterval = _blockInterval;
        startBlockNumber = _startBlockNumber;

        platform = _platform;
        lowerBoundaryETH = _lowerBoundaryETH;
        upperBoundaryETH = _upperBoundaryETH;

        miningInterval = _miningInterval;
        supplyPerInterval = _supplyPerInterval;
    }

    function changeWithdraw(address _platform) public onlyOwner {
        platform = _platform;
    }

    function changeRate(uint _c) public onlyOwner {
        c = _c;
    }

    function withdraw(address _to) public onlyOwner returns (bool success) {
        uint remainBalance = token.balanceOf(address(this));
        return token.transfer(_to, remainBalance);
    }

     
     
    function buy() public isWithinLimits(msg.value) payable {
       
        uint currentStage = getCurrentStage();  
       
        require(tokenMint < currentStage.mul(supplyPerInterval), "No token avaiable");
       
        uint currentPrice = calculatePrice(currentStage);  
       
        uint amountToBuy = msg.value.mul(10**uint(decimals)).div(currentPrice);
        
        if(tokenMint.add(amountToBuy) > currentStage.mul(supplyPerInterval)) {
            amountToBuy = currentStage.mul(supplyPerInterval).sub(tokenMint);
            token.transfer(msg.sender, amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            uint refund = msg.value.sub(amountToBuy.mul(currentPrice).div(10**uint(decimals)));
            msg.sender.transfer(refund);          
            platform.transfer(msg.value.sub(refund)); 
        } else {
            token.transfer(msg.sender, amountToBuy);
            tokenMint = tokenMint.add(amountToBuy);
            platform.transfer(msg.value);
        }
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
        if (currentStage <= miningInterval) {
            return currentStage;
        } else {
            return miningInterval;
        }
    }

     
     
     
    function calculatePrice(uint stage) public view returns (uint) {
        return a.mul(log(stage.mul(MAGNITUDE))).div(MAGNITUDE).add(b).div(c);
    }

     
     
     
    function log(uint input) internal pure returns (uint) {
        uint x = input;
        require(x >= MAGNITUDE, "");
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
}