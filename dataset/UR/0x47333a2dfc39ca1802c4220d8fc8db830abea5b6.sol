 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
   
}

interface ERC223 {
 
  function transfer(address to, uint256 value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public  returns (bool ok);
  
  
}


interface ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes _data) public ;
}

contract TokenERC20 {
     
    
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    string public symbol = "SATT";
    string public name = "Smart Advertisement Transaction Token";
    

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

   event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);


     
    function TokenERC20(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
                                       
    }

     
    function _transfer(address _from, address _to, uint _value,bytes _data) internal {
       
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value,_data);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

   

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         bytes memory empty;
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value,empty);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

   
    
}

 
 
 

contract SATTToken is owned, TokenERC20,ERC223 {

    uint256 public sellPrice = 0;
    uint256 public buyPrice = 1500;
    

     
  
    event Buy(address a,uint256 v);

     
    function SATTToken() TokenERC20(420000000) public {    }
    
     function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }
    
     function transfer(address to, uint256 value) public returns (bool success) {
          bytes memory empty;
        _transfer(msg.sender, to, value,empty);
        return true;
    }
    
     function transfer(address to, uint256 value,bytes data) public returns (bool success) {
        _transfer(msg.sender, to, value,data);
        return true;
    }
    
    function _transfer(address _from, address _to, uint _value,bytes _data) internal {
       
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        
        if(isContract(_to))
        {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        
        Transfer(_from, _to, _value,_data);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

   

     
     
     
    function giveToken(address target, uint256 givenAmount) onlyOwner public {
         bytes memory empty;
         balanceOf[owner] -= givenAmount;
        balanceOf[target] += givenAmount;
        Transfer(owner, target, givenAmount,empty);


    }
     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
     function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }
    

     function() public payable  {
         require(buyPrice >0);
          bytes memory empty;
         
        
        
         
        _transfer(owner, msg.sender, msg.value * buyPrice,empty);
        
        
    }

     
     
    function sell(uint256 amount) public {
        require(sellPrice >0);
         bytes memory empty;
        require(this.balance >= amount / sellPrice);       
        _transfer(msg.sender, owner, amount,empty);               
         
    }
    
    
}