 

pragma solidity ^0.4.17;

 
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
  bool public mintingFinished = false;

  mapping(address => uint256) releaseTime;
   
  modifier timeAllowed() {
    require(mintingFinished);
    require(now > releaseTime[msg.sender]);  
    _;
  }

   
  function transfer(address _to, uint256 _value) public timeAllowed returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function releaseAt(address _owner) public constant returns (uint256 date) {
    return releaseTime[_owner];
  }
   
  function changeReleaseAccount(address _owner, address _newowner) public returns (bool) {
    require(releaseTime[_owner] != 0 );
    require(releaseTime[_newowner] == 0 );
    balances[_newowner] = balances[_owner];
    releaseTime[_newowner] = releaseTime[_owner];
    balances[_owner] = 0;
    releaseTime[_owner] = 0;
    return true;
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(mintingFinished);
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public timeAllowed returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  event UnMint(address indexed from, uint256 amount);
  event MintFinished();

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount, uint256 _releaseTime) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    if ( _releaseTime > 0 ) {
        releaseTime[_to] = _releaseTime;
    }
    Mint(_to, _amount);
    return true;
  }
   
  function unMint(address _from) public onlyOwner returns (bool) {
    totalSupply = totalSupply.sub(balances[_from]);
    UnMint(_from, balances[_from]);
    balances[_from] = 0;
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}


