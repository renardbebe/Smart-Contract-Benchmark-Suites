 

pragma solidity ^0.4.16;


 
contract Ownable {
    address public owner;


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

 
contract Authorizable {

    address[] public authorizers;
    mapping(address => uint) authorizerIndex;

     
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

     
    function Authorizable() public {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

     
    function isAuthorized(address _addr) public view returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

     
    function addAuthorized(address _addr) external onlyAuthorized {
        authorizerIndex[_addr] = authorizers.length;
        authorizers.length++;
        authorizers[authorizers.length - 1] = _addr;
    }
}

 
contract Investors is Authorizable {

    address[] public investors;
    mapping(address => uint) investorIndex;

     
    function Investors() public {
        investors.length = 2;
        investors[1] = msg.sender;
        investorIndex[msg.sender] = 1;
    }

     
    function addInvestor(address _inv) public {
        if (investorIndex[_inv] <= 0) {
            investorIndex[_inv] = investors.length;
            investors.length++;
            investors[investors.length - 1] = _inv;
        }

    }
}

 
contract ExchangeRate is Ownable {

    event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

    mapping(bytes32 => uint) public rates;

     
    function updateRate(string _symbol, uint _rate) public onlyOwner {
        rates[keccak256(_symbol)] = _rate;
        RateUpdated(now, keccak256(_symbol), _rate);
    }

     
    function updateRates(uint[] data) public onlyOwner {
        if (data.length % 2 > 0)
        revert();
        uint i = 0;
        while (i < data.length / 2) {
            bytes32 symbol = bytes32(data[i * 2]);
            uint rate = data[i * 2 + 1];
            rates[symbol] = rate;
            RateUpdated(now, symbol, rate);
            i++;
        }
    }

     
    function getRate(string _symbol) public view returns(uint) {
        return rates[keccak256(_symbol)];
    }
}

 
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal view returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal view returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal view returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal view returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value)  public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            revert();
        }
        _;
    }

     
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) view returns (uint balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


     
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();
    event MintRestarted();

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        if(mintingFinished) revert();
        _;
    }

     
    function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
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

     
    function restartMinting() onlyOwner returns (bool) {
        mintingFinished = false;
        MintRestarted();
        return true;
    }
}


 
contract InvestyToken is MintableToken {

    string public name = "Investy Coin";
    string public symbol = "IVC66";
    uint public decimals = 18;

    bool public tradingStarted = false;

     
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

     
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) hasStartedTrading {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
        super.transferFrom(_from, _to, _value);
    }

}

 
contract InvestyPresale is Ownable, Authorizable, Investors {
    using SafeMath for uint;
    event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
    event AuthorizedCreate(address recipient, uint pay_amount);
    event PresaleFinished();
    event PresaleReStarted();

    InvestyToken public token = new InvestyToken();

    address public multisigVault;
    uint constant MILLI_USD_TO_IVC_RATE = 34; 

    ExchangeRate public exchangeRate;

    bool public presaleActive = true;
    modifier isPresaleActive() {
        if(!presaleActive) revert();
        _;
    }

     
    function InvestyPresale() {
    }

     
    function finishPresale() public onlyOwner returns (bool) {
        presaleActive = false;
        PresaleFinished();
        return true;
    }

     
    function restartPresale() public onlyOwner returns (bool) {
        presaleActive = true;
        PresaleReStarted();
        return true;
    }

     
    function createTokens(address recipient) public isPresaleActive payable {
        var einsteinToUsdRate = exchangeRate.getRate("EinsteinToUSD");
        uint ivc = (einsteinToUsdRate.mul(msg.value).div(MILLI_USD_TO_IVC_RATE)); 
        token.mint(recipient, ivc);
        addInvestor(recipient);
        require(multisigVault.send(msg.value));
        TokenSold(recipient, msg.value, ivc, einsteinToUsdRate / 1000);
    }

     
    function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
        token.mint(recipient, tokens);
        addInvestor(recipient);
        AuthorizedCreate(recipient, tokens);
    }

     
    function setExchangeRate(address _exchangeRate) public onlyOwner {
        exchangeRate = ExchangeRate(_exchangeRate);
    }

     
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 outerToken = ERC20(_token);
        token.transfer(multisigVault, outerToken.balanceOf(this));
    }

     
    function setMultisigVault(address _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

     
    function transferToken() public onlyOwner {
        token.transferOwnership(owner);
    }

     
    function() external payable {
        createTokens(msg.sender);
    }
}