 

pragma solidity ^0.5.1;

contract ERC20 {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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
 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract tokenRecipientInterface {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}

contract TZVC is Ownable, SafeMath, Pausable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public tokenLeft;
    address public tokenAddress;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Mapping(address _from, uint256 _value, bytes _extraData);
    
    event Burn(address _from, uint256 _value, string _zvAddr);




     
    constructor(address _tokenAddress) public payable  {
        tokenLeft = 90000000000000000;               
        totalSupply = 90000000000000000;                         
        name = "TZVC";                                    
        symbol = "TZVC";                                
        decimals = 9;                             
        tokenAddress = _tokenAddress;
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success){
        require(_to != address(0x0));                                
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);            
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }


     
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require (_to != address(0x0));                                 
        require (_value > 0);
        require (balanceOf[_from] >= _value);                  
        require (_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) whenNotPaused public returns (bool success) {
        tokenRecipientInterface spender = tokenRecipientInterface(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
    }
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public {
        require(_token == tokenAddress);
        require(_value > 0);
        require(_value <= tokenLeft);
        ERC20 token = ERC20(_token);
        if (token.transferFrom(_from, address(this), _value)) {
            balanceOf[_from] = SafeMath.safeAdd(balanceOf[_from], _value);
            tokenLeft = SafeMath.safeSub(tokenLeft, _value);
            emit Mapping(_from, _value, _extraData);
        }
    }
    
    function burn(uint256 _value, string memory _zvAddr) public {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); 
        totalSupply = SafeMath.safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value, _zvAddr); 
    }

    function () external payable {
    }

     
    function withdrawEther(uint256 _amount) public onlyOwner{
        msg.sender.transfer(_amount);
    }
}