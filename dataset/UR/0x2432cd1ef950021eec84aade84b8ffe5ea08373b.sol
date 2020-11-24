 

 

pragma solidity ^0.4.24;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint256 value, uint256 fee);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract TestingCoin is StandardToken, Owned {
    string public constant name = "TestingCoin";
    string public constant symbol = "TeC";
    uint8 public constant decimals = 18;
    uint256 public sellPrice = 0;  
    uint256 public buyPrice = 0;  
    mapping (address => bool) private SubFounders;       
    mapping (address => bool) private TeamAdviserPartner;

    constructor() public {
        totalSupply = 15000000;
        balances[msg.sender] = totalSupply;
    }
    
     
    function () public payable {
    }

     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        require(now > 1543536000);  
        uint amount = msg.value.div(buyPrice);        
        _transfer(owner, msg.sender, amount);    
    }

     
    function sell(uint256 amount) public {
        require(now > 1543536000);  
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        uint256 requiredBalance = amount.mul(sellPrice);
        require(address(this).balance >= requiredBalance);   
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        emit Transfer(msg.sender, owner, amount); 
        msg.sender.transfer(requiredBalance);     
    }

    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

     
    function transferBalanceToOwner(uint256 _value) public onlyOwner {
        require(_value <= address(this).balance);
        owner.transfer(_value);
    }
    
     
    function transferTokens(address _to, uint256 _tokens) lockTokenTransferBeforeStage4 public {
        _transfer(msg.sender, _to, _tokens);
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) lockTokenTransferBeforeStage4 public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    modifier lockTokenTransferBeforeStage4{
        if(msg.sender != owner){
           require(now > 1533513600);  
        }
        _;
    }

}