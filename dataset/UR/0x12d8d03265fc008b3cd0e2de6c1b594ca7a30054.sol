 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }


     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract MotherFuckingToken is StandardToken {

    string public constant name = "MotherFucking Token";
    string public constant symbol = "MFT";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 100 * 10**7 * (10**uint256(decimals));
    uint256 public weiRaised;
    uint256 public tokenAllocated;
    address public owner;
    bool public saleToken = true;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function MotherFuckingToken() public {
        totalSupply = INITIAL_SUPPLY;
        owner = msg.sender;
         
        balances[owner] = INITIAL_SUPPLY;
        tokenAllocated = 0;
        transfersEnabled = true;
    }

     
    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        require(saleToken == true);
        address wallet = owner;
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        TokenPurchase(_investor, weiAmount, tokens);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (addTokens > balances[owner]) {
            TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        return addTokens;
    }

     
    function getTotalAmountOfTokens(uint256 _weiAmount) internal pure returns (uint256) {
        uint256 amountOfTokens = 0;
        if(_weiAmount == 0){
            amountOfTokens = 0 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.001 ether){
            amountOfTokens = 300 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.002 ether){
            amountOfTokens = 600 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.003 ether){
            amountOfTokens = 900 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.004 ether){
            amountOfTokens = 1200 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.005 ether){
            amountOfTokens = 1500 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.006 ether){
            amountOfTokens = 1800 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.007 ether){
            amountOfTokens = 2100 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.008 ether){
            amountOfTokens = 2400 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.009 ether){
            amountOfTokens = 2700 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.01 ether){
            amountOfTokens = 3000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.02 ether){
            amountOfTokens = 6000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.03 ether){
            amountOfTokens = 9000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.04 ether){
            amountOfTokens = 12000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.05 ether){
            amountOfTokens = 15000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.06 ether){
            amountOfTokens = 18000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.07 ether){
            amountOfTokens = 21000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.08 ether){
            amountOfTokens = 24000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.09 ether){
            amountOfTokens = 27000 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.1 ether){
            amountOfTokens = 30 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.2 ether){
            amountOfTokens = 60 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.3 ether){
            amountOfTokens = 90 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.4 ether){
            amountOfTokens = 120 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.5 ether){
            amountOfTokens = 225 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.6 ether){
            amountOfTokens = 180 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.7 ether){
            amountOfTokens = 210 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.8 ether){
            amountOfTokens = 240 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 0.9 ether){
            amountOfTokens = 270 * 10**3 * (10**uint256(decimals));
        }
        if( _weiAmount == 1 ether){
            amountOfTokens = 600 * 10**3 * (10**uint256(decimals));
        }
        return amountOfTokens;
    }


    function mint(address _to, uint256 _amount, address _owner) internal returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[_owner]);

        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        Transfer(_owner, _to, _amount);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner public returns (bool){
        require(_newOwner != address(0));
        OwnerChanged(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    function startSale() public onlyOwner {
        saleToken = true;
    }

    function stopSale() public onlyOwner {
        saleToken = false;
    }

    function enableTransfers(bool _transfersEnabled) onlyOwner public {
        transfersEnabled = _transfersEnabled;
    }

     
    function claimTokens() public onlyOwner {
        owner.transfer(this.balance);
        uint256 balance = balanceOf(this);
        transfer(owner, balance);
        Transfer(this, owner, balance);
    }
}