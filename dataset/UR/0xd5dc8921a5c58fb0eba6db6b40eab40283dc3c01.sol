 

pragma solidity ^0.5.1;

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

contract DDAM is Ownable, SafeMath, Pausable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public blacklist;


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event MappingTo(address _from, uint256 _value, string _mainnetAddr);




     
    constructor() public payable  {
        totalSupply = 960000000000000000;
        balanceOf[msg.sender] = 960000000000000000;
        name = "DDAM";                                   
        symbol = "DDAM";                              
        decimals = 9;                           
    }
    
    modifier canTransfer() {
        require(!blacklist[msg.sender]);
        _;
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused canTransfer public returns (bool success){
        require(_to != address(0x0));                              
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);          
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                           
        emit Transfer(msg.sender, _to, _value);                  
        return true;
    }


     
    function approve(address _spender, uint256 _value) whenNotPaused canTransfer public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused canTransfer public returns (bool success) {
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

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) whenNotPaused canTransfer public returns (bool success) {
        tokenRecipientInterface spender = tokenRecipientInterface(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
    }
    
    function mappingTo(uint256 _value, string memory _mainnetAddr) canTransfer public {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply, _value);
        emit MappingTo(msg.sender, _value, _mainnetAddr);
    }
    

    function ban(address addr) onlyOwner public  {
        blacklist[addr] = true;
    }


    function enable(address addr) onlyOwner public  {
        blacklist[addr] = false;
    }

    function () external payable {
    }

     
    function withdrawEther(uint256 _amount) onlyOwner public {
        msg.sender.transfer(_amount);
    }
}