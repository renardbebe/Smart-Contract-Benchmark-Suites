 

pragma solidity ^0.4.21;

 
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


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
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
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract StandardToken is ERC20, BurnableToken {

    mapping (address => mapping (address => uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}

contract ASGToken is StandardToken {

    string constant public name = "ASGARD";
    string constant public symbol = "ASG";
    uint256 constant public decimals = 18;

    address constant public marketingWallet = 0x341570A97E15DbA3D92dcc889Fff1bbd6709D20a;
    uint256 public marketingPart = uint256(2100000000).mul(10 ** decimals);  

    address constant public airdropWallet = 0xCB3D939804C97441C58D9AC6566A412768a7433B;
    uint256 public airdropPart = uint256(1750000000).mul(10 ** decimals);  

    address constant public bountyICOWallet = 0x5570EE8D93e730D8867A113ae45fB348BFc2e138;
    uint256 public bountyICOPart = uint256(375000000).mul(10 ** decimals);  

    address constant public bountyECOWallet = 0x89d90bA8135C77cDE1C3297076C5e1209806f048;
    uint256 public bountyECOPart = uint256(375000000).mul(10 ** decimals);  

    address constant public foundersWallet = 0xE03d060ac22fdC21fDF42eB72Eb4d8BA2444b1B0;
    uint256 public foundersPart = uint256(2500000000).mul(10 ** decimals);  

    address constant public cryptoExchangeWallet = 0x5E74DcA28cE21Bf066FC9eb7D10946316528d4d6;
    uint256 public cryptoExchangePart = uint256(400000000).mul(10 ** decimals);  

    address constant public ICOWallet = 0xCe2d50c646e83Ae17B7BFF3aE7611EDF0a75E03d;
    uint256 public ICOPart = uint256(10000000000).mul(10 ** decimals);  

    address constant public PreICOWallet = 0x83D921224c8B3E4c60E286B98Fd602CBa5d7B1AB;
    uint256 public PreICOPart = uint256(7500000000).mul(10 ** decimals);  

    uint256 public INITIAL_SUPPLY = uint256(25000000000).mul(10 ** decimals);  

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[marketingWallet] = marketingPart;
        emit Transfer(this, marketingWallet, marketingPart);  

        balances[airdropWallet] = airdropPart;
        emit Transfer(this, airdropWallet, airdropPart);  

        balances[bountyICOWallet] = bountyICOPart;
        emit Transfer(this, bountyICOWallet, bountyICOPart);  

        balances[bountyECOWallet] = bountyECOPart;
        emit Transfer(this, bountyECOWallet, bountyECOPart);  

        balances[foundersWallet] = foundersPart;
        emit Transfer(this, foundersWallet, foundersPart);  

        balances[cryptoExchangeWallet] = cryptoExchangePart;
        emit Transfer(this, cryptoExchangeWallet, cryptoExchangePart);  

        balances[ICOWallet] = ICOPart;
        emit Transfer(this, ICOWallet, ICOPart);  

        balances[PreICOWallet] = PreICOPart;
        emit Transfer(this, PreICOWallet, PreICOPart);  
    }

}

contract ASGPresale is Pausable {
    using SafeMath for uint256;

    ASGToken public tokenReward;
    uint256 constant public decimals = 1000000000000000000;  

    uint256 public minimalPriceUSD = 5350;  
    uint256 public ETHUSD = 390;  
    uint256 public tokenPricePerUSD = 1666;  
    uint256 public bonus = 0;
    uint256 public tokensRaised;

    constructor(address _tokenReward) public {
        tokenReward = ASGToken(_tokenReward);
    }

    function () public payable {
        buy(msg.sender);
    }

    function buy(address buyer) whenNotPaused public payable {
        require(buyer != address(0));
        require(msg.value.mul(ETHUSD) >= minimalPriceUSD.mul(decimals).div(100));

        uint256 tokens = msg.value.mul(ETHUSD).mul(bonus.add(100)).div(100).mul(10000).div(tokenPricePerUSD);
        tokenReward.transfer(buyer, tokens);
        tokensRaised = tokensRaised.add(tokens);
    }

    function tokenTransfer(address who, uint256 amount) onlyOwner public {
        uint256 tokens = amount.mul(decimals);
        tokenReward.transfer(who, tokens);
        tokensRaised = tokensRaised.add(tokens);
    }

    function updateMinimal(uint256 _minimalPriceUSD) onlyOwner public {
        minimalPriceUSD = _minimalPriceUSD;
    }

    function updatePriceETHUSD(uint256 _ETHUSD) onlyOwner public {
        ETHUSD = _ETHUSD;
    }

    function updatePriceASGUSD(uint256 _tokenPricePerUSD) onlyOwner public {
        tokenPricePerUSD = _tokenPricePerUSD;
    }

    function updateBonus(uint256 _bonus) onlyOwner public {
        require(bonus <= 50);
        bonus = _bonus;
    }

    function finishPresale() onlyOwner public {
        owner.transfer(address(this).balance);
        uint256 tokenBalance = tokenReward.balanceOf(address(this));
        tokenReward.transfer(owner, tokenBalance);
    }

}