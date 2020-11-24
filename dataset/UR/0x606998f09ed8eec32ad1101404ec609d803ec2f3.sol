 

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

   
  function Ownable() public{
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(owner==msg.sender);
    _;
 }

   
  function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
  }
}
  
contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BetleyToken is Ownable, ERC20 {

    using SafeMath for uint256;

     
    string public name = "BetleyToken";                
    string public symbol = "BETS";                      
    uint256 public decimals = 18;

    uint256 public _totalSupply = 1000000000e18;        
	
    uint256 public _mainsaleSupply = 350000000e18;      
    uint256 public _presaleSupply = 650000000e18;       
	
    uint256 public _saleSupply = 390000000e18;          
    uint256 public _teamSupply = 65000000e18;           
    uint256 public _advisorsSupply = 55250000e18;       
    uint256 public _platformSupply = 130000000e18;      
    uint256 public _bountySupply = 9750000e18;          

     
    address private _teamAddress = 0x5cFDe81cF1ACa91Ff8b7fEa63cFBF81B713BBf00;
    address private _advisorsAddress = 0xC9F2DE0826235767c95254E1887e607d9Af7aA81;
    address private _platformAddress = 0x572eE1910DD287FCbB109320098B7EcC33CB7e51;
    address private _bountyAddress = 0xb496FB1F0660CccA92D1B4B199eDcC4Eb8992bfA;
    uint256 public isDistributionTransferred = 0;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;
    
     
    uint256 public preSaleStartTime; 
    uint256 public mainSaleStartTime;

     
    address public multisig;

     
    address public sec_addr;

     
    uint256 public price;

    uint256 public minContribAmount = 0.1 ether;
    uint256 public maxContribAmount = 100 ether;

    uint256 public hardCap = 30000 ether;
    uint256 public softCap = 1200 ether;
    
     
    uint256 public presaleTotalNumberTokenSold=0;
    uint256 public mainsaleTotalNumberTokenSold=0;

    bool public tradable = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier canTradable() {
        require(tradable || ((now < mainSaleStartTime + 30 days) && (now > preSaleStartTime)));
        _;
    }

     
     
     
    function BetleyToken() public{
         
        multisig = 0x7BAD2a7C2c2E83f0a6E9Afbd3cC0029391F3B013;

        balances[multisig] = _totalSupply;

        preSaleStartTime = 1527811200;  
        mainSaleStartTime = 1533081600;  

        owner = msg.sender;

        sendTeamSupplyToken(_teamAddress);
        sendAdvisorsSupplyToken(_advisorsAddress);
        sendPlatformSupplyToken(_platformAddress);
        sendBountySupplyToken(_bountyAddress);
        isDistributionTransferred = 1;
    }

     
     
    function () external payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
        require(msg.value >= minContribAmount && msg.value <= maxContribAmount);
        price = getPrice();
        uint256 weiAmount = msg.value;
        uint256 tokenToSend = weiAmount.mul(price);
        
        require(tokenToSend > 0);
        if ((now > preSaleStartTime) && (now < preSaleStartTime + 60 days)) {
		
			require(_presaleSupply >= tokenToSend);
		
        } else if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 30 days)) {
            	
            require(_mainsaleSupply >= tokenToSend);
        
		}
        
        balances[multisig] = balances[multisig].sub(tokenToSend);
        balances[recipient] = balances[recipient].add(tokenToSend);
        
        if ((now > preSaleStartTime) && (now < preSaleStartTime + 60 days)) {
            
			presaleTotalNumberTokenSold = presaleTotalNumberTokenSold.add(tokenToSend);
            _presaleSupply = _presaleSupply.sub(tokenToSend);
        
		} else if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 30 days)) {
            
			mainsaleTotalNumberTokenSold = mainsaleTotalNumberTokenSold.add(tokenToSend);
            _mainsaleSupply = _mainsaleSupply.sub(tokenToSend);
        
		}

        address tar_addr = multisig;
        if (presaleTotalNumberTokenSold + mainsaleTotalNumberTokenSold > 10000000) {  
            tar_addr = sec_addr;
        }
        tar_addr.transfer(msg.value);
        TokenPurchase(msg.sender, recipient, weiAmount, tokenToSend);
    }

     
    function setSecurityWalletAddr(address addr) public onlyOwner {
        sec_addr = addr;
    }

     
    function sendTeamSupplyToken(address to) public onlyOwner {
        require ((to != 0x0) && (isDistributionTransferred == 0));

        balances[multisig] = balances[multisig].sub(_teamSupply);
        balances[to] = balances[to].add(_teamSupply);
        Transfer(multisig, to, _teamSupply);
    }

     
    function sendAdvisorsSupplyToken(address to) public onlyOwner {
        require ((to != 0x0) && (isDistributionTransferred == 0));

        balances[multisig] = balances[multisig].sub(_advisorsSupply);
        balances[to] = balances[to].add(_advisorsSupply);
        Transfer(multisig, to, _advisorsSupply);
    }
    
     
    function sendPlatformSupplyToken(address to) public onlyOwner {
        require ((to != 0x0) && (isDistributionTransferred == 0));

        balances[multisig] = balances[multisig].sub(_platformSupply);
        balances[to] = balances[to].add(_platformSupply);
        Transfer(multisig, to, _platformSupply);
    }
    
     
    function sendBountySupplyToken(address to) public onlyOwner {
        require ((to != 0x0) && (isDistributionTransferred == 0));

        balances[multisig] = balances[multisig].sub(_bountySupply);
        balances[to] = balances[to].add(_bountySupply);
        Transfer(multisig, to, _bountySupply);
    }
    
     
    function startTradable(bool _tradable) public onlyOwner {
        tradable = _tradable;
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
    function presaleTotalNumberTokenSold() public view returns (uint256) {
        return presaleTotalNumberTokenSold;
    }

     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

     
     
     
     
    function transfer(address to, uint256 value) public canTradable returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public canTradable returns (bool success)  {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }
    
     
     
    function getPrice() public view returns (uint256 result) {
        if ((now > preSaleStartTime) && (now < preSaleStartTime + 60 days) && (presaleTotalNumberTokenSold < _saleSupply)) {
            
			if ((now > preSaleStartTime) && (now < preSaleStartTime + 14 days)) {
                return 15000;
            } else if ((now >= preSaleStartTime + 14 days) && (now < preSaleStartTime + 28 days)) {
                return 13000;
            } else if ((now >= preSaleStartTime + 28 days) && (now < preSaleStartTime + 42 days)) {
                return 11000;
            } else if ((now >= preSaleStartTime + 42 days)) {
                return 10500;
            }
			
        } else if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 30 days) && (mainsaleTotalNumberTokenSold < _mainsaleSupply)) {
            if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 30 days)) {
                return 10000;
            }
        } else {
            return 0;
        }
    }
}