 

pragma solidity ^0.4.15;





 
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

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
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
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
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

     
    function increaseApproval(address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}





 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        if (a != 0 && c / a != b) revert();
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        if (b > a) revert();
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        if (c < a) revert();
        return c;
    }
}


 
contract VLBToken is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string public constant name = "VLB Tokens";
    string public constant symbol = "VLB";
    uint8 public decimals = 18;

     
    uint256 public constant publicTokens = 220 * 10 ** 24;

     
    uint256 public constant teamTokens = 20 * 10 ** 24;

     
    uint256 public constant bountyTokens = 10 * 10 ** 24;

     
    uint256 public constant wingsTokensReserv = 25 * 10 ** 23;
    
     
    uint256 public wingsTokensReward = 0;

     
    address public constant teamTokensWallet = 0x6a6AcA744caDB8C56aEC51A8ce86EFCaD59989CF;
    address public constant bountyTokensWallet = 0x91A7DE4ce8e8da6889d790B7911246B71B4c82ca;
    address public constant crowdsaleTokensWallet = 0x5e671ceD703f3dDcE79B13F82Eb73F25bad9340e;
    
     
    address public constant wingsWallet = 0xcbF567D39A737653C569A8B7dFAb617E327a7aBD;


     
    address public crowdsaleContractAddress;

     
    bool isFinished = false;

     
    modifier onlyCrowdsaleContract() {
        require(msg.sender == crowdsaleContractAddress);
        _;
    }

     
    event TokensBurnt(uint256 tokens);

     
    event Live(uint256 supply);

     
    event BountyTransfer(address indexed from, address indexed to, uint256 value);

     
    function VLBToken() {
         
        balances[teamTokensWallet] = balanceOf(teamTokensWallet).add(teamTokens);
        Transfer(address(0), teamTokensWallet, teamTokens);

         
        balances[bountyTokensWallet] = balanceOf(bountyTokensWallet).add(bountyTokens);
        Transfer(address(0), bountyTokensWallet, bountyTokens);

         
         
        uint256 crowdsaleTokens = publicTokens.sub(wingsTokensReserv);
        balances[crowdsaleTokensWallet] = balanceOf(crowdsaleTokensWallet).add(crowdsaleTokens);
        Transfer(address(0), crowdsaleTokensWallet, crowdsaleTokens);

         
        totalSupply = publicTokens.add(bountyTokens).add(teamTokens);
    }

     
    function setCrowdsaleAddress(address _crowdsaleAddress) onlyOwner external {
        require(_crowdsaleAddress != address(0));
        crowdsaleContractAddress = _crowdsaleAddress;

         
        uint256 balance = balanceOf(crowdsaleTokensWallet);
        allowed[crowdsaleTokensWallet][crowdsaleContractAddress] = balance;
        Approval(crowdsaleTokensWallet, crowdsaleContractAddress, balance);
    }

     
    function endTokensale() onlyCrowdsaleContract external {
        require(!isFinished);
        uint256 crowdsaleLeftovers = balanceOf(crowdsaleTokensWallet);
        
        if (crowdsaleLeftovers > 0) {
            totalSupply = totalSupply.sub(crowdsaleLeftovers).sub(wingsTokensReserv);
            wingsTokensReward = totalSupply.div(100);
            totalSupply = totalSupply.add(wingsTokensReward);

            balances[crowdsaleTokensWallet] = 0;
            Transfer(crowdsaleTokensWallet, address(0), crowdsaleLeftovers);
            TokensBurnt(crowdsaleLeftovers);
        } else {
            wingsTokensReward = wingsTokensReserv;
        }
        
        balances[wingsWallet] = balanceOf(wingsWallet).add(wingsTokensReward);
        Transfer(crowdsaleTokensWallet, wingsWallet, wingsTokensReward);

        isFinished = true;

        Live(totalSupply);
    }
}








 

 
contract VLBRefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}
    State public state;

    mapping (address => uint256) public deposited;

    address public constant wallet = 0x02D408bc203921646ECA69b555524DF3c7f3a8d7;

    address crowdsaleContractAddress;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function VLBRefundVault() {
        state = State.Active;
    }

    modifier onlyCrowdsaleContract() {
        require(msg.sender == crowdsaleContractAddress);
        _;
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
        require(_crowdsaleAddress != address(0));
        crowdsaleContractAddress = _crowdsaleAddress;
    }

    function deposit(address investor) onlyCrowdsaleContract external payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close(address _wingsWallet) onlyCrowdsaleContract external {
        require(_wingsWallet != address(0));
        require(state == State.Active);
        state = State.Closed;
        Closed();
        uint256 wingsReward = this.balance.div(100);
        _wingsWallet.transfer(wingsReward);
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyCrowdsaleContract external {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }

     
    function kill() onlyOwner {
        require(state == State.Closed);
        selfdestruct(owner);
    }
}



 
contract VLBCrowdsale is Ownable, Pausable {
    using SafeMath for uint;

     
    VLBToken public token;

     
    VLBRefundVault public vault;

     
    uint startTime = 1511352000;

     
    uint endTime = 1513512000;

     
    uint256 public constant minPresaleAmount = 100 * 10**18;  

     
    uint256 public constant goal = 25 * 10**21;   
    uint256 public constant cap  = 300 * 10**21;  

     
    uint256 public weiRaised;

     
    bool public isFinalized = false;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Finalized();

     
    function VLBCrowdsale(address _tokenAddress, address _vaultAddress) {
        require(_tokenAddress != address(0));
        require(_vaultAddress != address(0));

         
        token = VLBToken(_tokenAddress);
        vault = VLBRefundVault(_vaultAddress);
    }

     
    function() payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(validPurchase(msg.value));

        uint256 weiAmount = msg.value;

         
        address buyer = msg.sender;

         
        uint256 tokens = weiAmount.mul(getConversionRate());

        weiRaised = weiRaised.add(weiAmount);

        if (!token.transferFrom(token.crowdsaleTokensWallet(), beneficiary, tokens)) {
            revert();
        }

        TokenPurchase(buyer, beneficiary, weiAmount, tokens);

        vault.deposit.value(weiAmount)(buyer);
    }

     
    function validPurchase(uint256 _value) internal constant returns (bool) {
        bool nonZeroPurchase = _value != 0;
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = weiRaised.add(_value) <= cap;
         
        bool withinAmount = now >= startTime + 5 days || msg.value >= minPresaleAmount;

        return nonZeroPurchase && withinPeriod && withinCap && withinAmount;
    }

     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        bool timeIsUp = now > endTime;
        return timeIsUp || capReached;
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

         
        if (goalReached()) {
            vault.close(token.wingsWallet());
        } else {
            vault.enableRefunds();
        }

        token.endTokensale();
        isFinalized = true;

        Finalized();
    }

     
    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

     
    function getConversionRate() public constant returns (uint256) {
        if (now >= startTime + 20 days) {
            return 650;
             
        } else if (now >= startTime + 15 days) {
            return 715;
             
        } else if (now >= startTime + 10 days) {
            return 780;
             
        } else if (now >= startTime + 5 days) {
            return 845;
             
        } else if (now >= startTime) {
            return 910;
             
        }
        return 0;
    }

     
    function kill() onlyOwner whenPaused {
        selfdestruct(owner);
    }
}