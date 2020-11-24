 

pragma solidity ^0.5.0;

 
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
 
    constructor() public {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }
    
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Owner must be different");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
}


 
contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    uint256 totalCirculated_;
    uint256 buyPrice_;
    uint256 sellPrice_;
    bool locked_;
    
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(locked_ == false || msg.sender == owner, "Transafers are currently locked");
        require(_to != address(0), "Must set an address to receive the tokens");
        require(_value <= balances[msg.sender], "Not enough funds");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(msg.sender == owner) {
            totalCirculated_ = totalCirculated_.add(_value);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}


contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(locked_ == false || msg.sender == owner, "Transfers are currently locked");
        require(_to != address(0), "Must set an address to send the token");
        require(_value <= balances[_from], "Not enough funds");
        require(_value <= allowed[_from][msg.sender], "Amount exceeds your limit");
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        if(msg.sender == owner) {
            totalCirculated_ = totalCirculated_.add(_value);
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[owner] >= _value, "Cannot burn more than we have");    
        balances[owner] = balances[owner].sub(_value);             
        totalSupply_ = totalSupply_.sub(_value);                        
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[_from] >= _value, "Cannot burn more than we have");         
        require(_value <= allowed[_from][msg.sender], "No allowance for this");     
        balances[_from] = balances[_from].sub(_value);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        totalSupply_ = totalSupply_.sub(_value);                               

        totalCirculated_ = totalCirculated_.add(_value);

        emit Burn(_from, _value);
        return true;
    }

}



 
contract LamboToken is StandardToken {
    string public constant name = "Lambo Token";
    string public constant symbol = "LBT";
    uint32 public constant decimals = 4;
    string public constant version = "1.2";

    constructor() public {
        totalSupply_ = 100000000000000;
        balances[owner] = totalSupply_;
        buyPrice_ = 0;
        sellPrice_ = 0;
        locked_ = true;
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balances[target] = balances[target].add(mintedAmount);
        totalSupply_ = totalSupply_.add(mintedAmount);
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }
    
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice_ = newSellPrice;
        buyPrice_ = newBuyPrice;
    }
    
     
    function getPrices() public view returns(uint256, uint256) {
        return (sellPrice_, buyPrice_);
    }

     
    function buy() public payable  {
        require(buyPrice_ > 0, "Token not available");    
        uint amount = msg.value.div(buyPrice_);           
        transferFrom(owner, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) public {
        require(balances[msg.sender] >= amount, "You don't have enough tokens");
        require(owner.balance > amount.mul(sellPrice_), "The contract does not have enough ether to buy your tokens");
        transferFrom(msg.sender, owner, amount);               
        msg.sender.transfer(amount.mul(sellPrice_));     
    }
    
    
    function totalCirculated() public view returns (uint256 circlulated) {
        circlulated = totalCirculated_;
    }
    
    function totalAvailable() public view returns (uint256 available) {
        available = balances[owner].sub(totalCirculated_);
    }
    
    function unlock() public onlyOwner {
        require(locked_ == true, "Transafers are currently locked");
        locked_ = false;        
    }

}