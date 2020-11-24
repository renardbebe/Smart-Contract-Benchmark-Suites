 

pragma solidity ^0.4.23;

 

 

pragma solidity 0.4.24;
 

interface IArbitrage {
    function executeArbitrage(
      address token,
      uint256 amount,
      address dest,
      bytes data
    )
      external
      returns (bool);
}

 

 

pragma solidity 0.4.24;


contract IBank {
    function totalSupplyOf(address token) public view returns (uint256 balance);
    function borrowFor(address token, address borrower, uint256 amount) public;
    function repay(address token, uint256 amount) external payable;
}

 

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
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

 

 

pragma solidity 0.4.24;







 
 
contract FlashLender is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public version = '0.1';
    address public bank;
    uint256 public fee;
    
     
    modifier isArbitrage(address token, uint256 amount) {
        uint256 balance = IBank(bank).totalSupplyOf(token);
        uint256 feeAmount = amount.mul(fee).div(10 ** 18); 
        _;
        require(IBank(bank).totalSupplyOf(token) >= (balance.add(feeAmount)));
    }

    constructor(address _bank, uint256 _fee) public {
        bank = _bank;
        fee = _fee;
    }

     
    function borrow(
        address token,
        uint256 amount,
        address dest,
        bytes data
    )
        external
        nonReentrant
        isArbitrage(token, amount)
        returns (bool)
    {
         
        IBank(bank).borrowFor(token, msg.sender, amount);
         
        return IArbitrage(msg.sender).executeArbitrage(token, amount, dest, data);
    }

     
    function setBank(address _bank) external onlyOwner {
        bank = _bank;
    }

     
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

}

 

 

pragma solidity 0.4.24;

contract ExternalCall {
     
     
     
    function external_call(address destination, uint value, uint dataLength, bytes data) internal returns (bool) {
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

 

 

pragma solidity 0.4.24;








 
 
contract Arbitrage is IArbitrage, ExternalCall {
    using SafeMath for uint256;

    address public lender;
    address public tradeExecutor;
    address constant public ETH = 0x0;
    uint256 constant public MAX_UINT = 2 ** 256 - 1;

    modifier onlyLender() {
        require(msg.sender == lender);
        _;
    }

    constructor(address _lender, address _tradeExecutor) public {
        lender = _lender;
        tradeExecutor = _tradeExecutor; 
    }

     
    function () payable public {}

     
    function submitTrade(address token, uint256 amount, address dest, bytes data) external {
        FlashLender(lender).borrow(token, amount, dest, data);
    }

     
    function executeArbitrage(
        address token,
        uint256 amount,
        address dest,
        bytes data
    )
        external
        onlyLender 
        returns (bool)
    {
        uint256 value = 0;
        if (token == ETH) {
            value = amount;
        } else {
             
            ERC20(token).transfer(tradeExecutor, amount);
        }

         
        external_call(tradeExecutor, value, data.length, data);

         
        uint256 repayAmount = getRepayAmount(amount);

        address bank = FlashLender(lender).bank();

         
        if (token == ETH) {
            IBank(bank).repay.value(repayAmount)(token, repayAmount);
            dest.transfer(address(this).balance);
        } else {
            if (ERC20(token).allowance(this, bank) < repayAmount) {
                ERC20(token).approve(bank, MAX_UINT);
            }
            IBank(bank).repay(token, repayAmount);
            uint256 balance = ERC20(token).balanceOf(this);
            require(ERC20(token).transfer(dest, balance));
        }

        return true;
    }

      
    function getRepayAmount(uint256 amount) public view returns (uint256) {
        uint256 fee = FlashLender(lender).fee();
        uint256 feeAmount = amount.mul(fee).div(10 ** 18);
        return amount.add(feeAmount);
    }

}