 

pragma solidity >=0.4.22 <0.6.0;

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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor() public {
        owner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner,"Owner can call this function.");
        _;
    }
   
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"Use new owner address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    } 
}

  
contract ERC223 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function roleOf(address who) public view returns (uint256);
    function setUserRole(address _user_address, uint256 _role_define) public;
    function transfer(address to, uint256 value) public;
    function transfer(address to, uint value, bytes memory data) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract WRTToken is Ownable, ERC223 {
    using SafeMath for uint256;
     
    string public name = "Warrior Token";
    string public symbol = "WRT";
    uint256 public decimals = 18;
    uint256 public numberDecimal18 = 1000000000000000000;
    uint256 public RATE = 360e18;

     
    uint256 public _totalSupply = 100000000e18;
    uint256 public _presaleSupply = 5000000e18;  
    uint256 public _projTeamSupply = 5000000e18;  
    uint256 public _PartnersSupply = 10000000e18;  
    uint256 public _PRSupply = 9000000e18;  
    uint256 public _metaIcoSupply = 1000000e18;  
    uint256 public _icoSupply = 30000000e18;  

     
    uint256 public totalNumberTokenSoldMainSale = 0;
    uint256 public totalNumberTokenSoldPreSale = 0;

    uint256 public softCapUSD = 5000000;
    uint256 public hardCapUSD = 10000000;
    
    bool public mintingFinished = false;
    bool public tradable = true;
    bool public active = true;


     
    mapping (address => uint256) balances;
    
     
     
    
    mapping (address => uint256) role;
    
     
    mapping (address => uint256) vault;

     
    mapping (address => mapping(address => uint256)) allowed;

    mapping (address => bool) whitelist;

     
    uint256 public mainSaleStartTime; 
    uint256 public mainSaleEndTime;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    
    uint256 public projsealDate;  
    uint256 public partnersealDate;  


    uint256 contractDeployedTime;
    

     
    address payable public  multisig;

     

    event MintFinished();
    event StartTradable();
    event PauseTradable();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Burn(address indexed burner, uint256 value);


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier canTradable() {
        require(tradable);
        _;
    }

    modifier isActive() {
        require(active);
        _;
    }
    
    modifier saleIsOpen(){
        require((mainSaleStartTime <= now && now <= mainSaleEndTime) || (preSaleStartTime <= now && now <= preSaleEndTime));
        _;
    }

     
     
     
    constructor(address payable _multisig, uint256 _preSaleStartTime, uint256 _mainSaleStartTime) public {
        require(_multisig != address(0x0),"Invalid address.");
        require(_mainSaleStartTime > _preSaleStartTime);
        multisig = _multisig;


        mainSaleStartTime = _mainSaleStartTime;
        preSaleStartTime = _preSaleStartTime;
         
        mainSaleEndTime = mainSaleStartTime + 60 days;
        preSaleEndTime = preSaleStartTime + 60 days;
        contractDeployedTime = now;

        balances[multisig] = _totalSupply;

         
        projsealDate = mainSaleEndTime + 180 days;
         
        partnersealDate = mainSaleEndTime + 365 days;

        owner = msg.sender;
    }

    function getTimePassed() public view returns (uint256) {
        return (now - contractDeployedTime).div(1 days);
    }

    function isPresale() public view returns (bool) {
        return now < preSaleEndTime && now > preSaleStartTime;
    }


    function applyBonus(uint256 tokens) public view returns (uint256) {
        if ( now < (preSaleStartTime + 1 days) ) {
            return tokens.mul(20).div(10);  
        } else if ( now < (preSaleStartTime + 7 days) ) {
            return tokens.mul(15).div(10);  
        } else if ( now < (preSaleStartTime + 14 days) ) {
            return tokens.mul(13).div(10);  
        } else if ( now < (preSaleStartTime + 21 days) ) {
            return tokens.mul(115).div(100);  
        } else if ( now < (preSaleStartTime + 28 days) ) {
            return tokens.mul(11).div(10);  
        } 
        return tokens;  
    }

     
     
    function () external payable {        
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) internal saleIsOpen isActive {
        require(recipient != address(0x0));
        require(validPurchase());
        require(whitelisted(recipient));
        
        uint256 weiAmount = msg.value;
        uint256 numberToken = weiAmount.mul(RATE).div(1 ether);

        numberToken = applyBonus(numberToken);
        
         
        require(numberToken >= 333e18 && numberToken <= 350000e18);

        
         
        if (isPresale()) {
            require(_presaleSupply >= numberToken);
            totalNumberTokenSoldPreSale = totalNumberTokenSoldPreSale.add(numberToken);
            _presaleSupply = _presaleSupply.sub(numberToken);
         
        } else {
            require(_icoSupply >= numberToken);
            totalNumberTokenSoldMainSale = totalNumberTokenSoldMainSale.add(numberToken);
            _icoSupply = _icoSupply.sub(numberToken);
        }
    
        updateBalances(recipient, numberToken);
        forwardFunds();
        whitelist[recipient] = false;
    }

    function transFromProjTeamSupply(address receiver, uint256 tokens) public onlyOwner {
 
        require(tokens <= _projTeamSupply);
        updateBalances(receiver, tokens);
        _projTeamSupply = _projTeamSupply.sub(tokens);
        role[receiver] = 2;
    }

    function transFromPartnersSupply(address receiver, uint256 tokens) public onlyOwner {
        require(tokens <= _PartnersSupply);
        updateBalances(receiver, tokens);        
        _PartnersSupply = _PartnersSupply.sub(tokens);
        role[receiver] = 4;
    }
    
    function setUserRole(address _user, uint256 _role) public onlyOwner {
        role[_user] = _role;
    }

    function transFromPRSupply(address receiver, uint256 tokens) public onlyOwner {
        require(tokens <= _PRSupply);
        updateBalances(receiver, tokens);
        _PRSupply = _PRSupply.sub(tokens);
        role[receiver] = 5;
    }

    function transFromMetaICOSupply(address receiver, uint256 tokens) public onlyOwner {
        require(tokens <= _metaIcoSupply);
        updateBalances(receiver, tokens);
        _metaIcoSupply = _metaIcoSupply.sub(tokens);
        role[receiver] = 6;
    }

    function setWhitelistStatus(address user, bool status) public onlyOwner returns (bool) {

        whitelist[user] = status; 
        
        return whitelist[user];
    }
    
    function setWhitelistForBulk(address[] memory listAddresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < listAddresses.length; i++) {
            whitelist[listAddresses[i]] = status;
        }
    }

     
    function transferToAll(address[] memory tos, uint256[] memory values) public onlyOwner canTradable isActive {
        require(
            tos.length == values.length
            );
        
        for(uint256 i = 0; i < tos.length; i++){
            require(_icoSupply >= values[i]);   
            totalNumberTokenSoldMainSale = totalNumberTokenSoldMainSale.add(values[i]);
            _icoSupply = _icoSupply.sub(values[i]);
            updateBalances(tos[i],values[i]);
        }
    }

    function transferToAllInPreSale(address[] memory tos, uint256[] memory values) public onlyOwner canTradable isActive {
        require(
            tos.length == values.length
            );
        
        for(uint256 i = 0; i < tos.length; i++){
            require(_presaleSupply >= values[i]);   
            totalNumberTokenSoldPreSale = totalNumberTokenSoldPreSale.add(values[i]);
            _presaleSupply = _presaleSupply.sub(values[i]);
            updateBalances(tos[i],values[i]);
        }
    }
    
    function updateBalances(address receiver, uint256 tokens) internal {
        balances[multisig] = balances[multisig].sub(tokens);
        balances[receiver] = balances[receiver].add(tokens);
        emit Transfer(multisig, receiver, tokens);
    }

    function whitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }
    
     
     
    function forwardFunds()  internal {
       multisig.transfer(msg.value);
    }

    
     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = (now >= mainSaleStartTime && now <= mainSaleEndTime) || (now >= preSaleStartTime && now <= preSaleEndTime);
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public view returns (bool) {
        return now > mainSaleEndTime;
    }

    function hasPreSaleEnded() public view returns (bool) {
        return now > preSaleEndTime;
    }

     
    function changeMultiSignatureWallet(address payable _multisig) public onlyOwner isActive {
        multisig = _multisig;
    }

     
    function changeTokenRate(uint _tokenPrice) public onlyOwner isActive {
        RATE = _tokenPrice;
    }

     
    function finishMinting() public onlyOwner isActive {
        mintingFinished = true;
        emit MintFinished();
    }

     
    function startTradable(bool _tradable) public onlyOwner isActive {
        tradable = _tradable;
        if (tradable)
            emit StartTradable();
        else
            emit PauseTradable();
    }
    
    function setActive(bool _active) public onlyOwner {
        active = _active;
    }
    
     
    function changeMainSaleStartTime(uint256 _mainSaleStartTime) public onlyOwner {
        mainSaleStartTime = _mainSaleStartTime;
    }

     
    function changeMainSaleEndTime(uint256 _mainSaleEndTime) public onlyOwner {
        mainSaleEndTime = _mainSaleEndTime;
    }

    function changePreSaleStartTime(uint256 _preSaleStartTime) public onlyOwner {
        preSaleStartTime = _preSaleStartTime;
    }

     
    function changePreSaleEndTime(uint256 _preSaleEndTime) public onlyOwner {
        preSaleEndTime = _preSaleEndTime;
    }

     
    function changeTotalSupply(uint256 newSupply) public onlyOwner {
        _totalSupply = newSupply;
    }

     
    function changeICOSupply(uint256 newICOSupply) public onlyOwner {
        _icoSupply = newICOSupply;
    }

     
     
    function getRate() public view returns (uint256 result) {
        return RATE;
    }
    
    function getTokenDetail() public view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (name, symbol, mainSaleStartTime, mainSaleEndTime, preSaleStartTime, preSaleEndTime, _totalSupply, _icoSupply, _presaleSupply, totalNumberTokenSoldMainSale, totalNumberTokenSoldPreSale);
    }


     
    
     
     
     
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    function roleOf(address who) public view returns (uint256) {
        return role[who];
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(multisig, _value);
        
    }
    
     
    function transfer(address _to, uint _value, bytes memory _data) public {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }
        if(role[msg.sender] == 2)
        {
            require(now >= projsealDate,"you can not transfer yet");
        }
        if(role[msg.sender] == 3 || role[msg.sender] == 4)
        {
            require(now >= partnersealDate,"you can not transfer yet");
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
     
    function transfer(address _to, uint _value) public {
        uint codeLength;
        bytes memory empty;
        assembly {
             
            codeLength := extcodesize(_to)
        }
       if(role[msg.sender] == 2)
        {
            require(now >= projsealDate,"you can not transfer yet");
        }
        if(role[msg.sender] == 3 || role[msg.sender] == 4)
        {
            require(now >= partnersealDate,"you can not transfer yet");
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public canTradable isActive {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        if(role[from] == 2)
        {
            require(now >= projsealDate,"you can not transfer yet");
        }
        if(role[from] == 3 || role[from] == 4)
        {
            require(now >= partnersealDate,"you can not transfer yet");
        }
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
    }
     
     
     
     
     
    function approve(address spender, uint256 value) public isActive {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }
     
     
     
     
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }    
}