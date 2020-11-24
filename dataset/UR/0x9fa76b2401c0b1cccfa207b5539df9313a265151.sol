 

pragma solidity ^0.4.18;




 
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





 
contract ERC20Basic {
  uint256 public totalSupply;
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









 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}









 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}








contract SeedPreSale is Ownable {
    uint public minPurchaseNum = 5*(10**17);
    uint public maxPurchaseNum = 50*(10**18);
    uint public preSaleLimit = 5000000*(10**18);
    bool public preSaleOpened = true;
    mapping (address => uint) public userPurchaseNumMap;
    ERC20 public seedContract;

    function SeedPreSale() public {
    }

    function setSeedContract(address seed) public onlyOwner {
        require(seedContract == ERC20(0));
        seedContract = ERC20(seed);
    }

    function setPreSaleOpened(bool opened) onlyOwner public {
        preSaleOpened = opened;
    }

    function getPurchaseETHNum() public view returns(uint) {
        return userPurchaseNumMap[msg.sender];
    }

    event Purchase(address user, uint num, uint money);

     
    function () public payable {
        require(preSaleOpened);
        require(preSaleLimit > 0);
        require(seedContract != ERC20(0));
        require(msg.sender != owner);
        require(msg.value >= minPurchaseNum);
        require(userPurchaseNumMap[msg.sender] < maxPurchaseNum);

        uint allowed = seedContract.allowance(owner, this);
        require(allowed > 0);

        uint remaining = 0;
        uint purchaseMoney = msg.value;
        if (msg.value + userPurchaseNumMap[msg.sender] > maxPurchaseNum) {
            remaining = msg.value + userPurchaseNumMap[msg.sender] - maxPurchaseNum;
            purchaseMoney = maxPurchaseNum - userPurchaseNumMap[msg.sender];
        }

        remaining += purchaseMoney%2500;
        purchaseMoney -= purchaseMoney%2500;

        uint num = purchaseMoney/2500*(10**6);
        if (num > preSaleLimit || num > allowed) {
            if (preSaleLimit > allowed) {
                num = allowed;
            } else {
                num = preSaleLimit;
            }
            num -= num%(10**6);
            require(num > 0);
            remaining += purchaseMoney - num/(10**6)*2500;
            purchaseMoney = num/(10**6)*2500;
        }

        if (remaining > 0) {
            msg.sender.transfer(remaining);
        }

        preSaleLimit -= num;
        seedContract.transferFrom(owner, msg.sender, num);
        userPurchaseNumMap[msg.sender] += purchaseMoney;
        Purchase(msg.sender, num, purchaseMoney);
    }

    event WithdrawFee(uint balance);
     
    function withdrawFee() public onlyOwner {
        require(this.balance > 0);
        owner.transfer(this.balance);
        WithdrawFee(this.balance);
    }
}