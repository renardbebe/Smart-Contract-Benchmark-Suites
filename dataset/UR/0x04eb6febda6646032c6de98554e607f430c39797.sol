 

pragma solidity ^0.4.20;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}


contract MintableToken is StandardToken, Ownable, Pausable {
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    uint256 public constant maxTokensToMint = 1500000000 ether;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

     
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(totalSupply_.add(_amount) <= maxTokensToMint);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
}


contract Well is MintableToken {

    string public constant name = "Token Well";

    string public constant symbol = "WELL";

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    uint256 public rate = 9000;

    uint256 public constant hardCap = 30000 ether;

    uint256 public weiFounded = 0;

    uint256 public icoTokensCount = 0;

    address public approvedUser = 0x1ca815aBdD308cAf6478d5e80bfc11A6556CE0Ed;

    address public wallet = 0x1ca815aBdD308cAf6478d5e80bfc11A6556CE0Ed;


    bool public icoFinished = false;

    uint256 public constant maxTokenToBuy = 600000000 ether;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);


     
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this));
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
    modifier canTransfer() {
        require(transferEnabled);
        _;
    }

    modifier onlyOwnerOrApproved() {
        require(msg.sender == owner || msg.sender == approvedUser);
        _;
    }

     
    function enableTransfer() onlyOwner returns (bool) {
        transferEnabled = true;
        return true;
    }

    function finishIco() onlyOwner returns (bool) {
        icoFinished = true;
        icoTokensCount = totalSupply_;
        return true;
    }

    modifier canBuyTokens() {
        require(!icoFinished && weiFounded.add(msg.value) <= hardCap);
        _;
    }

    function setApprovedUser(address _user) onlyOwner returns (bool) {
        require(_user != address(0));
        approvedUser = _user;
        return true;
    }


    function changeRate(uint256 _rate) onlyOwnerOrApproved returns (bool) {
        require(_rate > 0);
        rate = _rate;
        return true;
    }

    function() payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) canBuyTokens whenNotPaused payable {
        require(msg.value != 0);
        require(beneficiary != 0x0);

        uint256 weiAmount = msg.value;
        uint256 bonus = 0;

        bonus = getBonusByDate();

        uint256 tokens = weiAmount.mul(rate);


        if (bonus > 0) {
            tokens += tokens.mul(bonus).div(100);
             
        }

        require(totalSupply_.add(tokens) <= maxTokenToBuy);

        require(mintInternal(beneficiary, tokens));
        weiFounded = weiFounded.add(weiAmount);
        TokenPurchase(msg.sender, beneficiary, tokens);
        forwardFunds();
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }


    function changeWallet(address _newWallet) onlyOwner returns (bool) {
        require(_newWallet != 0x0);
        wallet = _newWallet;
        return true;
    }

    function getBonusByDate() view returns (uint256){
        if (block.timestamp < 1514764800) return 0;
        if (block.timestamp < 1521158400) return 40;
        if (block.timestamp < 1523836800) return 30;
        if (block.timestamp < 1523923200) return 25;
        if (block.timestamp < 1524441600) return 20;
        if (block.timestamp < 1525046400) return 10;
        if (block.timestamp < 1525651200) return 5;
        return 0;
    }

}