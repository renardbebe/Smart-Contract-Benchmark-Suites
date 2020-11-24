 

 
 
 
 
 

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

contract MultiOwnable {

    mapping (address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    function MultiOwnable() public {
         
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }
    
    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

     
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        OwnerAddedEvent(owner);
    }

     
    function removeOwner(address owner) onlyOwner public {
        require(isOwner[owner]);
        isOwner[owner] = false;
        OwnerRemovedEvent(owner);
    }
}

contract Pausable is MultiOwnable {

    bool public paused;

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier ifPaused {
        require(paused);
        _;
    }

     
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

     
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20 {
    
    using SafeMath for uint;

    mapping(address => uint256) balances;
    
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
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

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CommonToken is StandardToken, MultiOwnable {
    
    string public constant name   = 'FTEC';
    string public constant symbol = 'FTEC';
    uint8 public constant decimals = 18;
    
    uint256 public saleLimit;    
    uint256 public teamTokens;   
     
    
     
    address public teamWallet;  
    
    uint public unlockTeamTokensTime = now + 1 years;

     
    address public seller;  

    uint256 public tokensSold;  
    uint256 public totalSales;  

     
    bool public locked = true;
    
    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    function CommonToken(
        address _seller,
        address _teamWallet
    ) MultiOwnable() public {
        
        totalSupply = 998400000 ether;
        saleLimit   = 848640000 ether;
        teamTokens  =  69888000 ether;

        seller = _seller;
        teamWallet = _teamWallet;

        uint sellerTokens = totalSupply - teamTokens;
        balances[seller] = sellerTokens;
        Transfer(0x0, seller, sellerTokens);
        
        balances[teamWallet] = teamTokens;
        Transfer(0x0, teamWallet, teamTokens);
    }
    
    modifier ifUnlocked(address _from) {
        require(!locked);
        
         
        if (_from == teamWallet) {
            require(now >= unlockTeamTokensTime);
        }
        
        _;
    }
    
     
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        Unlock();
    }

     
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);
        
         
        require(balances[newSeller] == 0);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

     
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner public returns (bool) {

         
        require(tokensSold.add(_value) <= saleLimit);

        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[seller]);

        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        SellEvent(seller, _to, _value);
        return true;
    }
    
     
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender) public returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);
        return true;
    }
}

contract CommonTokensale is MultiOwnable, Pausable {
    
    using SafeMath for uint;
    
    address public beneficiary1;
    address public beneficiary2;
    address public beneficiary3;
    
     
    uint public balance1;
    uint public balance2;
    uint public balance3;
    
     
    CommonToken public token;

    uint public minPaymentWei = 0.1 ether;
    
    uint public minCapWei;
    uint public maxCapWei;

    uint public startTime;
    uint public endTime;
    
     
    
    uint public totalTokensSold;   
    uint public totalWeiReceived;  
    
     
    mapping (address => uint256) public buyerToSentWei;
    
    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    
    function CommonTokensale(
        address _token,
        address _beneficiary1,
        address _beneficiary2,
        address _beneficiary3,
        uint _startTime,
        uint _endTime
    ) MultiOwnable() public {

        require(_token != address(0));
        token = CommonToken(_token);

        beneficiary1 = _beneficiary1;
        beneficiary2 = _beneficiary2;
        beneficiary3 = _beneficiary3;

        startTime = _startTime;
        endTime   = _endTime;
    }

     
    function() public payable {
        sellTokensForEth(msg.sender, msg.value);
    }
    
    function sellTokensForEth(
        address _buyer, 
        uint256 _amountWei
    ) ifNotPaused internal {
        
        require(startTime <= now && now <= endTime);
        require(_amountWei >= minPaymentWei);
        require(totalWeiReceived.add(_amountWei) <= maxCapWei);

        uint tokensE18 = weiToTokens(_amountWei);
         
        require(token.sell(_buyer, tokensE18));
        
         
        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        ReceiveEthEvent(_buyer, _amountWei);
        
         
        uint part = _amountWei / 3;
        balance1 = balance1.add(_amountWei - part * 2);
        balance2 = balance2.add(part);
        balance3 = balance3.add(part);
    }
    
     
    function weiToTokens(uint _amountWei) public view returns (uint) {
        return _amountWei.mul(tokensPerWei(_amountWei));
    }
    
    function tokensPerWei(uint _amountWei) public view returns (uint256) {
        uint expectedTotal = totalWeiReceived.add(_amountWei);
        
         
        if (expectedTotal <  1000 ether) return 39960;
        if (expectedTotal <  2000 ether) return 37480;
        if (expectedTotal <  4000 ether) return 35270;
        
         
        if (expectedTotal <  6000 ether) return 33300; 
        if (expectedTotal <  8000 ether) return 32580;
        if (expectedTotal < 11000 ether) return 31880;
        if (expectedTotal < 15500 ether) return 31220;
        if (expectedTotal < 20500 ether) return 30590;
        if (expectedTotal < 26500 ether) return 29970;
        
        return 29970;  
    }
    
    function canWithdraw() public view returns (bool);
    
    function withdraw1(address _to) public {
        require(canWithdraw());
        require(msg.sender == beneficiary1);
        require(balance1 > 0);
        
        uint bal = balance1;
        balance1 = 0;
        _to.transfer(bal);
    }
    
    function withdraw2(address _to) public {
        require(canWithdraw());
        require(msg.sender == beneficiary2);
        require(balance2 > 0);
        
        uint bal = balance2;
        balance2 = 0;
        _to.transfer(bal);
    }
    
    function withdraw3(address _to) public {
        require(canWithdraw());
        require(msg.sender == beneficiary3);
        require(balance3 > 0);
        
        uint bal = balance3;
        balance3 = 0;
        _to.transfer(bal);
    }
}

contract Presale is CommonTokensale {
    
     
     
    uint public refundDeadlineTime;

     
    uint public totalWeiRefunded;
    
    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);
    
    function Presale(
        address _token,
        address _beneficiary1,
        address _beneficiary2,
        address _beneficiary3,
        uint _startTime,
        uint _endTime
    ) CommonTokensale(
        _token,
        _beneficiary1,
        _beneficiary2,
        _beneficiary3,
        _startTime,
        _endTime
    ) public {
        minCapWei = 2000 ether;
        maxCapWei = 4000 ether;
        refundDeadlineTime = _endTime + 3 * 30 days;
    }

     
    function canWithdraw() public view returns (bool) {
        return totalWeiReceived >= minCapWei || now > refundDeadlineTime;
    }
    
     
    function canRefund() public view returns (bool) {
        return totalWeiReceived < minCapWei && endTime < now && now <= refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());
        
        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);
        
         
        uint newBal = this.balance.sub(amount);
        uint part = newBal / 3;
        balance1 = newBal - part * 2;
        balance2 = part;
        balance3 = part;
        
        RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        totalWeiRefunded = totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}

contract ProdPresale is Presale {
    function ProdPresale() Presale(
        0x6BeC54E4fEa5d541fB14de96993b8E11d81159b2,
        0x5cAEDf960efC2F586B0260B8B4B3C5738067c3af, 
        0xec6014B7FF9E510D43889f49AE019BAD6EA35039, 
        0x234066EEa7B0E9539Ef1f6281f3Ca8aC5e922363, 
        1524578400, 
        1526997600 
    ) public {}
}