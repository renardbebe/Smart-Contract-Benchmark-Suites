 

pragma solidity ^0.4.22;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public  {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public  onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract BGCGToken is Pausable {

  using SafeMath for SafeMath;

  string public name = "Blockchain Game Coalition Gold";
  string public symbol = "BGCG";
  uint8 public decimals = 18;
  uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals);  

 
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);

 mapping (address => bool) public frozenAccount;
 event FrozenFunds(address target, bool frozen);



 constructor() public payable {
    balanceOf[msg.sender] = totalSupply;
    owner = msg.sender;
  }

   
  function() public payable {
       
    }

  
 
  function withdraw() public onlyOwner {
      owner.transfer(address(this).balance); 
    }

 
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_spender]);
   
    allowance[msg.sender][_spender] = _value;

    emit Approval(msg.sender,_spender, _value);

    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public whenNotPaused returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
      }
  }

  
  function burn(uint256 _value) public whenNotPaused returns (bool success) {
    require(balanceOf[msg.sender] >= _value);    
    require(totalSupply >= _value );
    require( _value > 0 );

    balanceOf[msg.sender] = SafeMath.sub( balanceOf[msg.sender],_value);             
    totalSupply = SafeMath.sub(totalSupply, _value);                       
    emit Burn(msg.sender, _value);
    return true;
  }

  
  function burnFrom(address _from, uint256 _value) public whenNotPaused returns (bool success) {
    require(balanceOf[_from] >= _value);                 
    require(_value <= allowance[_from][msg.sender]);     
    require(totalSupply >= _value );
    require( _value > 0 );

    balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);                          
    allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);              
    totalSupply = SafeMath.sub(totalSupply, _value);                               
    emit Burn(_from, _value);
    return true;
  }



 
 function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require( _value > 0 );
    require(_to != address(0)); 
    require(msg.sender != _to ); 
    require(balanceOf[msg.sender] >= _value);
    require(SafeMath.add(balanceOf[_to],_value) > balanceOf[_to]);   


    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_to]);
    
    uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_to]; 

    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender],_value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);
    emit Transfer(msg.sender, _to, _value);

     
    assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);

    return true;
  }

 
function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require( _value > 0 );
    require(_to != address(0));
    require(_from != address(0));
  
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    require(SafeMath.add(balanceOf[_to],_value) > balanceOf[_to]);  

    require(!frozenAccount[_from]);
    require(!frozenAccount[_to]);

    balanceOf[_from] = SafeMath.sub(balanceOf[_from],_value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);
    allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender],_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

 
  function freezeAccount(address target, bool freeze) public onlyOwner {
    require(target != address(0));
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
 }

 
  function mintToken(address target, uint256 mintedAmount) public whenNotPaused onlyOwner {
        require( mintedAmount > 0 );
        require(target != address(0));
        
        require(SafeMath.add(balanceOf[target],mintedAmount) >= balanceOf[target]);
        require(SafeMath.add(totalSupply,mintedAmount) >= totalSupply);

        balanceOf[target] = SafeMath.add(balanceOf[target],mintedAmount);
        totalSupply = SafeMath.add(totalSupply,mintedAmount);

        emit Transfer(owner, target, mintedAmount);
 }

}