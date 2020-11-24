 

pragma solidity ^0.4.11;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

 
contract ERC20 {
    uint256 public tokenTotalSupply;

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint256);

    function transfer(address to, uint256 value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address from, address to, uint256 value) returns (bool success);

    function approve(address spender, uint256 value) returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() constant returns (uint256 availableSupply);
}

 
contract BioToken is ERC20, Ownable {
    using SafeMath for uint;

    string public name = "BIONT Token";
    string public symbol = "BIONT";
    uint public decimals = 18;

    bool public tradingStarted = false;
    bool public mintingFinished = false;
    bool public salePaused = false;

    uint256 public tokenTotalSupply = 0;
    uint256 public trashedTokens = 0;
    uint256 public hardcap = 140000000 * (10 ** decimals);  
    uint256 public ownerTokens = 14000000 * (10 ** decimals);  

    uint public ethToToken = 300;  
    uint public noContributors = 0;

    uint public start = 1503346080;  
    uint public initialSaleEndDate = start + 9 weeks;
    uint public ownerGrace = initialSaleEndDate + 182 days;
    uint public fiveYearGrace = initialSaleEndDate + 5 * 365 days;

    address public multisigVault;
    address public lockedVault;
    address public ownerVault;

    address public authorizerOne;
    address public authorizerTwo;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) authorizedWithdrawal;

    event Mint(address indexed to, uint256 value);
    event MintFinished();
    event TokenSold(address recipient, uint256 ether_amount, uint256 pay_amount, uint256 exchangerate);
    event MainSaleClosed();

     
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
            revert();
        }
        _;
    }

    modifier canMint() {
        if (mintingFinished) {
            revert();
        }

        _;
    }

     
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

     
    modifier saleIsOn() {
        require(now > start && now < initialSaleEndDate && salePaused == false);
        _;
    }

     
    modifier isUnderHardCap() {
        require(tokenTotalSupply <= hardcap);
        _;
    }

    function BioToken(address _ownerVault, address _authorizerOne, address _authorizerTwo, address _lockedVault, address _multisigVault) {
        ownerVault = _ownerVault;
        authorizerOne = _authorizerOne;
        authorizerTwo = _authorizerTwo;
        lockedVault = _lockedVault;
        multisigVault = _multisigVault;

        mint(ownerVault, ownerTokens);
    }

     
    function mint(address _to, uint256 _amount) private canMint returns(bool) {
        tokenTotalSupply = tokenTotalSupply.add(_amount);

        require(tokenTotalSupply <= hardcap);

        balances[_to] = balances[_to].add(_amount);
        noContributors = noContributors.add(1);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }

     
    function masterMint(address _to, uint256 _amount) public canMint onlyOwner returns(bool) {
        tokenTotalSupply = tokenTotalSupply.add(_amount);

        require(tokenTotalSupply <= hardcap);

        balances[_to] = balances[_to].add(_amount);
        noContributors = noContributors.add(1);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }

     
    function finishMinting() private onlyOwner returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) hasStartedTrading returns (bool success) {
         
        if (msg.sender == lockedVault && now < fiveYearGrace) {
            revert();
        }

         
        if (msg.sender == ownerVault && now < ownerGrace) {
            revert();
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) hasStartedTrading returns (bool success) {
        if (_from == lockedVault && now < fiveYearGrace) {
            revert();
        }

         
        if (_from == ownerVault && now < ownerGrace) {
            revert();
        }

        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

     
    function masterTransferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public hasStartedTrading onlyOwner returns (bool success) {
        if (_from == lockedVault && now < fiveYearGrace) {
            revert();
        }

         
        if (_from == ownerVault && now < ownerGrace) {
            revert();
        }

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    function totalSupply() constant returns (uint256 availableSupply) {
        return tokenTotalSupply;
    }

     
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

     
    function pauseSale() onlyOwner {
        salePaused = true;
    }

     
    function resumeSale() onlyOwner {
        salePaused = false;
    }

     
    function getNoContributors() constant returns(uint contributors) {
        return noContributors;
    }

     
    function setMultisigVault(address _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

    function setAuthorizedWithdrawalAmount(uint256 _amount) public {
        if (_amount < 0) {
            revert();
        }

        if (msg.sender != authorizerOne && msg.sender != authorizerTwo) {
            revert();
        }

        authorizedWithdrawal[msg.sender] = _amount;
    }

     
    function withdrawEthereum(uint256 _amount) public onlyOwner {
        require(multisigVault != address(0));
        require(_amount <= this.balance);  

        if (authorizedWithdrawal[authorizerOne] != authorizedWithdrawal[authorizerTwo]) {
            revert();
        }

        if (_amount > authorizedWithdrawal[authorizerOne]) {
            revert();
        }

        if (!multisigVault.send(_amount)) {
            revert();
        }

        authorizedWithdrawal[authorizerOne] = authorizedWithdrawal[authorizerOne].sub(_amount);
        authorizedWithdrawal[authorizerTwo] = authorizedWithdrawal[authorizerTwo].sub(_amount);
    }

    function showAuthorizerOneAmount() constant public returns(uint256 remaining) {
        return authorizedWithdrawal[authorizerOne];
    }

    function showAuthorizerTwoAmount() constant public returns(uint256 remaining) {
        return authorizedWithdrawal[authorizerTwo];
    }

    function showEthBalance() constant public returns(uint256 remaining) {
        return this.balance;
    }

    function retrieveTokens() public onlyOwner {
        require(lockedVault != address(0));

        uint256 capOut = hardcap.sub(tokenTotalSupply);
        tokenTotalSupply = hardcap;

        balances[lockedVault] = balances[lockedVault].add(capOut);
        Transfer(this, lockedVault, capOut);
    }

    function trashTokens(address _from, uint256 _amount) onlyOwner returns(bool) {
        balances[_from] = balances[_from].sub(_amount);
        trashedTokens = trashedTokens.add(_amount);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);
    }

    function decreaseSupply(uint256 value, address from) onlyOwner returns (bool) {
      balances[from] = balances[from].sub(value);
      trashedTokens = trashedTokens.add(value);
      tokenTotalSupply = tokenTotalSupply.sub(value);
      Transfer(from, 0, value);
      return true;
    }

    function finishSale() public onlyOwner {
        finishMinting();
        retrieveTokens();
        startTrading();

        MainSaleClosed();
    }

    function saleOn() constant returns(bool) {
        return (now > start && now < initialSaleEndDate && salePaused == false);
    }

     
    function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
        uint bonus = 0;
        uint period = 1 weeks;
        uint256 tokens;

        if (now <= start + 2 * period) {
            bonus = 20;
        } else if (now > start + 2 * period && now <= start + 3 * period) {
            bonus = 15;
        } else if (now > start + 3 * period && now <= start + 4 * period) {
            bonus = 10;
        } else if (now > start + 4 * period && now <= start + 5 * period) {
            bonus = 5;
        }

         
        if (bonus > 0) {
            tokens = ethToToken.mul(msg.value) + ethToToken.mul(msg.value).mul(bonus).div(100);
        } else {
            tokens = ethToToken.mul(msg.value);
        }

        if (tokens <= 0) {
            revert();
        }

        mint(recipient, tokens);

        TokenSold(recipient, msg.value, tokens, ethToToken);
    }

    function() external payable {
        createTokens(msg.sender);
    }
}