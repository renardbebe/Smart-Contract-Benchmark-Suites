 

pragma solidity ^0.4.13;

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
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
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

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

contract Factory {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     

    function createContract(
        address newWallet,
        address newMarketingWallet,
        address newLiquidityReserveWallet,
        uint256 newIcoEtherMinCap,
        uint256 newIcoEtherMaxCap,
        uint256 totalPresaleRaised) returns(address created)
    {
        return new SomaIco(
                        newWallet,
                        newMarketingWallet,
                        newLiquidityReserveWallet,
                        newIcoEtherMinCap * 1 ether,
                        newIcoEtherMaxCap * 1 ether,
                        totalPresaleRaised
        );
    }

    function createTestNetContract(
        address wallet,
        address marketingWallet,
        address liquidityReserveWallet,
        uint256 newIcoEtherMinCap,
        uint256 newIcoEtherMaxCap,
        uint256 totalPresaleRaised) returns(address created)
    {
    
      
     
        address contractAddress = createContract(
            wallet,
            marketingWallet,
            liquidityReserveWallet,
            newIcoEtherMinCap,
            newIcoEtherMaxCap,
            totalPresaleRaised
        );

         

         

        return contractAddress;
    }

    function createMainNetContract(
        uint256 newIcoEtherMinCap,
        uint256 newIcoEtherMaxCap) returns(address created)
    {
         
        address wallet = 0x22c6731A21aD946Bcd934f62f04B2D06EBFbedC9;  
        address marketingWallet = 0x4A5467431b54C152E404EB702242E78030972DE7;  
        address liquidityReserveWallet = 0xdf398E0bE9e0Da2D8F8D687FD6B2c9082eEFC29a;

        uint256 totalPresaleRaised = 258405312277978624000;

        address contractAddress = createContract(
            wallet,
            marketingWallet,
            liquidityReserveWallet,
            newIcoEtherMinCap,
            newIcoEtherMaxCap,
            totalPresaleRaised
        );

         

         

        return contractAddress;
    }

    function transferOwnership(address owner, address contractAddress) public {
        Ownable ownableContract = Ownable(contractAddress);
        ownableContract.transferOwnership(owner);
    }

    function migratePresaleBalances(
        address icoContractAddress,
        address presaleContractAddress,
        address[] buyers) public
    {
        SomaIco icoContract = SomaIco(icoContractAddress);
        ERC20Basic presaleContract = ERC20Basic(presaleContractAddress);
        for (uint i = 0; i < buyers.length; i++) {
            address buyer = buyers[i];
            if (icoContract.balanceOf(buyer) > 0) {
                continue;
            }
            uint256 balance = presaleContract.balanceOf(buyer);
            if (balance > 0) {
                icoContract.manuallyAssignTokens(buyer, balance);
            }
        }
    }
}

