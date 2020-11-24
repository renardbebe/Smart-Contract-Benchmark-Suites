 

pragma solidity ^0.4.20;

 
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

 
contract AdviserTimeLock is Ownable{

    SignalsToken token;
    uint256 withdrawn;
    uint start;

    event TokensWithdrawn(address owner, uint amount);

     
    function AdviserTimeLock(address _token, address _owner) public{
        token = SignalsToken(_token);
        owner = _owner;
        start = now;
    }

     
    function withdraw() onlyOwner public {
        require(now - start >= 25920000);
        uint toWithdraw = canWithdraw();
        token.transfer(owner, toWithdraw);
        withdrawn += toWithdraw;
        TokensWithdrawn(owner, toWithdraw);
    }

     
    function canWithdraw() public view returns (uint256) {
        uint256 sinceStart = now - start;
        uint256 allowed = (sinceStart/2592000)*504546000000000;
        uint256 toWithdraw;
        if (allowed > token.balanceOf(address(this))) {
            toWithdraw = token.balanceOf(address(this));
        } else {
            toWithdraw = allowed - withdrawn;
        }
        return toWithdraw;
    }

     
    function cleanUp() onlyOwner public {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}

 
contract AdvisoryPool is Ownable{

    SignalsToken token;

     
    address constant ADVISER1 = 0x7915D5A865FE68C63112be5aD3DCA5187EB08f24;
    address constant ADVISER2 = 0x31cFF39AA68B91fa7C957272A6aA8fB8F7b69Cb0;
    address constant ADVISER3 = 0x358b3aeec9fae5ab15fe28d2fe6c7c9fda596857;
    address constant ADVISER4 = 0x1011FC646261eb5d4aB875886f1470d4919d83c8;
    address constant ADVISER5 = 0xcc04Cd98da89A9172372aEf4B62BEDecd01A7F5a;
    address constant ADVISER6 = 0xECD791f8E548D46A9711D853Ead7edC685Ca4ee8;
    address constant ADVISER7 = 0x38B58e5783fd4D077e422B3362E9d6B265484e3f;
    address constant ADVISER8 = 0x2934205135A129F995AC891C143cCae83ce175c7;
    address constant ADVISER9 = 0x9F5D00F4A383bAd14DEfA9aee53C5AF2ad9ad32F;
    address constant ADVISER10 = 0xBE993c982Fc5a0C0360CEbcEf9e4d2727339d96B;
    address constant ADVISER11 = 0xdf1E2126eB638335eFAb91a834db4c57Cbe18735;
    address constant ADVISER12 = 0x8A404969Ad1BCD3F566A7796722f535eD9cA22b2;
    address constant ADVISER13 = 0x066a8aD6fA94AC83e1AFB5Aa7Dc62eD1D2654bB2;
    address constant ADVISER14 = 0xA1425Fa987d1b724306d93084b93D62F37482c4b;
    address constant ADVISER15 = 0x4633515904eE5Bc18bEB70277455525e84a51e90;
    address constant ADVISER16 = 0x230783Afd438313033b07D39E3B9bBDBC7817759;
    address constant ADVISER17 = 0xe8b9b07c1cca9aE9739Cec3D53004523Ab206CAc;
    address constant ADVISER18 = 0x0E73f16CfE7F545C0e4bB63A9Eef18De8d7B422d;
    address constant ADVISER19 = 0x6B4c6B603ca72FE7dde971CF833a58415737826D;
    address constant ADVISER20 = 0x823D3123254a3F9f9d3759FE3Fd7d15e21a3C5d8;
    address constant ADVISER21 = 0x0E48bbc496Ae61bb790Fc400D1F1a57520f772Df;
    address constant ADVISER22 = 0x06Ee8eCc0145CcaCEc829490e3c557f577BE0e85;
    address constant ADVISER23 = 0xbE56bFF75A1cB085674Cc37a5C8746fF6C43C442;
    address constant ADVISER24 = 0xb442b5297E4aEf19E489530E69dFef7fae27F4A5;
    address constant ADVISER25 = 0x50EF1d6a7435C7FB3dB7c204b74EB719b1EE3dab;
    address constant ADVISER26 = 0x3e9fed606822D5071f8a28d2c8B51E6964160CB2;

    AdviserTimeLock public tokenLocker23;

     
    function AdvisoryPool(address _token, address _owner) public {
        owner = _owner;
        token = SignalsToken(_token);
    }

     
    function initiate() public onlyOwner {
        require(token.balanceOf(address(this)) == 18500000000000000);
        tokenLocker23 = new AdviserTimeLock(address(token), ADVISER23);

        token.transfer(ADVISER1, 380952380000000);
        token.transfer(ADVISER2, 380952380000000);
        token.transfer(ADVISER3, 659200000000000);
        token.transfer(ADVISER4, 95238100000000);
        token.transfer(ADVISER5, 1850000000000000);
        token.transfer(ADVISER6, 15384620000000);
        token.transfer(ADVISER7, 62366450000000);
        token.transfer(ADVISER8, 116805560000000);
        token.transfer(ADVISER9, 153846150000000);
        token.transfer(ADVISER10, 10683760000000);
        token.transfer(ADVISER11, 114285710000000);
        token.transfer(ADVISER12, 576923080000000);
        token.transfer(ADVISER13, 76190480000000);
        token.transfer(ADVISER14, 133547010000000);
        token.transfer(ADVISER15, 96153850000000);
        token.transfer(ADVISER16, 462500000000000);
        token.transfer(ADVISER17, 462500000000000);
        token.transfer(ADVISER18, 399865380000000);
        token.transfer(ADVISER19, 20032050000000);
        token.transfer(ADVISER20, 35559130000000);
        token.transfer(ADVISER21, 113134000000000);
        token.transfer(ADVISER22, 113134000000000);
        token.transfer(address(tokenLocker23), 5550000000000000);
        token.transfer(ADVISER23, 1850000000000000);
        token.transfer(ADVISER24, 100000000000000);
        token.transfer(ADVISER25, 100000000000000);
        token.transfer(ADVISER26, 2747253000000000);

    }

     
    function cleanUp() onlyOwner public {
        uint256 notAllocated = token.balanceOf(address(this));
        token.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}

 
contract CommunityPool is Ownable{

    SignalsToken token;

    event CommunityTokensAllocated(address indexed member, uint amount);

     
    function CommunityPool(address _token, address _owner) public{
        token = SignalsToken(_token);
        owner = _owner;
    }

     
    function allocToMember(address member, uint amount) public onlyOwner {
        require(amount > 0);
        token.transfer(member, amount);
        CommunityTokensAllocated(member, amount);
    }

     
    function clean() public onlyOwner {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}

 
contract CompanyReserve is Ownable{

    SignalsToken token;
    uint256 withdrawn;
    uint start;

     
    function CompanyReserve(address _token, address _owner) public {
        token = SignalsToken(_token);
        owner = _owner;
        start = now;
    }

    event TokensWithdrawn(address owner, uint amount);

     
    function withdraw() onlyOwner public {
        require(now - start >= 25920000);
        uint256 toWithdraw = canWithdraw();
        withdrawn += toWithdraw;
        token.transfer(owner, toWithdraw);
        TokensWithdrawn(owner, toWithdraw);
    }

     
    function canWithdraw() public view returns (uint256) {
        uint256 sinceStart = now - start;
        uint256 allowed;

        if (sinceStart >= 0) {
            allowed = 555000000000000;
        } else if (sinceStart >= 31536000) {  
            allowed = 1480000000000000;
        } else if (sinceStart >= 63072000) {  
            allowed = 3330000000000000;
        } else {
            return 0;
        }
        return allowed - withdrawn;
    }

     
    function cleanUp() onlyOwner public {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}


 
contract PresaleToken is PausableToken, MintableToken {

     
    string constant public name = "SGNPresaleToken";
    string constant public symbol = "SGN";
    uint8 constant public decimals = 9;

    event TokensBurned(address initiatior, address indexed _partner, uint256 _tokens);

     
    function PresaleToken() public {
        pause();
    }
     
    function burnTokens(address _partner, uint256 _tokens) public onlyOwner {
        require(balances[_partner] >= _tokens);

        balances[_partner] -= _tokens;
        totalSupply -= _tokens;
        TokensBurned(msg.sender, _partner, _tokens);
    }
}


 
contract SignalsToken is PausableToken, MintableToken {

     
    string constant public name = "Signals Network Token";
    string constant public symbol = "SGN";
    uint8 constant public decimals = 9;

}

contract PrivateRegister is Ownable {

    struct contribution {
        bool approved;
        uint8 extra;
    }

    mapping (address => contribution) verified;

    event ApprovedInvestor(address indexed investor);
    event BonusesRegistered(address indexed investor, uint8 extra);

     
    function approve(address _investor, uint8 _extra) onlyOwner public{
        require(!isContract(_investor));
        verified[_investor].approved = true;
        if (_extra <= 100) {
            verified[_investor].extra = _extra;
            BonusesRegistered(_investor, _extra);
        }
        ApprovedInvestor(_investor);
    }

     
    function approved(address _investor) view public returns (bool) {
        return verified[_investor].approved;
    }

     
    function getBonuses(address _investor) view public returns (uint8 extra) {
        return verified[_investor].extra;
    }

     
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

contract CrowdsaleRegister is Ownable {

    struct contribution {
        bool approved;
        uint8 commission;
        uint8 extra;
    }

    mapping (address => contribution) verified;

    event ApprovedInvestor(address indexed investor);
    event BonusesRegistered(address indexed investor, uint8 commission, uint8 extra);

     
    function approve(address _investor, uint8 _commission, uint8 _extra) onlyOwner public{
        require(!isContract(_investor));
        verified[_investor].approved = true;
        if (_commission <= 15 && _extra <= 5) {
            verified[_investor].commission = _commission;
            verified[_investor].extra = _extra;
            BonusesRegistered(_investor, _commission, _extra);
        }
        ApprovedInvestor(_investor);
    }

     
    function approved(address _investor) view public returns (bool) {
        return verified[_investor].approved;
    }

     
    function getBonuses(address _investor) view public returns (uint8 commission, uint8 extra) {
        return (verified[_investor].commission, verified[_investor].extra);
    }

     
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}


 
contract PresalePool is Ownable {

    PresaleToken public PublicPresale;
    PresaleToken public PartnerPresale;
    SignalsToken token;
    CrowdsaleRegister registry;

     
    uint256 compensation1;
    uint256 compensation2;
     
    uint256 deadLine;

    event SupporterResolved(address indexed supporter, uint256 burned, uint256 created);
    event PartnerResolved(address indexed partner, uint256 burned, uint256 created);

     
    function PresalePool(address _token, address _registry, address _owner, uint comp1, uint comp2) public {
        owner = _owner;
        PublicPresale = PresaleToken(0x15fEcCA27add3D28C55ff5b01644ae46edF15821);
        PartnerPresale = PresaleToken(0xa70435D1a3AD4149B0C13371E537a22002Ae530d);
        token = SignalsToken(_token);
        registry = CrowdsaleRegister(_registry);
        compensation1 = comp1;
        compensation2 = comp2;
        deadLine = now + 30 days;
    }

     
    function() public {
        swap();
    }

     
    function swap() public {
        require(registry.approved(msg.sender));
        uint256 oldBalance;
        uint256 newBalance;

        if (PublicPresale.balanceOf(msg.sender) > 0) {
            oldBalance = PublicPresale.balanceOf(msg.sender);
            newBalance = oldBalance * compensation1 / 100;
            PublicPresale.burnTokens(msg.sender, oldBalance);
            token.transfer(msg.sender, newBalance);
            SupporterResolved(msg.sender, oldBalance, newBalance);
        }

        if (PartnerPresale.balanceOf(msg.sender) > 0) {
            oldBalance = PartnerPresale.balanceOf(msg.sender);
            newBalance = oldBalance * compensation2 / 100;
            PartnerPresale.burnTokens(msg.sender, oldBalance);
            token.transfer(msg.sender, newBalance);
            PartnerResolved(msg.sender, oldBalance, newBalance);
        }
    }

     
    function swapFor(address whom) onlyOwner public returns(bool) {
        require(registry.approved(whom));
        uint256 oldBalance;
        uint256 newBalance;

        if (PublicPresale.balanceOf(whom) > 0) {
            oldBalance = PublicPresale.balanceOf(whom);
            newBalance = oldBalance * compensation1 / 100;
            PublicPresale.burnTokens(whom, oldBalance);
            token.transfer(whom, newBalance);
            SupporterResolved(whom, oldBalance, newBalance);
        }

        if (PartnerPresale.balanceOf(whom) > 0) {
            oldBalance = PartnerPresale.balanceOf(whom);
            newBalance = oldBalance * compensation2 / 100;
            PartnerPresale.burnTokens(whom, oldBalance);
            token.transfer(whom, newBalance);
            SupporterResolved(whom, oldBalance, newBalance);
        }

        return true;
    }

     
    function clean() onlyOwner public {
        require(now >= deadLine);
        uint256 notAllocated = token.balanceOf(address(this));
        token.transfer(owner, notAllocated);
        selfdestruct(owner);
    }
}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    SignalsToken public token;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    uint256 public startTime;
    bool public hasEnded;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(address _token, address _wallet) public {
        require(_wallet != 0x0);
        token = SignalsToken(_token);
        wallet = _wallet;
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) private {}

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {}

}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded);

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }
}


contract SignalsCrowdsale is FinalizableCrowdsale {

     
    uint256 public constant HARD_CAP = 18000*(10**18);
    uint256 public toBeRaised = 18000*(10**18);
    uint256 public constant PRICE = 360000;
    uint256 public tokensSold;
    uint256 public constant maxTokens = 185000000*(10**9);

     
    uint constant ADVISORY_SHARE = 18500000*(10**9);  
    uint constant BOUNTY_SHARE = 3700000*(10**9);  
    uint constant COMMUNITY_SHARE = 37000000*(10**9);  
    uint constant COMPANY_SHARE = 33300000*(10**9);  
    uint constant PRESALE_SHARE = 7856217611546440;  

     
    address constant ADVISORS = 0x98280b2FD517a57a0B8B01b674457Eb7C6efa842;  
    address constant BOUNTY = 0x8726D7ac344A0BaBFd16394504e1cb978c70479A;  
    address constant COMMUNITY = 0x90CDbC88aB47c432Bd47185b9B0FDA1600c22102;  
    address constant COMPANY = 0xC010b2f2364372205055a299B28ef934f090FE92;  
    address constant PRESALE = 0x7F3a38fa282B16973feDD1E227210Ec020F2481e;  
    CrowdsaleRegister register;
    PrivateRegister register2;

     
    bool public ready;

     
    event SaleWillStart(uint256 time);
    event SaleReady();
    event SaleEnds(uint256 tokensLeft);

    function SignalsCrowdsale(address _token, address _wallet, address _register, address _register2) public
    FinalizableCrowdsale()
    Crowdsale(_token, _wallet)
    {
        register = CrowdsaleRegister(_register);
        register2 = PrivateRegister(_register2);
    }


     
    function validPurchase() internal constant returns (bool) {
        bool started = (startTime <= now);
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = (weiRaised < HARD_CAP);
        bool approved = register.approved(msg.sender);
        bool approved2 = register2.approved(msg.sender);
        return ready && started && !hasEnded && nonZeroPurchase && capNotReached && (approved || approved2);
    }

     
    function buyTokens(address beneficiary) private {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 discount = ((toBeRaised*10000)/HARD_CAP)*15;

         
        uint256 tokens;

         
        weiRaised = weiRaised.add(weiAmount);
        toBeRaised = toBeRaised.sub(weiAmount);

        uint commission;
        uint extra;
        uint premium;

        if (register.approved(beneficiary)) {
            (commission, extra) = register.getBonuses(beneficiary);

             
            if (extra > 0) {
                discount += extra*10000;
            }
            tokens =  howMany(msg.value, discount);

             
            if (commission > 0) {
                premium = tokens.mul(commission).div(100);
                token.mint(BOUNTY, premium);
            }

        } else {
            extra = register2.getBonuses(beneficiary);
            if (extra > 0) {
                discount = extra*10000;
                tokens =  howMany(msg.value, discount);
            }
        }

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        tokensSold += tokens + premium;
        forwardFunds();

        assert(token.totalSupply() <= maxTokens);
    }

     
    function howMany(uint256 value, uint256 discount) public view returns (uint256){
        uint256 actualPrice = PRICE * (1000000 - discount) / 1000000;
        return value / actualPrice;
    }

     
    function initialize() public onlyOwner {
        require(!ready);

         
        token.mint(ADVISORS,ADVISORY_SHARE);
        token.mint(BOUNTY,BOUNTY_SHARE);
        token.mint(COMMUNITY,COMMUNITY_SHARE);
        token.mint(COMPANY,COMPANY_SHARE);
        token.mint(PRESALE,PRESALE_SHARE);

        tokensSold = PRESALE_SHARE;

        ready = true;
        SaleReady();
    }

     
    function changeStart(uint256 _time) public onlyOwner {
        startTime = _time;
        SaleWillStart(_time);
    }

     
    function endSale(bool end) public onlyOwner {
        require(startTime <= now);
        uint256 tokensLeft = maxTokens - token.totalSupply();
        if (tokensLeft > 0) {
            token.mint(wallet, tokensLeft);
        }
        hasEnded = end;
        SaleEnds(tokensLeft);
    }

     
    function finalization() internal {
        token.finishMinting();
        token.transferOwnership(wallet);
    }

     
    function cleanUp() public onlyOwner {
        require(isFinalized);
        selfdestruct(owner);
    }

}