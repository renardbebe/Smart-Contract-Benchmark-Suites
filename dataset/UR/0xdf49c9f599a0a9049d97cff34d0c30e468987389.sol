 

pragma solidity ^0.5.6;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function() external payable  {
    }
    
     function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
}




interface ERC20 {
  function transfer(address receiver, uint256 value) external returns (bool ok);
}


interface ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes32 _data) external ;
}



contract SaTT is owned,ERC20 {

    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 20000000000000000000000000000;  
    string public constant symbol = "SATT";
    string public constant name = "Smart Advertising Transaction Token";
    

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    
   
    constructor () public {
        balanceOf[msg.sender] = totalSupply;               
    }
    
     function isContract(address _addr) internal view returns (bool is_contract) {
      bytes32 hash;
     
      assembly {
             
            hash := extcodehash(_addr)
      }
      return (hash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 && hash != bytes32(0));
     
    }
    
     function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
     function transfer(address to, uint256 value,bytes memory  data) public returns (bool success) {
         if((data[0])!= 0) { 
            _transfer(msg.sender, to, value);
         }
        return true;
    }
    
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
       
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        
        if(isContract(_to))
        {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, bytes32(0));
        }
        
        emit Transfer(_from, _to, _value);
    }
    
     function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        ERC20 erc20 = ERC20(token);
        erc20.transfer(to,val);
    }
    
     function tokenFallback(address _from, uint _value, bytes memory  _data) pure public {
       
    }

}