 

pragma solidity ^0.4.11;


 
library SafeMath {

    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);

    function transferFrom(address from, address to, uint256 value);

    function approve(address spender, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;
    mapping (address => bool) public onChain;
    address[] public ownersOfToken;


    function ownersLen() constant returns (uint256) { return ownersOfToken.length; }
    function ownerAddress(uint256 number) constant returns (address) { return ownersOfToken[number]; }

     
    function transfer(address _to, uint256 _value) {

        require(balances[msg.sender] >= _value);
         
        require(balances[_to] + _value >= balances[_to]);
         

        if (!onChain[_to]){
            ownersOfToken.push(_to);
            onChain[_to] = true;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function burn(uint256 _value) {

        require(balances[msg.sender] >= _value);
         

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }


     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    address[] public ownersOfToken;


     
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

         
         
        if (!onChain[_to]){
            ownersOfToken.push(_to);
        }
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) {

         
         
         
         
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract Ownable {

    address public owner;
    address public manager;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }



    function setManager(address _manager) onlyOwner {
        manager = _manager;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool exchangeable;

    string public name = "LHCoin";

    string public symbol = "LHC";

    uint256 public decimals = 8;

    uint256 public decimalMultiplier = 100000000;

    bool public mintingFinished = false;

    address bountyCoin;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function MintableToken(){
        mint(msg.sender, 72000000 * decimalMultiplier);
        finishMinting();
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function exchangeBounty(address user, uint amount) {
        assert(msg.sender == bountyCoin);
        assert(exchangeable);
        balances[user] = amount;
        totalSupply += amount;
    }

    function setBountyCoin(address _bountyCoin) onlyAdmin {
        bountyCoin = _bountyCoin;
    }

    function setExchangeable(bool _exchangeable) onlyAdmin {
        exchangeable = _exchangeable;
    }
}


contract MintableTokenBounty is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    string public name = "LHBountyCoin";

    string public symbol = "LHBC";

    uint256 public decimals = 8;

    uint256 public decimalMultiplier = 100000000;

    bool public mintingFinished = false;

    MintableToken coin;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function MintableTokenBounty() {
        mint(msg.sender, 30000000 * decimalMultiplier);
    }

     
    function mint(address _to, uint256 _amount) onlyAdmin canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() onlyAdmin returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function setCoin(MintableToken _coin) onlyAdmin {
        coin = _coin;
    }

    function exchangeToken() {
        coin.exchangeBounty(msg.sender, balances[msg.sender]);
        totalSupply -= balances[msg.sender];
        balances[msg.sender] = 0;
    }
}