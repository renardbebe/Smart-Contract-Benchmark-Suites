 

pragma solidity ^0.4.24;
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner,address indexed spender,uint256 value);
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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
  
    
  event OwnerEvent(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnerEvent(owner, newOwner);
    owner = newOwner;
  }

}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
   
contract TBCPublishToken is StandardToken,Ownable,Pausable{
    
    string public name ;
    string public symbol ;
    uint8 public decimals ;
    address public owner;
 
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokenDecimals)  public {
        owner = msg.sender;
        totalSupply_ = initialSupply * 10 ** uint256(tokenDecimals);
        balances[owner] = totalSupply_;
        name = tokenName;
        symbol = tokenSymbol;
        decimals=tokenDecimals;
    }
    
    event Mint(address indexed to, uint256 value);
    event TransferETH(address indexed from, address indexed to, uint256 value);
    
    mapping(address => bool) touched;
    mapping(address => bool) airDropPayabled;
    
    bool public airDropShadowTag = true;
    bool public airDropPayableTag = true;
    uint256 public airDropShadowMoney = 888;
    uint256 public airDropPayableMoney = 88;
    uint256 public airDropTotalSupply = 0;
    uint256 public buyPrice = 40000;

    function setName(string name_) onlyOwner public{
        name = name_;
    }
    function setSymbol(string symbol_) onlyOwner public{
        symbol = symbol_;
    }
    function setDecimals(uint8 decimals_) onlyOwner public{
        decimals = decimals_;
    }

     
    function mint(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_value > 0 );
        balances[_to]  = balances[_to].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function setAirDropShadowTag(bool airDropShadowTag_,uint airDropShadowMoney_) onlyOwner public{
        airDropShadowTag = airDropShadowTag_;
        airDropShadowMoney = airDropShadowMoney_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(msg.sender != address(0));
 
        if(airDropShadowTag  && balances[_owner] == 0)
            balances[_owner] += airDropShadowMoney * 10 ** uint256(decimals);
        return balances[_owner];
    }
    function setPrices(uint256 newBuyPrice) onlyOwner public{
        require(newBuyPrice > 0) ;
        require(buyPrice != newBuyPrice);
        buyPrice = newBuyPrice;
    }
    function setAirDropPayableTag(bool airDropPayableTag_,uint airDropPayableMoney_) onlyOwner public{
        airDropPayableTag = airDropPayableTag_;
        airDropPayableMoney = airDropPayableMoney_;
    }
    function () public payable {
        require(msg.value >= 0 );
        require(msg.sender != owner);
        uint256 amount = airDropPayableMoney * 10 ** uint256(decimals);
        if(msg.value == 0 && airDropShadowTag && !airDropPayabled[msg.sender] && airDropTotalSupply < totalSupply_){
            balances[msg.sender] = balances[msg.sender].add(amount);
            airDropPayabled[msg.sender] = true;
            airDropTotalSupply = airDropTotalSupply.add(amount);
            balances[owner] = balances[owner].sub(amount);
            emit Transfer(owner,msg.sender,amount);
        }else{
            amount = msg.value.mul(buyPrice);
            require(balances[owner]  >= amount);
            balances[msg.sender] = balances[msg.sender].add(amount);
            balances[owner] = balances[owner].sub(amount);
            owner.transfer(msg.value);
            emit TransferETH(msg.sender,owner,msg.value);
            emit Transfer(owner,msg.sender,amount);
        }
    }  
     
    event Burn(address indexed burner, uint256 value);

    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        require(_value > 0 );
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public {
        require(_value > 0 );
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         
    
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
     
    function burnFrom(address _from, uint256 _value) public {
        require(_value > 0 );
        require(_value <= allowed[_from][msg.sender]);
         
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
    
    function transfer(address _to,uint256 _value) public whenNotPaused returns (bool){
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from,address _to, uint256 _value) public whenNotPaused returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender,uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender,uint _addedValue) public  whenNotPaused returns (bool success){
     return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval( address _spender,uint _subtractedValue)  public whenNotPaused returns (bool success){
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
        uint length_ = _receivers.length;
        uint256 amount =  _value.mul(length_);
        require(length_ > 0 );
        require(_value > 0 && balances[msg.sender] >= amount);
    
        balances[msg.sender] = balances[msg.sender].sub(amount);
        for (uint i = 0; i < length_; i++) {
            require (balances[_receivers[i]].add(_value) < balances[_receivers[i]]) ;  
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
            emit Transfer(msg.sender, _receivers[i], _value);
        }
        return true;
    }
     
}