 

pragma solidity > 0.4.99 <0.6.0;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool);
    function decimals() external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract Ownable {
  address payable public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract PayeeShare is Ownable{
    
    struct Payee {
        address payable payee;
        uint payeePercentage;
    }
    
    Payee[] public payees;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    IERC20Token public tokenContract;
    
    bool processingPayout = false;
    
    uint256 public payeePartsLeft = 100;
    uint256 public payeePartsToSell = 0;
    uint256 public payeePricePerPart = 0;
    
    uint256 public lockedToken;
    uint256 public lockedTokenTime;
    uint256 minTokenTransfer = 1;
    
    using SafeMath for uint256;
    
    event TokenPayout(address receiver, uint256 value, string memberOf);
    event EtherPayout(address receiver, uint256 value, string memberOf);
    event PayeeAdded(address payee, uint256 partsPerFull);
    event LockedTokensUnlocked();
    
    constructor(address _tokenContract, uint256 _lockedToken, uint256 _lockedTokenTime) public {
        tokenContract = IERC20Token(_tokenContract);
        lockedToken = _lockedToken;
        lockedTokenTime = _lockedTokenTime;
    }
    
    function changePayee(uint256 _payeeId, address payable _payee, uint256 _percentage) public onlyOwner {
      require(payees.length >= _payeeId);
      Payee storage myPayee = payees[_payeeId];
      myPayee.payee = _payee;
      myPayee.payeePercentage = _percentage;
    }
  
    function getPayeeLenght() public view returns (uint256) {
        return payees.length;
    }
    
     function getLockedToken() public view returns (uint256) {
        return lockedToken;
    }
    
    function addPayee(address payable _address, uint _payeePercentage) public payable {
        if (msg.sender == _owner) {
        require(payeePartsLeft >= _payeePercentage);
        payeePartsLeft = payeePartsLeft.sub(_payeePercentage);
        payees.push(Payee(_address, _payeePercentage));
        emit PayeeAdded(_address, _payeePercentage);
        }
        else if (msg.value == _payeePercentage.mul(payeePricePerPart)) {
        if (address(this).balance > 0) {
          etherPayout();
        }
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 1) {
          tokenPayout();
        }
            require(payeePartsLeft >= _payeePercentage);
            require(payeePartsToSell >= _payeePercentage);
            require(tx.origin == msg.sender);
            payeePartsToSell = payeePartsToSell.sub(_payeePercentage);
            payeePartsLeft = payeePartsLeft.sub(_payeePercentage);
            payees.push(Payee(tx.origin, _payeePercentage));
            emit PayeeAdded(tx.origin, _payeePercentage);
        } else revert();
    } 
    
    function setPartsToSell(uint256 _parts, uint256 _price) public onlyOwner {
        require(payeePartsLeft >= _parts);
        payeePartsToSell = _parts;
        payeePricePerPart = _price;
    }
    
    function etherPayout() public {
        require(processingPayout == false);
        processingPayout = true;
        uint256 receivedValue = address(this).balance;
        uint counter = 0;
        for (uint i = 0; i < payees.length; i++) {
           Payee memory myPayee = payees[i];
           myPayee.payee.transfer((receivedValue.mul(myPayee.payeePercentage).div(100)));
           emit EtherPayout(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100), "Shareholder");
            counter++;
          }
        if(address(this).balance > 0) {
            _owner.transfer(address(this).balance);
            emit EtherPayout(_owner, address(this).balance, "Owner");
        }
        processingPayout = false;
    }
    
     function tokenPayout() public payable {
        require(processingPayout == false);
        require(tokenContract.balanceOf(address(this)) >= lockedToken.add((minTokenTransfer.mul(10 ** tokenContract.decimals()))));
        processingPayout = true;
        uint256 receivedValue = tokenContract.balanceOf(address(this)).sub(lockedToken);
        uint counter = 0;
        for (uint i = 0; i < payees.length; i++) {
           Payee memory myPayee = payees[i];
           tokenContract.transfer(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100));
           emit TokenPayout(myPayee.payee, receivedValue.mul(myPayee.payeePercentage).div(100), "Shareholder");
            counter++;
          } 
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 0) {
            tokenContract.transfer(_owner, tokenContract.balanceOf(address(this)).sub(lockedToken));
            emit TokenPayout(_owner, tokenContract.balanceOf(address(this)).sub(lockedToken), "Owner");
        }
        processingPayout = false;
    }
    
    function payoutLockedToken() public payable onlyOwner {
        require(processingPayout == false);
        require(now > lockedTokenTime);
        require(tokenContract.balanceOf(address(this)) >= lockedToken);
        lockedToken = 0;
        if (address(this).balance > 0) {
          etherPayout();
        }
        if (tokenContract.balanceOf(address(this)).sub(lockedToken) > 1) {
          tokenPayout();
        }
        processingPayout = true;
        emit LockedTokensUnlocked();
        tokenContract.transfer(_owner, tokenContract.balanceOf(address(this)));
        processingPayout = false;
    }
    
    function() external payable {
    }
}