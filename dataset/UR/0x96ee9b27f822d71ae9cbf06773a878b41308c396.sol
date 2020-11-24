 

pragma solidity ^0.4.21;

contract SafeMath {
     function safeMul(uint a, uint b) internal pure returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal pure returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal pure returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}


contract Token is SafeMath {

     
     function transfer(address _to, uint256 _value) public;
     function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
     function approve(address _spender, uint256 _amount) public returns (bool success);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Crowdsale is Token {

     
    address public owner;
    string public name = "crowdsalenetworkplatform";
    string public symbol = "CSNP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 50000000 * 10 ** uint256(decimals);
    
    address internal foundersAddress;
    address internal bonusAddress;
    uint internal dayStart = now;


     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    function Crowdsale(address enterFoundersAddress, address enterBonusAddress) public {
        foundersAddress = enterFoundersAddress;
        bonusAddress = enterBonusAddress;
        balanceOf[foundersAddress] = 12500000 * 10 ** uint256(decimals);
        balanceOf[bonusAddress] = 18750000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply - (12500000 * 10 ** uint256(decimals)) - (18750000 * 10 ** uint256(decimals));                
        owner = msg.sender;

    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[_from] = safeSub(balanceOf[_from],_value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);

    }

     
    function transfer(address _to, uint256 _value) public  {
        if(now < (dayStart + 365 days)){
            require(msg.sender != foundersAddress && tx.origin != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(msg.sender != bonusAddress && tx.origin != bonusAddress);
        }
        

        _transfer(msg.sender, _to, _value);
    }




    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);      
        
        if(now < (dayStart + 365 days)){
            require(_from != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(_from != bonusAddress);
        }

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    
     
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        require((_amount == 0) || (allowance[msg.sender][_spender] == 0));
        
        if(now < (dayStart + 365 days)){
            require(msg.sender != foundersAddress && tx.origin != foundersAddress);
        }
        
        if(now < (dayStart + 180 days)){
            require(msg.sender != bonusAddress && tx.origin != bonusAddress);
        }
        
        
        allowance[msg.sender][_spender] = _amount;
        return true;
    }
    
        
     

}