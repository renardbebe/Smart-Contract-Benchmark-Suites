 

pragma solidity ^0.4.18;


 
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


 
contract Ownable {
    
     
    address public owner;
    
     
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner);

     
    function Ownable() public {
         
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

    uint256 public totalSupply = 0;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

}


contract MintableToken is ERC20Basic, Ownable {

    bool public mintingFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool);

     
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
  
}


 
contract StyrasToken is MintableToken {
  
    using SafeMath for uint256;

    string public name = "Styras";
    string public symbol = "STY";
    uint256 public decimals = 18;

    uint256 public reservedSupply;

    uint256 public publicLockEnd = 1516060800;  
    uint256 public partnersLockEnd = 1530230400;  
    uint256 public partnersMintLockEnd = 1514678400;  

    address public partnersWallet;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

     
    function StyrasToken(address partners, uint256 reserved) public {
        require(partners != address(0));
        partnersWallet = partners;
        reservedSupply = reserved;
        assert(publicLockEnd <= partnersLockEnd);
        assert(partnersMintLockEnd < partnersLockEnd);
    }

     
    function balanceOf(address investor) public constant returns (uint256 balanceOfInvestor) {
        return balances[investor];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0));
        require((msg.sender != partnersWallet && now >= publicLockEnd) || now >= partnersLockEnd);
        require(_amount > 0 && _amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
  
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0));
        require((_from != partnersWallet && now >= publicLockEnd) || now >= partnersLockEnd);
        require(_amount > 0 && _amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
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

     
    function burn(uint256 _value) public {
        require((msg.sender != partnersWallet && now >= publicLockEnd) || now >= partnersLockEnd);
        require(_value > 0 && _value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_to != partnersWallet);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function mintPartners(uint256 amount) onlyOwner canMint public returns (bool) {
        require(now >= partnersMintLockEnd);
        require(reservedSupply > 0);
        require(amount <= reservedSupply);
        totalSupply = totalSupply.add(amount);
        reservedSupply = reservedSupply.sub(amount);
        balances[partnersWallet] = balances[partnersWallet].add(amount);
        Mint(partnersWallet, amount);
        Transfer(address(0), partnersWallet, amount);
        return true;
    }
  
}


 
contract RefundVault is Ownable {
  
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _to) public {
        require(_to != address(0));
        wallet = _to;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        require(deposited[investor] > 0);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
  
}


contract Withdrawable is Ownable {

    bool public withdrawEnabled = false;
    address public wallet;

    event Withdrawed(uint256 weiAmount);
  
    function Withdrawable(address _to) public {
        require(_to != address(0));
        wallet = _to;
    }

    modifier canWithdraw() {
        require(withdrawEnabled);
        _;
    }
  
    function enableWithdraw() onlyOwner public {
        withdrawEnabled = true;
    }
  
     
    function withdraw(uint256 weiAmount) onlyOwner canWithdraw public {
        require(this.balance >= weiAmount);
        wallet.transfer(weiAmount);
        Withdrawed(weiAmount);
    }

}


contract StyrasVault is Withdrawable, RefundVault {
  
    function StyrasVault(address wallet) public
        Withdrawable(wallet)
        RefundVault(wallet) {
         
    }
  
    function balanceOf(address investor) public constant returns (uint256 depositedByInvestor) {
        return deposited[investor];
    }
  
    function enableWithdraw() onlyOwner public {
        require(state == State.Active);
        withdrawEnabled = true;
    }

}


 
contract StyrasCrowdsale is Ownable {

    using SafeMath for uint256;
  
    enum State { preSale, publicSale, hasFinalized }

     
     
     
     
    uint256 public rate;
    uint256 public goal;
    uint256 public cap;
    uint256 public minInvest = 100000000000000000;  

     
    uint256 public presaleDeadline = 1511827200;  
    uint256 public presaleRate = 4000;  
    uint256 public presaleCap = 50000000000000000000000000;  
  
     
    uint256 public pubsaleDeadline = 1514678400;  
    uint256 public pubsaleRate = 3000;  
    uint256 public pubsaleCap = 180000000000000000000000000;

     
    uint256 public reservedSupply = 20000000000000000000000000;  

    uint256 public softCap = 840000000000000000000000;  

     
     
    uint256 public startTime = 1511276400;  
    uint256 public endTime;

     
     
    uint256 public weiRaised = 0;
    address public escrowWallet;
    address public partnersWallet;

     
     
    StyrasToken public token;
    StyrasVault public vault;

    State public state;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event PresaleFinalized();
    event Finalized();

    function StyrasCrowdsale(address escrow, address partners) public {
        require(now < startTime);
        require(partners != address(0));
        require(startTime < presaleDeadline);
        require(presaleDeadline < pubsaleDeadline);
        require(pubsaleRate < presaleRate);
        require(presaleCap < pubsaleCap);
        require(softCap <= pubsaleCap);
        endTime = presaleDeadline;
        escrowWallet = escrow;
        partnersWallet = partners;
        token = new StyrasToken(partnersWallet, reservedSupply);
        vault = new StyrasVault(escrowWallet);
        rate = presaleRate;
        goal = softCap.div(rate);
        cap = presaleCap.div(rate);
        state = State.preSale;
        assert(goal < cap);
        assert(startTime < endTime);
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }
  
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(state < State.hasFinalized);
        require(validPurchase());
        uint256 weiAmount = msg.value;
         
        uint256 tokenAmount = weiAmount.mul(rate);
         
        weiRaised = weiRaised.add(weiAmount);
        token.mint(beneficiary, tokenAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
        assert(vault.balance == weiRaised);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = startTime <= now && now <= endTime;
        bool nonZeroPurchase = msg.value > 0;
        bool withinCap = weiRaised < cap;
        bool overMinInvest = msg.value >= minInvest || vault.balanceOf(msg.sender) >= minInvest;
        return withinPeriod && nonZeroPurchase && withinCap && overMinInvest;
    }

    function hardCap() public constant returns (uint256) {
        return pubsaleCap + reservedSupply;
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

     
    function hasEnded() public constant returns (bool) {
        bool afterPeriod = now > endTime;
        bool capReached = weiRaised >= cap;
        return afterPeriod || capReached;
    }

     
    function claimRefund() public {
        require(state == State.hasFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    function enableWithdraw() onlyOwner public {
        require(goalReached());
        vault.enableWithdraw();
    }
  
     
    function withdraw(uint256 _weiAmountToWithdraw) onlyOwner public {
        require(goalReached());
        vault.withdraw(_weiAmountToWithdraw);
    }

    function finalizePresale() onlyOwner public {
        require(state == State.preSale);
        require(hasEnded());
        uint256 weiDiff = 0;
        uint256 raisedTokens = token.totalSupply();
        rate = pubsaleRate;
        if (!goalReached()) {
            weiDiff = (softCap.sub(raisedTokens)).div(rate);
            goal = weiRaised.add(weiDiff);
        }
        weiDiff = (pubsaleCap.sub(raisedTokens)).div(rate);
        cap = weiRaised.add(weiDiff);
        endTime = pubsaleDeadline;
        state = State.publicSale;
        assert(goal < cap);
        assert(startTime < endTime);
        PresaleFinalized();
    }

     
    function finalize() onlyOwner public {
        require(state == State.publicSale);
        require(hasEnded());
        finalization();
        state = State.hasFinalized;
        Finalized();
    }

     
    function finalization() internal {
        if (goalReached()) {
            vault.close();
            token.mintPartners(reservedSupply);
        } else {
            vault.enableRefunds();
        }
        vault.transferOwnership(owner);
        token.transferOwnership(owner);
    }

}