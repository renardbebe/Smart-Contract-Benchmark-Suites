 

pragma solidity ^0.4.23;


 
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function isOwner() internal view returns(bool success) {
        if (msg.sender == owner) return true;
        return false;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].safeAdd(_value);
        balances[_from] = balances[_from].safeSub(_value);
        allowed[_from][msg.sender] = _allowance.safeSub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].safeAdd(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.safeSub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract ENTA is StandardToken,Owned {

    string public name = "ENTA";
    string public symbol = "ENTA";
    uint256 public decimals = 8;
    uint256 public INITIAL_SUPPLY = 2000000000 * (10 ** decimals);  
    uint256 public publicSell = 1530374400; 

    bool public allowTransfers = true;  
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed target, bool frozen);
    event MinedBalancesUnlocked(address indexed target, uint256 amount);

    struct MinedBalance {
        uint256 total;
        uint256 left;
    }

    mapping(address => MinedBalance) minedBalances;

    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transferMined(address to, uint256 tokens) public onlyOwner returns (bool success) {
        balances[msg.sender] = balances[msg.sender].safeSub(tokens);
        minedBalances[to].total = minedBalances[to].total.safeAdd(tokens);
        minedBalances[to].left = minedBalances[to].left.safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[msg.sender]);                                         
            require(!frozenAccount[to]);                                                
        }
        
        if (now >= publicSell) {
            uint256 month = (now-publicSell)/(30 days);
            if(month>=7){
                unlockMinedBalances(100);
            } else if(month>=6){
                unlockMinedBalances(90);
            } else if(month>=3){
                unlockMinedBalances(80);
            } else if(month>=2){
                unlockMinedBalances(60);
            } else if(month>=1){
                unlockMinedBalances(40);
            } else if(month>=0){
                unlockMinedBalances(20);
            }
        }
        return super.transfer(to,tokens);
    }

    function unlockMinedBalances(uint256 unlockPercent) internal {
        uint256 lockedMinedTokens = minedBalances[msg.sender].total*(100-unlockPercent)/100;
        if(minedBalances[msg.sender].left > lockedMinedTokens){
            uint256 unlock = minedBalances[msg.sender].left.safeSub(lockedMinedTokens);
            minedBalances[msg.sender].left = lockedMinedTokens;
            balances[msg.sender] = balances[msg.sender].safeAdd(unlock);
            emit MinedBalancesUnlocked(msg.sender,unlock);
        }
    }

    function setAllowTransfers(bool _allowTransfers) onlyOwner public {
        allowTransfers = _allowTransfers;
    }

    function destroyToken(address target, uint256 amount) onlyOwner public {
        balances[target] = balances[target].safeSub(amount);
        totalSupply = totalSupply.safeSub(amount);
        emit Transfer(target, this, amount);
        emit Transfer(this, 0, amount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[_from]);                                           
            require(!frozenAccount[_to]);                                             
        }
        return super.transferFrom(_from, _to, _value);
    }
    
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner].safeAdd(minedBalances[tokenOwner].left);
    }
}