contract SomaIco is PausableToken {
    using SafeMath for uint256;

    string public name = "Soma Community Token";
    string public symbol = "SCT";
    uint8 public decimals = 18;

    address public liquidityReserveWallet;  
    address public wallet;  
    address public marketingWallet;  

    uint256 public icoStartTimestamp;  
    uint256 public icoEndTimestamp;  

    uint256 public totalRaised = 0;  
    uint256 public totalSupply;  
    uint256 public marketingPool;  
    uint256 public tokensSold = 0;  

    bool public halted = false;  

    uint256 public icoEtherMinCap;  
    uint256 public icoEtherMaxCap;  
    uint256 public rate = 450;  

    event Burn(address indexed burner, uint256 value);

    function SomaIco(
        address newWallet,
        address newMarketingWallet,
        address newLiquidityReserveWallet,
        uint256 newIcoEtherMinCap,
        uint256 newIcoEtherMaxCap,
        uint256 totalPresaleRaised
    ) {
        require(newWallet != 0x0);
        require(newMarketingWallet != 0x0);
        require(newLiquidityReserveWallet != 0x0);
        require(newIcoEtherMinCap <= newIcoEtherMaxCap);
        require(newIcoEtherMinCap > 0);
        require(newIcoEtherMaxCap > 0);

        pause();

        icoEtherMinCap = newIcoEtherMinCap;
        icoEtherMaxCap = newIcoEtherMaxCap;
        wallet = newWallet;
        marketingWallet = newMarketingWallet;
        liquidityReserveWallet = newLiquidityReserveWallet;

         
         
         
         
         
        totalSupply = icoEtherMaxCap.mul(rate).mul(10).div(9);
        marketingPool = totalSupply.div(10);

         
        totalRaised = totalRaised.add(totalPresaleRaised);

         
        assignTokens(marketingWallet, marketingPool);
    }

     
    function () nonHalted nonZeroPurchase acceptsFunds payable {
        address recipient = msg.sender;
        uint256 weiAmount = msg.value;

        uint256 amount = weiAmount.mul(rate);

        assignTokens(recipient, amount);
        totalRaised = totalRaised.add(weiAmount);

        forwardFundsToWallet();
    }

    modifier acceptsFunds() {
        bool hasStarted = icoStartTimestamp != 0 && now >= icoStartTimestamp;
        require(hasStarted);

         
        bool isIcoInProgress = now <= icoEndTimestamp
                || (icoEndTimestamp == 0)  
                || totalRaised < icoEtherMinCap;
        require(isIcoInProgress);

        bool isBelowMaxCap = totalRaised < icoEtherMaxCap;
        require(isBelowMaxCap);

        _;
    }

    modifier nonHalted() {
        require(!halted);
        _;
    }

    modifier nonZeroPurchase() {
        require(msg.value > 0);
        _;
    }

    function forwardFundsToWallet() internal {
        wallet.transfer(msg.value);  
    }

    function assignTokens(address recipient, uint256 amount) internal {
        balances[recipient] = balances[recipient].add(amount);
        tokensSold = tokensSold.add(amount);

         
        if (tokensSold > totalSupply) {
             
             
             
            totalSupply = tokensSold;
        }

        Transfer(0x0, recipient, amount);
    }

    function setIcoDates(uint256 newIcoStartTimestamp, uint256 newIcoEndTimestamp) public onlyOwner {
        require(newIcoStartTimestamp < newIcoEndTimestamp);
        require(!isIcoFinished());
        icoStartTimestamp = newIcoStartTimestamp;
        icoEndTimestamp = newIcoEndTimestamp;
    }

    function setRate(uint256 _rate) public onlyOwner {
        require(!isIcoFinished());
        rate = _rate;
    }

    function haltFundraising() public onlyOwner {
        halted = true;
    }

    function unhaltFundraising() public onlyOwner {
        halted = false;
    }

    function isIcoFinished() public constant returns (bool icoFinished) {
        return (totalRaised >= icoEtherMinCap && icoEndTimestamp != 0 && now > icoEndTimestamp) ||
               (totalRaised >= icoEtherMaxCap);
    }

    function prepareLiquidityReserve() public onlyOwner {
        require(isIcoFinished());
        
        uint256 unsoldTokens = totalSupply.sub(tokensSold);
         
        require(unsoldTokens > 0);

         
        uint256 liquidityReserveTokens = tokensSold.div(10);
        if (liquidityReserveTokens > unsoldTokens) {
            liquidityReserveTokens = unsoldTokens;
        }
        assignTokens(liquidityReserveWallet, liquidityReserveTokens);
        unsoldTokens = unsoldTokens.sub(liquidityReserveTokens);

         
        if (unsoldTokens > 0) {
             
            totalSupply = totalSupply.sub(unsoldTokens);
        }

         
        assert(tokensSold == totalSupply);
    }

    function manuallyAssignTokens(address recipient, uint256 amount) public onlyOwner {
        require(tokensSold < totalSupply);
        assignTokens(recipient, amount);
    }

     
    function burn(uint256 _value) public whenNotPaused {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}