contract ArconaToken is MintableToken {
    
    string public constant name = "Arcona Distribution Contract";
    string public constant symbol = "Arcona";
    uint32 public constant decimals = 3;  
   
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public multisig;
    address public restricted;
    address public registerbot;
    address public release6m;
    address public release12m;
    address public release18m;

    mapping (address => uint) public weiBalances;
    mapping (address => bool) registered;
    mapping (address => address) referral;
    mapping (string => address) certificate;

    uint restrictedPercent;
    uint refererPercent = 55;  
    uint bonusPeriod = 10;  

    ArconaToken public token = new ArconaToken();
    uint public startPreSale;
    uint public finishPreSale;
    uint public startSale;
    uint public finishSale;
    bool public isGlobalPause=false;
    uint public tokenTotal;   
    uint public totalWeiSale=0;
    bool public isFinished=false;

    uint public hardcap;
    uint public softcap;

    uint public ratePreSale = 400*10**3;  
    uint public rateSale = 400*10**3;  

    function Crowdsale(uint256 _startPreSale,uint256 _finishPreSale,uint256 _startSale,uint256 _finishSale,address _multisig,address _restricted,address _registerbot, address _release6m, address _release12m, address _release18m) public {
        multisig = _multisig;
        restricted = _restricted;
        registerbot = _registerbot;
        release6m = _release6m;
        release12m = _release12m;
        release18m = _release18m;
        startSale=_startSale;
        finishSale=_finishSale;
        startPreSale=_startPreSale;
        finishPreSale=_finishPreSale;
        restrictedPercent = 40;
        hardcap = 135000*10**18;
        softcap = 2746*10**18;
    }

    modifier isRegistered() {
        require (registered[msg.sender]);
        _;
    }

    modifier preSaleIsOn() {
        require(now > startPreSale && now < finishPreSale && !isGlobalPause);
        _;
    }

    modifier saleIsOn() {
        require(now > startSale && now < finishSale && !isGlobalPause);
        _;
    }

    modifier anySaleIsOn() {
        require((now > startPreSale && now < finishPreSale && !isGlobalPause) || (now > startSale && now < finishSale && !isGlobalPause));
        _;
    }

    modifier isUnderHardCap() {
        require(totalWeiSale <= hardcap);
        _;
    }

    function changeMultisig(address _new) public onlyOwner {
        multisig = _new;
    }

    function changeRegisterBot(address _new) public onlyOwner {
        registerbot = _new;
    }

    function changeRestricted(address _new) public onlyOwner {
        if (isFinished) {
            require(token.releaseAt(_new) == 0);
            token.changeReleaseAccount(restricted,_new);
        }
        restricted = _new;
    }

    function changeRelease6m(address _new) public onlyOwner {
        if (isFinished) {
            require(token.releaseAt(_new) == 0);
            token.changeReleaseAccount(release6m,_new);
        }
        release6m = _new;
    }

    function changeRelease12m(address _new) public onlyOwner {
        if (isFinished) {
            require(token.releaseAt(_new) == 0);
            token.changeReleaseAccount(release12m,_new);
        }
        release12m = _new;
    }

    function changeRelease18m(address _new) public onlyOwner {
        if (isFinished) {
            require(token.releaseAt(_new) == 0);
            token.changeReleaseAccount(release18m,_new);
        }
        release18m = _new;
    }

    function addCertificate(string _id,  address _owner) public onlyOwner {
        require(certificate[_id] == address(0));
        if (_owner != address(0)) {
            certificate[_id] = _owner;
        } else {
            certificate[_id] = owner;
        }    
    }

    function editCertificate(string _id,  address _newowner) public {
        require(certificate[_id] != address(0));
        require(msg.sender == certificate[_id] || msg.sender == owner);
        certificate[_id] = _newowner;
    }

    function checkCertificate(string _id) public view returns (address) {
        return certificate[_id];
    }

    function deleteCertificate(string _id) public onlyOwner {
        delete certificate[_id];
    }

    function registerCustomer(address _customer, address _referral) public {
        require(msg.sender == registerbot || msg.sender == owner);
        require(_customer != address(0));
        registered[_customer] = true;
        if (_referral != address(0) && _referral != _customer) {
            referral[_customer] = _referral;
        }
    }

    function checkCustomer(address _customer) public view returns (bool, address) {
        return ( registered[_customer], referral[_customer]);
    }
    function checkReleaseAt(address _owner) public constant returns (uint256 date) {
        return token.releaseAt(_owner);
    }

    function deleteCustomer(address _customer) public onlyOwner {
        require(_customer!= address(0));
        delete registered[_customer];
        delete referral[_customer];
         
        token.unMint(_customer);
        if ( weiBalances[_customer] > 0 ) {
            _customer.transfer(weiBalances[_customer]);
            weiBalances[_customer] = 0;
        }
    }

    function globalPause(bool _state) public onlyOwner {
        isGlobalPause = _state;
    }

    function changeRateSale(uint _tokenAmount) public onlyOwner {
        require(isGlobalPause || (now > startSale && now < finishSale));
        rateSale = _tokenAmount;
    }

    function changeRatePreSale(uint _tokenAmount) public onlyOwner {
        require(isGlobalPause || (now > startPreSale && now < finishPreSale));
        ratePreSale = _tokenAmount;
    }

    function changeStartPreSale(uint256 _ts) public onlyOwner {
        startPreSale = _ts;
    }

    function changeFinishPreSale(uint256 _ts) public onlyOwner {
        finishPreSale = _ts;
    }

    function changeStartSale(uint256 _ts) public onlyOwner {
        startSale = _ts;
    }

    function changeFinishSale(uint256 _ts) public onlyOwner {
        finishSale = _ts;
    }

    function finishMinting() public onlyOwner {
        require(totalWeiSale >= softcap);
        require(!isFinished);
        multisig.transfer(this.balance);
        uint issuedTokenSupply = token.totalSupply();
         
        uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
        issuedTokenSupply = issuedTokenSupply.add(restrictedTokens);
         
        token.mint(restricted, issuedTokenSupply.mul(13).div(100), now);
         
        token.mint(release6m, issuedTokenSupply.mul(85).div(1000), now + 180 * 1 days);  
        token.mint(release12m, issuedTokenSupply.mul(85).div(1000), now + 365 * 1 days);  
        token.mint(release18m, issuedTokenSupply.mul(10).div(100), now + 545 * 1 days);  
        tokenTotal=token.totalSupply();
        token.finishMinting();
        isFinished=true;
    }

    function foreignBuyTest(uint256 _weiAmount, uint256 _rate) public pure returns (uint tokenAmount) {
        require(_weiAmount > 0);
        require(_rate > 0);
        return _rate.mul(_weiAmount).div(1 ether);
    }

    function foreignBuy(address _holder, uint256 _weiAmount, uint256 _rate) public isUnderHardCap preSaleIsOn onlyOwner {
        require(_weiAmount > 0);
        require(_rate > 0);
        registered[_holder] = true;
        uint tokens = _rate.mul(_weiAmount).div(1 ether);
        token.mint(_holder, tokens, 0);
        tokenTotal = token.totalSupply();
        totalWeiSale = totalWeiSale.add(_weiAmount);
    }

     
    function refund() public {
        require(totalWeiSale <= softcap && now >= finishSale);
        require(weiBalances[msg.sender] > 0);
        token.unMint(msg.sender);
        msg.sender.transfer(weiBalances[msg.sender]);
        totalWeiSale = totalWeiSale.sub(weiBalances[msg.sender]);
        tokenTotal = token.totalSupply();
        weiBalances[msg.sender] = 0;
    }

    function buyTokensPreSale() public isRegistered isUnderHardCap preSaleIsOn payable {
        uint tokens = ratePreSale.mul(msg.value).div(1 ether);
        require(tokens >= 10000);  
        multisig.transfer(msg.value);
        uint bonusValueTokens = 0;
        uint saleEther = (msg.value).mul(10).div(1 ether);
        if (saleEther >= 125 && saleEther < 375 ) {  
            bonusValueTokens = tokens.mul(15).div(100);
        } else if (saleEther >= 375 && saleEther < 750 ) {  
            bonusValueTokens = tokens.mul(20).div(100);
        } else if (saleEther >= 750 && saleEther < 1250 ) {  
            bonusValueTokens=tokens.mul(25).div(100);
        } else if (saleEther >= 1250  ) {  
            bonusValueTokens = tokens.mul(30).div(100);
        }
        tokens = tokens.add(bonusValueTokens);
        totalWeiSale = totalWeiSale.add(msg.value); 
        token.mint(msg.sender, tokens, 0);
        if ( referral[msg.sender] != address(0) ) {
            uint refererTokens = tokens.mul(refererPercent).div(1000);
            token.mint(referral[msg.sender], refererTokens, 0);
        }
        tokenTotal=token.totalSupply();
    }

    function createTokens() public isRegistered isUnderHardCap saleIsOn payable {
        uint tokens = rateSale.mul(msg.value).div(1 ether);
        require(tokens >= 10000);  
        uint bonusTokens = 0;
        if ( now < startSale + (bonusPeriod * 1 days) ) {
            uint percent = bonusPeriod - (now - startSale).div(1 days);
            if ( percent > 0 ) {
                bonusTokens = tokens.mul(percent).div(100);
            }
        }
        tokens=tokens.add(bonusTokens);
        totalWeiSale = totalWeiSale.add(msg.value);
        token.mint(msg.sender, tokens, 0);
        if ( referral[msg.sender] != address(0) ) {
            uint refererTokens = tokens.mul(refererPercent).div(1000);
            token.mint(referral[msg.sender], refererTokens, 0);
        }
        tokenTotal=token.totalSupply();
        weiBalances[msg.sender] = weiBalances[msg.sender].add(msg.value);
    }

    function createTokensAnySale() public isUnderHardCap anySaleIsOn payable {
        if ((now > startPreSale && now < finishPreSale) && !isGlobalPause) {
            buyTokensPreSale();
        } else if ((now > startSale && now < finishSale) && !isGlobalPause) {
            createTokens();
        } else {
            revert();
        }
    }

    function() external anySaleIsOn isUnderHardCap payable {
        createTokensAnySale();
    }
    
}