 

pragma solidity ^0.4.17;

 
 
 
 
 
 

contract ERC20Interface {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract Kryptor is ERC20Interface {
    uint public constant decimals = 10;

    string public constant symbol = "Kryptor";
    string public constant name = "Kryptor";

    uint private constant icoSupplyRatio = 30;   
    uint private constant bonusRatio = 20;    
    uint private constant bonusBound = 10;   
    uint private constant initialPrice = 5000;  

    bool public _selling = true;
    uint public _totalSupply = 10 ** 19;  
    uint public _originalBuyPrice = (10 ** 18) / (initialPrice * 10**decimals);  

     
    address public owner;
 
     
    mapping(address => uint256) balances;
    
     
     
    uint public _icoSupply = (_totalSupply * icoSupplyRatio) / 100;
    
     
    uint public bonusRemain = (_totalSupply * bonusBound) / 100; 
    
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

     
    modifier onlyNotOwner() {
        if (msg.sender == owner) {
            revert();
        }
        _;
    }

     
    modifier onSale() {
        if (!_selling || (_icoSupply <= 0) ) { 
            revert();
        }
        _;
    }

     
    modifier validOriginalBuyPrice() {
        if(_originalBuyPrice <= 0) {
            revert();
        }
        _;
    }

     
    function()
        public
        payable
    {
        buy();
    }

     
    function Kryptor() 
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
    
     
     
    function totalSupply()
        public 
        constant 
        returns (uint256) {
        return _totalSupply;
    }
 
     
     
     
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
        return balances[_addr];
    }
 
     
     
     
     
    function transfer(address _to, uint256 _amount)
        public 
        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount > 0) && 
             (balances[_to] + _amount > balances[_to]) ) {  

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            
            return true;

        } else {
            return false;
        }
    }

     
    function turnOnSale() onlyOwner 
        public {
        _selling = true;
    }

     
    function turnOffSale() onlyOwner 
        public {
        _selling = false;
    }

     
    function isSellingNow() 
        public 
        constant
        returns (bool) {
        return _selling;
    }

     
     
    function setBuyPrice(uint newBuyPrice) onlyOwner 
        public {
        _originalBuyPrice = newBuyPrice;
    }
    
      
     
     
    function buy() payable onlyNotOwner validOriginalBuyPrice onSale 
        public
        returns (uint256 amount) {
         
        uint requestedUnits = msg.value / _originalBuyPrice ;
        
         
        if(requestedUnits > _icoSupply){
            revert();
        }
        
         
        uint actualSoldUnits = 0;

         
        if (requestedUnits < bonusRemain) {
             
            actualSoldUnits = requestedUnits + ((requestedUnits*bonusRatio) / 100); 
             
            _icoSupply -= requestedUnits;
            
             
            bonusRemain -= requestedUnits;
        }
        else {
             
            actualSoldUnits = requestedUnits + (bonusRemain * bonusRatio) / 100;
            
             
            _icoSupply -= requestedUnits;

             
            bonusRemain = 0;
        }

         
        balances[owner] -= actualSoldUnits;
        balances[msg.sender] += actualSoldUnits;

         
        owner.transfer(msg.value);
        
         
        Transfer(owner, msg.sender, actualSoldUnits);

        return actualSoldUnits;
    }
    
     
    function withdraw() onlyOwner 
        public 
        returns (bool) {
        return owner.send(this.balance);
    }
}