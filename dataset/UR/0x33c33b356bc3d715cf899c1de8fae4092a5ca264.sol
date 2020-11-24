 

pragma solidity ^0.4.25;

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

contract AltcoinToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract ICOcontract is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    address _tokenContract = 0x0a450affd2172dbfbe1b8729398fadb1c9d3dce7;
    AltcoinToken cddtoken = AltcoinToken(_tokenContract);

    uint256 public tokensPerEth = 86000e4;
    uint256 public bonus = 0;   
    uint256 public constant minContribution = 1 ether / 1000;  
    uint256 public constant extraBonus = 1 ether / 10;  

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Distr(address indexed to, uint256 amount);

    event TokensPerEthUpdated(uint _tokensPerEth);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function ICOcontract () public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
        sendTokens();
    }
     
    function sendTokens() private returns (bool) {
        uint256 tokens = 0;

        require( msg.value >= minContribution );

        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;
        bonus = 0;

        if ( msg.value >= extraBonus ) {
            bonus = tokens / 2;
        }

        tokens = tokens + bonus;
        
        sendtokens(cddtoken, tokens, investor);
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        AltcoinToken t = AltcoinToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawAltcoinTokens(address anycontract) onlyOwner public returns (bool) {
        AltcoinToken anytoken = AltcoinToken(anycontract);
        uint256 amount = anytoken.balanceOf(address(this));
        return anytoken.transfer(owner, amount);
    }
    
    function sendtokens(address contrato, uint256 amount, address who) private returns (bool) {
        AltcoinToken alttoken = AltcoinToken(contrato);
        return alttoken.transfer(who, amount);
    }
}