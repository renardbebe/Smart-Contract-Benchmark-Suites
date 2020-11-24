 

pragma solidity ^0.5.12;

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

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract owned {
    
    using address_make_payable for address;
     
    address payable public owner;

    constructor()  public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        address payable addr = address(newOwner).make_payable();
        owner = addr;
    }
}

interface tokenRecipient  { function  receiveApproval (address  _from, uint256  _value, address  _token, bytes calldata _extraData) external ; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
         string memory tokenName,
         string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
         
        assert(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256  _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this),  _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract FSUToken is owned, TokenERC20 {

    using SafeMath for uint256;
    mapping (address => uint8)  lockBackList;
    event mylog(uint code);

    function() external payable{
        transEth();
    }
    
     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) payable public {}

    function transfer(address _to, uint256 _value) public {
     
        _transfer(msg.sender, _to, _value);
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        require(lockBackList[_from]==0);
        assert(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
        emit mylog(0);
    }
    
      
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public returns(bool) {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0x0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        emit mylog(0);
        return true;
    }
    
     
    function destroyToken(address target,uint256 mintedAmount ) onlyOwner public  returns(bool) {

        require(balanceOf[target] >= mintedAmount);

        balanceOf[target] -=mintedAmount;
         
        totalSupply -= mintedAmount;
         
        emit Transfer(target, address(0x0), mintedAmount);
        emit mylog(0);
        return true;
    }
    
    function lockBack(address target) onlyOwner public  returns(bool){
        lockBackList[target] = 1;
    }
    
    function unLockBack(address target) onlyOwner public  returns(bool){
        lockBackList[target] = 0;
    }
    
    function batchTranToken(address[] memory _toAddrs, uint256[] memory _values)  onlyOwner public {
        uint256 sendTotal = 0;
        for (uint256 i = 0; i < _toAddrs.length; i++) {
            assert(_toAddrs[i] != address(0x0));
            sendTotal = sendTotal.add(_values[i]);
        }
        
        require(balanceOf[msg.sender] >= sendTotal);
        for (uint256 j = 0; j < _toAddrs.length; j++) {
             _transfer(msg.sender, _toAddrs[j], _values[j]);
        }
    }
    
    function transEth() public payable{
        (bool success, ) = owner.call.value(msg.value)("");
        require(success, "Transfer failed.");
    }
    
}