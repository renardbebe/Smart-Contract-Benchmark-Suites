 

pragma solidity ^0.4.18;

 
contract Ownable {
    address public owner;
     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner()  {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

 
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
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
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

    mapping (address => mapping (address => uint256)) allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
      function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
      }

       
      function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
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

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(0X0, _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract StrikeCoin is MintableToken, Pausable{
    string public name = "StrikeCoin Token";
    string public symbol = "STC";
    uint256 public decimals = 18;

    event Ev(string message, address whom, uint256 val);

    struct XRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct QueueRecord {
        address whom;
        uint256 val;
    }

    address first = 0x0;
    address last = 0x0;

    mapping (address => XRec) public theList;

    QueueRecord[]  theQueue;

     
    function add(address whom, uint256 value) internal {
        theList[whom] = XRec(true,0x0,last,value);
        if (last != 0x0) {
            theList[last].next = whom;
        } else {
            first = whom;
        }
        last = whom;
        Ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = XRec(false,0x0,0x0,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        theList[whom] =XRec(false,0x0,0x0,0);
        Ev("remove",whom,0);
    }

    function update(address whom, uint256 value) internal {
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                Ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
            remove(whom);
        }
    }

     
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        bool result = super.transfer(_to, _value);
        update(msg.sender,balances[msg.sender]);
        update(_to,balances[_to]);
        return result;
    }

     
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        update(_from,balances[_from]);
        update(_to,balances[_to]);
        return result;
    }

     

    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        bool result = super.mint(_to,_amount);
        update(_to,balances[_to]);
        return result;
    }

    function StrikeCoin()  public{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract StrikeCoinCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    StrikeCoin public token = new StrikeCoin();

     
    uint256 public startTimestamp = 1516773600;
    uint256 public endTimestamp = 1519452000;
    uint256 etherToWei = 10**18;

     
    address public hardwareWallet = 0xb0c7fc7fFe80867A5Bd2e31e43d4D494085321B3;
    address public restrictedWallet = 0xD36AA5Eaf6B1D6eC896E4A110501a872773a0125;
    address public bonusWallet = 0xb9325bd27e91D793470F84e9B3550596d34Bbe26;

    mapping (address => uint256) public deposits;
    uint256 public numberOfPurchasers;

     
    uint[] private bonus = [8,8,4,4,2,2,0,0,0,0];
    uint256 public rate = 2400;  

     
    uint256 public weiRaised;
    uint256 public tokensSold;
    uint256 public tokensGranted = 0;

    uint256 public minContribution = 1 finney;
    uint256 public hardCapEther = 50000;
    uint256 hardcap = hardCapEther * etherToWei;
    uint256 maxBonusRate = 20;   

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event MainSaleClosed();

    uint256 public weiRaisedInPresale  = 0 ether;
    uint256 public grantedTokensHardCap ;


    function setWallet(address _wallet) public onlyOwner {
        require(_wallet != 0x0);
        hardwareWallet = _wallet;
    }

    function setRestrictedWallet(address _restrictedWallet) public onlyOwner {
        require(_restrictedWallet != 0x0);
        restrictedWallet = _restrictedWallet;
    }

    function setHardCapEther(uint256 newEtherAmt) public onlyOwner{
        require(newEtherAmt > 0);
        hardCapEther = newEtherAmt;
        hardcap = hardCapEther * etherToWei;
        grantedTokensHardCap = etherToWei * hardCapEther*rate*40/60*(maxBonusRate+100)/100;
    }

    function StrikeCoinCrowdsale() public  {

        grantedTokensHardCap = etherToWei * hardCapEther*rate*40/60*(maxBonusRate+100)/100;
        require(startTimestamp >= now);
        require(endTimestamp >= startTimestamp);
    }

     
    modifier validPurchase {
        require(now >= startTimestamp);
        require(now < endTimestamp);
        require(msg.value >= minContribution);
        _;
    }

     
    function hasEnded() public constant returns (bool) {
        if (now > endTimestamp)
            return true;
        return false;
    }

     
    function buyTokens(address beneficiary) public payable   validPurchase {
        require(beneficiary != 0x0);

        uint256 weiAmount = msg.value;

        if (deposits[msg.sender] == 0) {
            numberOfPurchasers++;
        }
        deposits[msg.sender] = weiAmount.add(deposits[msg.sender]);

        uint256 daysInSale = (now - startTimestamp) / (1 days);
        uint256 thisBonus = 0;
        if(daysInSale < 7 ){
            thisBonus = bonus[daysInSale];
        }

         
        uint256 tokens = weiAmount.mul(rate);
        uint256 extraBonus = tokens.mul(thisBonus);
        extraBonus = extraBonus.div(100);
        uint256 finalTokenCount ;
        tokens = tokens.add(extraBonus);
        finalTokenCount = tokens.add(tokensSold);
        uint256 weiRaisedSoFar = weiRaised.add(weiAmount);
        require(weiRaisedSoFar + weiRaisedInPresale <= hardcap);

        weiRaised = weiRaisedSoFar;
        tokensSold = finalTokenCount;

        token.mint(beneficiary, tokens);
        hardwareWallet.transfer(msg.value);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function grantTokens(address beneficiary,uint256 stcTokenCount) public onlyOwner{
        stcTokenCount = stcTokenCount * etherToWei;
        uint256 finalGrantedTokenCount = tokensGranted.add(stcTokenCount);
        require(finalGrantedTokenCount<grantedTokensHardCap);
        tokensGranted = finalGrantedTokenCount;
        token.mint(beneficiary,stcTokenCount);
    }
     
    function finishMinting() public onlyOwner returns(bool){
        require(hasEnded());

         
        uint256 deltaBonusTokens = tokensSold-weiRaised*rate;
        uint256 bonusTokens = weiRaised*maxBonusRate*rate/100-deltaBonusTokens;

         
        token.mint(bonusWallet,bonusTokens);

         
        uint256 preICOTokens = weiRaisedInPresale*3000;
        token.mint(bonusWallet,preICOTokens);

        uint issuedTokenSupply = token.totalSupply();

        uint restrictedTokens = (issuedTokenSupply-tokensGranted)*40/60-tokensGranted;  

        if(restrictedTokens>0){
            token.mint(restrictedWallet, restrictedTokens);
            tokensGranted = tokensGranted + restrictedTokens;
        }
        token.finishMinting();
        token.transferOwnership(owner);
        MainSaleClosed();
        return true;
    }

     
    function () payable public {
        buyTokens(msg.sender);
    }

    function setWeiRaisedInPresale(uint256 amount) onlyOwner public {
        require(amount>=0);
        weiRaisedInPresale = amount;
    }
    function setEndTimeStamp(uint256 end) onlyOwner public {
        require(end>now);
        endTimestamp = end;
    }
    function setStartTimeStamp(uint256 start) onlyOwner public {
        startTimestamp = start;
    }
    function setBonusAddress(address _bonusWallet) onlyOwner public {
        require(_bonusWallet != 0x0);
        bonusWallet = _bonusWallet;
    }
    function pauseTrading() onlyOwner public{
        token.pause();
    }
    function startTrading() onlyOwner public{
        token.unpause();
    }

    function changeTokenOwner(address newOwner) public onlyOwner {
        require(hasEnded());
        token.changeOwner(newOwner);
    }
}