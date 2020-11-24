 

pragma solidity ^ 0.4.16;


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

   
}
contract tokenRecipient {
    function  receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20 is Ownable{
     
    string public standard = 'CREDITS';
    string public name = 'CREDITS';
    string public symbol = 'CS';
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000000000;
    bool public IsFrozen=false;
    address public ICOAddress;

     
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
 modifier IsNotFrozen{
      require(!IsFrozen||msg.sender==owner
      ||msg.sender==0x0a6d9df476577C0D4A24EB50220fad007e444db8
      ||msg.sender==ICOAddress);
      _;
  }
     
    function ERC20() public {
        balanceOf[msg.sender] = totalSupply;
    }
    function setICOAddress(address _address) public onlyOwner{
        ICOAddress=_address;
    }
    
   function setIsFrozen(bool _IsFrozen)public onlyOwner{
      IsFrozen=_IsFrozen;
    }
     
    function transfer(address _to, uint256 _value) public IsNotFrozen {
        require(balanceOf[msg.sender] >= _value);  
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
        Transfer(msg.sender, _to, _value);  
    }
  
 
     
    function approve(address _spender, uint256 _value)public
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value)public IsNotFrozen returns(bool success)  {
        require (balanceOf[_from] >= _value) ;  
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;  
        require (_value <= allowance[_from][msg.sender]) ;  
      
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
  
    event Burn(address indexed from, uint256 value);
    function burn(uint256 _value) public onlyOwner  returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }
      

    
    
    function setName(string name_) public onlyOwner {
        name = name_;
    }
     
    function () public {
     require(1==2) ;  
    }
}