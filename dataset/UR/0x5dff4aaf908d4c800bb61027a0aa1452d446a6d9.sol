 

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

contract SuperOwners {

    address public owner1;
    address public pendingOwner1;
    
    address public owner2;
    address public pendingOwner2;

    function SuperOwners(address _owner1, address _owner2) internal {
        require(_owner1 != address(0));
        owner1 = _owner1;
        
        require(_owner2 != address(0));
        owner2 = _owner2;
    }

    modifier onlySuperOwner1() {
        require(msg.sender == owner1);
        _;
    }
    
    modifier onlySuperOwner2() {
        require(msg.sender == owner2);
        _;
    }
    
     
    modifier onlySuperOwner() {
        require(isSuperOwner(msg.sender));
        _;
    }
    
     
    function isSuperOwner(address _addr) public view returns (bool) {
        return _addr == owner1 || _addr == owner2;
    }

     
    function transferOwnership1(address _newOwner1) onlySuperOwner1 public {
        pendingOwner1 = _newOwner1;
    }
    
    function transferOwnership2(address _newOwner2) onlySuperOwner2 public {
        pendingOwner2 = _newOwner2;
    }

    function claimOwnership1() public {
        require(msg.sender == pendingOwner1);
        owner1 = pendingOwner1;
        pendingOwner1 = address(0);
    }
    
    function claimOwnership2() public {
        require(msg.sender == pendingOwner2);
        owner2 = pendingOwner2;
        pendingOwner2 = address(0);
    }
}

contract MultiOwnable is SuperOwners {

    mapping (address => bool) public ownerMap;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    function MultiOwnable(address _owner1, address _owner2) 
        SuperOwners(_owner1, _owner2) internal {}

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address owner) public view returns (bool) {
        return isSuperOwner(owner) || ownerMap[owner];
    }
    
    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

     
    function addOwner(address owner) onlySuperOwner public {
        require(owner != address(0));
        require(!ownerMap[owner]);
        ownerMap[owner] = true;
        ownerHistory.push(owner);
        OwnerAddedEvent(owner);
    }

     
    function removeOwner(address owner) onlySuperOwner public {
        require(ownerMap[owner]);
        ownerMap[owner] = false;
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

     
    function pause() external onlySuperOwner {
        paused = true;
    }

     
    function resume() external onlySuperOwner ifPaused {
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
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
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

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    string public version = 'v0.1';

    address public seller;      

    uint256 public saleLimit;   
    uint256 public tokensSold;  
    uint256 public totalSales;  

     
    bool public locked = true;
    
    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    function CommonToken(
        address _owner1,
        address _owner2,
        address _seller,
        string _name,
        string _symbol,
        uint256 _totalSupplyNoDecimals,
        uint256 _saleLimitNoDecimals
    ) MultiOwnable(_owner1, _owner2) public {

        require(_seller != address(0));
        require(_totalSupplyNoDecimals > 0);
        require(_saleLimitNoDecimals > 0);

        seller = _seller;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupplyNoDecimals * 1e18;
        saleLimit = _saleLimitNoDecimals * 1e18;
        balances[seller] = totalSupply;

        Transfer(0x0, seller, totalSupply);
    }
    
    modifier ifUnlocked(address _from, address _to) {
        require(!locked || isOwner(_from) || isOwner(_to));
        _;
    }
    
     
    function unlock() onlySuperOwner public {
        require(locked);
        locked = false;
        Unlock();
    }

    function changeSeller(address newSeller) onlySuperOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = balances[newSeller].add(unsoldTokens);
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
    
     
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender, _to) public returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value) ;
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);

        return true;
    }
}

contract RaceToken is CommonToken {
    
    function RaceToken() CommonToken(
        0x229B9Ef80D25A7e7648b17e2c598805d042f9e56,  
        0xcd7cF1D613D5974876AfBfd612ED6AFd94093ce7,  
        0x2821e1486D604566842FF27F626aF133FddD5f89,  
        'Coin Race',
        'RACE',
        100 * 1e6,  
        70 * 1e6    
    ) public {}
}

contract CommonTokensale is MultiOwnable, Pausable {
    
    using SafeMath for uint;
    
    uint public balance1;
    uint public balance2;
    
     
    RaceToken public token;

    uint public minPaymentWei = 0.001 ether;
    uint public tokensPerWei = 15000;
    uint public maxCapTokens = 6 * 1e6 ether;  
    
     
    
    uint public totalTokensSold;   
    uint public totalWeiReceived;  
    
     
    mapping (address => bool) public isBuyer;
    
    event ChangeTokenEvent(address indexed _oldAddress, address indexed _newAddress);
    event ChangeMaxCapTokensEvent(uint _oldMaxCap, uint _newMaxCap);
    event ChangeTokenPriceEvent(uint _oldPrice, uint _newPrice);
    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    
    function CommonTokensale(
        address _owner1,
        address _owner2
    ) MultiOwnable(_owner1, _owner2) public {}
    
    function setToken(address _token) onlySuperOwner public {
        require(_token != address(0));
        require(_token != address(token));
        
        ChangeTokenEvent(token, _token);
        token = RaceToken(_token);
    }
    
    function setMaxCapTokens(uint _maxCap) onlySuperOwner public {
        require(_maxCap > 0);
        ChangeMaxCapTokensEvent(maxCapTokens, _maxCap);
        maxCapTokens = _maxCap;
    }
    
    function setTokenPrice(uint _tokenPrice) onlySuperOwner public {
        require(_tokenPrice > 0);
        ChangeTokenPriceEvent(tokensPerWei, _tokenPrice);
        tokensPerWei = _tokenPrice;
    }

     
    function() public payable {
        sellTokensForEth(msg.sender, msg.value);
    }
    
    function sellTokensForEth(
        address _buyer, 
        uint256 _amountWei
    ) ifNotPaused public payable {
        
        require(_amountWei >= minPaymentWei);

        uint tokensE18 = weiToTokens(_amountWei);
        require(totalTokensSold.add(tokensE18) <= maxCapTokens);
        
         
        require(token.sell(_buyer, tokensE18));
        
         
        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        isBuyer[_buyer] = true;
        ReceiveEthEvent(_buyer, _amountWei);
        
        uint half = _amountWei / 2;
        balance1 = balance1.add(half);
        balance2 = balance2.add(_amountWei - half);
    }
    
     
    function weiToTokens(uint _amountWei) public view returns (uint) {
        return _amountWei.mul(tokensPerWei);
    }

    function withdraw1(address _to) onlySuperOwner1 public {
        if (balance1 > 0) _to.transfer(balance1);
    }
    
    function withdraw2(address _to) onlySuperOwner2 public {
        if (balance2 > 0) _to.transfer(balance2);
    }
}

contract Tokensale is CommonTokensale {
    
    function Tokensale() CommonTokensale(
        0x229B9Ef80D25A7e7648b17e2c598805d042f9e56,  
        0xcd7cF1D613D5974876AfBfd612ED6AFd94093ce7   
    ) public {}
}